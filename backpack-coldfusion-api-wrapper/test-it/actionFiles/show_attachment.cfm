<cfset filePath = application.backPack.fileDirectory & "page_#url.id#/#url.fileName#" />

<cfif not fileExists(filePath) or structKeyExists(url, "flush") or structKeyExists(url, "reload")>
	
	<cfinvoke component="#application.backpack_obj#" method="getFile" returnvariable="theFile">
		<cfinvokeargument name="page_id" value="#url.id#" />
		<cfinvokeargument name="fileName" value="#url.fileName#" />
	</cfinvoke>
	
	<!--- <comment author="P. Klinkenberg"> if cfhttp returned a binary file as a frikkin stream, we will reset it to the usuable format 'byteArray' </comment> --->
	<cfif theFile.getClass().getName() eq "java.io.ByteArrayOutputStream">
		<cfset theFile = theFile.toByteArray() />
	</cfif>
	
	<!--- <comment author="P. Klinkenberg"> create directory if necessary</comment> --->
	<cfset pathToCreate = expandPath('/') />
	<cfif not directoryExists(filePath)>
		<cfloop list="#replaceNoCase(getDirectoryFromPath(filePath), pathToCreate, '')#" index="newDir" delimiters="/\">
			<cfset pathToCreate = pathToCreate & newDir & "/" />
			<cfif not directoryExists(pathToCreate)>
				<cfdirectory action="create" directory="#pathToCreate#" />
			</cfif>
		</cfloop>
	</cfif>
	
	<!--- <comment author="P. Klinkenberg"> write file to disk </comment> --->
	<cffile action="write" file="#filePath#" output="#theFile#" />
	
</cfif>
<cfset variables.mimeType_str = createObject("component", "nl.ongevraagdadvies.http.getFileMimeType").getFileMimeType(filePath) />

<cfheader name="Content-Disposition" value="attachment; filename=""#url.fileName#""" />
<cfcontent type="#variables.mimeType_str#" reset="yes" file="#filePath#" />
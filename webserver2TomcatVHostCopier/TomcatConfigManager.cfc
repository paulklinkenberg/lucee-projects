<cfcomponent output="no" extends="VHostsConfigManager">


	<!--- tomcatDefaultHostName: <Engine name="Catalina" defaultHost="localhost">...</Engine> --->
	<cfset variables.tomcatDefaultHostName = "localhost" />
	
	<!---	<Host name="www.tools.ik" appBase="webapps" unpackWARs="true" autoDeploy="true" xmlValidation="false" xmlNamespaceAware="false">
		<Context path="" docBase="/developing/tools/" />
		<!--Alias>[ENTER ALIAS DOMAIN]</Alias-->
	</Host>
	--->


	<cffunction name="writeContextXMLFile" access="public" returntype="void" output="no"
	hint="(re)writes the ROOT.xml file and containing directory in the Catalina directory for the given hostname">
		<cfargument name="host" type="string" required="yes" />
		<cfargument name="path" type="string" required="yes" />
		<cfset var hostConfRoot = getConfig().tomcatrootpath & "conf/Catalina/#arguments.host#" />
		<cfset var confContents = "<?xml version='1.0' encoding='utf-8'?>"
			& '<Context docBase="#rereplace(replace(arguments.path, '\', '/', 'all'), '/$', '')#"><WatchedResource>WEB-INF/web.xml</WatchedResource></Context>' />
		<cfif not DirectoryExists(hostConfRoot)>
			<cfdirectory action="create" directory="#hostConfRoot#" />
		</cfif>
		<cffile action="write" file="#hostConfRoot#/ROOT.xml" output="#confContents#" addnewline="no" />
	</cffunction>
	
	
	<cffunction name="removeContextXMLFile" access="public" returntype="void" output="no"
	hint="Tries to delete the ROOT.xml file and containing directory in the Catalina directory for the given hostname">
		<cfargument name="host" type="string" required="yes" />
		<cfset var hostConfRoot = getConfig().tomcatrootpath & "conf/Catalina/#arguments.host#/" />
		<cfset var qFiles = "" />
		<cfif directoryExists(hostConfRoot)>
			<cfdirectory action="list" directory="#hostConfRoot#" name="qFiles" />
			<cftry>
				<cfloop query="qFiles">
					<cfif qFiles.type eq "dir">
						<cfreturn />
					<cfelse>
						<cffile action="delete" file="#hostConfRoot##qFiles.name#" />
					</cfif>
				</cfloop>
				<cfdirectory action="delete" directory="#hostConfRoot#" />
				<cfcatch>
					<cfreturn />
				</cfcatch>
			</cftry>
		</cfif>
	</cffunction>
	
	
	<cffunction name="createTomcatVHosts" access="public" returntype="string" output="no">
		<cfargument name="VHosts" type="struct" required="yes" hint="key=hostname, value=webroot" />
		<cfset var allVHostTags = "" />
		<cfset var VHostTag = "" />
		<cfset var hostname = "" />
				
		<cfloop collection="#arguments.VHosts#" item="hostname">
			<cfsavecontent variable="VHostTag"><cfoutput>
				<Host name="<cfif hostname eq "_default_">#variables.tomcatDefaultHostName#<cfelse>#hostname#</cfif>" appBase="webapps" unpackWARs="true" autoDeploy="true" xmlValidation="false" xmlNamespaceAware="false" />
			</cfoutput></cfsavecontent>
			<cfset allVHostTags &= VHostTag />
		</cfloop>
		<cfset allVHostTags = rereplace(allVHostTags, '[\t]+', '', 'all') />
		<cfreturn allVHostTags />
	</cffunction>
	
	
	<cffunction name="overwriteVHostSettings" access="public" returntype="void">
		<cfargument name="VHostsText" type="string" required="yes" />
		<cfargument name="doBackup" type="boolean" required="no" default="yes" />
		<cfset var tomcatRoot = getConfig().tomcatrootpath />
		<cfset var tomcatFile = tomcatRoot & "conf/server.xml" />
		<cfset var tomcatConfigData = fileRead(tomcatfile) />
		<!--- remove all comments from the file --->
		<cfset var aComments = [] />
		<cfset var foundPos = "" />
		<cfloop condition="refind('<\!--.*?-->', tomcatConfigData)">
			<cfset foundPos = refind('<\!--.*?-->', tomcatConfigData, 1, true) />
			<cfset arrayAppend(aComments, mid(tomcatConfigData, foundPos.pos[1], foundPos.len[1])) />
			<cfset tomcatConfigData = replace(tomcatConfigData, aComments[arrayLen(aComments)], "$COMMENTHERE$") />
		</cfloop>
		
		<cfset var catalinaEngineRegex = "<Engine[[:space:]]+[^<>]*name=['""]Catalina['""].*?</Engine>" />
		<!--- get the part of the config file where the VHosts are stored for Railo --->
		<cfset var catalinaEngineData = rereplace(tomcatConfigData, ".+(" & catalinaEngineRegex & ").+", "\1") />
		<cfset catalinaEngineData = rereplace(catalinaEngineData, "<Host[[:space:]]([^>]+/>|.*?</Host>)", "", "all") />
		<!--- add the new hosts --->
		<cfset catalinaEngineData = replace(catalinaEngineData, "</Engine>", VHostsText & "</Engine>") />
		<!--- now change the file contents--->
		<cfset tomcatConfigData = rereplace(tomcatConfigData, catalinaEngineRegex, catalinaEngineData) />
		
		<!--- re-add the comments --->
		<cfloop from="1" to="#arrayLen(aComments)#" index="arrIndex">
			<cfset tomcatConfigData = replace(tomcatConfigData, "$COMMENTHERE$", aComments[arrIndex]) />
		</cfloop>
		
		<!--- backup old file? --->
		<cfif arguments.doBackup>
			<cfset backupFile(tomcatfile) />
		</cfif>
		<!--- write the new config file --->
		<cfset fileWrite(tomcatFile, tomcatConfigData) />
		
		<!--- now write the <Context>s into the appropriate files --->
		
	</cffunction>


</cfcomponent>
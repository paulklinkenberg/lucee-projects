<cfcomponent output="no" hint="Parses webserver config files to get the (virtual) hosts" extends="VHostsConfig">
	
	<cfset variables.errorMailTo = "paul@ongevraagdadves.nl" />
	<cfset variables.previousVHostDataFilename = "previousVHostData.txt" />
	<cfset variables.config = getConfig() />


	<cffunction name="saveCurrentVHosts" returntype="void" access="public">
		<cfargument name="VHosts" type="struct" required="yes" hint="key=hostname, value=webroot" />
		<cffile action="write" file="#variables.previousVHostDataFilename#" output="#serialize(arguments.VHosts)#" addnewline="no" />
	</cffunction>
	
	
	<cffunction name="getChangedHosts" returntype="struct" access="public">
		<cfargument name="VHosts" type="struct" required="yes" hint="key=hostname, value=webroot" />
		<cfset var newData = evaluate(serialize(arguments.VHosts)) />
		<cfset var currStruct = "" />
		<cfset var arrIndex = 1 />
		<cfset var arrIndex2 = 1 />
		<cfset var key = "" />
		
		<cfif fileExists(variables.previousVHostDataFilename)>
			<cfset var oldData = evaluate(fileRead(variables.previousVHostDataFilename)) />

			<!--- compare the 2 structs --->
			<cfloop collection="#oldData#" item="key">
				<!--- exists in old and new? remove from new --->
				<cfif structKeyExists(newData, key) and newData[key] eq oldData[key]>
					<cfset structDelete(newData, key, false) />
				<!--- already existed, but different path--->
				<cfelseif structKeyExists(newData, key)>
					<cfset newData[key] = "changed" />
				<!--- does not exist in new? --->
				<cfelse>
					<cfset newData[key] = "deleted" />
				</cfif>
			</cfloop>
			<!--- now look if we have new hosts --->
			<cfloop collection="#newData#" item="key">
				<cfif not structKeyExists(oldData, key)>
					<cfset newData[key] = "new" />
				</cfif>
			</cfloop>

		<!--- we had no backup of the VHosts yet? Then return the given array, but with a key indicating that all sites are newly added--->
		<cfelse>
			<cfloop collection="#newData#" item="key">
				<cfset newData[key] = "new" />
			</cfloop>
		</cfif>
		<cfreturn newData />
	</cffunction>
	
	
	<cffunction name="backupFile" access="public" returntype="void" output="no">
		<cfargument name="filepath" type="string" required="yes" />
		<cfset var fileExt = listLast(arguments.filepath, ".") />
		<cftry>
			<cffile action="copy" source="#arguments.filepath#" destination="#arguments.filepath#.#dateformat(now(), 'yyyymmdd')##timeformat(now(), 'HHmmss')#.#fileExt#" />
			<cfcatch>
				<cffile action="copy" source="#arguments.filepath#" destination="#getdirectoryFromPath(GetCurrentTemplatePath())##getfilefrompath(arguments.filepath)#.#dateformat(now(), 'yyyymmdd')##timeformat(now(), 'HHmmss')#.#fileExt#" />
			</cfcatch>
		</cftry>
	</cffunction>
	
	
	<cffunction name="createVHostContainer" access="private">
		<cfargument name="path" type="string" required="yes" />
		<cfargument name="host" type="string" required="no" default="" />
		<cfargument name="aliases" type="struct" required="no" default="#{}#" />
		<cfargument name="port" type="string" required="no" default="" />
		<cfargument name="ip" type="string" required="no" default="" />
		<cfreturn {
			path=arguments.path
			, host=arguments.host
			, aliases=arguments.aliases
			, port=arguments.port
			, ip=arguments.ip
		} />
	</cffunction>
	
	
	<cffunction name="getCleanedAbsPath" access="public" returntype="string" output="no">
		<cfargument name="relPath" type="string" required="yes" />
		<cfargument name="currentPath" type="string" required="yes" />
		<!--- remove any trailing spaces of the path --->
		<cfset var filePath = rereplace(arguments.relPath, "[[:space:]]+$", "") />
		<!--- remove quotes surrounding the include path--->
		<cfset filePath = rereplace(filePath, "^(['""])(.*)\1$", "\2") />
		<cfreturn getAbsPath(filePath, arguments.currentPath) />
	</cffunction>
	
	
	<cffunction name="getAbsPath" access="public" returntype="string" output="no">
		<cfargument name="relPath" type="string" required="yes" />
		<cfargument name="currentPath" type="string" required="no" hint="If not given, then relPath must already be an abs path. We will only change %systemroot%, %systemdrive%, and backward slashes to forward ones." />
		<cfset var filePath = rereplace(arguments.relPath, '^./', '') />
		<cfset var i = "" />
		<cfset filePath = replace(filePath, '[\\/]+', '/', 'all') />
		
		<cfif find("%", filepath)>
			<cfset var systemroot = getwindowsroot() />
			<cfset filepath = replaceNoCase(filepath, "%systemroot%", systemroot) />
			<cfset filepath = replaceNoCase(filepath, "%systemDrive%", left(systemroot, 1)) />
			<cfif find("%", filepath)>
				<cfset handleError(msg="Fnc getAbsPath(): Filepath could not be translated: #filepath#", type="CRIT") />
			</cfif>
		</cfif>
		<!--- if already an abs path, return --->
		<cfif refind("^([a-zA-Z]:[/\\]|/)", filePath)>
			<cfreturn filePath />
		</cfif>
		<cfif not structKeyExists(arguments, "currentPath")>
			<cfset handleError(msg="Fnc getAbsPath(): given filepath is not absolute, but no 'currentPath' argument was given to calculate the abs path! (filepath=#filepath#)", type="CRIT") />
		</cfif>
		
		<cfset var fullPath = rereplace(GetDirectoryFromPath(currentPath) & "/" & filePath, '[\\/]+', '/', 'all') />
		<cfloop condition="find('../', fullPath)">
			<cfset fullPath = rereplace(fullPath, "(/[^/:]+/|^/|^[a-zA-Z]:/)/../", "/", "all") />
		</cfloop>
		<cfreturn fullPath />
	</cffunction>
	

	<cffunction name="getwindowsroot" access="private" returntype="string">
		<!--- if it can be found in the config, just get it from there --->
		<cfif structKeyExists(variables.config, "windowsroot") and len(variables.config.windowsroot)>
			<cfreturn variables.config.windowsroot />
		</cfif>
		<cfset var systemPath = createObject('java','java.lang.System').getProperty('java.library.path') />
		<cfset var winSysRoot = rereplaceNoCase(systemPath, '(.*;|^)([^;]+)[/\\]system(32|64)([;\\/].*|$)', '\2') />
		<!--- not found in system path? Then try it by using a batch file --->
		<cfif winSysRoot eq systemPath>
			<cffile action="write" file="getsystemroot.bat" output="echo $$$%systemroot%$$$" />
			<cftry>
				<cfset var batchOutput = "" />
				<cfexecute name="getsystemroot.bat" variable="batchOutput" timeout="2" />
				<cfset winSysRoot = rereplace(batchOutput, '.*\$\$\$(.*?)\$\$\$.*', '\1') />
				<cfcatch>
					<cfset winSysRoot = "" />
				</cfcatch>
			</cftry>
		</cfif>
		<cfreturn winSysRoot />
	</cffunction>
	
	
</cfcomponent>
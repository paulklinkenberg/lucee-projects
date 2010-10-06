<cfcomponent output="no">
	
	<cfset variables.webserver2TomcatVHostCopier = new Webserver2TomcatVHostCopier() />
	
	<cffunction name="startWebserver2TomcatVHostCopier" access="public" returntype="void">
    	<cfargument name="data" type="struct" required="yes" />
		<cfset variables.webserver2TomcatVHostCopier.copyWebserverVHosts2Tomcat() />
	</cffunction>
	
</cfcomponent> 
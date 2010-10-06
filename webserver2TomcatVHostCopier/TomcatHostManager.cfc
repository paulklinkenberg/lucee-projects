<cfcomponent output="no" extends="VHostsConfig">

	<cfset variables.config = getConfig() />
	<cfset variables.hostmanagerURL = "http://localhost:#variables.config.tomcatport#/host-manager" />
	

	<cffunction name="addHost" returntype="void" output="no" access="public">
		<cfargument name="hostname" type="string" required="yes" />
		<cfset var addURL = hostmanagerURL & "/add?name=#arguments.hostname#&appBase=webapps&autoDeploy=on&deployOnStartup=on&deployXML=on&unpackWars=on&aliases=" />
		<!---${tomcat.host-manager.url}/add?name=${tomcat.host}&amp;aliases=${tomcat.host.aliases}&amp;appBase=${tomcat.deploy.dir.absolute}&amp;autoDeploy=on&amp;deployOnStartup=on&amp;deployXML=on&amp;unpackWARs=on--->
		<cfset var cfhttp = "" />
		<cftry>
			<cfhttp url="#addURL#" username="#variables.config.hostmanagerusername#"
				password="#variables.config.hostmanagerpassword#" timeout="10" throwonerror="yes" />
			<cfcatch>
				<cfset handleError(msg="The host could not be added to tomcat by using the hostmanager.#chr(10)#Error msg: #cfcatch.Message# #cfcatch.Detail#.#chr(10)#URL: #addURL##chr(10)#Host-name: #arguments.hostname#", type="WARNING") />
			</cfcatch>
		</cftry>
	</cffunction>
	
	
	<cffunction name="removeHost" returntype="void" output="no" access="public">
		<cfargument name="hostname" type="string" required="yes" />
		<cfset var addURL = hostmanagerURL & "/remove?name=#arguments.hostname#" />
		<cfset var cfhttp = "" />
		<cftry>
			<cfhttp url="#addURL#" username="#variables.config.hostmanagerusername#"
				password="#variables.config.hostmanagerpassword#" timeout="10" throwonerror="yes" />
			<cfcatch>
				<cfset handleError(msg="The host could not be removed from tomcat by using the hostmanager.#chr(10)#Error msg: #cfcatch.Message# #cfcatch.Detail#.#chr(10)#URL: #addURL##chr(10)#Host-name: #arguments.hostname#", type="WARNING") />
			</cfcatch>
		</cftry>
	</cffunction>
	
	
	<cffunction name="listHosts" returntype="any" output="no" access="public">
		<cfset var listURL = hostmanagerURL & "/list" />
		<cfset var cfhttp = "" />
		
		<cftry>
			<cfhttp url="#listURL#" username="#variables.config.hostmanagerusername#"
				password="#variables.config.hostmanagerpassword#" timeout="10" throwonerror="yes" />
			<cfcatch>
				<cfset handleError(msg="A list of the hosts could not be retrieved by using the hostmanager.#chr(10)#Error msg: #cfcatch.Message# #cfcatch.Detail#.#chr(10)#URL: #listURL##chr(10)#", type="CRIT") />
			</cfcatch>
		</cftry>
		<!---returns:

OK - Listed hosts
www.site1.local:
www.site2.local:
coldbox.local:aliasname.local,aliasname2.local
etcetera
--->
		<cfreturn cfhttp.FileContent />
	</cffunction>

</cfcomponent>
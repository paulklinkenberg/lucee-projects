<cfcomponent output="no">
<!---
/*
 * Webserver2TomcatVHostCopier.cfc, developed by Paul Klinkenberg
 * http://www.railodeveloper.com/post.cfm/apache-iis-to-tomcat-vhost-copier-for-railo
 *
 * Date: 2010-10-06 16:07:00 +0100
 * Revision: 0.2
 *
 * Copyright (c) 2010 Paul Klinkenberg, Ongevraagd Advies
 * Licensed under the GPL license.
 *
 *    This program is free software: you can redistribute it and/or modify
 *    it under the terms of the GNU General Public License as published by
 *    the Free Software Foundation, either version 3 of the License, or
 *    (at your option) any later version.
 *
 *    This program is distributed in the hope that it will be useful,
 *    but WITHOUT ANY WARRANTY; without even the implied warranty of
 *    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *    GNU General Public License for more details.
 *
 *    You should have received a copy of the GNU General Public License
 *    along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 *    ALWAYS LEAVE THIS COPYRIGHT NOTICE IN PLACE!
 */
--->	

	<cffunction name="copyWebserverVHosts2Tomcat" access="public" returntype="void" output="yes">
		<cfargument name="testOnly" type="boolean" required="no" default="false" />
		<cfargument name="sendCriticalErrors" type="boolean" required="no" default="true" />

		<cfset var tomcatConfigManager = new TomcatConfigManager().init(sendCriticalErrors=arguments.sendCriticalErrors) />
		<cfset var parserConfig = tomcatConfigManager.getConfig() />
		
		<!--- apache --->
		<cfif parserConfig.webservertype eq "apache">
			<cfset var apacheConfigManager = new ApacheConfigManager().init(sendCriticalErrors=arguments.sendCriticalErrors) />
			<!--- get all Vhosts from Apache--->
			<cfset var VHosts = apacheConfigManager.getVHostsFromHTTPDFile(file=parserConfig.httpdfile) />
		<!--- IIS6 --->
		<cfelseif parserConfig.webservertype eq "IIS6">
			<cfset var IISConfigManager = new IISConfigManager().init(sendCriticalErrors=arguments.sendCriticalErrors) />
			<!--- for testing, get the config file from a different location --->
			<cfif structKeyExists(parserConfig, "IIS6File")>
				<cfset var VHosts = IISConfigManager.getVHostsFromIIS6File(parserConfig.IIS6File) />
			<cfelse>
				<cfset var VHosts = IISConfigManager.getVHostsFromIIS6File() />
			</cfif>
		<!--- IIS7 --->
		<cfelseif parserConfig.webservertype eq "IIS7">
			<cfset var IISConfigManager = new IISConfigManager().init(sendCriticalErrors=arguments.sendCriticalErrors) />
			<!--- for testing, get the config file from a different location --->
			<cfif structKeyExists(parserConfig, "IIS7File")>
				<cfset var VHosts = IISConfigManager.getVHostsFromIIS7File(parserConfig.IIS7File) />
			<cfelse>
				<cfset var VHosts = IISConfigManager.getVHostsFromIIS7File() />
			</cfif>
		<cfelse>
			<cfset tomcatConfigManager.handleError(msg="Webserver type '#parserConfig.webservertype#' is not yet implemented in the VHostParser. Only one of the following is allowed: IIS6, IIS7, Apache", type="CRIT") />
			<cfreturn />
		</cfif>
	
		<!--- The Vhosts array which we have now, is very detailed. It has entries for every ip+port+host+webroot.
		This means that we can have the same hostname+webroot multiple times, but listening on different ips or ports.
		Since the tomcat config does not need this/ can not handle this, we will simplify the VHosts here.
		Also, a check will be done to see if the same hostname is used with multiple webroots. This cannot be dealt with by tomcat. --->
		<cfset var tomcatVHosts = {} />
		<cfset var duplicates = [] />
		<cfset var stHost = "" />
		<cfset var hostname = "" />
		<cfloop array="#VHosts#" index="stVHost">
			<cfloop list="#iif(not len(stVHost.host), de('localhost'), 'stVHost.host')#,#structKeyList(stVHost.aliases)#" index="hostname">
				<cfif structKeyExists(tomcatVHosts, hostname) and stVHost.path neq tomcatVHosts[hostname]>
					<cfset arrayAppend(duplicates, "        Same host found twice, with different webroots! Host=#hostname#, path1=#tomcatVHosts[hostname]#, path2=#stVHost.path#") />
				<cfelse>
					<cfset structInsert(tomcatVHosts, hostname, stVHost.path, true) />
				</cfif>
			</cfloop>
		</cfloop>
		<!---did we find duplicates? Log it.--->
		<cfif arrayLen(duplicates)>
			<cfset tomcatConfigManager.handleError("One or more duplicate hosts with different webroots where found in #parserConfig.webservertype#. This tool can not handle this.#chr(10)##arrayToList(duplicates, chr(10))#", "WARNING") />
		</cfif>
	
		<!--- check if there are VHost changes --->
		<cfset var stChangedVHosts = tomcatConfigManager.getChangedHosts(tomcatVHosts) />
		<cfif not structIsEmpty(stChangedVHosts)>
			<cfsavecontent variable="temp">
				Changed hosts: 
				<cfset var host = "" />
				<cfloop collection="#stChangedVHosts#"  item="host">
					<br /> - #UCase(stChangedVHosts[host])#: #host#
				</cfloop>
			</cfsavecontent>
			#temp#
			<br /><br />
			<cfset tomcatConfigManager.handleError(rereplace(temp, '(<.*?>|[\r\n\t])+', chr(10), 'all'), "MESSAGE") />
			
			<!--- create the xml text with the VHosts for tomcat --->
			<cfset var VHostsText = tomcatConfigManager.createTomcatVHosts(tomcatVHosts) />
			
			The xml to write to tomcat:
			<cfoutput><pre>#HTMLEditFormat(VHostsText)#</pre></cfoutput>
			
			<cfif arguments.testOnly>
				TEST-ONLY, so nothing will be written to tomcat. Exiting now.
				<cfreturn />
			</cfif>
			
			<!--- write/change the VHost context data for tomcat (delteion comes later on) --->
			<cfset var key = "" />
			<cfloop collection="#stChangedVHosts#" item="key">
				<cfif stChangedVHosts[key] eq "new" or stChangedVHosts[key] eq "changed">
					<cfset tomcatConfigManager.writeContextXMLFile(host=key, path=tomcatVHosts[key]) />
				</cfif>
			</cfloop>
			
			<!--- overwrite the tomcat VHosts --->
			<cfset tomcatConfigManager.overwriteVHostSettings(VHostsText) />
			
			All files have been written<br /><br />
			
			<!--- now activate the new and changed host by using the Tomcat host-manager --->
			<cfset var tomcatHostManager = new TomcatHostManager().init(sendCriticalErrors=arguments.sendCriticalErrors) />
			<cfloop collection="#stChangedVHosts#" item="key">
				<cfif stChangedVHosts[key] eq "new">
					<cfset tomcatHostManager.addHost(key) />
					<cfoutput>Added host #key#</cfoutput> with the tomcat host-manager<br /><br />
					<cfflush />
				<cfelseif stChangedVHosts[key] eq "changed">
					<!--- no need to do anything; the new xml file will be picked up automatically by tomcat --->
				<cfelseif stChangedVHosts[key] eq "deleted">
					<cfset tomcatHostManager.removeHost(key) />
					<cfoutput>Removed host #key#</cfoutput> with the tomcat host-manager<br /><br />
					<cfflush />
				</cfif>
			</cfloop>
		
			<!--- delete the outdated VHost context data for tomcat --->
			<cfloop collection="#stChangedVHosts#" item="key">
				<cfif stChangedVHosts[key] eq "deleted">
					<cfset tomcatConfigManager.removeContextXMLFile(host=key) />
				</cfif>
			</cfloop>
			
			<!--- save the current vhost settings --->
			<cfset tomcatConfigManager.saveCurrentVHosts(tomcatVHosts) />
			
			Data saved to tomcat. Done.
		<cfelse>
			<cfset tomcatConfigManager.handleError("No changes in the VHosts", "MESSAGE") />
			No changes in the VHosts.
		</cfif>
	</cffunction>
	
</cfcomponent>
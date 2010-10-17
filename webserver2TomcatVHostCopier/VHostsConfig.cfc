<cfcomponent output="no">
<!---
/*
 * VHostsConfig.cfc, developed by Paul Klinkenberg
 * http://www.railodeveloper.com/post.cfm/apache-iis-to-tomcat-vhost-copier-for-railo
 *
 * Date: 2010-10-17 04:16:00 +0100
 * Revision: 0.3.00
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

	<cfset variables.errorMailTo = "paul@ongevraagdadvies.nl" />
	<cfset variables._sendCriticalErrors = true />
	
	
	<cffunction name="init" returntype="any" access="public" output="no">
		<!--- zero or more arguments --->
		<cfset var key = "" />
		<cfloop collection="#arguments#" item="key">
			<cfif structKeyExists(this, "set#key#")>
				<cfset this["set#key#"](arguments[key]) />
			</cfif>
		</cfloop>
		<cfreturn this />
	</cffunction>
	
	
	<cffunction name="getConfig" access="public" returntype="struct">
		<cfset var stConfig = {} />
		<cfset var line = "" />
		<cfloop file="config.conf" index="line">
			<cfset line = trim(line) />
			<cfif listlen(line, '=') gt 1>
				<cfset stConfig[listFirst(line, '=')] = listRest(line, '=') />
			</cfif>
		</cfloop>
		<cfreturn stConfig />
	</cffunction>
	
	
	<cffunction name="handleError" access="public" returntype="void">
		<cfargument name="msg" type="string" required="yes" />
		<cfargument name="type" type="string" required="no" default="WARNING" />
		<!--- rotate logs, max. 3--->
		<cfset var qLogFileSize = "" />
		<cfdirectory action="list" directory="." filter="parserLog.log" name="qLogFileSize" />
		<cfloop query="qLogFileSize">
			<cfif int(qLogFileSize.size) gt 500*1024>
				<cfif fileExists('parserLog3.log')>
					<cfset fileDelete('parserLog3.log') />
				</cfif>
				<cfif fileExists('parserLog2.log')>
					<cffile action="rename" source="parserLog2.log" destination="parserLog3.log"  />
				</cfif>
				<cffile action="rename" source="parserLog.log" destination="parserLog2.log"  />
			</cfif>
			<cfbreak />
		</cfloop>
		<!--- write log file --->
		<cffile action="append" file="parserLog.log" output="#dateformat(now(), 'dd-mm-yyyy')# #timeformat(now(), 'HH:mm:ss')#	#arguments.type#	#arguments.msg#" addnewline="yes" fixnewline="yes" />
		
		<!--- CRITICAL? Abort the operation, and optionally send debug mail --->
		<cfif arguments.type eq "CRIT">
			<cfif variables._sendCriticalErrors>
				<!--- check how many mails have been sent in the meanwhile --->
				<cfset var mailsSentCounterFile = "mailsSentCounter.txt" />
				<cfif fileExists(mailsSentCounterFile)>
					<cfset var numMailsSent = int(fileRead(mailsSentCounterFile)) />
				<cfelse>
					<cfset var numMailsSent = 0 />
				</cfif>
				<cfif numMailsSent lt 10>
					<cfset fileWrite(mailsSentCounterFile, ++numMailsSent) />
					
					<cfmail to="#variables.errorMailTo#" from="#variables.errorMailTo#" subject="VHostParser error" type="html"><!---
						---><cfmailparam file="parserLog.log" /><!---
						also send the previous logfile, since it might have been backed up just now
						---><cfif fileExists('parserLog2.log')><cfmailparam file="parserLog2.log" /></cfif>
						Date: #now()#<br />
						<cfdump var="#getConfig()#" label="config" />
						<cfdump var="#form#" label="form data" />
					</cfmail>
					<cfoutput>Debug mail for this critical error has been sent to the developer<br /></cfoutput>
				<cfelse>
					<cffile action="append" file="parserLog.log" output="#dateformat(now(), 'dd-mm-yyyy')# #timeformat(now(), 'HH:mm:ss')#	The maximum amount of debug mails has been reached. No mail was sent." addnewline="yes" fixnewline="yes" />
				</cfif>
			</cfif>
			<cfoutput><p style="color:red;">CRITICAL ERROR: #msg#</p>
				<p><em>aborting the request</em></p>
			</cfoutput>
			<cfabort />
		</cfif>
	</cffunction>
	
	
	<cffunction name="setSendCriticalErrors" returntype="void" access="public" output="no">
		<cfargument name="sendCriticalErrors" type="boolean" required="yes" />
		<cfset variables._sendCriticalErrors = arguments.sendCriticalErrors />
	</cffunction>
	
	
</cfcomponent>
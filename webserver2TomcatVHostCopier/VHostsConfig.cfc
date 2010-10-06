<cfcomponent output="no">

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
		<!--- write log file --->
		<cffile action="append" file="parserLog.log" output="#dateformat(now(), 'dd-mm-yyyy')# #timeformat(now(), 'HH:mm:ss')#	#arguments.type#	#arguments.msg#" addnewline="yes" />
		<cfif arguments.type eq "CRIT">
			<cfif variables._sendCriticalErrors>
				<cfmail to="#variables.errorMailTo#" from="#variables.errorMailTo#" subject="VHostParser error on #cgi.http_host#" type="html"><!---
					---><cfmailparam file="parserLog.log" disposition="attachment" />
					Date: #now()#<br />
					<cfdump var="#getConfig()#" label="config" />
					<cfdump var="#cgi#" label="cgi vars" />
					<cfdump var="#form#" label="form data" />
				</cfmail>
				<cfoutput>Debug mail for this critical error has been sent to the developer<br /></cfoutput>
			</cfif>
			<cfoutput><p style="color:red;">CRITICAL ERROR: #msg#</p></cfoutput>
			<cfabort />
		</cfif>
	</cffunction>
	
	
	<cffunction name="setSendCriticalErrors" returntype="void" access="public" output="no">
		<cfargument name="sendCriticalErrors" type="boolean" required="yes" />
		<cfset variables._sendCriticalErrors = arguments.sendCriticalErrors />
	</cffunction>
	
	
</cfcomponent>
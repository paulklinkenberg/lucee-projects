<cfcomponent output="no">

	<cfset variables.errorMailTo = "paul@ongevraagdadves.nl" />


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
			<cfmail to="#variables.errorMailTo#" from="#variables.errorMailTo#" subject="VHostParser error!" type="html">
				<cfmailparam file="parserLog.log" />
				<cfdump var="#getConfig()#" />
			</cfmail>
			<cfoutput><p style="color:red;">CRITICAL ERROR: #msg#</p></cfoutput>
			<cfabort />
		</cfif>
	</cffunction>
	
	
</cfcomponent>
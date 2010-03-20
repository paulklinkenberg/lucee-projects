<cfcomponent output="no" hint="I am a dirty little component who includes something, gets all filthy with leaked variables, returns the output, and then dies.">
	
	<cffunction name="include" access="public" returntype="string">
		<cfargument name="path" type="string" required="yes" />
		<cfset var sHtml = "" />
		<cfsavecontent variable="sHtml"><cfoutput><cfinclude template="#arguments.path#" /></cfoutput></cfsavecontent>
		<cfreturn sHtml />
	</cffunction>
	
</cfcomponent>
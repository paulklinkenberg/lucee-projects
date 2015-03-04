<!--- Request for this function: https://issues.jboss.org/browse/RAILO-1168
	Code originally from: http://www.lucee.nl/post.cfm/regexsafe-function-for-coldfusion
	Characters escaped in OBD 1.5 BER: $, {, }, (, ), <, >, [, ], ^, ., *, +, ?, #, :, &, and \
---><cffunction name="REEscape" returntype="string" access="public" output="no" hint="Escapes characters with special meaning for regular expression in a given string">
	<cfargument name="text" type="string" required="yes" hint="The string to escape the characters in" />
	<cfreturn rereplace(arguments.text, "(?=[\[\]\\^$.|?*+()])", "\", "all") />
</cffunction>
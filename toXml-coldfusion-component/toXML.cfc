<cfcomponent displayname="toXML" hint="Set of utility functions to generate XML" output="false">
<!---
	Based on the toXML component by Raymond Camden: http://www.coldfusionjedi.com/index.cfm/2006/7/2/ToXML-CFC--Converting-data-types-to-XML
	
	toXML function made by Paul Klinkenberg, 25-feb-2009
	http://www.coldfusiondeveloper.nl/post.cfm/toxml-function-for-coldfusion
	
	Version 1.1, March 8, 2010
	Now using <cfsavecontent> while generating the xml output in the functions, since it increases process speed
	Thanks to Brian Meloche (http://www.brianmeloche.com/blog/) for pointing it out
--->

	<cffunction name="toXML" returntype="string" access="public" output="no" hint="Recursively converts any kind of data to xml">
		<cfargument name="data" type="any" required="yes" />
		<cfargument name="rootelement" type="string" required="false" default="data" />
		<cfargument name="elementattributes" type="string" required="false" default="" hint="Optional string like 'order=2', which will be added into the starting rootElement tag." />
		<cfargument name="addXMLHeader" type="boolean" required="no" default="false" hint="Whether or not to add the &lt;?xml?&gt; tag" />
		<cfset var s = "" />
		
		<!---add space before the attributes, if any--->
		<cfif len(arguments.elementattributes)>
			<cfset arguments.elementattributes = " " & trim(arguments.elementattributes) />
		</cfif>
		
		<cfsavecontent variable="s"><cfoutput><cfif addXMLHeader><?xml version="1.0" encoding="UTF-8"?>
</cfif><!---
			---><cfif isNumeric(data)><!---
				---><#rootelement##arguments.elementattributes#>#data#</#rootelement#><!---
			---><cfelseif IsBoolean(data)><!---
				---><#rootelement##arguments.elementattributes#>#iif(data, 1, 0)#</#rootelement#><!---
			---><cfelseif IsSimpleValue(data) and not len(data)><!---
				---><#rootelement##arguments.elementattributes#/><!---
			---><cfelseif IsSimpleValue(data)><!---
				---><#rootelement##arguments.elementattributes#>#xmlFormat(data)#</#rootelement#><!---
			---><cfelseif IsQuery(data)><!---
				--->#_queryToXML(data, rootelement, arguments.elementattributes)#<!---
			---><cfelseif IsArray(data)><!---
				--->#_arrayToXML(data, rootelement, arguments.elementattributes)#<!---
			---><cfelseif IsStruct(data)><!---
				--->#_structToXML(data, rootelement, arguments.elementattributes)#<!---
			---><!--- is it an exception, like cfcatch? ---><!---
			---><cfelseif refindNoCase("^coldfusion\..*Exception$", data.getClass().getName())><!---
				--->#_structToXML(data, rootelement, arguments.elementattributes)#<!---
			---><cfelse><!---
				---><#rootelement##arguments.elementattributes#>Unknown object of type #_data.getClass().getName()#</#rootelement#><!---
			---></cfif><!---
		---></cfoutput></cfsavecontent>

		<cfreturn s />
	</cffunction>
	
	
	<cffunction name="_arrayToXML" returntype="string" access="private" output="false" hint="Converts an array into XML">
		<cfargument name="data" type="array" required="true">
		<cfargument name="rootelement" type="string" required="false" default="data">
		<cfargument name="elementattributes" type="string" required="false" default="" />
		<cfargument name="itemelement" type="string" required="false" default="item">
		<cfset var s = "" />
		<cfset var x = "" />
		
		<cfsavecontent variable="s"><cfoutput><#arguments.rootelement# type="array"#elementattributes#><!---
			---><cfloop index="x" from="1" to="#arrayLen(arguments.data)#"><!---
				--->#toXML(data=arguments.data[x], rootelement=arguments.itemelement, elementattributes="order=""#x#""")#<!---
			---></cfloop><!---
		---></#arguments.rootelement#></cfoutput></cfsavecontent>
		
		<cfreturn s />
	</cffunction>
	
	
	<cffunction name="_queryToXML" returntype="string" access="private" output="false" hint="Converts a query to XML">
		<cfargument name="data" type="query" required="true">
		<cfargument name="rootelement" type="string" required="false" default="data">
		<cfargument name="elementattributes" type="string" required="false" default="" />
		<cfargument name="itemelement" type="string" required="false" default="row">
		<cfset var s = "" />
		<cfset var col = "" />
		<cfset var columns = arguments.data.columnlist />
		
		<cfsavecontent variable="s"><cfoutput><#arguments.rootelement# type="query"#elementattributes#><!---
			---><cfloop query="arguments.data"><#arguments.itemelement# order="#data.currentrow#"><!---
				---><cfloop index="col" list="#columns#">#toXML(data=arguments.data[col][currentRow], rootElement=col)#</cfloop><!---
			---></#arguments.itemelement#></cfloop>
		</#arguments.rootelement#></cfoutput></cfsavecontent>

		<cfreturn s />
	</cffunction>
	
	
	<cffunction name="_structToXML" returntype="string" access="private" output="false" hint="Converts a struct into XML.">
		<cfargument name="data" type="any" required="true" hint="It should be a struct, but can also be an 'exception' type.">
		<cfargument name="rootelement" type="string" required="false" default="data">
		<cfargument name="elementattributes" type="string" required="false" default="" />
		<cfargument name="itemelement" type="string" required="false" default="object">
		<cfset var s = "" />
		<cfset var keys = structKeyList(arguments.data)>
		<cfset var key = "">
		
		<cfsavecontent variable="s"><cfoutput><#arguments.rootelement# type="struct"#elementattributes#><#arguments.itemelement#><!---
			---><cfloop index="key" list="#keys#">#toXML(data=arguments.data[key], rootelement=key)#</cfloop><!---
		---></#arguments.itemelement#></#arguments.rootelement#></cfoutput></cfsavecontent>
		<cfreturn s />
	</cffunction>


</cfcomponent>
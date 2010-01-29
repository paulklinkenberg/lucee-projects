<cfcomponent displayname="toXML" hint="Set of utility functions to generate XML" output="false">
<!---
	Based on the toXML component by Raymond Camden: http://www.coldfusionjedi.com/index.cfm/2006/7/2/ToXML-CFC--Converting-data-types-to-XML
	
	toXML function made by Paul Klinkenberg, 25-feb-2009
	http://www.coldfusiondeveloper.nl/post.cfm/toxml-function-for-coldfusion
--->

	<cffunction name="toXML" returntype="string" access="public" output="no" hint="Recursively converts any kind of data to xml">
		<cfargument name="data" type="any" required="yes" />
		<cfargument name="rootelement" type="string" required="false" default="data" />
		<cfargument name="elementattributes" type="string" required="false" default="" hint="Optional string like 'order=2', which will be added into the starting rootElement tag." />
		<cfargument name="addXMLHeader" type="boolean" required="no" default="false" hint="Whether or not to add the &lt;?xml?&gt; tag" />
		<cfset var s = iif(addXMLHeader, de("<?xml version=""1.0"" encoding=""UTF-8""?>"), de('')) />

		<!---add space before the attributes, if any--->
		<cfif len(elementattributes)>
			<cfset elementattributes = " " & trim(elementattributes) />
		</cfif>
		
		<cfif isNumeric(data)>
			<cfset s = s & "<#rootelement##elementattributes#>#data#</#rootelement#>" />
		<cfelseif IsBoolean(data)>
			<cfset s = s & "<#rootelement##elementattributes#>#iif(data, 1, 0)#</#rootelement#>" />
		<cfelseif IsSimpleValue(data)>
			<cfset s = s & "<#rootelement##elementattributes#>#xmlFormat(data)#</#rootelement#>" />
		<cfelseif IsQuery(data)>
			<cfset s = s & _queryToXML(data, rootelement, elementattributes) />
		<cfelseif IsArray(data)>
			<cfset s = s & _arrayToXML(data, rootelement, elementattributes) />
		<cfelseif IsStruct(data)>
			<cfset s = s & _structToXML(data, rootelement, elementattributes) />
		<!--- is it an exception, like cfcatch? --->
		<cfelseif refindNoCase("^coldfusion\..*Exception$", data.getClass().getName())>
			<cfset s = s & _structToXML(data, rootelement, elementattributes) />
		<cfelse>
			<cfset s = s & "<#rootelement##elementattributes#>Unknown object of type #_data.getClass().getName()#</#rootelement#>" />
		</cfif>

		<cfreturn s />
	</cffunction>
	
	
	<cffunction name="_arrayToXML" returntype="string" access="private" output="false" hint="Converts an array into XML">
		<cfargument name="data" type="array" required="true">
		<cfargument name="rootelement" type="string" required="false" default="data">
		<cfargument name="elementattributes" type="string" required="false" default="" />
		<cfargument name="itemelement" type="string" required="false" default="item">
		<cfset var s = "" />
		<cfset var x = "" />
		
		<cfset s = s & "<" & arguments.rootelement & " type=""array""#elementattributes#>">
		<cfloop index="x" from="1" to="#arrayLen(arguments.data)#">
			<cfset s = s & toXML(data=arguments.data[x], rootelement=arguments.itemelement, elementattributes="order=""#x#""") />
		</cfloop>
		<cfset s = s & "</" & arguments.rootelement & ">">
		
		<cfreturn s>
	</cffunction>
	
	
	<cffunction name="_queryToXML" returntype="string" access="private" output="false" hint="Converts a query to XML">
		<cfargument name="data" type="query" required="true">
		<cfargument name="rootelement" type="string" required="false" default="data">
		<cfargument name="elementattributes" type="string" required="false" default="" />
		<cfargument name="itemelement" type="string" required="false" default="row">
		<cfset var s = "" />
		<cfset var col = "">
		<cfset var columns = arguments.data.columnlist>
		<cfset var txt = "">
		
		<cfset s = s & "<" & arguments.rootelement & " type=""query""#elementattributes#>">
		
		<cfloop query="arguments.data">
			<cfset s = s & "<" & arguments.itemelement & " order=""#data.currentrow#"">">
	
			<cfloop index="col" list="#columns#">
				<cfset s = s & toXML(data=arguments.data[col][currentRow], rootElement=col) />
			</cfloop>
			
			<cfset s = s & "</" & arguments.itemelement & ">">
		</cfloop>
		
		<cfset s = s & "</" & arguments.rootelement & ">">
		
		<cfreturn s>
	</cffunction>
	
	
	<cffunction name="_structToXML" returntype="string" access="private" output="false" hint="Converts a struct into XML.">
		<cfargument name="data" type="any" required="true" hint="It should be a struct, but can also be an 'exception' type.">
		<cfargument name="rootelement" type="string" required="false" default="data">
		<cfargument name="elementattributes" type="string" required="false" default="" />
		<cfargument name="itemelement" type="string" required="false" default="object">
		<cfset var s = "<" & arguments.rootelement & " type=""struct""#elementattributes#><" & arguments.itemelement & ">" />
		<cfset var keys = structKeyList(arguments.data)>
		<cfset var key = "">
		
		<cfloop index="key" list="#keys#">
			<cfset s = s & toXML(data=arguments.data[key], rootelement=key) />
		</cfloop>
		
		<cfset s = s & "</" & arguments.itemelement & "></" & arguments.rootelement & ">">
		
		<cfreturn s>
	</cffunction>


</cfcomponent>
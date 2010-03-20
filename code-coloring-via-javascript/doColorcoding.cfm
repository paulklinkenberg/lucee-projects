<cfparam name="form.ref" default="" />

<cfif structKeyExists(form, "text")>
	<cfinvoke component="CodeColoring" method="colorString" returnvariable="variables.colorText">
		<cfinvokeargument name="dataString" value="#form.text#" />
		<cfinvokeargument name="useCaching" value="true" />
		<cfinvokeargument name="lineNumbers" value="false" />
		<cfinvokeargument name="keepTabs" value="true" />
	</cfinvoke>
<cfelse>
	<cfset variables.colorText = "Error: no form.text was passed to #cgi.SCRIPT_NAME#!" />
</cfif>

<cfcontent reset="yes" type="text/xml; charset=utf-8" /><!---

---><cfoutput><?xml version="1.0" encoding="utf-8"?>
<codecoloring>
	<ref>#xmlFormat(form.ref)#</ref>
	<text><![CDATA[#variables.colorText#]]></text>
</codecoloring></cfoutput><!---

---><cfabort />
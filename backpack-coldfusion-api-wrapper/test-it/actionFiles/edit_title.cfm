<cfif structKeyExists(form, "title")>

	<cfinvoke component="#application.backpack_obj#" method="updateTitle" returnvariable="page_xml">
		<cfinvokeargument name="id" value="#url.id#" />
		<cfinvokeargument name="title" value="#form.title#" />
	</cfinvoke>
	
	<cfoutput>
		<strong>The page title has been updated!</strong>
		<br />
		Check it out: <a href="#cgi.script_name#?fuseaction=show_page&amp;id=#url.id#">#form.title#</a>
	</cfoutput>
<cfelse>
	<!--- <comment author="P. Klinkenberg"> retrieve page</comment> --->
	<cfset page_xml = application.backPack_obj.showPage(id=url.id) />

	<cfoutput>
		<form action="#cgi.script_name#?fuseaction=#url.fuseaction#&amp;id=#url.id#" method="post">
			<table>
				<tr><td>Title: </td><td><input type="text" name="title" size="40" value="#htmlEditFormat(page_xml.response.page.xmlAttributes.title)#" /></td></tr>
				<tr><td>&nbsp;</td><td><input type="submit" value="go" /></td></tr>
			</table>
		</form>
	</cfoutput>
</cfif>
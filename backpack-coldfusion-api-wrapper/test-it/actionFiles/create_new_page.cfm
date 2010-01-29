
<h2>Creating a new page</h2>

<cfif cgi.REQUEST_METHOD eq "POST">
	<cfinvoke component="#application.backpack_obj#" method="createPage" returnvariable="page_xml">
		<cfinvokeargument name="title" value="#form.title#" />
	</cfinvoke>
	
	<cfoutput>
		<strong>Your new page has been created!</strong>
		<br />
		Check it out: <a href="#cgi.script_name#?fuseaction=show_page&amp;id=#page_xml.response.page.xmlAttributes.id#">#page_xml.response.page.xmlAttributes.title#</a>
	</cfoutput>
<cfelse>
	<cfoutput>
		<form action="#cgi.script_name#?fuseaction=#url.fuseaction#" method="post">
			<table>
				<tr><td>Title: </td><td><input type="text" name="title" size="40" /></td></tr>
				<tr><td>&nbsp;</td><td><input type="submit" value="go" /></td></tr>
			</table>
		</form>
	</cfoutput>
</cfif>
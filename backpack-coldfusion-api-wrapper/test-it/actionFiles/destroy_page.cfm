
<h2>Deleting a page</h2>

<cfif cgi.REQUEST_METHOD eq "POST">
	<cfinvoke component="#application.backpack_obj#" method="destroyPage" returnvariable="page_xml">
		<cfinvokeargument name="id" value="#url.id#" />
	</cfinvoke>
	
	<cfoutput>
		<strong>The page has been deleted!</strong>
		<br />
	</cfoutput>
<cfelse>
	<cfoutput>
		<form action="#cgi.script_name#?fuseaction=#url.fuseaction#&amp;id=#url.id#" method="post">
			Are you sure you want to delete the page?
			<table>
				<tr><td>&nbsp;</td><td><input type="submit" value="go" /></td></tr>
			</table>
		</form>
	</cfoutput>
</cfif>
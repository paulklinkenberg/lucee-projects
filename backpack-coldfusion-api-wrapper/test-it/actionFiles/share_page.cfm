<h2>Sharing a page</h2>

<cfif structKeyExists(form, "email_addresses")>

	<cfinvoke component="#application.backpack_obj#" method="sharePage" returnvariable="page_xml">
		<cfinvokeargument name="id" value="#url.id#" />
		<cfinvokeargument name="email_addresses" value="#form.email_addresses#" />
		<cfinvokeargument name="public" value="#form.public#" />
	</cfinvoke>
	
	<cfoutput>
		<strong>The page sharing has been committed!</strong>
		<br />
		<a href="#cgi.script_name#?fuseaction=show_page&amp;id=#url.id#">Go to the page</a>
	</cfoutput>
<cfelse>

	<cfoutput>
		<p>
			For some reason, the currently sharing email addresses cannot be retrieved by the api.<br />
			Hope they will add it once...
		</p>
		<p>
			If you choose to make this page public, it will be visible at: 
			<a href="http://#application.backPack.hostUrl#/pub/#url.id#">http://#application.backPack.hostUrl#/pub/#url.id#</a>
		</p>
		<form action="#cgi.script_name#?fuseaction=#url.fuseaction#&amp;id=#url.id#" method="post">
			<table>
				<tr><td>Email address(es): </td><td><textarea name="email_addresses" cols="50" rows="4"></textarea></td></tr>
				<tr><td>Make page public: </td><td><select name="public"><option value="0">No</option><option value="1">Yes</option></select></td></tr>
				<tr><td>&nbsp;</td><td><input type="submit" value="go" /></td></tr>
			</table>
		</form>
	</cfoutput>
</cfif>
<cfif structKeyExists(form, "term") and len(form.term)>

	<cfinvoke component="#application.backpack_obj#" method="searchPages" returnvariable="pageList_qry">
		<cfinvokeargument name="id" value="#url.id#" />
		<cfinvokeargument name="term" value="#form.term#" />
		<cfinvokeargument name="returnType" value="query" />
	</cfinvoke>
	
	<cfoutput>
		<strong>A search has been done on the serach term '#form.term#'.</strong>
		<br />#pageList_qry.recordcount# result(s):
		<cfdump var="#pageList_qry#" />
	</cfoutput>
<cfelse>
	<cfoutput>
		<form action="#cgi.script_name#?fuseaction=#url.fuseaction#" method="post">
			<table>
				<tr><td>Search term: </td><td><input type="text" name="term" size="40" value="" /></td></tr>
				<tr><td>&nbsp;</td><td><input type="submit" value="go" /></td></tr>
			</table>
		</form>
	</cfoutput>
</cfif>
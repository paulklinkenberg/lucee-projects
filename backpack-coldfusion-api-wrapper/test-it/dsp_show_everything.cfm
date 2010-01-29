<cfif not structKeyExists(variables, "allPages_qry")>
	<cfset allPages_qry = application.backPack_obj.getAllPages(orderBy="scope,title") />
</cfif>

<cfoutput query="allPages_qry">
	<cfset url.id = allPages_qry.id />
	<cfinclude template="dsp_page.cfm" />
	<hr />
</cfoutput>
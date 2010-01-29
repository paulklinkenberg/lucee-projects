<cfset allPages_qry = application.backPack_obj.getAllPages(orderBy="scope,title") />

<!--- <comment author="P. Klinkenberg"> param this ID, so we can optionally mark the current item </comment> --->
<cfparam name="url.id" default="" />

<ul class="projectlist">
	<cfoutput query="allpages_qry" group="scope">
		<li><strong>#scope#</strong>
			<ul>
				<cfoutput>
					<li><a href="#cgi.script_name#?fuseAction=show_page&amp;id=#id#"<cfif url.id eq allPages_qry.id> class="activeLink"</cfif>>#title#</a></li>
				</cfoutput>
			</ul>
		</li>
	</cfoutput>
</ul>
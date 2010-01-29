<cfparam name="url.page" default="" />
<cfparam name="url.method" default="" />
<cfset qwe = application.methods_struct />
<cfoutput>
<cfloop list="#listSort(structKeyList(qwe), 'textNoCase')#" index="variables.page">
	<h3 id="#page#">#page#</h3>
	<ul id="ul_#page#">
		<cfloop list="#listSort(structKeyList(qwe[page]), 'textNoCase')#" index="variables.method">
			<li><a href="?method=#method#&amp;page=#page#"<cfif url.page eq variables.page and url.method eq variables.method> class="current"</cfif>>#method#</a></li>
		</cfloop>
	</ul>
</cfloop></cfoutput>
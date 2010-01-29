<cfparam name="url.orderBy" default="item" />
<cfset url.orderBy = "list_name,completed" & iif(len(url.orderBy), de(','), de('')) & url.orderBy />

<!--- <comment author="P. Klinkenberg"> retrieve the page's xml </comment> --->
<cfset page_xml = application.backPack_obj.showPage(id=url.id) />

<!--- <comment author="P. Klinkenberg">
	Now convert the xml to 2 recordsets:
	- 1 with the page data
	- 1 with the page items
</comment> --->
<cfset page_qry = application.backPack_obj.convertPageToQuery(pageXML=page_xml) />
<cfset pageItems_qry = application.backPack_obj.getPageItemsAsQuery(pageXML=page_xml, orderBy="#url.orderBy#") />

<!--- <comment author="P. Klinkenberg"> if page not found: warn user and leave </comment> --->
<cfif not page_qry.recordcount>
	<strong class="error">The requested page (ID: <cfoutput>#url.id#</cfoutput>) could not be found.</strong>
	<cfexit method="exittemplate" />
</cfif>

<cfoutput query="page_qry">
	<h2 style="margin: 10px 0px;">#page_qry.title#</h2>
</cfoutput>

<!--- <comment author="P. Klinkenberg"> optionally display notes </comment> --->
<cfif structKeyExists(page_xml.response.page, "notes") and arrayLen(page_xml.response.page.notes.xmlChildren)>
	<hr />
	<h2>Notes</h2>
	<cfset allNotes = page_xml.response.page.notes.xmlChildren />
	<cfoutput>
		<cfloop from="1" to="#arrayLen(allNotes)#" index="noteNr">
			<div style="border: 1px dashed silver; padding: 5px; margin: 10px 0px; width:500px;">
				<p style="margin: 0px 0px 8px 0px;">
					<em style="float:right; font-size:smaller">Date: #lsDateFormat(parseDateTime(allNotes[noteNr].xmlAttributes.created_at), 'dddd d mmmm yyyy')#</em>
					<strong>#allNotes[noteNr].xmlAttributes.title#</strong>
				</p>
				<div style="clear:both">
					#application.textileConverter_obj.textile2HTML(allNotes[noteNr].xmlText)#
				</div>
			</div>
		</cfloop>
	</cfoutput>
</cfif>

<!--- <comment author="P. Klinkenberg"> optionally display attachments </comment> --->
<cfif structKeyExists(page_xml.response.page, "attachments") and arrayLen(page_xml.response.page.attachments.xmlChildren)>
	<hr />
	<h2>Attachments / files</h2>
	<cfset allNodes = page_xml.response.page.attachments.xmlChildren />
	<cfoutput>
		<ul class="attachments">
			<cfloop from="1" to="#arrayLen(allNodes)#" index="noteNr">
				<cfset fileName = allNodes[noteNr].xmlAttributes.file_name />
				<li>
					<!--- <comment author="P. Klinkenberg"> image </comment> --->
					<a href="actionFiles/show_attachment.cfm?id=#url.id#&amp;fileName=#fileName#"><!---
						---><img src="images/icons/#listLast(fileName, '.')#.gif" alt="file icon #listLast(fileName, '.')#" class="fileIcon" /><!---
						---> #fileName#</a>
				</li>
			</cfloop>
		</ul>
	</cfoutput>
</cfif>


<!--- <comment author="P. Klinkenberg"> optionally display images </comment> --->
<cfif structKeyExists(page_xml.response.page, "images") and arrayLen(page_xml.response.page.images.xmlChildren)>
	<hr />
	<h2>Images</h2>
	<cfset allNodes = page_xml.response.page.images.xmlChildren />
	<cfoutput>
		<div class="imagesHolder">
			<cfloop from="1" to="#arrayLen(allNodes)#" index="noteNr">
				<cfset fileName = allNodes[noteNr].xmlAttributes.file_name />
				<cfset title = allNodes[noteNr].xmlAttributes.description />
				<span class="imageThumb">
					<!--- <comment author="P. Klinkenberg"> image </comment> --->
					<a href="actionFiles/show_image.cfm?id=#url.id#&amp;fileName=#fileName#<cfif structKeyExists(url, 'flush')>&amp;reload=1</cfif>" target="_blank"><!---
						---><img src="actionFiles/show_image.cfm?id=#url.id#&amp;fileName=thumb_#fileName#<cfif structKeyExists(url, 'flush')>&amp;reload=1</cfif>" alt="actionFiles/show_image.cfm?id=#url.id#&fileName=thumb_#fileName#" border="1" /><!---
					---></a>
					<br />#title#
				</span>
			</cfloop>
		</div>
	</cfoutput>
</cfif>


<table border="1" cellspacing="0" cellpadding="4">
	<cfoutput>
		<thead>
			<tr>
				<th><a href="#cgi.script_name#?fuseAction=show_page&amp;id=#page_qry.ID#&amp;orderBy=completed,item">completed</a></th>
				<th><a href="#cgi.script_name#?fuseAction=show_page&amp;id=#page_qry.ID#&amp;orderBy=id,item">id</a></th>
				<th><a href="#cgi.script_name#?fuseAction=show_page&amp;id=#page_qry.ID#&amp;orderBy=item">item</a></th>
			</tr>
		</thead>
	</cfoutput>
	<tbody>
		<cfoutput query="pageItems_qry" group="list_name">
			<tr><td colspan="3"><strong>#list_name#</strong><cfif not len(list_name)><em>no list name</em></cfif></td></tr>
			<cfoutput>
				<tr class="<cfif not completed>not</cfif>Completed">
					<td><cfif completed>yes<cfelse>NO</cfif></td>
					<td>#id#</td>
					<td>#item#</td>
				</tr>
			</cfoutput>
		</cfoutput>
		<cfif not pageItems_qry.recordcount>
			<tr><td colspan="3"><em>There are no items attached to this page at the moment.</em></td></tr>
		</cfif>
	</tbody>
</table>

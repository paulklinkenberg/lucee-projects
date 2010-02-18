<cfoutput>
<form method="post" action="#cgi.script_name#">
	<p>
		<label for="excludeSearchEngines">Count views from web spiders/crawlers?</label>
		<span class="hint">These are page requests done by search engines like Google, to index your website.
		<br />To be honest, this isn't a real view, but it <em>is</em> a request.</span>
		<span class="field"><select name="excludeSearchEngines">
			<option value="1">No (default)</option>
			<option value="0"<cfif getSetting('excludeSearchEngines') eq 0> selected="selected"</cfif>>Yes</option>
		</select></span>
	</p>
	<p>
		<label for="maxHours">How many hours inbetween a count for the same IP address?</label>
		<span class="hint">ViewCount remembers the time and IP address for each counted view.
		After how many hours should we consider a page view from the same IP to the same post a new view?</span>
		<span class="field"><input type="text" id="maxHours" name="maxHours" value="#getSetting('maxHours')#" size="3" maxlength="4" />
			<em>(numeric; 0 = count each page view)</em>
		</span>
	</p>
	
	<div class="actions">
		<input type="submit" class="primaryAction" value="Submit"/>
		<input type="hidden" value="event" name="action" />
		<input type="hidden" value="showViewCountSettings" name="event" />
		<input type="hidden" value="true" name="apply" />
		<input type="hidden" value="ViewCount" name="selected" />
	</div>
</form>

<cfparam name="data.externaldata.viewCountsOrder" default="page" />
<cfparam name="data.externaldata.viewCountsOrderDir" default="ASC" />
<cfsavecontent variable="sql_str">
	SELECT <cfif findNoCase('mssql', variables.dbType)>ISNULL<cfelse>IFNULL</cfif>(#variables.tablePrefix#viewCounts.viewCount,0) AS viewCount
		, #variables.tablePrefix#entry.id, #variables.tablePrefix#entry.title, #variables.tablePrefix#entry.name, #variables.tablePrefix#post.posted_on
	FROM #variables.tablePrefix#entry
	INNER JOIN #variables.tablePrefix#post ON #variables.tablePrefix#post.id = #variables.tablePrefix#entry.id
	LEFT OUTER JOIN #variables.tablePrefix#viewCounts ON #variables.tablePrefix#viewCounts.postID = #variables.tablePrefix#entry.id
	ORDER BY <cfif data.externaldata.viewCountsOrder eq 'page'>#variables.tablePrefix#entry.title<cfelseif data.externaldata.viewCountsOrder eq 'date'>#variables.tablePrefix#post.posted_on<cfelse>#variables.tablePrefix#viewCounts.viewCount</cfif> <cfif listFindNoCase('asc,desc', data.externaldata.viewCountsOrderDir)>#data.externaldata.viewCountsOrderDir#</cfif>
</cfsavecontent>
<cfset viewCounts_qry = variables.objQryAdapter.makeQuery(query=sql_str) />

<hr />
<h3>View Counts so far</h3>

<form method="post" action="#cgi.script_name#">
	<table>
		<thead>
			<tr>
				<th><a href="?event=showViewCountSettings&amp;owner=ViewCount&amp;selected=showViewCountSettings&amp;viewCountsOrder=date<cfif data.externaldata.viewCountsOrder neq 'date' or data.externaldata.viewCountsOrderDir eq 'ASC'>&amp;viewCountsOrderDir=DESC</cfif>" title="Order on this column">Publish date</a></th>
				<th><a href="?event=showViewCountSettings&amp;owner=ViewCount&amp;selected=showViewCountSettings&amp;viewCountsOrder=page<cfif data.externaldata.viewCountsOrder eq 'page' and data.externaldata.viewCountsOrderDir eq 'ASC'>&amp;viewCountsOrderDir=DESC</cfif>" title="Order on this column">Page</a></th>
				<th><a href="?event=showViewCountSettings&amp;owner=ViewCount&amp;selected=showViewCountSettings&amp;viewCountsOrder=viewCount&amp;viewCountsOrderDir=<cfif data.externaldata.viewCountsOrder neq 'viewCount' or data.externaldata.viewCountsOrderDir eq 'ASC'>DESC<cfelse>ASC</cfif>" title="Order on this column">viewCount</a>
					<span style="float:right">(<a href="?event=showViewCountSettings&amp;owner=ViewCount&amp;selected=showViewCountSettings&amp;editViewCounts=1">edit</a>)</span>
				</th>
			</tr>
		</thead>
		<tbody>
			<cfloop query="viewCounts_qry"><tr<cfif not viewCounts_qry.currentrow mod 2> class="alternate"</cfif>>
				<td>#lsdateFormat(viewCounts_qry.posted_on, 'medium')#</td>
				<td><a href="/post.cfm/#viewCounts_qry.name#" target="_blank">#viewCounts_qry.title#</a></td>
				<td>#viewCounts_qry.viewCount#
					<cfif structKeyExists(data.externaldata, 'editViewCounts')>
						<input type="text" name="viewCount_#viewCounts_qry.id#" value="#viewCounts_qry.viewCount#" size="4" style="float:right" />
					</cfif>
				</td>
			</tr></cfloop>
		</tbody>
		<tfoot>
			<tr style="border-top:1px solid ##000;">
				<td colspan="2" style="text-align:right;"><strong>Total:</strong></td>
				<td><strong>#evaluate(valueList(viewCounts_qry.viewCount, '+'))#</strong>
					<cfif structKeyExists(data.externaldata, 'editViewCounts')>
						<input type="submit" class="primaryAction" value="Submit" style="float:right" />
						<input type="hidden" value="event" name="action" />
						<input type="hidden" value="showViewCountSettings" name="event" />
						<input type="hidden" value="true" name="saveViewCounts" />
						<input type="hidden" value="ViewCount" name="selected" />
					</cfif>
				</td>
			</tr>
		</tfoot>
	</table>
</form>
</cfoutput>
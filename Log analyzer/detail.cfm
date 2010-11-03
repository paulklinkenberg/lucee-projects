<!---
/*
 * detail.cfm, enhanced by Paul Klinkenberg
 * Originally written by Gert Franz
 * http://www.railodeveloper.com/post.cfm/railo-admin-log-analyzer
 *
 * Date: 2010-11-03 20:22:00 +0100
 * Revision: 1.0.0
 *
 * Copyright (c) 2010 Paul Klinkenberg, railodeveloper.com
 * Licensed under the GPL license.
 *
 *    This program is free software: you can redistribute it and/or modify
 *    it under the terms of the GNU General Public License as published by
 *    the Free Software Foundation, either version 3 of the License, or
 *    (at your option) any later version.
 *
 *    This program is distributed in the hope that it will be useful,
 *    but WITHOUT ANY WARRANTY; without even the implied warranty of
 *    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *    GNU General Public License for more details.
 *
 *    You should have received a copy of the GNU General Public License
 *    along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 *    ALWAYS LEAVE THIS COPYRIGHT NOTICE IN PLACE!
 */
---><cfoutput>
<cfset stData = evaluate(form.data)>
<cfset dMin = stData.firstdate />
<cfset dMax = stData.lastdate />

<cfset stOccurences = {} />
<cfloop from="1" to="#arrayLen(stData.dateTime)#" index="i">
	<cfset tempdate = dateFormat(stData.dateTime[i], "yyyy-mm-dd ") & timeformat(stData.dateTime[i], "HH:mm") />
	<cfif not structKeyExists(stOccurences, tempdate)>
		<cfset stOccurences[tempdate] = 1 />
	<cfelse>
		<cfset stOccurences[tempdate]++ />
	</cfif>
</cfloop>

<cfset qValues = queryNew("date,datedisplay,occurences", "timestamp,varchar,integer") />
<cfloop collection="#stOccurences#" item="i">
	<cfset queryAddRow(qValues) />
	<cfset querySetCell(qValues, "date", parseDateTime(i)) /> 
	<cfset querySetCell(qValues, "datedisplay", dateformat(parseDateTime(i), arguments.lang.dateformatchart) & timeformat(parseDateTime(i), arguments.lang.timeformatchart)) /> 
	<cfset querySetCell(qValues, "occurences", stOccurences[i]) /> 
</cfloop>
<cfquery name="qValues" dbtype="query">
	SELECT *
	FROM qValues
	ORDER BY date
</cfquery>

<h3>#listLast(form.logfile, '/\')# - #stData.message#</h3>
<table class="tbl" width="650">
	<tr>
		<td class="tblHead">#arguments.lang.Message#</td>
		<td class="tblContent">#stData.message#</td>
	</tr><tr>
		<td class="tblHead">#arguments.lang.Lastoccurence#</td>
		<td class="tblContent">#getTextTimeSpan(dMax, arguments.lang)#: #dateFormat(dMax, arguments.lang.dateformat)# #timeFormat(dMax, arguments.lang.timeformat)#</td>
	</tr><tr>
		<td class="tblHead">#arguments.lang.Threadname#</td>
		<td class="tblContent">#stData.thread#</td>
	</tr><tr>
		<td class="tblHead">#arguments.lang.Type#</td>
		<td class="tblContent">#stData.type#</td>
	</tr>
	<cfif len(trim(stData.file))>
		<tr>
			<td class="tblHead">#arguments.lang.File#</td>
			<td class="tblContent">#stData.file#, #arguments.lang.line# #stData.line#</td>
		</tr>
	</cfif>
	<tr>
		<td class="tblHead" style="vertical-align:top;">#arguments.lang.Occurences#</td>
		<td class="tblContent">#stData.iCount#<!---
			---><cfif stData.iCount gt 1>,
				#arguments.lang.from# #DateFormat(dMin, arguments.lang.dateformat)# #TimeFormat(dMin, arguments.lang.timeformatshort)# #arguments.lang.untill# 
				#DateFormat(dMax, arguments.lang.dateformat)# #TimeFormat(dMax, arguments.lang.timeformatshort)#
				<br /><br />
				<cfchart format="png" chartheight="200" chartwidth="500" showygridlines="no" backgroundcolor="##FFFFFF"
				seriesplacement="default" labelformat="number" xaxistitle="#arguments.lang.date#" yaxistitle="#arguments.lang.Occurences#"
				xaxistype="date" yaxistype="numeric" sortxaxis="yes">
					<cfchartseries type="line" itemcolumn="datedisplay" valuecolumn="occurences" query="qValues" seriescolor="##00F000" markerstyle="circle"></cfchartseries> 
				</cfchart>
			</cfif>
		</td>
	</tr><tr>
		<td class="tblHead">#arguments.lang.Detail#</td>
		<td class="tblContent" style="word-wrap:break-word;">#replace(rereplace(stData.detail, "\(([^\(\)]+\.cf[cm]:[0-9]+)\)", "(<strong style='background-color:##FF3'>\1</strong>)", "all"), chr(10), '<br />', 'all')#</td>
	</tr>
	<tr><td colspan="2"><form action="#action('list')#" method="post">
		<input type="hidden" name="logfile" value="#form.logfile#">
		<input class="submit" type="submit" value="#arguments.lang.Back#" name="mainAction"/>
	</form></td></tr>
</table>
</cfoutput>
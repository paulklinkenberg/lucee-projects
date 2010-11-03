<!---
/*
 * overview.cfm, enhanced by Paul Klinkenberg
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
---><cfif structKeyExists(url, "delfile")>
	<cfset var tempFilePath = getLogPath(file=url.delfile) />
	<cffile action="write" file="#tempFilePath#" output="" />
	<cfoutput><p class="CheckOk">#replace(arguments.lang.logfilehasbeencleared, "%1", listLast(tempFilePath, '/\'))#</p></cfoutput>
</cfif>

<cfoutput><table class="tbl" width="650">
	<tr>
		<td class="tblHead">#arguments.lang.logfilename#</td>
		<td class="tblHead">#arguments.lang.logfiledate#</td>
		<td class="tblHead">#arguments.lang.logfilesize#</td>
		<td class="tblHead">#arguments.lang.actions#</td>
	</tr>
	<cfset frmaction = rereplace(action('list'), "^[[:space:]]+", "") />
	<cfset downloadaction = rereplace(action('download'), "^[[:space:]]+", "") />
	<cfset delaction = rereplace(action('overview'), "^[[:space:]]+", "") />
	<cfloop query="arguments.req.logfiles">
		<tr>
			<td class="tblContent">#name#</td>
			<td class="tblContent"><abbr title="#dateformat(datelastmodified, arguments.lang.dateformat)# #timeformat(datelastmodified, arguments.lang.timeformatshort)#">#getTextTimeSpan(datelastmodified, arguments.lang)#</abbr></td>
			<td class="tblContent"><cfif size lt 1024>#size# #arguments.lang.bytes#<cfelse>#ceiling(size/1024)# #arguments.lang.KB#</cfif></td>
			<td class="tblContent" style="text-align:right; white-space:nowrap; width:1%"><form action="#frmaction#" method="post" style="display:inline;margin:0;padding:0;">
				<input type="hidden" name="logfile" value="#name#">
				<input type="submit" value="#arguments.lang.details#" class="button" />
				<input type="button" class="button" onclick="self.location.href='#downloadaction#&amp;file=#name#'" value="#arguments.lang.download#" />
				<input type="button" class="button" onclick="self.location.href='#delaction#&amp;delfile=#name#'" value="#arguments.lang.delete#" />
			</form></td>
		</tr>
	</cfloop>
</table>
<p>#arguments.lang.logfilelocation#: <em>#arguments.req.logfiles.directory#</em></p>
</cfoutput>


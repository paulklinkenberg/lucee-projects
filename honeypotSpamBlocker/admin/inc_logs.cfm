<cfset logFileWebPath = replace(replace(getDirectoryFromPath(GetCurrentTemplatePath()), expandPath('/'), '/'), '\', '/', 'all') />
<cfset logFileWebPath = rereplace(logFileWebPath, 'admin/?$', '') />

<!--- clear log file? --->
<cfif structKeyExists(url, "deletelog") and refind('\.log$', url.deletelog) and fileExists(expandPath("#logFileWebPath##getFileFromPath(url.deletelog)#"))>
	<cffile action="write" file="#expandPath('#logFileWebPath##getFileFromPath(url.deletelog)#')#" output="" />
	<cfoutput><p>The log file #url.deletelog# has been emptied.</p></cfoutput>
</cfif>

<!--- show log files --->
<cfdirectory name="qFiles" action="list" filter="*.log" directory="#expandPath(logFileWebPath)#" />
<ul>
	<cfif not qFiles.recordcount>
		<li><em>no logs yet</em></li>
	</cfif>
	<cfoutput query="qFiles">
		<li><a href="#settingsPageUrl#&amp;currentTab=logs&amp;showlog=#qFiles.name#">#qFiles.name#</a> - #ceiling(qFiles.size/1024)#KB, last update: #dateformat(qFiles.datelastmodified, 'd mmmm yyyy')# #timeformat(qFiles.datelastmodified, 'HH:mm:ss')#
			&nbsp; <a href="#settingsPageUrl#&amp;currentTab=logs&amp;deletelog=#qFiles.name#">Clear log file</a>
		</li>
	</cfoutput>
</ul>

<cfif structKeyExists(url, "showlog") and refind('\.log$', url.showlog) and fileExists(expandPath("#logFileWebPath##getFileFromPath(url.showlog)#"))>
	<cfoutput>
		<h3>Log file #url.showlog#</h3>
		<table id="logs">
			<thead>
				<tr>
					<th>Date</th>
					<th>Type</th>
					<th>IP address</th>
					<th>Message</th>
				</tr>
			</thead>
			<tbody>
				<cfset sLogFiletxt = fileRead(expandPath("#logFileWebPath##getFileFromPath(url.showlog)#")) />
				<cfif not len(sLogFiletxt)>
					<tr><td colspan="4"><em>no log lines yet</em></td></tr>
				<cfelse>
					<cfset sLogFiletxt = replace(sLogFiletxt, "	", "</td><td>", "all") />
					<cfset sLogFiletxt = replace(sLogFiletxt, chr(10), "</td></tr>#chr(10)#<tr><td>", "all") />
					<tr>#sLogFiletxt#
						</td><td colspan="3"><strong>#listLen(sLogFiletxt, chr(10)) - 1# lines</strong></td>
					</tr>
				</cfif>
			</tbody>
		</table>
	</cfoutput>
</cfif>

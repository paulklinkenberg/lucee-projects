<!---
/*
 * this file was created by Paul Klinkenberg
 * http://www.lucee.nl/post.cfm/railo-tasks-viewer-extension
 *
 * Date: 2012-10-01
 * Revision: 1.2.6
 *
 * Copyright (c) 2012 Paul Klinkenberg, lucee.nl
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
--->
<cfsetting enablecfoutputonly="yes" requesttimeout="9999" />
<cfset startTime = getTickCount() />
<cfset qAllSchedules = getAllSchedules() />
<cfset currCheckDate = now() />
<cfset testresults = "" />
<cfset mailto = getConfigData('email') />

<cfset lastCheckDate = getConfigData("lastCheckDate") />
<cfif not isDate(lastCheckDate)>
	<cfset lastCheckDate = dateAdd('d', -7, now()) />
	<cfset checkedPeriodText = "Since this is the first run, the Alerter Service only looked at the last 7 days." />
<cfelse>
	<cfset checkedPeriodText = "The Alerter Service only looked at tasks between #dateformat(lastCheckDate, 'mmmm d')# #timeformat(lastCheckDate, 'HH:mm:ss')# and #dateformat(currCheckDate, 'mmmm d')# #timeformat(currCheckDate, 'HH:mm:ss')#." />
</cfif>
<cfset missingLogDataText = "" />


<cfoutput>
	<h1>Alerter Service - manual run</h1>
	<p>#checkedPeriodText#</p>
</cfoutput>

<!--- no email defined? --->
<cfif not isValid('email', mailto)>
	<cfoutput>
		<p class="error">No valid email address is defined!</p>
	</cfoutput>
	<cfif cgi.HTTP_USER_AGENT eq "CFSCHEDULE">
		<cfthrow message="No valid email address is defined! This task will not continue." />
	<cfelse>
		<cfoutput>
			<p><strong>But since you are manually requesting this page, we will log the results on-screen.</strong></p>
		</cfoutput>
	</cfif>
</cfif>

<cfloop query="qAllSchedules">
	<cfoutput><b>Checking task <em>#name#</em></b><br /></cfoutput>
		
	<cfset logFile = getLogFile(qAllSchedules.configfile) />
	<cfset logdata = getLogData(logFile, name) />
	
	<cfif logdata eq "">
		<cfoutput>
			<p class="error">No log data was found for this task</p>
		</cfoutput>
	<cfelse>
		<cfset logStartDate = getLogStartDate(logfile) />
		
		<cfset from = parseDateTime(startDate & " " & startTime) />
		<cfif interval eq "once">
			<cfset untill = from />
		<cfelseif endDate eq "">
			<cfset untill = now() />
		<cfelseif paused eq true>
			<cfset line = listLast(logdata, chr(10)&chr(13)) />
			<cfset untill = getExecDate(line) />
		<cfelse>
			<cfset untill = parseDateTime(endDate & " " & endTime) />
		</cfif>
	
		<!--- if the task runs/ran between logStartDate and now() --->
		<cfif from lt now() and untill gt lastCheckDate>
			<!--- if the log file is younger then lastCheckDate, note this--->
			<cfif logStartDate gt lastCheckDate>
				<cfset missingLogDataText &= "<br />Log data for task [#name#] is only available since #dateformat(logStartDate, 'mmmm d yyyy')# #timeformat(logStartDate, 'HH:mm:ss')#" />
				<cfset checkFromDate = logStartDate />
			<cfelse>
				<cfset checkFromDate = lastCheckDate />
			</cfif>
			<!--- get an array of exec. dates --->
			<cfset execDates = getDateIntervals(from, untill, starttime, endtime, checkFromDate, qAllSchedules.interval, qAllSchedules.timeout) />
			<cfif not arrayIsEmpty(execDates)>
				<!--- now check the log: did it run? --->
				<cfset addLogExecutionsToDateIntervals(execDates, logdata, qAllSchedules.timeout, checkFromDate) />
				
				<cfsavecontent variable="testresults">
					<cfoutput>#testresults#</cfoutput>
					<cfloop array="#execDates#" index="st">
						<!--- is it possible this task is still running? --->
						<cfif st.missed and datediff('s', st.date, currCheckDate) lt qAllSchedules.timeout/1000>
							<!--- if so, then make sure we check this task again! 
							(as a penalty, we might get double hits on other tasks, but that's better then missing one) --->
							<cfset currCheckDate = st.date />
						<cfelseif st.missed or (structKeyExists(st, "error") and st.error)>
							<cfoutput>
								<tr>
									<td>#name#</td>
									<td>#getIntervalAsString(qAllSchedules.interval, qAllSchedules.startTime, qAllSchedules.startDate, qAllSchedules.endTime, qAllSchedules.endDate)#</td>
									<td>#dateformat(st.date, "mmm. d, yyyy")# #timeformat(st.date, "HH:mm:ss")#</td>
									<cfif st.missed>
										<td>Did not execute</td>
									<cfelse>
										<td>Executed with error: #st.text#</td>
									</cfif>
									<td><a href="#qAllSchedules.url#<cfif isnumeric(timeout)><cfif find('?', qAllSchedules.url)>&amp;<cfelse>?</cfif>RequestTimeout=#timeout/1000#</cfif>">task URL</a>
										
										<cfif qAllSchedules.webContextURL neq "">
											<a href="#qAllSchedules.webContextURL#/railo-context/admin/web.cfm?action=services.schedule&action2=edit&task=#hash(qAllSchedules.name)#">edit task</a>
										</cfif>
									</td>
								</tr>
							</cfoutput>
						</cfif>
					</cfloop>
				</cfsavecontent>
			</cfif>
		</cfif>
	</cfif>
</cfloop>

<cfif testresults eq "">
	<cfoutput>
		<h2>No errors and missed executions were found</h2>
		<p>#missingLogDataText#</p>
	</cfoutput>
<cfelse>
	<cfset tmUrl = "http://#cgi.http_host##cgi.SCRIPT_NAME#" />
	
	<cfsavecontent variable="mailText">
		<cfoutput>
			<h3>Scheduled tasks Alerter Service</h3>
			<cfif checkedPeriodText neq "">
				<p><strong>#checkedPeriodText#</strong></p>
			</cfif>
			<p>
				Date: #dateformat(currCheckDate, 'mmmm d, yyyy')# #timeformat(currCheckDate, 'HH:mm:ss')#<br />
				<br />
				One or more of your scheduled tasks did not run succesfully.<br />
				You can get detailed info by visiting <a href="#tmUrl#">your Tasks manager plugin</a>.
			</p>
			<table border="1" cellspacing="0" cellpadding="2">
				<thead>
					<tr>
						<td><strong>Task</strong></td>
						<td><strong>Interval</strong></td>
						<td><strong>Date</strong></td>
						<td><strong>Message</strong></td>
						<td><strong>Task URL</strong></td>
					</tr>
				</thead>
				<tbody>#testresults#</tbody>
			</table>
			<p>#missingLogDataText#</p>
		</cfoutput>
	</cfsavecontent>
	
	<cfoutput>#mailText#</cfoutput>
	
	<cfif isValid('email', mailto)>
		<cfmail to="#mailto#" from="#mailto#" subject="Scheduled tasks Alerter Service" type="html">
<!DOCTYPE html>
<html>
<head>
	<style type="text/css">
		body, td, th { font-size:11px; font-family:Arial, Helvetica, sans-serif; color:##000; }
		table { border-collapse: collapse; }
		td, th { padding:2px 3px; border:1px solid ##eee; text-align:left; vertical-align:top; }
	</style>
</head>
<body>
	#mailText#
	<hr />
	<br /><br />
	<cfset totalTime = getTickcount() - startTime />
	<p>Total execution time of the Alerter Service: #totalTime# msecs.</p>
	<p>
		<em>The Tasks Viewer extension and Alerter Service was created by Paul Klinkenberg,</em>
		<a href="http://www.lucee.nl/"><em>lucee.nl</em></a>
	</p>
</body>
</html>
		</cfmail>
		
		<cfoutput>
			<h3>The results have been mailed to [#mailto#]!</h3>
		</cfoutput>
	</cfif>
</cfif>

<cfif isValid('email', mailto)>
	<cfset setConfigData('lastCheckDate', currCheckDate) />
</cfif>

<cfoutput>
	<h1>done</h1>
	<cfset totalTime = getTickcount() - startTime />
	<p><em>Total execution time of the Alerter Service: #totalTime# msecs.</em></p>
</cfoutput>

<!--- this text is here for the scheduled task, so it can see that the code actually succeeded --->
<cfoutput><span class="alerterservicesucceeded"></span></cfoutput>

<cfif cgi.HTTP_USER_AGENT eq "CFSCHEDULE">
	<cfabort />
<cfelse>
	<cfoutput>
		<cfset a = action('alertservice') />
		<form action="#a#" method="post">
			<input class="submit" type="submit" value="Back" name="mainAction"/>
		</form>
	</cfoutput>
</cfif>
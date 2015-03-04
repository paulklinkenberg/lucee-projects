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
<cfsavecontent variable="js">
	<script type="text/javascript" src="<cfoutput>#arguments.app.currPath#</cfoutput>flot/jquery.min.js"></script>
</cfsavecontent>
<cfhtmlhead text="#js#" />

<cfsetting enablecfoutputonly="yes" />

<cfset qAllSchedules = getEmptyScheduleQuery() />
<cfset addScheduleRows(url.xmlpath, qAllSchedules, url.contextName, url.config) />

<cfloop query="qAllSchedules">
	<cfif qAllSchedules.name eq url.task>
		<cfoutput>
			<h1>Task details for task <em>#url.task#</em></h1>
			#showScheduleDetails(qAllSchedules, qAllSchedules.currentrow, true)#
		</cfoutput>
		
		<cfset logFile = getLogFile(qAllSchedules.configfile) />
		<cfset logdata = getLogData(logFile, url.task) />
		
		<cfif logdata eq "">
			<cfoutput>
				<p class="error">No log data was found for this task.<br />The log file may have been full, and thus emptied.</p>
			</cfoutput>
		<cfelse>
			<!--- create a graph of executions --->
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
			<cfif from lt now() and untill gte logStartDate>
				<!--- get an array of exec. dates --->
				<cfset execDates = getDateIntervals(from, untill, starttime, endtime, logStartDate, qAllSchedules.interval, qAllSchedules.timeout) />
			
				<!--- now check the log: did it run? --->
				<cfset addLogExecutionsToDateIntervals(execDates, logdata, qAllSchedules.timeout) />
				
				<cfset sError = "" />
				<cfset sSuccess = "" />
				<cfset sMissed = "" />
				<cfset sNotScheduled = "" />
				<cfloop array="#execDates#" index="st">
					<cfif st.missed>
						<cfset sMissed = listappend(sMissed, '[_d(#dateformat(st.date, "yyyy,m-1,d,")##timeformat(st.date, "H,m,s")#),3,""]') />
					<cfelseif structKeyExists(st, "error") and st.error>
						<cfset sError = listappend(sError, '[_d(#dateformat(st.date, "yyyy,m-1,d,")##timeformat(st.date, "H,m,s")#),2,"#jsstringformat(st.text)#"]') />
					<cfelse>
						<cfset sSuccess = listappend(sSuccess, '[_d(#dateformat(st.date, "yyyy,m-1,d,")##timeformat(st.date, "H,m,s")#),4,"#jsstringformat(st.text)#"]') />
					</cfif>
					<cfif structKeyExists(st, "notscheduled")>
						<cfset sNotScheduled = listappend(sNotScheduled, '[_d(#dateformat(st.date, "yyyy,m-1,d,")##timeformat(st.date, "H,m,s")#),1,"#jsstringformat(st.text)#"]') />
					</cfif>
				</cfloop>
				
				<cfoutput>
					<cfsavecontent variable="js">
						<style type="text/css">
							##chart .button {
								position: absolute;
								cursor: pointer;
							}
							##chart div.button {
								font-size: smaller;
								color: ##555;
								background-color: ##eee;
								padding: 2px;
							}
						</style>
						<!--[if lte IE 8]><script language="javascript" type="text/javascript" src="#arguments.app.currPath#flot/excanvas.min.js"></script><![endif]-->
						<script language="javascript" type="text/javascript" src="#arguments.app.currPath#flot/jquery.flot.min.js"></script>
						<script language="javascript" type="text/javascript" src="#arguments.app.currPath#flot/jquery.flot.symbol.min.js"></script>
						<script language="javascript" type="text/javascript" src="#arguments.app.currPath#flot/jquery.flot.navigate.min.js"></script>
						<script language="javascript" type="text/javascript" src="#arguments.app.currPath#taskgraph.js"></script>
						<script type="text/javascript">
							var mainUrl = '#arguments.app.currPath#';
							var data = [
								<cfset komma = "" />
								<cfif sError neq "">
									{
										data: [#sError#]
										, points: { symbol: "diamond" }
										, label: "Error"
										, color:'rgb(255, 0, 0)'
									}
									<cfset komma = "," />
								</cfif>
								<cfif sMissed neq "">
									#komma#{
										data: [#sMissed#]
										, points: { symbol: "circle" }
										, label: "Missed"
										, color:'rgb(255, 140, 0)'
									}
									<cfset komma = "," />
								</cfif>
								<cfif sSuccess neq "">
									#komma#{
										data: [#sSuccess#]
										, points: { symbol: "triangle" }
										, label: "Executed"
										, color:'rgb(0, 255, 0)'
									}
									<cfset komma = "," />
								</cfif>
								<cfif sNotScheduled neq "">
									#komma#{
										data: [#sNotScheduled#]
										, points: { symbol: "square" }
										, label: "Not scheduled"
										, color:'rgb(255, 223, 48)'<!---#FFCC33--->
									}
									<cfset komma = "," />
								</cfif>
							];
							$(function(){
								var chart = $("##chart");
								plotchart(chart, data);
							});
						</script>
					</cfsavecontent>
					<cfhtmlhead text="#js#" />
					
					<p>Log and graph data is available since the log start date: #dateformat(logStartDate, 'mmmm d, yyyy')# #timeformat(logStartDate, 'HH:mm:ss')#</p>
					
					<h2>Execution graph</h2>
					<p><em>Note: unscheduled exections are shown twice: once at Error/Success, and once at Unscheduled</em>
						<br />You can zoom in/out, and drag the chart horizontally.
					</p>
					<div id="chart" style="width:750px; height:150px;"></div>

					<h2>Log data for this task</h2>
					<pre style="border:1px solid ##666; padding:5px; width:740px; overflow:auto; max-height:150px;">#htmleditformat(logdata)#</pre>
				</cfoutput>
				
			<cfelse>
				<cfoutput>
					<p>This task did not run between the log's start date and now.</p>
				</cfoutput>
			</cfif>
		</cfif>
	</cfif>
</cfloop>
<cfsetting enablecfoutputonly="no" />
<cfoutput>
	<form action="#action('overview')#" method="post">
		<input class="submit" type="submit" value="Back" name="mainAction"/>
	</form>
</cfoutput>
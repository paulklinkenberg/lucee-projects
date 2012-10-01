<cfcomponent hint="I contain the main functions for the plugin" extends="railo-context.admin.plugin.Plugin">
<!---
/*
 * this file was created by Paul Klinkenberg
 * http://www.railodeveloper.com/post.cfm/railo-tasks-viewer-extension
 *
 * Date: 2012-10-01
 * Revision: 1.2.6
 *
 * Copyright (c) 2012 Paul Klinkenberg, railodeveloper.com
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
	<cfset variables._configDataFile = "config.conf" />
	<cfset variables._configData = {} />

	
	<cffunction name="init" hint="this function will be called to initalize">
		<cfargument name="lang" type="struct">
		<cfargument name="app" type="struct" required="no" default="#{}#">
		<cfset app.currPath = action('getfile') & "file=" />
		
		<cfset loadConfig() />
		
		<cfset setConfigData('serverpw', session.passwordserver) />
	</cffunction>
	
	
	<cffunction name="getLogStartDate" returntype="date" output="no">
		<cfargument name="logfile" type="string" required="yes" />
		<cfset var line = "" />
		<cfloop file="#logfile#" index="line">
			<cfif refind('[0-9]{4}', listGetAt(line, 3))>
				<cfreturn getExecDate(line) />
			</cfif>
		</cfloop>
		<cfreturn getFileInfo(logfile).lastmodified />
	</cffunction>


	<cffunction name="getExecDate" returntype="date" output="no">
		<cfargument name="line" type="string" required="yes" />
		<cfreturn parseDateTime(replace(listGetAt(line, 3) & " " & listGetat(line, 4), """", "", "all")) />
	</cffunction>
	
	
	<cffunction name="getWebContexts" returntype="query" access="public" output="no">
		<cfargument name="fromCache" type="boolean" default="true" />
		<cfset var qWebContexts = "" />
		
		<cfif not structKeyExists(variables, "qWebContexts") or not arguments.fromCache>
			<!--- get all web contexts --->
			<cfadmin
				action="getContextes"
				type="server"
				password="#getConfigData('serverpw')#"
				returnVariable="qWebContexts" />
			<cfset variables.qWebContexts = qWebContexts />
		</cfif>
		<cfreturn variables.qWebContexts />
	</cffunction>
	
	
	<cffunction name="getEmptyScheduleQuery" returntype="query" output="no">
		<cfreturn queryNew("webContextURL,xmlpath,webContext,configfile,name,file,hidden,interval,port,proxyPort,publish,readonly,resolveUrl,startDate,startTime,endDate,endTime,timeout,url,password,username,paused,proxyHost,proxyUser,proxyPassword,autoDelete") />
	</cffunction>
	
	
	<cffunction name="getAllSchedules" returntype="query" output="no">
		<cfset var qContexts = getWebContexts() />
		<cfset var schedulerFile = "" />
		<cfset var qAllSchedules = getEmptyScheduleQuery() />
		
		<cfloop query="qContexts">
			<cfif fileExists(rereplace(getDirectoryFromPath(qContexts.config_file), "[/\\]$", "") & "#server.separator.file#scheduler#server.separator.file#scheduler.xml")>
				<cfset schedulerFile = rereplace(getDirectoryFromPath(qContexts.config_file), "[/\\]$", "") & "#server.separator.file#scheduler#server.separator.file#scheduler.xml" />
			<cfelse>
				<cfset schedulerFile = "" />
				<cfset var configXml = xmlParse(qContexts.config_file) />
				<cfif structKeyExists(configXml['railo-configuration'], "scheduler") and structKeyExists(configXml['railo-configuration'].scheduler.xmlAttributes, "directory")>
					<cfset schedulerFile = configXml['railo-configuration'].scheduler.xmlAttributes.directory & "scheduler.xml" />
					<cfset schedulerFile = replaceNoCase(schedulerFile, "{railo-web}", getDirectoryFromPath(qContexts.config_file)) />
				</cfif>
			</cfif>
			<cfif schedulerFile neq "" and fileExists(schedulerFile)>
				<cfset var contextName = ((structKeyExists(qContexts, "hash") ? qContexts.hash : qContexts.id) eq qContexts.label ? qContexts.path : qContexts.label) />
				<cfset addScheduleRows(schedulerFile, qAllSchedules, contextName, qContexts.config_file, qContexts.url) />
			</cfif>
		</cfloop>
		<cfreturn qAllSchedules />
	</cffunction>


	<cffunction name="addScheduleRows" output="no" returntype="void">
		<cfargument name="xmlPath" type="string" />
		<cfargument name="q" type="query" />
		<cfargument name="contextName" type="string" />
		<cfargument name="configFile" type="string" />
		<cfargument name="webContextURL" type="string" />
		<cfset var xml = fileRead(xmlPath) />
		<cfif find('<task', xml)>
			<cfset xml = xmlParse(xml) />
			<cfset var i = 0 />
			<cfif isDefined("xml.schedule.task")>
				<cfloop from="1" to="#arrayLen(xml.schedule.task)#" index="i">
					<cfset queryAddRow(q) />
					<cfset querySetCell(q, "xmlPath", xmlPath) />
					<cfset querySetCell(q, "webContext", contextName) />
					<cfset querySetCell(q, "webContextURL", arguments.webContextURL) />
					<cfset querySetCell(q, "configFile", configFile) />
					<cfset var attr = xml.schedule.task[i].xmlAttributes />
					<cfset var key = "" />
					<cfloop collection="#attr#" item="key">
						<cfif refindNoCase("(Date|Time)$", key)>
							<cfset querySetCell(q, key, rereplace(attr[key], "\{[td] '(.+)'\}", "\1")) />
						<cfelse>
							<cfset querySetCell(q, key, attr[key]) />
						</cfif>
					</cfloop>
				</cfloop>
			</cfif>
		</cfif>
	</cffunction>
	
	
	<cffunction name="overview" output="yes">
		<cfargument name="lang" type="struct" required="yes">
		<cfargument name="app" type="struct" required="yes">
		<cfargument name="req" type="struct" required="no">
	</cffunction>
	
	
	<cffunction name="getfile" output="no">
		<cfif structKeyExists(url, "file") and not refind('(\.\.|^/)', url.file)>
			<cfif fileExists(url.file) and not listFindNoCase('cfm,cfc', listLast(url.file, '.'))>
				<cfcontent type="#getFileMimeType(expandPath(url.file))#" file="#url.file#" reset="yes"  />
			</cfif>
		<cfelse>
			<cfdump var="#url#" abort />
		</cfif>
	</cffunction>
	

	<cffunction name="getFileMimeType" returntype="string" output="no">
		<cfargument name="filePath" type="string" required="yes" />
		<cfset var testStruct = structNew() />
		<cfset testStruct.fileExt_str = getPageContext().getServletContext().getMimeType(arguments.filePath) />
		<cfif structIsEmpty(testStruct) or not len(testStruct.fileExt_str)>
			<cfset testStruct.fileExt_str = "application/x-unknown" />
		</cfif>
		<cfreturn testStruct.fileExt_str />
	</cffunction>

	
	<cffunction name="showScheduleDetails" returntype="void">
		<cfargument name="qAllSchedules" type="query" />
		<cfargument name="row" type="numeric" />
		<cfargument name="isdetailview" type="boolean" default="false" />
		<cfset var today = parseDateTime(dateformat(now(), 'yyyy-mm-dd')) />
		<cfoutput query="qAllSchedules" startrow="#row#" maxrows="1">
			<strong class="title">#qAllSchedules.name#<cfif qAllSchedules.paused eq true> <em>(paused)</em></cfif></strong><br />
			<div class="details">
				<span class="url">#qAllSchedules.url#<cfif isnumeric(timeout)><cfif find('?', qAllSchedules.url)>&amp;<cfelse>?</cfif>RequestTimeout=#timeout/1000#</cfif></span>
				<br />
				<cfif username neq "">
					Using Basic Authentication: user #username#<br />
				</cfif>
				<!--- scheduled time --->
				#getIntervalAsString(interval, startTime, startDate, endTime, endDate)#
				<br />
				<!--- proxy--->
				<cfif proxyHost neq "">
					Using proxy #proxyHost#:#proxyPort# (<cfif proxyUser neq "">user #proxyUser#<cfelse>anonymous</cfif>)
					<br />
				</cfif>
				<cfif publish eq true>
					Saved to file #file#<br />
				</cfif>
				<cfif parseDateTime(startDate) lte today and not isdetailview>
					<a href="#action('detail')#&amp;config=#URLEncodedFormat(configFile)#&amp;xmlpath=#URLEncodedFormat(xmlpath)#&amp;contextName=#URLEncodedFormat(webContext)#&amp;task=#urlencodedformat(name)#">View details, execution log, and graph</a><br />
				</cfif>
				<cfif qAllSchedules.webContextURL neq "">
					<a href="#qAllSchedules.webContextURL#/railo-context/admin/web.cfm?action=services.schedule&action2=edit&task=#hash(qAllSchedules.name)#">Edit this task</a>
				</cfif>
			</div>
		</cfoutput>
	</cffunction>


	<cffunction name="getIntervalAsString" returntype="string" output="no">
		<cfargument name="interval" type="string" />
		<cfargument name="startTime" type="string" />
		<cfargument name="startDate" type="string" />
		<cfargument name="endTime" type="string" />
		<cfargument name="endDate" type="string" />
		<cfset var sInterval = "" />
		<cfset var today = parseDateTime(dateformat(now(), 'yyyy-mm-dd')) />
		<cfif isNumeric(interval)>
			<cfset var time = parseDateTime('1-1-2000') />
			<cfset time = dateadd('s', interval, time) />
			<cfif hour(time) gt 0>
				<cfset sInterval = "every #timeformat(time, 'HH:mm:ss')#" />
			<cfelseif minute(time) gt 1>
				<cfset sInterval = "every #minute(time)# minutes#second(time) gt 0 ? ' #second(time)# second' & (second(time) eq 1 ? '':'s') : ''#" />
			<cfelse>
				<cfset sInterval = "every #interval# seconds" />
			</cfif>
		<cfelse>
			<cfset sInterval = interval />
			<cfif startTime neq "">
				<cfset sInterval &= " at #startTime#" />
			</cfif>
		</cfif>
		<!--- date and time --->
		<cfif endDate neq "">
			<cfif parseDateTime(endDate) lt today>
				<cfset sInterval = "Has run #sInterval# from #startDate# untill #endDate#" />
			<cfelseif parseDateTime(endDate) eq today>
				<cfset sInterval = "Has run #sInterval# from #startDate# untill today" />
			<cfelseif parseDateTime(startDate) gt today>
				<cfset sInterval = "Will run #sInterval# from #startDate# untill #endDate#" />
			<cfelseif parseDateTime(startDate) eq today>
				<cfset sInterval = "Runs #sInterval# from today untill #endDate#" />
			<cfelse>
				<cfset sInterval = "Runs #sInterval# from #startDate# untill #endDate#" />
			</cfif>
		<cfelse>
			<cfif parseDateTime(startDate) gt today>
				<cfif interval eq "once">
					<cfset sInterval = "Will run once on #startDate# at #startTime#" />
				<cfelse>
					<cfset sInterval = "Will start to run #sInterval# from #startDate#" />
				</cfif>
			<cfelseif parseDateTime(startDate) eq today>
				<cfif interval eq "once">
					<cfset sInterval = "Runs once, today at #startTime#" />
				<cfelse>
					<cfset sInterval = "Starts to run #sInterval# today" />
				</cfif>
			<cfelse>
				<cfif interval eq "once">
					<cfset sInterval = "Ran once on #startDate# at #startTime#" />
				<cfelse>
					<cfset sInterval = "Runs #sInterval# since #startDate#" />
				</cfif>
			</cfif>
		</cfif>
		<cfif isNumeric(interval)>
			<cfif (endTime neq "" and endTime neq "00:00") or (startTime neq "" and startTime neq "00:00")>
				<cfset sInterval &= ", from #startTime eq '' ? '00:00': startTime# untill #endTime eq '' or endTime eq '00:00' ? 'midnight' : endTime#" />
			</cfif>
		</cfif>
		<cfreturn sInterval />
	</cffunction>
	
	
	<cffunction name="getLogFile" returntype="string" output="no">
		<cfargument name="configFile" type="string" />
		<cfset var configxml = xmlParse(arguments.configfile) />
		<cfreturn replaceNoCase(configXml['railo-configuration'].scheduler.xmlAttributes.log, "{railo-web}", getDirectoryFromPath(arguments.configfile)) />
	</cffunction>
	
	<cffunction name="getLogData" returntype="string" output="no">
		<cfargument name="logfile" type="string" />
		<cfargument name="taskname" type="string" />
		<cfset var logdata = "" />
		<cfset var line = "" />
		<cfif fileExists(logFile)>
			<cfsavecontent variable="logdata"><cfoutput>
				<cfloop file="#logfile#" index="line"><cfif findNoCase(',"schedule task:#taskname#"', line)>#line#
</cfif></cfloop>
			</cfoutput></cfsavecontent>
		</cfif>
		<cfreturn trim(logdata) />
	</cffunction>


	<cffunction name="getDateIntervals" returntype="array" output="no">
		<cfargument name="from" type="date" />
		<cfargument name="untill" type="date" />
		<cfargument name="startTime" type="string" />
		<cfargument name="endTime" type="string" />
		<cfargument name="logStartDate" type="date" />
		<cfargument name="interval" type="string" />
		<cfargument name="timeout" type="string" />
		<cfset var execDates = [] />
		<cfset var tmp = "" />
		
		<cfset var startSeconds = refind('[1-9]', starttime) eq 0 ? 0 : getSeconds(from) />
		<cfset var endseconds = 0 />
		<cfif refind('[1-9]', endtime)>
			<cfset tmp = parseDateTime("2000-01-01 " & endTime) />
			<cfset endSeconds = getSeconds(tmp) />
		</cfif>
		
		<!--- get first execution date since logStartDate
		First extract as much time as possible, while being sure that the nextexec is still before logStartdate.
		In next step, add 1 interval untill nextExecution is found. --->
		<cfset var nextexec = from />
		<cfif nextexec lt logStartDate>
			<cfif interval eq "daily" or isNumeric(interval)>
				<cfset nextexec = dateadd('d', datediff('d', nextexec, logStartDate)-1, nextexec) />
			<cfelseif interval eq "weekly">
				<cfset nextexec = dateadd('ww', datediff('ww', nextexec, logStartDate)-1, nextexec) />
			<cfelseif interval eq "monthly">
				<cfset nextexec = dateadd('m', datediff('m', nextexec, logStartDate)-1, nextexec) />
			<cfelse>
				<cfthrow message="invalid interval [#interval#]!" />
			</cfif>
			<cfloop condition="nextexec lt logStartDate">
				<cfset nextexec = _addInterval(nextexec, interval, startseconds, endseconds, startTime) />
			</cfloop>
		</cfif>
		
		<!--- now create an array of exec dates untill now() --->
		<cfset var nowdate = now() />
		<cfloop condition="nextexec lt nowdate">
			<cfset arrayAppend(execDates, {date:nextexec, missed:1}) />
			<cfif interval eq "once">
				<cfset nextexec = nowdate />
			<cfelse>
				<cfset nextexec = _addInterval(nextexec, interval, startseconds, endseconds, startTime) />
			</cfif>
		</cfloop>
		
		<cfreturn execDates />
	</cffunction>


	<cffunction name="_addInterval" returntype="date" output="no">
		<cfargument name="nextexec" />
		<cfargument name="interval" />
		<cfargument name="startseconds" />
		<cfargument name="endseconds" />
		<cfargument name="startTime" />
		<cfif interval eq "daily">
			<cfreturn dateadd('d', 1, nextexec) />
		<cfelseif interval eq "weekly">
			<cfreturn dateadd('ww', 1, nextexec) />
		<cfelseif interval eq "monthly">
			<cfreturn dateadd('m', 1, nextexec) />
		<cfelse>
			<cfset var tmp = dateadd('s', interval, nextexec) />
			<!--- go to first execution of the next day--->
			<cfif day(tmp) neq day(nextexec) or (endseconds neq 0 and getSeconds(tmp) gt endseconds)>
				<cfreturn parseDateTime(dateformat(dateAdd('d', 1, nextexec), 'yyyy-mm-dd ') & startTime) />
			</cfif>
			<cfreturn tmp />
		</cfif>
	</cffunction>


	<cffunction name="_removeInterval" returntype="date" output="no">
		<cfargument name="nextexec" />
		<cfargument name="interval" />
		<cfargument name="startseconds" />
		<cfargument name="endseconds" />
		<cfargument name="startTime" />
		<cfif interval eq "daily">
			<cfreturn dateadd('d', -1, nextexec) />
		<cfelseif interval eq "weekly">
			<cfreturn dateadd('ww', -1, nextexec) />
		<cfelseif interval eq "monthly">
			<cfreturn dateadd('m', -1, nextexec) />
		<cfelse>
			<cfset tmp = dateadd('s', interval*-1, nextexec) />
			<cfset var prevSeconds = getSeconds(tmp) />
			<!--- go back to last execution previous day--->
			<cfif day(tmp) neq day(nextexec) or prevSeconds lt startseconds>
				<cfset var dailyExecSeconds = (endseconds eq 0 ? 86400 : endseconds) - startSeconds />
				<cfset nextexec = parseDateTime(dateformat(dateAdd('d', -1, nextexec), 'yyyy-mm-dd ') & startTime) />
				<cfset nextExec = dateAdd('s', interval * int(dailyExecSeconds/interval), nextExec) />
			</cfif>
			<cfreturn nextexec />
		</cfif>
	</cffunction>


	<cffunction name="getSeconds" output="no" returntype="numeric">
		<cfargument name="d" />
		<cfreturn hour(arguments.d)*3600 + minute(arguments.d)*60 + second(arguments.d) />
	</cffunction>
	
	
	<cffunction name="addLogExecutionsToDateIntervals" output="no" returntype="void">
		<cfargument name="execDates" type="array" />
		<cfargument name="logData" type="string" />
		<cfargument name="timeout" type="numeric" />
		<cfargument name="startDate" type="date" required="no" />
		<cfset var errorIgnorePatterns = listToArray(getConfigData('errorIgnorePatterns'), chr(10)) />
		<cfset var arrIndex = 1 />
		<cfset var line = "" />
		<cfloop list="#logdata#" delimiters="#chr(10)##chr(13)#" index="line">
			<cfif find('"ERROR",', line) eq 1 or refind(',"executed"$', line)>
				<cfset var execdate = getExecDate(line) />
				<cfif not structKeyExists(arguments, "startDate") or arguments.startDate lte execdate>
					<cfset var logMsg = rereplace(line, '^([^,]+,){5}', '') />
					<cfset var isError = find('"ERROR",', line) eq 1 ? 1:0 />
					<cfif isError and arrayFindNoCase(errorIgnorePatterns, unQuote(logMsg))>
						<cfset isError = 0 />
						<cfset logMsg &= " (error ignored)" />
					</cfif>
					<cfif arrIndex gt arrayLen(execDates)>
						<cfset ArrayAppend(execDates, {date:execDate, missed:0, error:isError, notscheduled:1, text:"#logMsg#"}) />
					<cfelse>
						<cfset var evalDate = execDates[arrIndex].date />
						<cfset var secondsDiff = dateDiff('s', evalDate, execdate) />
						<!--- task may run 2 minutes before actual schedule --->
						<!--- more then 2 mins before schedule --->
						<cfif secondsDiff lt -120>
							<cfset ArrayInsertAt(execDates, arrIndex, {date:execDate, missed:0, error:isError, notscheduled:1, text:"#logMsg#"}) />
							<cfset ++arrIndex />
						<!--- executed after evalDate+requesttimeout --->
						<cfelseif secondsDiff gt (timeout/1000 + 120)>
							<!--- no more schedule dates --->
							<cfif arrIndex eq arrayLen(execDates)>
								<cfset ArrayAppend(execDates, {date:execDate, missed:0, error:isError, notscheduled:1, text:"#logMsg#"}) />
							<cfelse>
								<cfset var found = 0 />
								<cfloop condition="found eq 0 and arrIndex lt arrayLen(execDates)">
									<cfset ++arrIndex />
									<cfset evalDate = execDates[arrIndex].date />
									<cfset secondsDiff = dateDiff('s', evalDate, execdate) />
									<!--- if task ran on this execdate --->
									<cfif secondsDiff gte -120 and secondsDiff lt (timeout/1000 + 120)>
										<cfset execDates[arrIndex] = {date:execDate, missed:0, error:isError, text:logMsg} />
										<cfset ++arrIndex />
										<cfset found = 1 />
									<!--- check next execdate; this one is too much in the past --->
									<cfelseif secondsDiff gt (timeout/1000 + 120)>
										<!--- skip --->
									<!--- execution outside the schedule --->
									<cfelse>
										<cfset ArrayInsertAt(execDates, arrIndex, {date:execDate, missed:0, error:isError, notscheduled:1, text:"#logMsg#"}) />
										<cfset ++arrIndex />
										<cfset found = 1 />
									</cfif>
								</cfloop>
							</cfif>
						<!--- it fits right in :) --->
						<cfelse>
							<cfset execDates[arrIndex] = {date:execDate, missed:0, error:isError, text:logMsg} />
							<cfset ++arrIndex />
						</cfif>
					</cfif>
				</cfif>
			</cfif>
		</cfloop>
	</cffunction>
	
	
	<cffunction name="getConfigData" output="no" returntype="any" hint="loads data">
		<cfargument name="key" type="string" required="yes" />
		<cfif structKeyExists(variables._configData, key)>
			<cfreturn variables._configData[key] />
		<cfelse>
			<cfreturn "" />
		</cfif>
	</cffunction>
	
	
	<cffunction name="setConfigData" returntype="void" output="no" hint="saves data">
		<cfargument name="key" type="string" required="yes" />
		<cfargument name="data" type="any" required="yes" />
		<cfset variables._configData[key] = data />
		<cfset saveConfig() />
	</cffunction>
	
	
	<cffunction name="removeConfigData" returntype="void" output="no" hint="saves data">
		<cfargument name="key" type="string" required="yes" />
		<cfif structKeyExists(variables._configData, key)>
			<cfset structDelete(variables._configData, key, false) />
			<cfset saveConfig() />
		</cfif>
	</cffunction>
	

	<cffunction name="loadConfig" returntype="void" output="no">
		<cfif fileExists(variables._configDataFile)>
			<cfwddx action="wddx2cfml" input="#fileRead(variables._configDataFile)#" output="variables._configData" />
		<cfelse>
			<cfset variables._configData = {} />
		</cfif>
	</cffunction>

	<cffunction name="saveConfig" returntype="void" output="no">
		<cfset var data = "" />
		<cfwddx action="cfml2wddx" input="#variables._configData#" output="data" />
		<cfset fileWrite(variables._configDataFile, data) />
	</cffunction>


	<cffunction name="unQuote" returntype="string" output="no">
		<cfargument name="str" />
		<cfif arguments.str neq "" and left(arguments.str, 1) eq '"' and right(arguments.str, 1) eq '"'>
			<cfreturn mid(arguments.str, 2, len(arguments.str)-2) />
		</cfif>
		<cfreturn arguments.str />
	</cffunction>


</cfcomponent>
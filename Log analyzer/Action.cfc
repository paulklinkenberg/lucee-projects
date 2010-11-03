<cfcomponent hint="I contain the main functions for the log Analyzer plugin" extends="railo-context.admin.plugin.Plugin">
<!---
/*
 * Action.cfc, enhanced by Paul Klinkenberg
 * Originally written by Gert Franz
 * http://www.railodeveloper.com/post.cfm/railo-admin-log-analyzer
 *
 * Date: 2010-11-03 23:41:00 +0100
 * Revision: 1.0.1
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
--->		
	<cffunction name="init" hint="this function will be called to initalize">
		<cfargument name="lang" type="struct">
		<cfargument name="app" type="struct">
	</cffunction>

	<cffunction name="getLogPath" hint="This function returns the full log file path, and does some security checking">
		<cfargument name="file" type="string" required="false" hint="When given, we check and return the full path to this file. Otherwise, we just return the log files directory" />
		<cfargument name="webID" type="string" required="false" hint="When in server-admin, we must know for which website we are viewing the logs" />
		<cfif request.admintype eq "web">
			<cfset var logDir = expandPath("{railo-web}/logs/") />
		<cfelseif structKeyExists(arguments, "webID") and len(arguments.webID)>
			<cfset var logDir = "" />
		<cfelse>
			<cfthrow message="When not in the web admin, the argument 'webID' is required for function getLogPath()!" />
		</cfif>
		<cfif structKeyExists(arguments, "file") and len(arguments.file)>
			<cfset logDir = rereplace(logDir, "\#server.separator.file#$", "") & server.separator.file & listLast(arguments.file, "/\") />
			<cfif not fileExists(logDir)>
				<cfthrow message="log directory '#logDir#' does not exist!" />
			</cfif>
		</cfif>
		<cfreturn logDir />
	</cffunction>

	<cffunction name="getTextTimeSpan" output="no" hint="creates a text string indicating the timespan between NOW and given datetime">
		<cfargument name="date" type="date" required="yes" />
		<cfargument name="lang" type="struct" required="yes" />
		<cfset var diffSecs = dateDiff('s', arguments.date, now()) />
		<cfif diffSecs lt 60>
			<cfreturn replace(lang.Xsecondsago, '%1', diffSecs) />
		<cfelseif diffSecs lt 3600>
			<cfreturn replace(lang.Xminutesago, '%1', int(diffSecs/60)) />
		<cfelseif diffSecs lt 86400>
			<cfreturn replace(lang.Xhoursago, '%1', int(diffSecs/3600)) />
		<cfelse>
			<cfreturn replace(lang.Xdaysago, '%1', int(diffSecs/86400)) />
		</cfif>
	</cffunction>
	
	<cffunction name="overview" output="yes" hint="list all files from the local web">
		<cfargument name="lang" type="struct">
		<cfargument name="app" type="struct">
		<cfargument name="req" type="struct">
		<cfset arguments.req.logfiles = getLogs()>
	</cffunction>
	
	<cffunction name="getLogs" output="Yes" returntype="query">
		<cfset var qGetLogs = ""/>
		<cfset var tempFilePath = getLogPath() />
		<cfdirectory action="list" listinfo="Name,datelastmodified,size" directory="#tempFilePath#" name="qGetLogs" sort="name asc" />
		<cfreturn qGetLogs />
	</cffunction>	
	
	<cffunction name="list" output="no" hint="analyze the logfile">
		<cfargument name="lang" type="struct">
		<cfargument name="app" type="struct">
		<cfargument name="req" type="struct">
		<cfset var i        = 0>
		<cfset var j        = 0>
		<cfset var bCheck   = true>
		<cfset var stErrors = StructNew()>
		<cfset var sLine    = "">
		<cfset var aDump    = ArrayNew(1)>
		<cfset var iFound   = 0>
		<cfset var sTmp     = "">
		<cfset var sHash    = "">
		<cfset var aLine    = arrayNew(1)>
		<cfset var st       = arrayNew(1)>
		<cfset var tempdate = "" />
		<cfparam name="url.logfile" default="" />
		<cfparam name="form.logfile" default="#url.logfile#" />
		<cfset form.logfile = getLogPath(file=form.logfile) />
		
		<cfparam name="url.sort" default="date" />
		<cfparam name="url.dir" default="desc" />
		
		<cfloop file="#form.logfile#" index="sLine">
			<!--- If line starts with a quote, then it is either an error line, or the end of a dump--->
			<cfif left(trim(sLine), 1) eq '"'>
				<cfset aTmp = ListToArray(sLine, ",", true)>
				<!--- if not a new error --->
				<cfif arrayLen(aTmp) neq 6>
					<cfif isDefined("aDump") and ArrayLen(aDump) gt 1>
						<cfif isStruct(aDump[6])>
				 			<cfset aDump[6].detail &= Chr(13) & Chr(10) & sLine>
						<cfelse>
							<cfset sTmp = aDump[6]>
							<cfset aDump[6]          = structNew()>
							<cfset aDump[6].error    = sTmp>
				 			<cfset aDump[6].detail   = sLine>
							<cfset aDump[6].fileName = "" />
							<cfset aDump[6].lineNo   = "" />
							<cfset sTmp = "" />
						</cfif>
					</cfif>
				<!--- new error --->
				<cfelse>
					<!--- was there a previous error --->
					<cfif ArrayLen(aDump) eq 6>
						<cftry>
							<!--- 	at test_cfm$cf.call(/developing/tools/test.cfm:1):1 --->
							<cfset aLine = REFind("\(([^\(\)]+\.cfm):([0-9]+)\)", aDump[6].detail, 1, true) />
							<cfif aLine.pos[1] gt 0>
								<cfset aDump[6].fileName = Mid(aDump[6].detail, aLine.pos[2], aLine.len[2])>
								<cfset aDump[6].lineNo   = Mid(aDump[6].detail, aLine.pos[3], aLine.len[3])>
							</cfif>
							<cfset sHash = Hash(aDump[6].error)>
							<cfif structKeyExists(stErrors, sHash)>
								<cfset stErrors[sHash].iCount++ />
								<cfset tempdate = parsedatetime(replace(aDump[3] & " " & aDump[4], '"', '', "ALL")) />
								<cfset ArrayAppend(stErrors[sHash].datetime, tempdate) />
								<cfset stErrors[sHash].lastdate = tempdate />
							<cfelse>
								<cfset tempdate = parsedatetime(replace(aDump[3] & " " & aDump[4], '"', '', "ALL")) />
								<cfset stErrors[sHash] = {
									"message":replace(aDump[6].error, '"', "", "ALL"),
									"detail":replace(aDump[6].detail, '"', "", "ALL"),
									"file":aDump[6].fileName,
									"line":aDump[6].lineNo,
									"type":replace(aDump[1], '"', "", "ALL"),
									"thread":replace(aDump[2], '"', "", "ALL"),
									"datetime":[tempdate],
									"iCount":1
									, "firstdate": tempdate
									, "lastdate": tempdate
								} />
							</cfif>
							<cfcatch></cfcatch>
						</cftry>
					</cfif>
					<!--- create new error container --->
					<cfset aDump = aTmp>
					<cfset sTmp = aDump[6]>
					<cfset aDump[6]          = structNew()>
					<cfset aDump[6].error    = sTmp>
		 			<cfset aDump[6].detail   = sLine>
					<cfset aDump[6].fileName = "">
					<cfset aDump[6].lineNo   = 0>
					<cfset sTmp = "">
				</cfif>
			<!--- within a dump output --->
			<cfelse>
				<cfif isDefined("aDump") and ArrayLen(aDump) gt 1>
					<cfif isStruct(aDump[6])>
			 			<cfset aDump[6].detail &= Chr(13) & Chr(10) & sLine>
					<cfelse>
						<cfset sTmp = aDump[6]>
						<cfset aDump[6]          = structNew()>
						<cfset aDump[6].error    = sTmp>
			 			<cfset aDump[6].detail   = sLine>
						<cfset aDump[6].fileName = "">
						<cfset aDump[6].lineNo   = 0>
						<cfset sTmp = "">
					</cfif>
				</cfif>
			</cfif>
		</cfloop>
		<!--- orderby can change--->
		<cfif url.sort eq "msg">
			<cfset st = structSort(stErrors, "textnocase", url.dir, "message")>
		<cfelseif url.sort eq "date">
			<cfset st = structSort(stErrors, "textnocase", url.dir, "lastdate")>
		<cfelse>
			<cfset st = structSort(stErrors, "numeric", url.dir, "icount")>
		</cfif>
		<cfset req.result.sortOrder = st>
		<cfset req.result.stErrors  = stErrors>
	</cffunction>
	
</cfcomponent>
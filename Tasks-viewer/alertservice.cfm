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
<cfsavecontent variable="headText">
	<script type="text/javascript" src="<cfoutput>#arguments.app.currPath#</cfoutput>flot/jquery.min.js"></script>
</cfsavecontent>
<cfhtmlhead text="#headText#" />

<h1>Tasks viewer Alerter Service</h1>

<cfif cgi.REQUEST_METHOD eq "post" and structKeyExists(form, "email")>
	<!--- path wehere the schedule file will be saved --->
	<cfset savePath = rereplace(expandPath("{railo-web}/context/tasks-viewer/"), "[/\\]/", "/") />
	<cfif not refind('[/\\]', right(savePath, 1))>
		<cfset savePath &= "/" />
	</cfif>

	<cfif structKeyExists(form, "disable")>
		<cfif getConfigData('webContextPassword') neq "">
			<cfadmin action="schedule" type="web" password="#getConfigData('webContextPassword')#"
			scheduleAction="delete" task="Tasks-viewer Alerter Service" />
		</cfif>
		<cfset removeConfigData('email') />
		<cfset removeConfigData('serviceInterval') />
		<cfset removeConfigData('errorIgnorePatterns') />
		<cfset removeConfigData('webContextPassword') />
		<cfif directoryExists(savePath)>
			<cftry>
				<cffile action="delete" file="#savePath#alerterservice.cfm" />
				<cfcatch></cfcatch>
			</cftry>
			<cftry>
				<cfdirectory action="delete" directory="#savePath#" recurse="yes" />
				<cfcatch>
					<p class="CheckErr">
						<cfoutput>The directory [#savepath#] could not be deleted!<br /></cfoutput>
						Since it contains a file with your server admin password, you might want to delete it manually.
					</p>
				</cfcatch>
			</cftry>
		</cfif>
		<p class="CheckOK">The alerter service has been disabled.</p>
	<cfelseif isValid('email', form.email)>
		<!--- define and save data --->
		<cfif isNumeric(form.serviceIntervalMultiplier)>
			<cfset serviceInterval = form.serviceIntervalMultiplier * form.serviceIntervalNum />
		<cfelse>
			<cfset serviceInterval = form.serviceIntervalMultiplier />
		</cfif>
		<cfset setConfigData('email', form.email) />
		<cfset setConfigData('serviceInterval', serviceInterval) />
		<cfset setConfigData('webContextPassword', form.webContextPassword) />
		<cfset setConfigData('errorIgnorePatterns', rereplace(trim(form.errorIgnorePatterns), "[\r\n]+", chr(10), 'all')) />

		<!--- save the necessary file to the web context --->
		<cfset URLPath = "http#cgi.SERVER_PORT eq 443 or cgi.https eq 'on' ? 's':''#://#cgi.http_host##getDirectoryFromPath(cgi.script_name)#" />
		<cfif right(URLPath, 1) neq "/">
			<cfset URLPath &= "/" />
		</cfif>
		<cfset scheduleAction = action('alerter') />
		<cfset defaultActionQS = listRest(action('overview'), '?') />
		<cfsavecontent variable="httpCode"><cfoutput>[!--- This file is created by the Railo server admin extension "Tasks Viewer" ---]
[cfsetting requesttimeout="59" /]
[cfhttp url="#URLPath##scheduleAction#" method="post" useragent="CFSCHEDULE"]
	[cfhttpparam type="formfield" name="login_passwordserver" value="#session.passwordserver#" /]
	[cfhttpparam type="formfield" name="lang" value="en" /]
[/cfhttp]
[cfif not structKeyExists(variables, "cfhttp") or not structKeyExists(variables.cfhttp, "filecontent")
or not find('<span class="alerterservicesucceeded"></span>', variables.cfhttp.filecontent)]

	[cfmail to="#form.email#" from="#form.email#" subject="Error occured in Scheduled Tasks alerter service" type="html"]
		Date: ##now()##<br />
		The scheduled task which runs the Scheduled Tasks Alerter Service received an invalid response.<br />
		It called the URL [#URLPath##scheduleAction#], but did not find the expected string "&lt;span class="alerterservicesucceeded"&gt;&lt;/span&gt;" in the response.
		<br /><br />
		Possible reasons / solutions:
		<ul>
			<li>The Railo server admin password has changed. If that's the case, then change the password in the Tasks Viewer plugin as well.</li>
			<li>Your firewall blocked access to the Railo server admin from the local IP</li>
			<li>An error occured in the Alerter Service script. You can probably check this by going to the URL noted before.</li>
			<li>Anything else... take a look at the cfdump underneath, especially the FileContent value. It is plain html, and it might say exactly what the problem is :-)</li>
		</ul>
		<p>This email was sent to you, because you activated the Alerter Service within the Railo extension Tasks Viewer.<br />
			To disable or change this service, go to <a href="http#cgi.SERVER_PORT eq 443 or cgi.https eq 'on' ? 's':''#://#cgi.http_host##cgi.script_name#?#defaultActionQS#">the Tasks Viewer plugin</a> in your Railo server admin.
		</p>
		[cfif structKeyExists(variables, "cfhttp")]
			[cfdump var="##cfhttp##" label="cfhttp returndata" /]
		[cfelse]
			<h2>The variable CFHTTP does not exist.</h2>
			<p>Now it's up to you to find out what the heck went wrong, sorry.</p>
		[/cfif]
	[/cfmail]
	
	[cfthrow message="Incorrect response returned from the Alerter Service!" /]
[/cfif]
OK
		</cfoutput></cfsavecontent>
		<cfset httpCode = replaceList(httpCode, "[,]", "<,>") />
		
		<!--- create the schedule files --->
		<cfif not directoryExists(savePath)>
			<cfdirectory action="create" directory="#savePath#" mode="755" />
		</cfif>
		<cffile action="write" file="#savePath#alerterservice.cfm" output="#httpCode#" mode="644" />

		<!--- add the schedule to the WEB context --->
		<cfset startDate = listFindNoCase('daily,weekly,monthly', serviceInterval) ? dateAdd('d', 1, now()) : now() />
		<cfset serviceURL = "#replaceNoCase(URLPath, '/admin/', '/tasks-viewer/')#alerterservice.cfm" />
		<cfadmin
		action="schedule"
		type="web"
		password="#form.webContextPassword#"
		scheduleAction="update"
		task="Tasks-viewer Alerter Service"
		url="#serviceURL#"
		port="#cgi.SERVER_PORT#"
		requesttimeout="60"
		publish="0"
		resolveurl="0"
		startdate="#dateformat(startDate, 'yyyy-mm-dd')#"
		starttime="00:00:00"
		enddate=""
		endtime=""
		interval="#serviceInterval#"
		file="" />
		<!--- serverpassword="#variables.passwordserver#" --->
		
		<p class="CheckOK">The Alerter Service has been created!
			<br /><br />
			The task will run from
			<cfoutput><a href="#serviceURL#">#serviceURL#</a>.</cfoutput>
			<br />Please make sure that this URL is accessible from your Railo Administrator.
			<br />You might want to click the URL to see if it really works in your setup.
		</p>
	<cfelse>
		<p class="CheckError">You entered an incorrect email address. Please try again.</p>
	</cfif>
</cfif>

<p>The Alerter Service checks all scheduled tasks, to see if there are any missed or failed intervals,
	since the last time it was checked.
	<br />
	If any are found, an email will be sent to the email address you can specify underneath.
</p>

<h2>Setup</h2>
<ol>
	<li>Set your email address where you want to receive the notifications</li>
	<li>Choose the interval for the Alerter Service.<br />
		The code behind the Alerter service can take up quite a lot of resources; it loops through the complete log file (max. 1MB) for every scheduled task.
		<br />Keep this in mind when you choose the interval.
	</li>
	<cfoutput>
		<li>Supply the Railo web administrator password for #cgi.http_host#</li>
	</cfoutput>
	<li>
		Please note: the Alerter Service will store your Railo server administrator password.<br />
		When you change this password, be sure to save the settings underneath again.
		Otherwise, the Service will not work anymore.
	</li>
</ol>
<cfoutput>
	<cfset a = action('alertservice') />
	<form action="#a#" method="post" id="asform">
		<table>	
			<tr>
				<td>Your email address</td>
				<td><input type="text" name="email" value="#getConfigData('email')#" size="50" /></td>
			</tr>
			<tr>
				<td>Web administrator password for #cgi.http_host#</td>
				<td>
					<input type="password" name="webContextPassword" value="#getConfigData('webContextPassword')#" size="25" />
				</td>
			</tr>
			<tr>
				<td>Alerter Service interval</td>
				<td>Every
					<cfset serviceInterval = getConfigData('serviceInterval') />
					<cfif serviceInterval eq "">
						<cfset serviceIntervalNum = 1 />
						<cfset serviceIntervalMultiplier = "daily" />
					<cfelseif not isNumeric(serviceInterval)>
						<cfset serviceIntervalNum = 1 />
						<cfset serviceIntervalMultiplier = serviceInterval />
					<!--- every x hours --->
					<cfelseif serviceInterval mod 3600 eq 0>
						<cfset serviceIntervalNum = serviceInterval/3600 />
						<cfset serviceIntervalMultiplier = 3600 />
					<!--- every x minutes --->
					<cfelse>
						<cfset serviceIntervalNum = serviceInterval/60 />
						<cfset serviceIntervalMultiplier = 60 />
					</cfif>
					<select name="serviceIntervalMultiplier" id="serviceIntervalMultiplier">
						<option value="daily">day</option>
						<option value="weekly"<cfif serviceIntervalMultiplier eq "weekly"> selected</cfif>>week</option>
						<option value="monthly"<cfif serviceIntervalMultiplier eq "monthly"> selected</cfif>>month</option>
						<option value="3600"<cfif serviceIntervalMultiplier eq 3600> selected</cfif>>X hours: </option>
						<option value="60"<cfif serviceIntervalMultiplier eq 60> selected</cfif>>X minutes: </option>
					</select>
					<input type="text" name="serviceIntervalNum" id="serviceIntervalNum" value="#serviceIntervalNum#" size="3" maxlength="2" />
					<script type="text/javascript">
						$(function(){
							$('##serviceIntervalMultiplier').change(function(){
								$('##serviceIntervalNum').css('display', (isNaN($(this).val()) ? 'none':''));
							}).triggerHandler('change');
									
							$('##asform').submit(function(){
								var serviceIntervalNum = $('##serviceIntervalNum:visible');
								if (serviceIntervalNum.length)
								{
									var num = serviceIntervalNum.val();
									if (isNaN(num))
									{
										alert('You must set a numeric interval!');
										return false;
									} else if ($('##serviceIntervalMultiplier').val() == 3600 && num > 23)
									{
										alert('Please enter an hour value less then 24!');
										return false;
									} else if ($('##serviceIntervalMultiplier').val() == 60 && num > 59)
									{
										alert('Please enter a minute value less then 60!');
										return false;
									}
								}
							});
						});
					</script>
				</td>
			</tr>
			<tr>
				<td>Error texts to ignore
					<br /><i>In case you don't want to receive notifications about one or more error texts, add them here. One per line)</i>
				</td>
				<td>
					<textarea name="errorIgnorePatterns" rows="4" cols="50" placeholder="Read timed out">#getConfigData('errorIgnorePatterns')#</textarea>
				</td>
			</tr>
			<tr>
				<td>&nbsp;</td>
				<td><input type="submit" value="Save" class="submit" />
					<cfif getConfigData('email') neq "">
						&nbsp; <input type="submit" name="disable" value="Disable service" class="submit" />
					</cfif>
				</td>
			</tr>
		</table>
	</form>

	<h2>Run manually</h2>
	<p>You can run the Service manually as well.
		<cfif getConfigData('email') neq "">
			<br />Since you already activated the Alerter Service, it will send you an email if any errors are found (like a normal run).
		</cfif>
		<cfset a = action('alerter') />
		<br />Just <a href="#a#">click here</a> to run the Service.
	</p>
	<p>&nbsp;</p>
	<cfset a = action('overview') />
	<form action="#a#" method="post">
		<input class="submit" type="submit" value="Back" name="mainAction"/>
	</form>
</cfoutput>
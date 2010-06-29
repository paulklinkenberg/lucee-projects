<cfoutput><cftry>
	<p><strong>Honeypot Spam Blocker plugin made by Paul Klinkenberg,</strong>
		<a href="http://www.coldfusiondeveloper.nl" target="_blank" title="Links opens in new window/tab"><strong>www.coldfusiondeveloper.nl</strong></a>
		&nbsp; (<a href="http://www.coldfusiondeveloper.nl/post.cfm/honeypot-spam-blocker-mangoblog-plugin" target="_blank" title="Links opens in new window/tab">Check for updates</a>)
	</p>
	
	<cfparam name="url.currentTab" default="settings" />
	<div style="border-bottom:3px solid ##aaa;"><div>
		<a href="#settingsPageUrl#&amp;currentTab=settings" style="text-decoration:none;padding:3px 10px;font-weight:bold; background-color:##aaa;color:<cfif url.currentTab eq 'settings'>##208df6<cfelse>##fff</cfif>;">Settings</a>
		<a href="#settingsPageUrl#&amp;currentTab=logs" style="text-decoration:none;padding:3px 10px;font-weight:bold; background-color:##aaa;color:<cfif url.currentTab eq 'logs'>##208df6<cfelse>##fff</cfif>;">Logs</a>
		<a href="#settingsPageUrl#&amp;currentTab=testit" style="text-decoration:none;padding:3px 10px;font-weight:bold; background-color:##aaa;color:<cfif url.currentTab eq 'testit'>##208df6<cfelse>##fff</cfif>;">Test IP address</a>
	</div></div>
	<br />
	
	<cfif url.currentTab eq "logs">
		<h3>Log files</h3>
		<cfinclude template="inc_logs.cfm" />
	<cfelseif url.currentTab eq "testit">
		<h3>Test your configuration</h3>
		<cfinclude template="inc_testit.cfm" />
	<cfelse>
		<form method="post" action="#cgi.script_name#">
			<p>
				<label for="honeypotKey">Your httpBL honeypot key</label>
				<span class="hint">
					You have to join project Honeypot to  get a key: <a href="http://www.projecthoneypot.org/httpbl.php">www.projecthoneypot.org/httpbl.php</a>
				</span>
				<span class="field"><input type="text" id="honeypotKey" name="honeypotKey" value="#getSetting('honeypotKey')#" size="12" maxlength="20" /></span>
			</p>
			<p>
				<label for="blockText">Text to show when an ip is blocked</label>
				<span class="hint">
					This is the only text that will be shown on screen, afterwards the request will be stopped. (hence "spam blocker")
				</span>
				<span class="field"><textarea name="blockText" id="blockText" cols="50" rows="6">#getSetting('blockText')#</textarea></span>
			</p>
			
			<p>
				<label for="blockText">Blocker / suspicious settings</label>
				<span class="hint">
					When you choose Block, it will be blocked.<br />
					When you choose Suspicious, it will be logged as suspicious (if you enable that log)
				</span>
			</p>
			<cfset labels = listToArray("Search Engine,Suspicious,Harvester,Suspicious &amp; Harvester,Comment Spammer,Suspicious &amp; Comment Spammer,Harvester &amp; Comment Spammer,Suspicious &amp; Harvester &amp; Comment Spammer") />
			<table style="width:auto;">
				<thead>
					<tr>
						<th>Type</th>
						<th>Block + log</th>
						<th>Log as Suspicious</th>
						<th>No action</th>
					</tr>
				</thead>
				<tbody>
					<cfloop from="0" to="7" index="nr">
						<tr>
							<td>#labels[nr+1]#</td>
							<td><input type="radio" name="action_#nr#" value="block"<cfif listFind(getSetting('blockNrs'), nr)> checked="checked"</cfif> /></td>
							<td><input type="radio" name="action_#nr#" value="suspicious"<cfif listFind(getSetting('suspiciousNrs'), nr)> checked="checked"</cfif> /></td>
							<td><input type="radio" name="action_#nr#" value=""<cfif not listFind(getSetting('blockNrs') & "," & getSetting('suspiciousNrs'), nr)> checked="checked"</cfif> /></td>
						</tr>
					</cfloop>
				</tbody>
			</table>
	
			<p>
				<label for="logtypes">Log the following events</label>
				<span class="field">
					<cfloop list="blocked,error,suspicious,lowthreatnumber,threattoomanydaysago" index="eventname">
						<input type="checkbox" name="logtypes" value="#eventname#"<cfif listFind(getSetting('logtypes'), eventname)> checked="checked"</cfif> />#eventname#<br />
					</cfloop>
				</span>
			</p>
			<p>
				<label for="email">Email address <em>(for spam block notifications)</em></label>
				<span class="hint">
					Leave empty if you do not want to receive notifications.<br />
					Multiple email adresses can be entered, separated by <strong>;</strong>.<br />
					The mail will contain: date, ip, honeypot response, cgi and form data
				</span>
				<span class="field"><input type="text" id="email" name="email" value="#getSetting('email')#" size="30" /></span>
			</p>
			
			<p><label>Unblock settings:</label>
				<span class="hint">If a block condition is found, you can still unblock it with the following settings.
					<br />If this occurs, then it will be written to the log 'lowthreatnumber' or 'threattoomanydaysago'.
				</span>
			</p>
				<p style="width:40%;float:left;margin-right:20px;">
					<label for="isNoThreatAfterDayNum">Last activity must be less then or equal to</label>
					<span class="hint">
						Enter a number between 0 and 256.<br />
						256=always block/do not use this exclusion<br />
						0=never block<br />
						20=do not block if last spam/harvesting activity was more then 20 days ago.<br />
						<a href="http://www.projecthoneypot.org/httpbl_api.php" target="_blank" title="Link opens in new window/tab">The specs</a> say:<br />
						<em>This represents the number of days since last activity. 
							In the example above, it has been 3 days since the last time the queried IP address saw activity 
							on the Project Honey Pot network. This value ranges from 0 days to 255 days. This value is useful 
							in helping you assess how "stale" the information provided by http:BL is and therefore the extent 
							to which you should rely on it.
						</em>
					</span>
					<span class="field"><input type="text" id="isNoThreatAfterDayNum" name="isNoThreatAfterDayNum" value="#getSetting('isNoThreatAfterDayNum')#" size="3" maxlength="3" />
						days ago (between 0 and 256)
					</span>
				</p>
				<p style="width:40%;float:left; clear:none">
					<label for="minimumThreatScore">Minimum threat score must be</label>
					<span class="hint">
						Enter a number between 0 and 256.<br />
						256=never block<br />
						0=always block<br />
						20=block if the threat score given by HTTP:BL is 20 or higher.<br />
						<a href="http://www.projecthoneypot.org/httpbl_api.php" target="_blank" title="Link opens in new window/tab">The specs</a> say:<br />
						<em>This represents a threat score for IP. 
							This score is assigned internally by Project Honey Pot based on a number of factors including
							the number of honey pots the IP has been seen visiting, the damage done during those visits
							(email addresses harvested or forms posted to), etc. The range of the score is from 0 to 255,
							where 255 is extremely threatening and 0 indicates no threat score has been assigned. In the 
							example above, the IP queried has a threat score of "5", which is relatively low. While a rough
							and imperfect measure, this value may be useful in helping you assess the threat posed by a visitor to your site.
						</em>
					</span>
					<span class="field"><input type="text" id="minimumThreatScore" name="minimumThreatScore" value="#getSetting('minimumThreatScore')#" size="3" maxlength="3" />
						(between 0 and 256)
					</span>
				</p>
			<br clear="all" />
			<div class="actions">
				<input type="submit" class="primaryAction" value="Submit"/>
				<input type="hidden" value="event" name="action" />
				<input type="hidden" value="showHoneypotSpamBlockerSettings" name="event" />
				<input type="hidden" value="true" name="apply" />
				<input type="hidden" value="HoneypotSpamBlocker" name="selected" />
			</div>
		</form>
	</cfif>
		
	<cfcatch><h3>Oops, an error?!</h3><cfdump var="#cfcatch#" /></cfcatch>
</cftry></cfoutput>
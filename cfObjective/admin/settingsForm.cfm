<cfoutput>

<form method="post" action="#cgi.script_name#">

	<fieldset>
	
		<legend>General Settings</legend>
		
		<p>
			<label for="cfObjectiveTitle">cf.Objective() Title:</label>
			<span class="hint">Set the title of the pod</span>
			<span class="field">
				<input type="text" id="cfObjectiveTitle" name="cfObjectiveTitle" value="#getSetting("cfObjectiveTitle")#" size="20"/>
			</span>
		</p>
		
		<p>
			<label for="cfObjectiveShowTitle">Show cf.Objective() Title:</label>
			<span class="hint">Enable/Disable the pod title</span>
			<span class="field">
				<input type="checkbox" id="cfObjectiveShowTitle" name="cfObjectiveShowTitle" value="true" <cfif getSetting("cfObjectiveShowTitle")>checked="checked"</cfif> />
			</span>
		</p>
		
		<p>
			<label for="cfObjectiveIconSet">Icon set:</label>
			<span class="hint">Select which badge to use</span>
			<!--- <img src="#request.blogManager.getBlog().getUrl()#assets/plugins/cfObjective/images/badges/Attendee.png" width="100" height="50" /> --->
			<span class="field">
				<select id="cfObjectiveBadge" name="cfObjectiveBadge" onchange="updateBadgeExample()">
					<option value="Attendee" <cfif getSetting("cfObjectiveBadge") EQ "Attendee">selected="selected"</cfif>>Attendee</option>
					<option value="Speaker" <cfif getSetting("cfObjectiveBadge") EQ "Speaker">selected="selected"</cfif>>Speaker</option>
					<option value="Sponsor" <cfif getSetting("cfObjectiveBadge") EQ "Sponsor">selected="selected"</cfif>>Sponsor</option>
				</select>
			</span>
		</p>
		
		<p>
			<label for="cfObjectiveIconSize">Badge width: (actual width: 125px)</label>
			<span class="hint">Width of the badge in px, height is calcutated based on the width.</span>
			<span class="field">
				<input type="text" id="cfObjectiveBadgeWidth" name="cfObjectiveBadgeWidth" value="#getSetting("cfObjectiveBadgeWidth")#" size="5"/>px
			</span>
		</p>
		<p><label for="darkOrLight">Badge color scheme</label>
			<span class="field">
				<select name="darkOrLight" id="darkOrLight" onchange="updateBadgeExample()">
					<option value="">Dark</option>
					<option value="_w"<cfif getSetting("darkOrLight") eq "_w"> selected="selected"</cfif>>Light</option>
				</select>
			</span>
		</p>
		<p><strong>Example badge:</strong><br />
			<img id="exampleimg" src="" width="125" height="125" />
		</p>
		<script type="text/javascript">
			function updateBadgeExample()
			{
				var t = document.getElementById('cfObjectiveBadge');
				var d = document.getElementById('darkOrLight');
				var imgurl = '/assets/plugins/cfObjective/images/badges/CFObjective11_' + t.options[t.selectedIndex].value + '_125x125' + d.options[d.selectedIndex].value + '.gif';
				document.getElementById('exampleimg').src = imgurl;
			}
			updateBadgeExample();
		</script>
	</fieldset>
		
	<p class="actions">
		<input type="submit" class="primaryAction" value="Submit"/>
		<input type="hidden" value="event" name="action" />
		<input type="hidden" value="showcfObjectiveSettings" name="event" />
		<input type="hidden" value="true" name="apply" />
		<input type="hidden" value="cfObjective" name="selected" />
	</p>

</form>

</cfoutput>
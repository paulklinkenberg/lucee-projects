<cfoutput>
	<form method="post" action="#cgi.script_name#">
		<p>
			<label for="adsenseCode">Adsense code</label>
			<span class="hint">This code is shown when you create or manage your adsense adverts at http://adsense.google.com/</span>
			<span class="field"><textarea name="adsenseCode" id="adsenseCode" cols="70" rows="10" style="width:600px;">#getSetting('adsenseCode')#</textarea></span>
		</p>
		<p>
			<label for="showOnActionsList">Show where</label>
			<span class="hint">Mango blog has a series of pre-defined points where the ads can be displayed.<br />
			You can also add extra places inside your templates by adding a custom event: <a href="http://www.coldfusiondeveloper.nl/post.cfm/mangoblog-plugin-adsense-ads-on-your-blog">read more</a></span>
			<span class="field"><select name="showOnActionsList" id="showOnActionsList" size="3" multiple="multiple">
				<option value="">- choose</option>
				<option value="beforePostContentEnd"<cfif listFindNoCase(getSetting('showOnActionsList'), "beforePostContentEnd")> selected="selected"</cfif>>After a full blog post (post.cfm page)</option>
				<option value="showAdsense"<cfif listFindNoCase(getSetting('showOnActionsList'), "showAdsense")> selected="selected"</cfif>>When the custom event 'showAdsense' is called</option>
			</select></span>
		</p>
		<p>
			<label for="showOnIterationNrs">On which iterations should the advertisements be shown?</label>
			<span class="hint">If you want to show ads on your index page, but only after the 1st, 3rd, and 5th item, then insert "1,3,5" here.<br />
			You can leave this field empty if you want to show ads on every call.</span>
			<span class="field"><input type="text" id="showOnIterationNrs" name="showOnIterationNrs" value="#getSetting('showOnIterationNrs')#" size="12" />
				<em>(numeric list, or leave empty)</em>
			</span>
		</p>
		
		<div class="actions">
			<input type="submit" class="primaryAction" value="Submit"/>
			<input type="hidden" value="event" name="action" />
			<input type="hidden" value="showAdsenseSettings" name="event" />
			<input type="hidden" value="true" name="apply" />
			<input type="hidden" value="adsense" name="selected" />
		</div>
	</form>
</cfoutput>
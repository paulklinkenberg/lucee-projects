<p>Fill in an ip address, click the Test button.<br />
	A new window will then be opened, which will act as if the given ip address is yours.<br />
	You can safely close the window afterwards.
</p>
<form method="post" action="/index.cfm" target="_blank">
	<input type="hidden" name="testHoneypotSpamBlocker" value="1" />
	<p>
		<label for="testip">Use this IP address</label>
		<input type="text" name="testip" value="" maxlength="15" size="12" />
	</p>
	<div class="actions">
		<input type="submit" class="primaryAction" value="Test" />
	</div>
</form>

<form action="index.cfm" method="post" id="loginfrm">
	<h3>Please enter your Smartermail login details first</h3>
	<label for="password">Server URL</label>
	<input type="text" name="serverURL" id="serverURL" value="http://" size="45" /> <em>(http://www.yourmailserver.com)</em>
	<br />
	<label for="username">User name</label>
	<input type="text" name="username" id="username" size="20" />
	&nbsp;
	<label for="password">Password</label>
	<input type="password" name="password" id="password" size="20" />
	<br />
	<label for="debugMode">&nbsp;</label>
	<input type="checkbox" name="debugMode" id="debugMode" value="1" /> <em style="white-space:nowrap">Show extra debug data</em>
	<br />
	<input type="submit" value="Login" /><br />
</form>

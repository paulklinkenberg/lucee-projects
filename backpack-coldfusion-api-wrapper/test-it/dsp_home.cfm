<h2>Coldfusion backpack api wrapper - example files</h2>

<p>
	Please choose one of the files on the side navigation.
</p>

<!--- <comment author="P. Klinkenberg">
	If an error occurs while retrieving the navigation project list,
	we add an error to the home page of the examples app.
</comment> --->
<cfif structKeyExists(variables, "includeSettingsWarning_bool")>
	<p class="error">
		While trying to retrieve your project list, an error occured.<br />
		This could happen if the settings in the file Application.cfm are incorrect.
	</p>
	<p class="error">
		For these example pages to work, you need an account (free!) for the BackPack application.
		It can be found at <a href="http://www.backpackit.com/" target="_blank">www.backpackit.com</a>.
	</p>
</cfif>
<cfapplication name="backPack" />

<!--- English (UK)  /  Dutch (Standard)  / 
	check available locales with: <cfoutput>#replace(server.ColdFusion.SupportedLocales, ',', '<br />', 'ALL')#</cfoutput>
--->
<cfset setLocale("Dutch (Standard)") />

<cfsetting requesttimeout="100" />

<cfif not structKeyExists(application, "backPack") or structKeyExists(url, "flush") or application.backpack.useDevelopmentMode>

	<cfset application.backPack = structNew() />
	
	<!--- <comment author="P. Klinkenberg"> Are you developing right now? If yes, components will not be cached, and debug output will be displayed </comment> --->
	<cfset application.backPack.useDevelopmentMode = true />
	
	<!--- <comment author="P. Klinkenberg"> the backPack API key can be found in the Account page, at the end of the document (30/1/2007) </comment> --->
	<cfset application.backPack.token = "812d406cfa908cb542d86c112357f3aa81d35333" />
	
	<!--- <comment author="P. Klinkenberg"> hostUrl: the root url to your backPack account, minus 'http://' and '/'  (i.e. myPage.backpackit.com) </comment> --->
	<cfset application.backPack.hostUrl = "usertest.backpackit.com" />
	
	<!--- <comment author="P. Klinkenberg"> Optional settings, only needed to retrieve images and attachments </comment> --->
	<cfset application.backPack.loginName = "testuser" />
	<cfset application.backPack.loginPassword = "usertest" />
	
	<!--- <comment author="P. Klinkenberg"> directory path where files and images can be stored </comment> --->
	<cfset application.backPack.fileDirectory = getDirectoryFromPath(getCurrentTemplatePath()) & "files/" />
	
	<!--- <comment author="P. Klinkenberg"> if we should use https; only available for premium accounts </comment> --->
	<cfset application.backPack.useSSL = false />
	
	<!--- <comment author="P. Klinkenberg"> the max. time (in seconds) a http request to backpackit.com may take. (This is the timeout attr. of cfhttp)  </comment> --->
	<cfset application.backpack.httpCallTimeout = 30 />
	
	<cfset application.backPack_obj = createObject("component", "nl.ongevraagdadvies.apis.backpack.Backpack") />

	<cfset application.textileConverter_obj = createObject("component", "nl.ongevraagdadvies.String.Textile") />
	
	<!--- <comment author="P. Klinkenberg"> container which will hold all request and response xml for debug output </comment> --->	
	<cfif application.backpack.useDevelopmentMode>
		<cfset request.cfhttpRequests_arr = arrayNew(1) />
	</cfif>
</cfif>
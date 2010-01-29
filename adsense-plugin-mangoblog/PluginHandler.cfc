<cfcomponent name="viewCount" extends="BasePlugin">


	<cfset variables.name = "adsense" />
	<cfset variables.package = "nl/coldfusiondeveloper/mango/plugins/adsense" />


<!--- :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: --->
	<cffunction name="init" access="public" output="false" returntype="any">
		<cfargument name="mainManager" type="any" required="true" />
		<cfargument name="preferences" type="any" required="true" />
		<cfset var blogid = arguments.mainManager.getBlog().getId() />
		<cfset var path = blogid & "/" & variables.package />
		<cfset variables.preferencesManager = arguments.preferences />
		<cfset variables.manager = arguments.mainManager />

		<cfset initSettings(adsenseCode="", showOnIterationNrs="", showOnActionsList="showAdsense,beforePostContentEnd") />
				
		<cfreturn this/>
	</cffunction>
	

<!--- :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: --->	
	<cffunction name="setup" hint="This is run when a plugin is activated" access="public" output="false" returntype="any">
		<cfreturn "Adsense plugin activated. <br />You can now <a href='generic_settings.cfm?event=showAdsenseSettings&amp;owner=adsense&amp;selected=showAdsenseSettings'>Configure it</a>" />
	</cffunction>
	
<!--- :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: --->	
	<cffunction name="processEvent" hint="Synchronous event handling" access="public" output="false" returntype="any">
		<cfargument name="event" type="any" required="true" />
		<cfset var outputData = "" />
		<cfset var context =  "" />
		<cfset var requestData = "" />
		<cfset var postID = "" />
		<cfset var err_str = "" />
		<cfset var sql_str = "" />
		<cfset var viewCounts_qry = "" />
		<cfset var key = "" />
		<cfset var data = "" />
		<cfset var link = "" />
		<cfset var page = "" />
		<cfset var eventName = arguments.event.getName() />
		
		<cfif listFindNoCase(getSetting('showOnActionsList'), eventName)>
			<!--- this is a template event, there should be a context and a request --->
			<cfset outputData = arguments.event.getOutputData() />
			<cfset context = arguments.event.getContextData() />
			<cfset requestData = arguments.event.getRequestData() />
			<cfparam name="requestData.adSenseIterationNr" default="0" />
			<cfset requestData.adSenseIterationNr=requestData.adSenseIterationNr+1 />
			<cfif len(getSetting('adsensecode')) and (
				eventName eq "beforePostContentEnd"
				or not len(getSetting('showOnIterationNrs'))
				or listFind(getSetting('showOnIterationNrs'), requestData.adSenseIterationNr)
			)>
				<cfset arguments.event.setOutputData(outputData & "<div class='adsensecode'>" & getSetting('adsenseCode') & "</div>") />
			</cfif>
		<!--- admin dashboard event --->
		<cfelseif eventName eq "dashboardPod">
			<cfif variables.manager.isCurrentUserLoggedIn()>
				<cfif not len(variables.adsenseCode)>
					<!--- add a pod warning about missin account number --->
				
					<cfsavecontent variable="outputData"><cfoutput><p class="error">You have not entered your Google Adsense code yet, so no advertisements can be shown.</p>
						<p><a href='generic_settings.cfm?event=showAdsenseSettings&amp;owner=adsense&amp;selected=showAdsenseSettings'>Enter the adsense code now</a></p>
					</cfoutput></cfsavecontent>
					
					<cfset data = structnew() />
					<cfset data.title = "Google Adsense" />
					<cfset data.content = outputData />
					<cfset arguments.event.addPod(data)>
				</cfif>
			</cfif>
		<!--- admin nav event --->
		<cfelseif eventName eq "settingsNav">
			<cfset link = structnew() />
			<cfset link.owner = "adsense">
			<cfset link.page = "settings" />
			<cfset link.title = "Google Adsense" />
			<cfset link.eventName = "showAdsenseSettings" />
			
			<cfset arguments.event.addLink(link) />
		<!--- admin event --->
		<cfelseif eventName eq "showAdsenseSettings">
			<cfif variables.manager.isCurrentUserLoggedIn()>
				<cfset data = arguments.event.getData() />
				<cfif structkeyexists(data.externaldata,"apply")>
					<cfif refind("[^0-9,]", data.externaldata.showOnIterationNrs)>
						<cfset err_str = '<p class="error">The (optional) list of iteration numbers is invalid!<br />Only numbers separated by commas are allowed.</p>' />
					<cfelse>
						<cfparam name="data.externaldata.showOnActionsList" default="" />
						<cfset setSettings(showOnIterationNrs=data.externaldata.showOnIterationNrs, adsenseCode=data.externaldata.adsenseCode, showOnActionsList=data.externaldata.showOnActionsList) />
						<cfset persistSettings() />
														
						<cfset data.message.setstatus("success") />
						<cfset data.message.setType("settings") />
						<cfset data.message.settext("Google Adsense settings have been saved") />
					</cfif>
				</cfif>
				
				<cfsavecontent variable="page">
					<cfoutput>#err_str#</cfoutput>
					<cfinclude template="admin/settingsForm.cfm">
				</cfsavecontent>
					
				<!--- change message --->
				<cfset data.message.setTitle("Google Adsense settings") />
				<cfset data.message.setData(page) />
			</cfif>
		</cfif>
		
		<cfreturn arguments.event />
	</cffunction>
		
</cfcomponent>
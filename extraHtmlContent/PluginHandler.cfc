<cfcomponent name="extrahtmlcontent" extends="BasePlugin">


	<cfset variables.name = "extrahtmlcontent" />
	<cfset variables.package = "nl/coldfusiondeveloper/mango/plugins/extrahtmlcontent" />


<!--- :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: --->
	<cffunction name="init" access="public" output="false" returntype="any">
		<cfargument name="mainManager" type="any" required="true" />
		<cfargument name="preferences" type="any" required="true" />
		<cfset var blogid = arguments.mainManager.getBlog().getId() />
		<cfset var path = blogid & "/" & variables.package />
		<cfset variables.preferencesManager = arguments.preferences />
		<cfset variables.manager = arguments.mainManager />

		<cfset initSettings(headhtml="", bodyhtml="") />
		
		<cfreturn this/>
	</cffunction>
	

<!--- :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: --->	
	<cffunction name="setup" hint="This is run when a plugin is activated" access="public" output="false" returntype="any">
		<cfreturn "extraHtmlContent plugin activated. <br />You can now <a href='generic_settings.cfm?event=showextrahtmlcontentSettings&amp;owner=extrahtmlcontent&amp;selected=showextrahtmlcontentSettings'>Configure it</a>" />
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
		
		<cfif eventname eq "beforeHtmlHeadEnd">
			<!--- this is a template event, there should be a context and a request --->
			<cfset outputData = arguments.event.getOutputData() />
			<cfset context = arguments.event.getContextData() />
			<cfset arguments.event.setOutputData(outputData & getSetting('headhtml')) />
		<cfelseif eventname eq "beforeHtmlBodyEnd">
			<!--- this is a template event, there should be a context and a request --->
			<cfset outputData = arguments.event.getOutputData() />
			<cfset context = arguments.event.getContextData() />
			<cfset arguments.event.setOutputData(outputData & getSetting('bodyhtml')) />
		<!--- admin nav event --->
		<cfelseif eventName eq "settingsNav">
			<cfset link = structnew() />
			<cfset link.owner = "extrahtmlcontent">
			<cfset link.page = "settings" />
			<cfset link.title = "Extra HTML Content" />
			<cfset link.eventName = "showextrahtmlcontentSettings" />
			
			<cfset arguments.event.addLink(link) />
		<!--- admin event --->
		<cfelseif eventName eq "showextrahtmlcontentSettings">
			<cfif variables.manager.isCurrentUserLoggedIn()>
				<cfset data = arguments.event.getData() />
				<cfif structkeyexists(data.externaldata,"apply")>
					<cfset setSettings(headhtml=data.externaldata.headhtml, bodyhtml=data.externaldata.bodyhtml) />
					<cfset persistSettings() />
														
					<cfset data.message.setstatus("success") />
					<cfset data.message.setType("settings") />
					<cfset data.message.settext("Extra HTML Content settings have been saved") />
				</cfif>
				
				<cfsavecontent variable="page">
					<cfinclude template="admin/settingsForm.cfm" />
				</cfsavecontent>
					
				<!--- change message --->
				<cfset data.message.setTitle("Extra HTML Content settings") />
				<cfset data.message.setData(page) />
			</cfif>
		</cfif>
		
		<cfreturn arguments.event />
	</cffunction>
		
</cfcomponent>
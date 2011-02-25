<cfcomponent extends="BasePlugin"> 
 
    <cffunction name="init" access="public" output="false" returntype="any"> 
        <cfargument name="mainManager" type="any" required="true" /> 
        <cfargument name="preferences" type="any" required="true" /> 
         
        <cfset setManager(arguments.mainManager) /> 
        <cfset setPreferencesManager(arguments.preferences) /> 
        <cfset setPackage("com/railodeveloper/mango/plugins/cfObjective") /> 
         
        <!--- Default preferences --->
		<cfset variables.defaults = structnew() />
        <cfset variables.defaults.cfObjectiveTitle = "cf.Objective() 2011" />
		<cfset variables.defaults.cfObjectiveShowTitle = true />
		<cfset variables.defaults.cfObjectiveBadge = "Attendee" />
		<cfset variables.defaults.cfObjectiveBadgeWidth = "125" />
		<cfset variables.defaults.darkOrLight = "" />
		
		<cfset initSettings(argumentCollection = variables.defaults) />
             
        <cfreturn this/> 
    </cffunction> 
 
    <cffunction name="setup" hint="This is run when a plugin is activated" access="public" output="false" returntype="any"> 
        <cfreturn "Plugin activated." /> 
    </cffunction> 
     
    <cffunction name="unsetup" hint="This is run when a plugin is de-activated" access="public" output="false" returntype="any"> 
        <cfreturn "Plugin deactivated." /> 
    </cffunction> 
 
    <cffunction name="handleEvent" hint="Asynchronous event handling" access="public" output="false" returntype="any"> 
        <cfargument name="event" type="any" required="true" />         
        <cfreturn /> 
    </cffunction> 
 
	<cffunction name="processEvent" hint="Synchronous event handling" access="public" output="false" returntype="any">
		<cfargument name="event" type="any" required="true" />

			<cfset var cfObjectiveContainer = "" />
			<cfset var cfObjectiveJS = "" />
			<cfset var data =  "" />
			<cfset var eventName = arguments.event.name />
			<cfset var pod = "" />
			<cfset var link = "" />
			<cfset var page = "" />
			
			<cfswitch expression="#eventName#">
				<cfcase value="getPods">
				
					<cfif event.allowedPodIds EQ "*" OR listfindnocase(event.allowedPodIds, "cfObjective")>
						
						<cfsavecontent variable="cfObjectiveContainer">
							<cfoutput><div id="cfobjectivebadge"><a href="http://www.cfobjective.com/" target="_blank"><!---
								---><img src="#request.blogManager.getBlog().getUrl()#assets/plugins/cfObjective/images/badges/CFObjective11_#lCase(getSetting("cfObjectiveBadge"))#_125x125#getSetting("darkOrLight")#.gif" width="#getSetting("cfObjectiveBadgeWidth")#" height="#getSetting("cfObjectiveBadgeWidth")#" style="border:0;width:#getSetting("cfObjectiveBadgeWidth")#px;height:#getSetting("cfObjectiveBadgeWidth")#px;" alt="cf.Objective() #lCase(getSetting("cfObjectiveBadge"))# badge" title="#htmleditformat(getSetting("cfObjectiveTitle"))#" /></a></div>
							</cfoutput>
						</cfsavecontent>
						
						<cfset pod = structnew() />
						<cfif getSetting("cfObjectiveShowTitle")>
							<cfset pod.title = getSetting("cfObjectiveTitle") />
						<cfelse>
							<cfset pod.title = "" />
						</cfif>
						<cfset pod.content = cfObjectiveContainer />
						<cfset pod.id = "cfObjective" />
						<cfset arguments.event.addPod(pod)>
					</cfif>
				</cfcase>

				<cfcase value="beforeHtmlHeadEnd">
					<cfsavecontent variable="cfObjectiveJS"></cfsavecontent>
					
					<cfset data = arguments.event.outputData />
					<cfset data = data & cfObjectiveJS />
					<cfset arguments.event.outputData = data />
				</cfcase>

				<cfcase value="settingsNav">
					<cfset link = structnew() />
					<cfset link.owner = "cfObjective">
					<cfset link.page = "settings" />
					<cfset link.title = "cfObjective badges" />
					<cfset link.eventName = "showcfObjectiveSettings" />
					<cfset arguments.event.addLink(link)>
				</cfcase>
				
				<cfcase value="showcfObjectiveSettings">
					<cfif getManager().isCurrentUserLoggedIn()>
						<cfset data = arguments.event.data />				

						<cfif structkeyexists(data.externaldata,"apply")>
						
							<cfparam name="data.externaldata.cfObjectiveTitle" default="0" />
							<cfparam name="data.externaldata.cfObjectiveShowTitle" default="0" />
							<cfparam name="data.externaldata.cfObjectiveBadge" default="0" />
							<cfparam name="data.externaldata.cfObjectiveBadgeWidth" default="0" />
							
							<cfset LOCAL.newSettings = StructNew() />
							<cfloop collection="#variables.defaults#" item="LOCAL.key">
								<cfset LOCAL.newSettings[LOCAL.key] = data.externaldata[LOCAL.key] />
							</cfloop>
							
							<cfset setSettings(argumentCollection = LOCAL.newSettings) />
							
							<cfset persistSettings() />
							<cfset data.message.setstatus("success") />
							<cfset data.message.setType("settings") />
							<cfset data.message.settext("cfObjective Settings Updated") />
						</cfif>
					</cfif>
						
					<cfsavecontent variable="page">
						<cfinclude template="admin/settingsForm.cfm">
					</cfsavecontent>
						
					<cfset data.message.setTitle("cfObjective Settings") />
					<cfset data.message.setData(page) />
				</cfcase>
				
				<cfcase value="getPodsList">
					<cfset pod = structnew() />
					<cfset pod.title = "cfObjective badges" />
					<cfset pod.id = "cfObjective" />
					<cfset arguments.event.addPod(pod)>
				</cfcase>
			</cfswitch>
		
		<cfreturn arguments.event />
	</cffunction>
 
</cfcomponent>
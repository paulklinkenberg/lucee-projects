<cfcomponent name="HoneypotSpamBlocker" extends="BasePlugin">


	<cfset variables.name = "honeypotSpamBlocker" />
	<cfset variables.package = "nl/coldfusiondeveloper/mango/plugins/honeypotSpamBlocker" />
	<cfset variables.oHoneypot = createObject("component", "projecthoneypot") />
	
<!--- :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: --->
	<cffunction name="init" access="public" output="false" returntype="any">
		<cfargument name="mainManager" type="any" required="true" />
		<cfargument name="preferences" type="any" required="true" />
		<cfset var blogid = arguments.mainManager.getBlog().getId() />
		<cfset var path = blogid & "/" & variables.package />
		<cfset variables.preferencesManager = arguments.preferences />
		<cfset variables.manager = arguments.mainManager />
		
		<cfset initSettings(
			honeypotKey				=variables.oHoneypot.honeypotKey
			, blockText				=variables.oHoneypot.sBlockText
			, blockNrs				=variables.oHoneypot.lsAbsoluteThreatNrs
			, suspiciousNrs			=variables.oHoneypot.lsPossibleThreatNrs
			, email					=variables.oHoneypot.sNoticesMailAddress
			, logtypes				=variables.oHoneypot.sLogTypes
			, isNoThreatAfterDayNum	=variables.oHoneypot.nIsNoThreatAfterDayNum
			, minimumThreatScore	=variables.oHoneypot.nMinimumThreatScore) />
		
		<!--- set any previously changed setting into the honeypot object --->
		<cfset _updateHoneypotCFCSettings() />
		
		<cfreturn this/>
	</cffunction>
	

<!--- :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: --->	
	<cffunction name="setup" hint="This is run when a plugin is activated" access="public" output="false" returntype="any">
		<cfset super.setup(argumentCollection=arguments) />
		<cfreturn "honeypot Spam Blocker plugin activated. <br />You can now <a href='generic_settings.cfm?event=showHoneypotSpamBlockerSettings&amp;owner=HoneypotSpamBlocker&amp;selected=showHoneypotSpamBlockerSettings'>Configure it</a>" />
	</cffunction>
	
	
<!--- :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: --->	
	<cffunction name="processEvent" hint="Synchronous event handling" access="public" output="false" returntype="any">
		<cfargument name="event" type="any" required="true" />
		<cfset var outputData = "" />
		<cfset var context =  "" />
		<cfset var postID = "" />
		<cfset var err_str = "" />
		<cfset var key = "" />
		<cfset var data = "" />
		<cfset var link = "" />
		<cfset var page = "" />
		<cfset var logFileWebPath = "" />
		<cfset var qFiles = "" />
		<cfset var eventName = arguments.event.getName() />
		<cfset var currentEmail = "" />
		<cfset var settingsPageUrl = "#cgi.SCRIPT_NAME#?event=showHoneypotSpamBlockerSettings&amp;owner=HoneypotSpamBlocker&amp;selected=showHoneypotSpamBlockerSettings" />
		

		<cfif refindNoCase("^before.*template", eventName)>
			<cfif structKeyExists(form, "testHoneypotSpamBlocker") and structKeyExists(form, "testIP")>
				<cfif not isValidIPAddress(form.testIP)>
					<cfoutput><h1>HoneypotSpamBlocker: the IP address '#htmleditformat(form.testIP)#' is not valid!</h1></cfoutput>
					<cfabort />
				</cfif>
				<cfset variables.oHoneypot.blockThreatUser(testIP=form.testIP) />
			<cfelse>
				<cfset variables.oHoneypot.blockThreatUser() />
			</cfif>
		<!--- admin nav event --->
		<cfelseif eventName eq "settingsNav">
			<cfset link = structnew() />
			<cfset link.owner = "HoneypotSpamBlocker">
			<cfset link.page = "settings" />
			<cfset link.title = "HoneypotSpamBlocker" />
			<cfset link.eventName = "showHoneypotSpamBlockerSettings" />
			
			<cfset arguments.event.addLink(link) />
		<!--- admin event --->
		<cfelseif eventName eq "showHoneypotSpamBlockerSettings">
			<cfif variables.manager.isCurrentUserLoggedIn()>
				<cfset data = arguments.event.getData() />				
				<cfif structkeyexists(data.externaldata,"apply")>
					<!--- params --->
					<cfparam name="data.externaldata.logtypes" default="" />
					<cfparam name="data.externaldata.blockNrs" default="" />
					<cfparam name="data.externaldata.suspiciousNrs" default="" />
					<cfset data.externaldata.email = replace(data.externaldata.email, ' ', '', 'all') />
					<!--- set the form fields 'action_#nr#' into blockNrs/suspiciousNrs. --->
					<cfloop from="0" to="7" index="currentNr">
						<cfif structKeyExists(data.externaldata, "action_#currentNr#")>
							<cfif data.externaldata["action_#currentNr#"] eq "block">
								<cfset data.externaldata.blockNrs = listAppend(data.externaldata.blockNrs, currentNr) />
							<cfelseif data.externaldata["action_#currentNr#"] eq "suspicious">
								<cfset data.externaldata.suspiciousNrs = listAppend(data.externaldata.suspiciousNrs, currentNr) />
							</cfif>
						</cfif>
					</cfloop>
					<!--- check valid email(s) --->
					<cfloop list="#data.externaldata.email#" index="currentEmail" delimiters=";">
						<cfif not isValid('email', currentEmail)>
							<cfset data.message.setstatus("error") />
							<cfset data.message.setType("settings") />
							<cfset data.message.settext("The email address '#currentEmail#' is invalid. Please correct this.") />
							<cfbreak />
						</cfif>
					</cfloop>
					<!--- check valid numbers --->
					<cfloop list="isNoThreatAfterDayNum,minimumThreatScore" index="currentEmail">
						<cfif not isValid('integer', data.externaldata[currentEmail]) or data.externaldata[currentEmail] lt 0>
							<cfset data.message.setstatus("error") />
							<cfset data.message.setType("settings") />
							<cfset data.message.settext("The field '#currentEmail#' must contain a number! Please correct this.") />
							<cfbreak />
						</cfif>
					</cfloop>

					<cfif data.message.getstatus() neq "error">
						<cfset setSettings(honeypotKey=data.externaldata.honeypotKey
							, blockText=data.externaldata.blockText
							, blockNrs=data.externaldata.blockNrs
							, suspiciousNrs=data.externaldata.suspiciousNrs
							, email=data.externaldata.email
							, logtypes=data.externaldata.logtypes
							, isNoThreatAfterDayNum=data.externaldata.isNoThreatAfterDayNum
							, minimumThreatScore=data.externaldata.minimumThreatScore) />

						<cfset persistSettings() />
						
						<!--- update the values in the projecthoneypot cfc --->
						<cfset _updateHoneypotCFCSettings() />
						
						<cfset data.message.setstatus("success") />
						<cfset data.message.setType("settings") />
						<cfset data.message.settext("HoneypotSpamBlocker settings have been saved") />
					</cfif>
				</cfif>
				
				<cfsavecontent variable="page">
					<cfinclude template="admin/settingsForm.cfm" />
				</cfsavecontent>
					
				<!--- change message --->
				<cfset data.message.setTitle("HoneypotSpamBlocker settings") />
				<cfset data.message.setData(page) />
			</cfif>
		</cfif>
		
		<cfreturn arguments.event />
	</cffunction>

	
	<cffunction name="_updateHoneypotCFCSettings" access="private" returntype="void">
		<cfset variables.oHoneypot.honeypotKey = getSetting('honeypotKey') />
		<cfset variables.oHoneypot.sBlockText = getSetting('blockText') />
		<cfset variables.oHoneypot.lsAbsoluteThreatNrs = getSetting('blockNrs') />
		<cfset variables.oHoneypot.lsPossibleThreatNrs = getSetting('suspiciousNrs') />
		<cfset variables.oHoneypot.sNoticesMailAddress = getSetting('email') />
		<cfset variables.oHoneypot.sLogTypes = getSetting('logtypes') />
		<cfset variables.oHoneypot.nIsNoThreatAfterDayNum = getSetting('isNoThreatAfterDayNum') />
		<cfset variables.oHoneypot.nMinimumThreatScore = getSetting('minimumThreatScore') />
	</cffunction>
	
	
	<cffunction name="isValidIPAddress" returntype="boolean" access="public">
		<cfargument name="IP" type="string" required="yes" />
		<cfset var currentNr = -1 />
		<cfif not refind("^([0-9]{1,3}\.){3}[0-9]{1,3}$", arguments.IP)>
			<cfreturn false />
		</cfif>
		<cfif reFind("(^0\.|\.0$)", arguments.IP)>
			<cfreturn false />
		</cfif>
		<cfloop list="#arguments.IP#" delimiters="." index="currentNr">
			<cfif currentNr gt 255>
				<cfreturn false />
			</cfif>
		</cfloop>
		<cfreturn true />
	</cffunction>
	
</cfcomponent>
<cfcomponent extends="BasePlugin">

	<cffunction name="init" access="public" output="false" returntype="any">
		<cfargument name="mainManager" type="any" required="true" />
		<cfargument name="preferences" type="any" required="true" />
		
		<cfset setManager(arguments.mainManager) />
		<cfset setPreferencesManager(arguments.preferences) />
		<cfset setPackage("nl/coldfusiondeveloper/mango/plugins/cfmlincluder") />
		
		<cfset variables.customFieldKey = "cfmlincluder" />
		<cfset variables.pluginName = "CFML includer" />

		<cfreturn this/>
	</cffunction>

	<cffunction name="setup" hint="This is run when a plugin is activated" access="public" output="false" returntype="any">
		<cfreturn "#variables.pluginName# plugin activated"/>
	</cffunction>
	<cffunction name="unsetup" hint="This is run when a plugin is de-activated" access="public" output="false" returntype="any">
		<cfreturn "#variables.pluginName# plugin de-activated"/>
	</cffunction>

	<cffunction name="handleEvent" hint="Asynchronous event handling" access="public" output="false" returntype="any">
		<cfargument name="event" type="any" required="true" />
		<!--- no asynchronous events for this plugin --->
		<cfreturn />
	</cffunction>

	<cffunction name="processEvent" hint="Synchronous event handling" access="public" output="false" returntype="any">
		<cfargument name="event" type="any" required="true" />
		
		<cfset var formfieldHtml = ""/>
		<cfset var local = StructNew() />
		
		<cftry>
		<cfswitch expression="#arguments.event.name#">
			
			<!--- show the field before the end of the page / post --->
			<cfcase value="beforeAdminPostFormEnd,beforeAdminPageFormEnd">
				<cfset local.entryId = arguments.event.item.id />
				<cfset local.includeFile = "" />
				<cfif arguments.event.item.customFieldExists(variables.customFieldKey)>
					<cfset local.includeFile = arguments.event.item.getCustomField(variables.customFieldKey).value />
				<!--- this is true if the event 'beforeAdminPostFormDisplay' was called earlier on --->
				<cfelseif structKeyExists(request, "cfmlincluderRawData")>
					<cfset local.includeFile = request.cfmlincluderRawData />
				</cfif>
				<cfsavecontent variable="formfieldHtml"><cfoutput>
					<fieldset id="customFieldsFieldset" class="">
						<legend>&lt;cfinclude&gt;</legend>
						<div>
							<label for="cfmlincluder">Pad naar include</label>
							<span class="field"><input type="text" name="#variables.customFieldKey#" id="cfmlincluder" value="#local.includeFile#" size="40" /></span>
						</div>
					</fieldset>
				</cfoutput></cfsavecontent>
				<cfset arguments.event.setOutputData(arguments.event.getOutputData() & formfieldHtml) />
			</cfcase>
			
			
			<cfcase value="beforeAdminPostFormDisplay,beforeAdminPageFormDisplay">
				<!--- use this event to hide related entries data from the user in the "custom fields" section... no reason for its raw data to show up ---> 
				<cfif arguments.event.item.customFieldExists(variables.customFieldKey)>
					<cfset request.cfmlincluderRawData = arguments.event.item.getCustomField(variables.customFieldKey).value />
					<cfset arguments.event.item.removeCustomField(variables.customFieldKey) />
				</cfif>
			</cfcase>
			
			<!--- include the requested file --->
			<cfcase value="beforePostContentEnd,beforePageContentEnd">
				<cfif arguments.event.name eq "beforePageContentEnd">
					<cfset local.data = arguments.event.contextData.currentPage />
				<cfelse>
					<cfset local.data = arguments.event.contextData.currentPost />
				</cfif>
				<cfif local.data.customFieldExists(variables.customFieldKey)>
					<cfset local.includefile = local.data.getCustomField(variables.customFieldKey).value />
					<cfif len(local.includefile) or 1>
						<cfsavecontent variable="local.includeOutput"><cfoutput>
							<cfinclude template="#local.includefile#" />
						</cfoutput></cfsavecontent>
						<cfset arguments.event.setOutputData(arguments.event.getOutputData() & local.includeOutput) />
					</cfif>
				</cfif>
			</cfcase>
			
			<!--- save the custom field --->
			<cfcase value="afterPostAdd,afterPostUpdate,afterPageAdd,afterPageUpdate">
				<cfif find('afterPost', arguments.event.name)>
					<cfset local.data = arguments.event.data.post />
				<cfelse>
					<cfset local.data = arguments.event.data.page />
				</cfif>
				<cfset local.data.setCustomField(variables.customFieldKey, "cfmlincluder", arguments.event.data.rawdata[variables.customFieldKey]) />
				<cfif find('afterPost', arguments.event.name)>
					<cfset getManager().getAdministrator().editPost(
						arguments.event.data.post.getId(),
						arguments.event.data.post.getTitle(),
						arguments.event.data.post.getContent(),
						arguments.event.data.post.getExcerpt(),
						arguments.event.data.post.getStatus() eq "published",
						arguments.event.data.post.getCommentsAllowed(),
						arguments.event.data.post.getPostedOn(),
						"",<!--- user, isn't used --->
						local.data.customFields
					)/>
				<cfelse>
					<cfset getManager().getAdministrator().editPage(
						arguments.event.data.page.getId(),
						arguments.event.data.page.getTitle(),
						arguments.event.data.page.getContent(),
						arguments.event.data.page.getExcerpt(),
						arguments.event.data.page.getStatus() eq "published",
						arguments.event.data.page.getParentpageID(),
						arguments.event.data.page.getTemplate(),
						arguments.event.data.page.getSortOrder(),
						arguments.event.data.page.getCommentsAllowed(),
						"",<!--- user, isn't used --->
						local.data.customFields
					)/>
				</cfif>
			</cfcase>
			
		</cfswitch>
		<cfcatch>
			<cfsavecontent variable="local.err"><cfoutput><cfdump var="#cfcatch#" /></cfoutput></cfsavecontent>
			<cfset arguments.event.setOutputData(arguments.event.getOutputData() & local.err) />
		</cfcatch>
		</cftry>
		
		<cfreturn arguments.event />
	</cffunction>

</cfcomponent>
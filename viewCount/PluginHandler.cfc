<cfcomponent name="viewCount" extends="BasePlugin">


	<cfset variables.name = "viewCount" />
	<cfset variables.package = "nl/coldfusiondeveloper/mango/plugins/viewCount" />

<!--- :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: --->
	<cffunction name="init" access="public" output="false" returntype="any">
		<cfargument name="mainManager" type="any" required="true" />
		<cfargument name="preferences" type="any" required="true" />
		<cfset var blogid = arguments.mainManager.getBlog().getId() />
		<cfset var path = blogid & "/" & variables.package />
		<cfset variables.preferencesManager = arguments.preferences />
		<cfset variables.manager = arguments.mainManager />
		
		<cfset initSettings(maxHours=2, excludeSearchEngines=1, showPublicly=1, appearance="View count: $viewcount$") />

		<!--- get database related specs and handler --->
		<cfset variables.objQryAdapter = variables.manager.getQueryInterface() />
		<!--- get db-type, but remove any version nrs etc.--->
		<cfset variables.dbType = rereplaceNoCase(variables.objQryAdapter.getDBType(), ".*(m[ys]sql).*", "\1") />
		<cfset variables.tablePrefix = variables.objQryAdapter.getTablePrefix() />
		
		<cfreturn this/>
	</cffunction>
	

<!--- :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: --->	
	<cffunction name="setup" hint="This is run when a plugin is activated" access="public" output="false" returntype="any">
		<cfset super.setup(argumentCollection=arguments) />
		<!--- check supported database types --->
		<cfif not listFindNoCase("mysql,mssql", variables.dbType)>
			<cfthrow message="Only mySQL and MSSQL databases are currently supported for plugin ViewCount!" />
		</cfif>
		<cfset _createViewCountsTable() />
		<cfreturn "ViewCount plugin activated. <br />You can now <a href='generic_settings.cfm?event=showViewCountSettings&amp;owner=ViewCount&amp;selected=showViewCountSettings'>Configure it</a>" />
	</cffunction>
	
	
<!--- :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: --->	
	<cffunction name="processEvent" hint="Synchronous event handling" access="public" output="false" returntype="any">
		<cfargument name="event" type="any" required="true" />
		<cfset var outputData = "" />
		<cfset var context =  "" />
		<cfset var postID = "" />
		<cfset var err_str = "" />
		<cfset var sql_str = "" />
		<cfset var viewCounts_qry = "" />
		<cfset var key = "" />
		<cfset var data = "" />
		<cfset var link = "" />
		<cfset var page = "" />
		<cfset var eventName = arguments.event.getName() />
		<cfset var javascript_str = "" />
		
		<cfif eventName eq "showViewCount">
			<!--- this is a template event, there should be a context and a request --->
			<cfset outputData = arguments.event.getOutputData() />
			<cfset context = arguments.event.getContextData() />
			<cfif structkeyexists(context,"currentPost")>
				<cfset postID = context.currentPost.getID() />
				<cfset arguments.event.setOutputData(outputData & getViewCountHTML(postID)) />
			</cfif>
		<cfelseif eventName eq "updateViewCount">
			<!--- this is a template event, there should be a context and a request --->
			<cfset context = arguments.event.getContextData() />
			<cfif structkeyexists(context,"currentPost")>
				<cfset postID = context.currentPost.getID() />
				<cfset _updateViewCount(postID) />
			</cfif>
		<cfelseif eventName eq "beforePostContentEnd">
			<!--- this is a template event, there should be a context and a request --->
			<cfset context = arguments.event.getContextData() />
			<cfif structkeyexists(context,"currentPost")>
				<cfset postID = context.currentPost.getID() />
				<cfset _updateViewCount(postID) />
				<cfif getSetting('showPublicly') eq 1>
					<cfset outputData = arguments.event.getOutputData() />
					<cfset arguments.event.setOutputData(outputData & " " & getViewCountHTML(postID)) />
				</cfif>
			</cfif>
		<!--- admin nav event --->
		<cfelseif eventName eq "settingsNav">
			<cfset link = structnew() />
			<cfset link.owner = "ViewCount">
			<cfset link.page = "settings" />
			<cfset link.title = "ViewCount" />
			<cfset link.eventName = "showViewCountSettings" />
			
			<cfset arguments.event.addLink(link) />
		<!--- show the viewCounts in the admin posts overview --->
		<cfelseif listFindNoCase("postsNav,customPostsNav", eventName)>
			<cfif cgi.SCRIPT_NAME eq "/admin/posts.cfm">
				<!--- get all viewcounts --->
				<cfset viewCounts_qry = getViewCounts() />
				
				<!--- create javascript to inject the counts into the existing table --->
				<cfsavecontent variable="javascript_str"><cfoutput>
					<script type="text/javascript">
						$(function(){
							var counts = {0:0<cfloop query="viewCounts_qry">, '#id#':#viewCount#</cfloop>};
							var $postsTRs = $('##content tr');
							$postsTRs.each(function()
							{
								var $a = $('a:first', this);
								if ($a.length)
								{
									var id = $a.get(0).href.replace(/^.*?[\?;&]id=([0-9A-F-]+).*$/i, "$1");
									var td = "<td style=\"text-align:right\">" + counts[id] + "</td>";
								} else
									var td = "<th>Views</th>";
								$(this).append($(td).addClass($a.parent().attr('class')));
							});
						});
					</script>
				</cfoutput></cfsavecontent>
				<!--- add javascript to the page --->
				<cfhtmlhead text="#javascript_str#" />
			</cfif>
		<!--- admin event --->
		<cfelseif eventName eq "showViewCountSettings">
			<cfif variables.manager.isCurrentUserLoggedIn()>
				<cfset data = arguments.event.getData() />				
				<cfif structkeyexists(data.externaldata,"apply")>
					<cfif not isNumeric(data.externaldata.maxHours) or data.externaldata.maxHours lt 0 or int(data.externaldata.maxHours) neq data.externaldata.maxHours>
						<cfset err_str = '<p class="error">The number of hours is invalid!</p>' />
					<cfelse>
						<cfif not findNoCase("$viewcount$", data.externaldata.appearance)>
							<cfset data.externaldata.appearance = data.externaldata.appearance & " $viewcount$" />
						</cfif>
						<cfset setSettings(maxHours=data.externaldata.maxHours
							, excludeSearchEngines=data.externaldata.excludeSearchEngines
							, showPublicly=data.externaldata.showPublicly
							, appearance=data.externaldata.appearance) />
						<cfset persistSettings() />
																	
						<cfset data.message.setstatus("success") />
						<cfset data.message.setType("settings") />
						<cfset data.message.settext("ViewCount settings have been saved") />
					</cfif>
				<cfelseif structKeyExists(data.externaldata, "saveViewCounts")>
					<cfloop collection="#data.externaldata#" item="key">
						<cfif findNoCase('viewCount_', key) eq 1 and (
							not isNumeric(data.externaldata[key])
							or int(data.externaldata[key]) neq data.externaldata[key]
							or data.externaldata[key] lt 0
						)>
							<cfset data.message.setstatus("error") />
							<cfset data.message.setType("settings") />
							<cfset data.message.settext("All viewCounts must be integers, 0 or higher (#data.externaldata[key]#)") />
							<cfbreak />
						</cfif>
					</cfloop>
					<cfif data.message.getstatus() neq "error">
						<cfloop collection="#data.externaldata#" item="key">
							<cfif findNoCase('viewCount_', key) eq 1>
								<cfset _setViewCount(postID=listgetat(key, 2, '_'), viewCount=data.externaldata[key]) />
							</cfif>
						</cfloop>
						<!--- now re-init the viewcount-cache --->
						<cfset _clearViewCountCache() />
						<cfset data.message.setstatus("success") />
						<cfset data.message.setType("settings") />
						<cfset data.message.settext("All viewCounts are updated!") />
					</cfif>
				</cfif>
				
				<cfsavecontent variable="page">
					<cfinclude template="admin/settingsForm.cfm" />
				</cfsavecontent>
					
				<!--- change message --->
				<cfset data.message.setTitle("ViewCount settings") />
				<cfset data.message.setData(page) />
			</cfif>
		</cfif>
		
		<cfreturn arguments.event />
	</cffunction>

	
	<cffunction name="getViewCountHTML" access="public" returntype="string" hint="Returns the html indicating the viewCount for a post">
		<cfargument name="postID" type="string" required="yes" />
		<cfreturn replaceNoCase(getSetting('appearance'), "$viewcount$", getViewCount(arguments.postID), "all") />
	</cffunction>
	
	
	<cffunction name="getViewCount" access="public" hint="Retrieves the view count for a given post" returntype="numeric">
		<cfargument name="postID" type="string" required="yes" />
		<cfset var viewCountCache_struct = _getViewCountCache() />
		<cfif structKeyExists(viewCountCache_struct, arguments.postID)>
			<cfreturn viewCountCache_struct[arguments.postID] />
		</cfif>
		<cfreturn 0 />
	</cffunction>
	
	
	<cffunction name="_updateViewCount" access="private" hint="Updates the view count for a given post, when certain criteria are met" returntype="void">
		<cfargument name="postID" type="string" required="yes" />
		<cfset var sql_str = "" />
		
		<cfif (getSetting('maxHours') gt 0 and _viewAlreadyLogged(postID=arguments.postID))
		or (getSetting('excludeSearchEngines') and _isSearchEngine())>
			<!--- do nothing; already counted for this IP in the last x hours / it is a searchengine --->
		<cfelse>
			<!--- database driver for mysql on Railo (Adobe CF as well?) can be set to only accept one statement per call.
			So just to be sure, call it in 2 times. --->
			<cfif variables.dbType eq "mySQL">
				<cfset variables.objQryAdapter.makeQuery(query="INSERT IGNORE INTO #variables.tablePrefix#viewCounts (postID, viewCount)
					VALUES ('#arguments.postID#', 0)", returnResult=false) />
			</cfif>
			<cfsavecontent variable="sql_str"><cfoutput>
				<cfif variables.dbType eq "MSSQL">
					IF NOT EXISTS (
						SELECT *
						FROM #variables.tablePrefix#viewCounts
						WHERE postID = '#arguments.postID#'
					) BEGIN
						INSERT INTO #variables.tablePrefix#viewCounts (postID, viewCount)
						VALUES ('#arguments.postID#', 0)
					END;
				</cfif>
				UPDATE #variables.tablePrefix#viewCounts
				SET viewCount = viewCount+1
				WHERE postID = '#arguments.postID#'
			</cfoutput></cfsavecontent>
			<cfset variables.objQryAdapter.makeQuery(query=sql_str, returnResult=false) />
			
			<cfset _updateViewCountCache(postID=arguments.postID, increaseBy=1) />
		</cfif>
	</cffunction>
	
	
	<cffunction name="_setViewCount" access="private" returntype="void"
	hint="Sets a given view count for a given post. Is used by the admin page, where one can change the viewCounts manually ('pimp my viewCount' ;-)">
		<cfargument name="postID" type="string" required="yes" />
		<cfargument name="viewCount" type="numeric" required="yes" />
		
		<cfset variables.objQryAdapter.makeQuery(query="DELETE
			FROM #variables.tablePrefix#viewCounts
			WHERE postID = '#arguments.postID#'", returnResult=false) />
		<cfset variables.objQryAdapter.makeQuery(query="INSERT INTO #variables.tablePrefix#viewCounts (postID, viewCount)
			VALUES ('#arguments.postID#', #arguments.viewCount#)", returnResult=false) />
	</cffunction>
	
	
	<cffunction name="_createViewCountsTable" access="private" hint="Creates the database table where results will be stored" returntype="void">
		<cfset var sql_str = "" />
		
		<cfsavecontent variable="sql_str"><cfoutput>
			<cfif variables.dbType eq "MSSQL">
				IF OBJECT_ID('#variables.tablePrefix#viewCounts', 'U') IS NULL
			</cfif>CREATE TABLE <cfif variables.dbType eq "mySQL">IF NOT EXISTS </cfif>#variables.tablePrefix#viewCounts(
				viewCount int NOT NULL,
				postID varchar(35) UNIQUE NOT NULL
			)
		</cfoutput></cfsavecontent>
		<cfset variables.objQryAdapter.makeQuery(query=sql_str, returnResult=false) />
	</cffunction>
	
	
	<cffunction name="_clearViewCountCache" access="private" hint="Erases the stored viewCount cache" returntype="void">
		<cflock name="writeIntoViewCountCache" timeout="3" throwontimeout="yes">
			<cfset structDelete(application, "_viewCountCache", false) />
		</cflock>
	</cffunction>

	
	
	<cffunction name="_updateViewCountCache" access="private" returntype="void"
	hint="Updates the local cache of viewCount numbers (does not alter the database; that must be done with _setViewCountCache/_updateViewCountCache)">
		<cfargument name="postID" type="string" required="yes" />
		<cfargument name="increaseBy" type="numeric" required="yes" hint="Can be any number, usually '1' though." />
		<cfset var viewCounts_struct = "" />
		
		<cflock name="writeIntoViewCountCache" timeout="1" throwontimeout="no">
			<cfset viewCounts_struct = _getViewCountCache() />
			<cfif not structKeyExists(viewCounts_struct, arguments.postID)>
				<cftry>
					<cfset structInsert(viewCounts_struct, arguments.postID, 0, false) />
					<cfcatch><!--- in 0.00000001 seconds, another thread just wrote the key for us. That's okay. ---></cfcatch>
				</cftry>
			</cfif>
			<cfset structUpdate(viewCounts_struct, arguments.postID, viewCounts_struct[arguments.postID]+arguments.increaseBy) />
		</cflock>
	</cffunction>
		

	<cffunction name="_getViewCountCache" access="private" hint="Retrieves all current view counts in a structure" returntype="struct">
		<cfset var sql_str = "" />
		<cfset var sel_qry = "" />
		<cfset var viewCounts_struct = structNew() />
		<!--- if the cache does not exist (anymore), create it --->
		<cfif not structKeyExists(variables, "_viewCountCache")>
			<cfsavecontent variable="sql_str"><cfoutput>
				SELECT postID, viewCount
				FROM #variables.tablePrefix#viewCounts
			</cfoutput></cfsavecontent>
			<cfset sel_qry = variables.objQryAdapter.makeQuery(query=sql_str, returnResult=true) />

			<cfloop query="sel_qry">
				<cfset structInsert(viewCounts_struct, sel_qry.postID, sel_qry.viewCount) />
			</cfloop>
			<cfset structInsert(variables, "_viewCountCache", viewCounts_struct, true) />
		</cfif>
		<cfreturn variables._viewCountCache />
	</cffunction>
		

	<cffunction name="_isSearchEngine" access="private" returntype="boolean" hint="Checks the http_user_agent to see if the current visitor is a spider/bot/serach engine">
		<cfif reFindNoCase("(googlebot|yahoo\.com|wise-guys|baidu\.com|gigabot|ia_archiver|linkwalker|Ask Jeeves|Indy Library|ilse\.nl|grub\.org|voila\.com|girafabot|msnbot|qweerybot|Scooter|Surveybot|Turnitinbot|botje\.nl|ZoekyBot|looksmart\.net|walhello)", cgi.http_user_agent)>
			<cfreturn true />
		</cfif>
		<cfreturn false />
	</cffunction>
	

	<cffunction name="_viewAlreadyLogged" access="private" returntype="boolean"
	hint="Checks to see if the current IP already viewed this page in the last x hours">
		<cfargument name="postID" type="string" required="yes" />
		<cfargument name="ip" type="string" required="yes" default="#cgi.remote_addr#" />
		<cfset var lastView = "" />
		
		<cfif not structKeyExists(application, "_viewCountIPs")>
			<cfset structInsert(application, "_viewCountIPs", structNew(), true) />
		</cfif>
		<cfif not structKeyExists(application._viewCountIPs, arguments.postID)>
			<cfset structInsert(application._viewCountIPs, arguments.postID, structNew(), true) />
		</cfif>
		<!--- if the IP was logged for this post --->
		<cfif structKeyExists(application._viewCountIPs[arguments.postID], arguments.ip)>
			<!--- check if the last view was more then maxHours ago. (if so, the datetime will be overwritten further on) --->
			<cfset lastView = application._viewCountIPs[arguments.postID][arguments.ip] />
			<cfif dateDiff('n', lastView, now()) lt getSetting('maxHours')*60>
				<cfreturn true />
			</cfif>
		</cfif>
		<!--- remember this view including the view time --->
		<cfset structInsert(application._viewCountIPs[arguments.postID], arguments.ip, now(), true) />
		<cfreturn false />
	</cffunction>
	
	
	<cffunction name="getViewCounts" access="public" returntype="query" hint="I return a query with all viewcounts, optionally sorted">
		<cfargument name="order" type="string" required="no" default="page" />
		<cfargument name="dir" type="string" required="no" default="ASC" hint="ASC or DESC" />
		<cfset var sql_str = "" />
		
		<cfsavecontent variable="sql_str"><cfoutput>
			SELECT <cfif findNoCase('mssql', variables.dbType)>ISNULL<cfelse>IFNULL</cfif>(#variables.tablePrefix#viewCounts.viewCount,0) AS viewCount
				, #variables.tablePrefix#entry.id, #variables.tablePrefix#entry.title, #variables.tablePrefix#entry.name, #variables.tablePrefix#post.posted_on
			FROM #variables.tablePrefix#entry
			INNER JOIN #variables.tablePrefix#post ON #variables.tablePrefix#post.id = #variables.tablePrefix#entry.id
			LEFT OUTER JOIN #variables.tablePrefix#viewCounts ON #variables.tablePrefix#viewCounts.postID = #variables.tablePrefix#entry.id
			ORDER BY <cfif arguments.order eq 'page'>#variables.tablePrefix#entry.title<cfelseif arguments.order eq 'date'>#variables.tablePrefix#post.posted_on<cfelse>#variables.tablePrefix#viewCounts.viewCount</cfif> <cfif listFindNoCase('asc,desc', arguments.dir)>#arguments.dir#</cfif>
		</cfoutput></cfsavecontent>
		<cfreturn variables.objQryAdapter.makeQuery(query=sql_str, returnResult=true) />
	</cffunction>
	
</cfcomponent>
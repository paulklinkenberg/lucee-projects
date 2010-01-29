<cfcomponent output="no" displayname="nl.ongevraagdadvies.apis.backpack.Backpack" hint="Coldfusion wrapper for backPack API">
<!---
* Copyright (c) 2009 Paul Klinkenberg
* Blog: http://www.coldfusiondeveloper.nl/post.cfm/backpack-api-wrapper-for-coldfusion
* Licensed under the GPL license v 3.0, see http://www.gnu.org/copyleft/gpl.html
*
* Date: 2009-06-13
--->
	
	<cfset variables._textileConverter_obj = createObject("component", "nl.ongevraagdadvies.String.Textile") />

	<!--- <comment author="P. Klinkenberg">  Struct with all the URL's we can call to.
	Everything within curly brackets will be replaced with the variable (with the same name) from the arguments scope.
	i.e. If you request page 'showPage', you must include the argument 'id' to the called function.
	</comment> --->
	<cfset variables._requestURL_struct = structNew() />
	<cfset structInsert(variables._requestURL_struct, "listAllPages", "/ws/pages/all") />
	<cfset structInsert(variables._requestURL_struct, "createPage", "/ws/pages/new") />
	<cfset structInsert(variables._requestURL_struct, "searchPages", "/ws/pages/search") />
	<cfset structInsert(variables._requestURL_struct, "showPage", "/ws/page/{id}") />
	<cfset structInsert(variables._requestURL_struct, "destroyPage", "/ws/page/{id}/destroy") />
	<cfset structInsert(variables._requestURL_struct, "updatePage", "/ws/page/{id}/update") />
	<cfset structInsert(variables._requestURL_struct, "updateTitle", "/ws/page/{id}/update_title") />
	<cfset structInsert(variables._requestURL_struct, "duplicatePage", "/ws/page/{id}/duplicate") />
	<cfset structInsert(variables._requestURL_struct, "sharePage", "/ws/page/{id}/share") />
	<cfset structInsert(variables._requestURL_struct, "unshareFriendPage", "/ws/page/{id}/unshare_friend_page") />
	<cfset structInsert(variables._requestURL_struct, "emailPage", "/ws/page/{id}/email") />
	<!--- <comment author="P. Klinkenberg"> list items	</comment> --->
		<!--- this one is really bad, because it only returns the items in the first list --->
	<cfset structInsert(variables._requestURL_struct, "showPageItems", "/ws/page/{id}/items/list") />
	<cfset structInsert(variables._requestURL_struct, "getPageLists", "/ws/page/{id}/lists/list") />
	<cfset structInsert(variables._requestURL_struct, "exportAll", "/ws/account/export") />

	
	<!--- <comment author="P. Klinkenberg"> doing some guessing about where to find attachment data </comment> --->
	<cfset structInsert(variables._requestURL_struct, "getAttachmentList", "/ws/page/{id}/attachments/list") />

	<cfset structInsert(variables._requestURL_struct, "getFile", "/assets/{page_id}/{fileName}") />
	
	
	<cffunction name="_structCopy" access="private" returntype="struct" output="false" description="structCopy(args) is broken in scorpio Beta 2, so this is a workaround">
		<cfargument name="strct" type="struct" required="yes" />
		<cfset var copied_struct = structNew() />
		<cfset var key = "" />
		<cfloop collection="#arguments.strct#" item="key">
			<cfset structInsert(copied_struct, key, arguments.strct[key]) />
		</cfloop>
		<cfreturn copied_struct />
	</cffunction>
	
	
	<cffunction name="splitIDforAssetsPath" access="public" returntype="string" output="false">
		<cfargument name="id" type="string" required="yes" hint="
This is the page ID which has the attachment.
This id is split into 2 parts in the download url, which is what this function is about.

Sample url to a download: http://yourpage.backpackit.com/assets/123/789/wordDoc.doc
The page-id which holds the attachment would be '123789' then.

If your page-id is '12389' (5 digits), the url would be: http://yourpage.backpackit.com/assets/12/389/wordDoc.doc
(according to 1 hopefully reliable post in the forums: http://www.backpackit.com/forum/viewtopic.php?id=1400)
		" />
		<cfreturn rereplace(arguments.id, "^(.*?)(.{3})$", "\1/\2") />
	</cffunction>
	
	
<!--- <comment author="P. Klinkenberg"> all page functions </comment> --->
	<cffunction name="convertPageToQuery" access="public" returntype="query" output="false">
		<cfargument name="pageXML" type="xml" required="yes" hint="The page xml" />
		<cfset var page_qry = queryNew("id,title,email_address") />
		<cfset page_qry = _convertXmlToQuery(pageXML.response.page, page_qry, false) />
		<cfreturn page_qry />
	</cffunction>


	<cffunction name="getPageItemsAsQuery" access="public" returntype="query" output="false">
		<cfargument name="pageXML" type="xml" required="yes" hint="The page xml" />
		<cfargument name="orderBy" type="string" required="no" hint="Order the retrieved records by this column(s)" />
		<cfset var items_qry = queryNew("item,completed,id,list_id,list_name") />
		<cfset var arrIndex_num = 0 />
		
		<!--- <comment author="Paul Klinkenberg"> since there are more lists, always group them by list_name first </comment> --->
		<cfset arguments.orderBy = listPrepend(arguments.orderBy, "list_name") />
		
		<!--- <comment author="Paul Klinkenberg"> if we have a list </comment> --->
		<cfif structKeyExists(pageXML.response.page, "lists") and structKeyExists(pageXML.response.page.lists, "list")>
			<!--- <comment author="Paul Klinkenberg"> loop through all lists </comment> --->
			<cfloop from="1" to="#arrayLen(pageXML.response.page.lists.list)#" index="arrIndex_num">
				<!--- <comment author="P. Klinkenberg"> first put the items in a query </comment> --->
				<cfset items_qry = _convertXmlToQuery(pageXML.response.page.lists.list[arrIndex_num].items, items_qry) />
				<!--- <comment author="P. Klinkenberg"> add the list names to the query </comment> --->
				<cfloop query="items_qry">
					<cfif items_qry.list_id eq pageXML.response.page.lists.list[arrIndex_num].xmlAttributes.id>
						<cfset querySetCell(items_qry, "list_name", pageXML.response.page.lists.list[arrIndex_num].xmlAttributes.name, items_qry.currentrow) />
					</cfif>
				</cfloop>
<!--- 				<cfquery name="items_qry" dbtype="query">
					UPDATE items_qry
					SET list_name = '#pageXML.response.page.lists.list[arrIndex_num].xmlAttributes.name#'
					WHERE list_ID = '#pageXML.response.page.lists.list[arrIndex_num].xmlAttributes.id#'
				</cfquery>
 --->			</cfloop>
		</cfif>

		<!--- <comment author="P. Klinkenberg"> optionally (re)order the query </comment> --->
		<cfif structKeyExists(arguments, "orderBy")>
			<cfset items_qry = _orderQuery(items_qry, arguments.orderBy) />
		</cfif>
		<cfreturn items_qry />
	</cffunction>


	<cffunction name="getAllPages" access="public" returntype="query" output="false">
		<cfargument name="orderBy" type="string" required="no" hint="Order the retrieved records by this column(s)" />
		<cfset var pages_qry = listAllPages(returnType="query") />
		<!--- <comment author="P. Klinkenberg"> optionally (re)order the query </comment> --->
		<cfif structKeyExists(arguments, "orderBy")>
			<cfset pages_qry = _orderQuery(pages_qry, arguments.orderBy) />
		</cfif>
		<cfreturn pages_qry />
	</cffunction>


	<cffunction name="listAllPages" access="public" returntype="any" output="false">
		<cfargument name="returnType" type="string" required="no" default="xml" hint="Returns the retrieved pages as one of the following: query, xml" />
		<cfset var response_xml = _doRequest(url="listAllPages") />
		<cfset var pages_qry = queryNew("scope,title,id") />
		
		<cfif returnType eq "query">
			<cfreturn _convertXmlToQuery(response_xml.response.pages, pages_qry) />
		<cfelse>
			<cfreturn response_xml />
		</cfif>
	</cffunction>


	<cffunction name="showPage" access="public" returntype="any" output="false">
		<cfargument name="id" type="string" required="yes" hint="ID of the item to retrieve" />
		<cfset var response_xml = _doRequest(url="showPage", id=arguments.id) />
		<cfreturn response_xml />
	</cffunction>


	<cffunction name="showPageItems" access="public" returntype="any" output="false">
		<cfargument name="id" type="string" required="yes" hint="ID of the item to retrieve" />
		<cfset var response_xml = _doRequest(url="showPageItems", id=arguments.id) />
		<cfreturn response_xml />
	</cffunction>


	<cffunction name="getPageLists" access="public" returntype="xml" output="false">
		<cfargument name="id" type="string" required="yes" hint="ID of the item to retrieve" />
		<cfset var response_xml = _doRequest(url="getPageLists", id=arguments.id) />
		<cfreturn response_xml />
	</cffunction>


	<cffunction name="createPage" access="public" returntype="xml" output="false">
		<cfargument name="title" type="string" required="yes" />
		<cfset var response_xml = "" />
		<!--- <comment author="P. Klinkenberg"> create a struct which will be the xml tag 'page' (with children) </comment> --->
		<cfset var xmlArgument_struct = structNew() />
		<cfset xmlArgument_struct['title'] = arguments.title />
		<cfset response_xml = _doRequest(url="createPage", page=xmlArgument_struct) />
		<cfreturn response_xml />
	</cffunction>


	<cffunction name="destroyPage" access="public" returntype="xml" output="false">
		<cfargument name="id" type="string" required="yes" hint="ID of the item to delete" />
		<cfset var response_xml = _doRequest(url="destroyPage", id=arguments.id) />
		<cfreturn response_xml />
	</cffunction>


	<cffunction name="updateTitle" access="public" returntype="xml" output="false">
		<cfargument name="id" type="string" required="yes" hint="ID of the item to update" />
		<cfargument name="title" type="string" required="yes" />
		<cfset var response_xml = "" />
		<cfset var xmlArgument_struct = structNew() />
		<cfset xmlArgument_struct['title'] = arguments.title />
		<cfset response_xml = _doRequest(url="updateTitle", id=arguments.id, page=xmlArgument_struct) />
		<cfreturn response_xml />
	</cffunction>


	<cffunction name="updatePage" access="public" returntype="xml" output="false">
		<cfargument name="id" type="string" required="yes" hint="ID of the item to update" />
		<cfargument name="title" type="string" required="yes" />
		<cfset var response_xml = "" />
		<cfset var xmlArgument_struct = structNew() />
		<cfset xmlArgument_struct['title'] = arguments.title />
		<cfset response_xml = _doRequest(url="updateTitle", id=arguments.id, page=xmlArgument_struct) />
		<cfreturn response_xml />
	</cffunction>


	<cffunction name="duplicatePage" access="public" returntype="xml" output="false">
		<cfargument name="id" type="string" required="yes" hint="ID of the item to duplicate" />
		<cfset var response_xml = _doRequest(url="duplicatePage", id=arguments.id) />
		<cfreturn response_xml />
	</cffunction>


	<cffunction name="exportAll" access="public" returntype="xml" output="false">
		<cfset var response_xml = _doRequest(url="exportAll") />
		<cfreturn response_xml />
	</cffunction>


	<cffunction name="getAttachmentList" access="public" returntype="xml" output="false">
		<cfargument name="id" type="string" required="yes" hint="ID of the item to retrieve" />
		<cfset var response_xml = _doRequest(url="getAttachmentList", id=arguments.id) />
		<cfreturn response_xml />
	</cffunction>


	<cffunction name="getFile" access="public" returntype="any" output="false">
		<cfargument name="page_id" type="string" required="yes" hint="ID of the page" />
		<cfargument name="fileName" type="string" required="yes" hint="Name of the attachment or image" />
		<cfset var response_file = _getFile(url="getFile", page_id=splitIDforAssetsPath(arguments.page_id), fileName=arguments.fileName) />
		<cfreturn response_file />
	</cffunction>


	<cffunction name="sharePage" access="public" returntype="xml" output="false">
		<cfargument name="id" type="string" required="yes" hint="ID of the item to update" />
		<cfargument name="email_addresses" type="string" required="no" />
		<cfargument name="public" type="boolean" required="no" />
		<cfset var response_xml = "" />
		<cfset var xmlArgument_struct = structNew() />
		<cfif structKeyExists(arguments, "email_addresses")>
			<cfset xmlArgument_struct['email_addresses'] = arguments.email_addresses />
		</cfif>
		<cfif structKeyExists(arguments, "public")>
			<cfset xmlArgument_struct['public'] = iif(arguments.public, 1, 0) />
		</cfif>
		<cfset response_xml = _doRequest(url="sharePage", id=arguments.id, page=xmlArgument_struct) />
		<cfreturn response_xml />
	</cffunction>


	<cffunction name="emailPage" access="public" returntype="xml" output="false">
		<cfargument name="id" type="string" required="yes" hint="ID of the page to email" />
		<cfset var response_xml = _doRequest(url="emailPage", id=arguments.id) />
		<cfreturn response_xml />
	</cffunction>


	<cffunction name="searchPages" access="public" returntype="any" output="false">
		<cfargument name="term" type="string" required="yes" hint="the search string" />
		<cfargument name="returnType" type="string" required="no" default="xml" hint="If 'query', returns the pages-xml as..." />
		<cfset var response_xml = _doRequest(url="searchPages", term=arguments.term) />
		<cfset var pages_qry = queryNew("scope,title,id") />
		<cfif arguments.returnType eq "query">
			<cfreturn _convertXmlToQuery(response_xml.response.pages, pages_qry) />
		<cfelse>
			<cfreturn response_xml />
		</cfif>
	</cffunction>



<!--- <comment author="P. Klinkenberg">   I haven't added these functions yet, since I absolutely never ever need them (probably ;-P  ) </comment>

Unshare yourself from a friends page: /ws/page/1234/unshare_friend_page

<request>
  <token>202cb962ac59075b964b07152d234b70</token>
</request>

<response success='true' />

Email page to yourself: /ws/page/1234/email

<request>
  <token>202cb962ac59075b964b07152d234b70</token>
</request>

<response success='true' />
--->

	<cffunction name="_getFile" access="private" output="false" returntype="any" description="I do a http request to retrieve a file, or get it from local cache if available.">
		<cfargument name="url" type="string" required="true" hint="The page to request (must be referenced in variables._requestURL_struct)" />

		<!--- <comment author="P. Klinkenberg"> optional arguments may be given; they will all be used to construct the request xml </comment> --->
		<cfset var timerStart_num = getTickCount() />
		<cfset var requestUrl_str = iif(application.backPack.useSSL, de("https://"), de("http://")) & application.backPack.hostUrl & variables._requestURL_struct[arguments.url] />
		<cfset var httpResponse_struct = structNew() />
		<cfset var httpResponse_file = "" />
		
		<cfset var reFindPos_struct = "" />
		<cfset var valueNameToBeReplaced = "" />
		<cfset var cookieNow = "" />
		<cfset var doItAgain = false />
		<cfset var timesTried = 0 />
		
		<!--- <comment author="P. Klinkenberg"> check if the backpack login credentials are set </comment> --->
		<cfif not len(application.backpack.loginName) or not len(application.backpack.loginPassword)>
			<cfthrow message="Files (attachments, images, etc.) can only be retrieved if a login name and password is given in Application.cfm!" />
		</cfif>
		
		<!--- <comment author="P. Klinkenberg"> replace all optional variable pointers (= argument names wrapped in curly braces, i.e. {id}) with the argument values </comment> --->
		<cfloop condition="reFind('\{([^\}]+)\}', requestUrl_str)">
			<cfset reFindPos_struct = reFind("\{[^\}]+\}", requestUrl_str, 1, true) />
			<cfset valueNameToBeReplaced = mid(requestUrl_str, reFindPos_struct['pos'][1]+1, reFindPos_struct['len'][1]-2) />
			<cfset requestUrl_str = replace(requestUrl_str, "{#valueNameToBeReplaced#}", arguments[valueNameToBeReplaced], "ALL") />
		</cfloop>
		
		<!--- <comment author="P. Klinkenberg"> we will try to retrieve files. Since this might fail the first time due to an out-of-date session, we will try it twice </comment> --->
		<cfloop condition="timesTried eq 0 or doItAgain">
			<cfset timesTried = timesTried + 1 />

			<!--- <comment author="P. Klinkenberg"> login to backpack (this is a hack to be able to access YOUR OWN files without going to the site yourself) </comment> --->
			<cfif not structKeyExists(variables, "backpackSessionCookies") or doItAgain>
				<cfset _loginToBackPack() />
			</cfif>
			
			<cfset doItAgain = false />
			
			<cftry>
				<cfhttp url="#requestUrl_str#" method="get" result="httpResponse_struct" redirect="no" throwonerror="yes" timeout="#application.backpack.httpCallTimeout#" useragent="coldfusion backPack component">
					<cfloop list="#variables.backpackSessionCookies#" index="cookieNow">
						<cfhttpparam name="#listFirst(cookieNow, '=')#" value="#listLast(listFirst(cookieNow, ';'), '=')#" type="cookie" />
					</cfloop>
					<cfhttpparam type="cgi" name="referer" value="#requestUrl_str#" />
				</cfhttp>
				<cfcatch>
					<cfif timesTried eq 1 and findNoCase("Moved Temporarily", cfcatch.message)>
						<cfset doItAgain = true />
					<cfelse>
						<cfset _handleHTTPError(errorStruct=duplicate(cfcatch), requestURL=requestUrl_str) />
					</cfif>
				</cfcatch>
			</cftry>
		</cfloop>

		<cfset httpResponse_file = httpResponse_struct.fileContent />
		
		<!--- <comment author="P. Klinkenberg"> if developing, show cfhttp processing time </comment> --->
		<cfif application.backpack.useDevelopmentMode>
			<cftrace text="Function _getFile(url='#arguments.url#') took #(getTickCount() - timerStart_num)# milliseconds to complete." type="information" />
		</cfif>

		<cfreturn httpResponse_file />
	</cffunction>
	
	
	<cffunction name="_loginToBackPack" access="private" output="false" returntype="void">
		<cfset var httpResponse_struct = "" />
		<cfset var cookieNow = "" />
		
		<!--- <comment author="P. Klinkenberg"> get session ID </comment> --->
		<cfhttp url="http://#application.backPack.hostUrl#/account/authorize" method="head" result="httpResponse_struct"></cfhttp>

		<cfset variables.backpackSessionCookies = httpResponse_struct.Responseheader['Set-Cookie'] />

		<!--- <comment author="P. Klinkenberg"> login </comment> --->
		<cfhttp url="http://#application.backPack.hostUrl#/account/authorize" method="post" result="httpResponse_struct">
			<cfloop list="#variables.backpackSessionCookies#" index="cookieNow">
				<cfhttpparam name="#listFirst(cookieNow, '=')#" value="#listLast(listFirst(cookieNow, ';'), '=')#" type="cookie" />
			</cfloop>
			<cfhttpparam name="username" value="#application.backpack.loginName#" type="formfield" />
			<cfhttpparam name="password" value="#application.backpack.loginPassword#" type="formfield" />
			<cfhttpparam name="save_login" value="1" type="formfield" />
		</cfhttp>
	</cffunction>


	<cffunction name="_doRequest" access="private" output="false" returntype="xml" description="I send the request, and either return the response or handle the error.">
		<cfargument name="url" type="string" required="true" hint="The page to request (must be referenced in variables._requestURL_struct)" />
		<!--- <comment author="P. Klinkenberg"> optional arguments may be given; they will all be used to construct the request xml </comment> --->
		<cfset var timerStart_num = getTickCount() />
		<cfset var requestUrl_str = iif(application.backPack.useSSL, de("https://"), de("http://")) & application.backPack.hostUrl & variables._requestURL_struct[arguments.url] />
		<!--- <comment author="P. Klinkenberg"> create the xml which we will send with this request </comment> --->
		<cfset var requestBody_xml = _createRequestXml(argumentCollection=arguments) />
		<cfset var httpResponse_struct = structNew() />
		<cfset var httpResponse_xml = "" />
		
		<cfset var reFindPos_struct = "" />
		<cfset var valueNameToBeReplaced = "" />
		
		<!--- <comment author="P. Klinkenberg"> replace all optional variable pointers (= argument names wrapped in curly braces, i.e. {id}) with the argument values </comment> --->
		<cfloop condition="reFind('\{([^\}]+)\}', requestUrl_str)">
			<cfset reFindPos_struct = reFind("\{[^\}]+\}", requestUrl_str, 1, true) />
			<cfset valueNameToBeReplaced = mid(requestUrl_str, reFindPos_struct['pos'][1]+1, reFindPos_struct['len'][1]-2) />
			<cfset requestUrl_str = replace(requestUrl_str, "{#valueNameToBeReplaced#}", arguments[valueNameToBeReplaced], "ALL") />
		</cfloop>
		
		<cftry>
			<cfhttp url="#requestUrl_str#" method="post" result="httpResponse_struct" redirect="no" throwonerror="yes" timeout="#application.backpack.httpCallTimeout#" useragent="coldfusion backPack component">
				<cfhttpparam type="header" name="Content-Type" value="application/xml" />
				<cfhttpparam type="xml" value="#requestBody_xml#" />
			</cfhttp>
			<cfcatch>
				<cfset _handleHTTPError(errorStruct=duplicate(cfcatch), requestURL=requestUrl_str, bodyXML=requestBody_xml) />
			</cfcatch>
		</cftry>
		
		<!--- <comment author="P. Klinkenberg"> some freaky shit in the api: the returned xml always has a root node 'response', except for when using 'exportAll'.
		To have the same xml evverywhere, we will change the xml here to be like the rest of the xml responses. </comment> --->
		<cfset httpResponse_xml = httpResponse_struct.fileContent />
		<cfif not find("<response ", httpResponse_xml) and arguments.url eq "exportAll">
			<cfset httpResponse_xml = replace(httpResponse_xml, "<backpack username=", "<response success=""true"" username=") />
			<cfset httpResponse_xml = replace(httpResponse_xml, "</backpack>", "</response>") />
		</cfif>
		
		<!--- <comment author="P. Klinkenberg"> now parse the xml_string to an xml-object </comment> --->
		<cfset httpResponse_xml = xmlParse(httpResponse_xml) />
		
		<!--- <comment author="P. Klinkenberg"> if an error is specified in the response xml, handle the error </comment> --->
		<cfif structKeyExists(httpResponse_xml, "response") and (not structKeyExists(httpResponse_xml.response.xmlAttributes, "success") or httpResponse_xml.response.xmlAttributes.success neq "true")>
			<cfset _handleError(httpResponse_xml) />
		</cfif>
		
		<!--- <comment author="P. Klinkenberg"> if developing, show cfhttp processing time </comment> --->
		<cfif application.backpack.useDevelopmentMode>
			<!--- <comment author="P. Klinkenberg"> log this call to the request scope for debug output later on</comment> --->
			<cfset debugStruct = structNew() />
			<cfset debugStruct.url = requestUrl_str />
			<cfset debugStruct.request_xml = requestBody_xml />
			<cfset debugStruct.response_xml = toString(httpResponse_xml) />
			<cfset arrayAppend(request.cfhttpRequests_arr, debugStruct) />
			
			<cftrace text="Function _doRequest(url='#arguments.url#') took #(getTickCount() - timerStart_num)# milliseconds to complete." type="information" />
		</cfif>

		<cfreturn httpResponse_xml />
	</cffunction>
	
	
	<cffunction name="_createRequestXml" access="private" output="false" returntype="string" description="I create the xml (as string) necessary for doing requests">
		<cfargument name="url" type="string" required="true" hint="The page to request (must be referenced in variables._requestURL_struct)" />
		<!--- <comment author="P. Klinkenberg"> optional arguments may be given; they will all be used to construct the request xml </comment> --->
		<cfset var requestXml_str = "" />
		<!--- <comment author="P. Klinkenberg"> copy the arguments scope (only top level keys, rest as pointer) </comment> --->
		<cfset var optionalArguments_struct = structNew() />
		<cfset var structKey = "" />
		
		<!--- <comment author="P. Klinkenberg"> delete all args which are given because they have to be set in the url (I assume they don't have to be set in the xml) </comment> --->
		<cfloop collection="#arguments#" item="structKey">
			<cfif not find("{#structKey#}", variables._requestURL_struct[arguments.url])>
				<cfset structInsert(optionalArguments_struct, lCase(structKey), arguments[structKey], true) />
			</cfif>
		</cfloop>
		<!--- <comment author="P. Klinkenberg"> now delete the argument 'url', since that isn't necessary for creating request xml.  </comment> --->
		<cfset structDelete(optionalArguments_struct, "url", false) />
		
		
		<cfsavecontent variable="requestXml_str"><cfoutput><request>
			<token>#application.backPack.token#</token>
			<!--- <comment author="P. Klinkenberg"> optional extra xml tags, sent by argument scope </comment> --->
			<cfif not structIsEmpty(optionalArguments_struct)>
				#_structToXml(theStruct=optionalArguments_struct)#
			</cfif>
		</request></cfoutput></cfsavecontent>
		
		<!--- <comment author="P. Klinkenberg"> remove all whitespace from the xml </comment> --->
		<cfset requestXml_str = reReplace(requestXml_str, "[	#chr(10)##chr(13)#]+", "", "ALL") />
		<cfreturn requestXml_str />
	</cffunction>
	
	
	<cffunction name="_structToXml" access="private" output="false" returntype="any" description="I create xml from a given struct">
		<cfargument name="theStruct" type="struct" required="yes" />
		<cfargument name="returnType" type="string" required="no" default="string" hint="Either string or xml" />
		<cfargument name="depth" type="numeric" required="no" default="1" />
		<cfset var theXml = "" />
		<cfset var structKey = "" />
		<!--- <comment author="P. Klinkenberg"> loop through all elements of the given structure </comment> --->
		<cfloop collection="#theStruct#" item="structKey">
			<!--- <comment author="P. Klinkenberg"> recursive if necessary </comment> --->
			<cfif isStruct(theStruct[structKey]) and not isCustomFunction(theStruct[structKey]) and not isXMLDoc(theStruct[structKey])>
				<cfset theXml = theXml & "<#structKey#>" & _structToXml(theStruct=arguments.theStruct[structKey], returnType="string", depth=incrementValue(arguments.depth))  & "</#structKey#>" />
			<!--- <comment author="P. Klinkenberg"> if it is a simple value without markup (so no CDATA) </comment> --->
			<cfelseif isSimpleValue(theStruct[structKey]) and not reFind("[#chr(10)##chr(13)#<>]", theStruct[structKey])>
				<cfset theXml = theXml & "<#structKey#>" & xmlFormat(theStruct[structKey]) & "</#structKey#>" />
			<cfelse>
				<cfset theXml = theXml & "<#structKey#><![CDATA[" & toString(theStruct[structKey]) & "]]></#structKey#>" />
			</cfif>
		</cfloop>
		<!--- <comment author="P. Klinkenberg"> if we have to return the end result now (depth=1), then (optionally) format the result based on argument 'returnType' </comment> --->
		<cfif arguments.depth eq 1 and returnType eq "xml">
			<cfset theXml = xmlParse(theXml) />
		</cfif>
		<cfreturn theXml />
	</cffunction>
	
	
	<cffunction name="_handleError" access="private" output="false" returntype="void" description="I handle any error answer that might be returned in the xml">
		<cfargument name="response" type="xml" required="yes" hint="The respoinse xml from the server" />
		<!--- <comment author="P. Klinkenberg"> check if the response xml has an 'error'  part in it </comment> --->
		<cfif structKeyExists(arguments.response.response, "error")>
			<cfif structKeyExists(arguments.response.response.error.xmlAttributes, "code")>
				<cfheader statuscode="#arguments.response.response.error.xmlAttributes.code#" statustext="Error received from backPack API" />
				<cfoutput>
					This is the error received from backPack:<br />
					#arguments.response.response.error.xmlText#
				</cfoutput>
				<!--- <comment author="P. Klinkenberg"> stop processing </comment> --->
				<cfabort />
			</cfif>
		<cfelse>
			<cfthrow message="Unknown error-xml was given to _handleError!" />
		</cfif>
	</cffunction>
	

	<cffunction name="_handleHTTPError" access="private" output="false" returntype="void" description="I handle any cfhttp error">
		<cfargument name="errorStruct" type="struct" required="yes" hint="The error struct from cfcatch" />
		<cfargument name="requestURL" type="string" required="no" hint="Optional, only used while in dev. mode: the url the error was received from" />
		<cfargument name="bodyXML" type="string" required="no" hint="Optional, only used while in dev. mode: the xml which was sent with the request" />
		<cfoutput>
			<h1>Error</h1>
			<cfswitch expression="#arguments.errorStruct.message#">
				<cfcase value="404 Not Found">
					<strong>The page we requested could not be found.</strong><br />
					Please check the 'hostURL' setting in Application.cfm.<br />
					Perhaps you used an incorrect ID?
				</cfcase>
				<cfcase value="302 Moved Temporarily">
					<strong>A redirect was returned from the server.</strong><br />
					Please check the 'token' setting in Application.cfm.<br />
					The most probable cause is a wrong login, which will happen if you have an incorrect token set.<br />
					Otherwise, check the API documentation at backpackIt's website, to see if urls to the API have changed.
				</cfcase>
				<cfdefaultcase>
					<strong>An error occured while trying to retrieve data from the backpack server.</strong><br />
					The error description: #arguments.errorStruct.message#.<br />
					#arguments.errorStruct.detail#
					<cfif application.backPack.useDevelopmentMode>
						<h2>using development mode:</h2>
						<cfdump var="#arguments.errorStruct#" label="error struct" />
					</cfif>
				</cfdefaultcase>
			</cfswitch>
			<cfif application.backpack.useDevelopmentMode>
				<h1>Extra debug info because development mode</h1>
				<cfif structKeyExists(arguments, "requestURL")>
					<h3>Requested url</h3>
					#requestURL#<br /><br />
				</cfif>
				<cfif structKeyExists(arguments, "bodyXML")>
					<h3>posted xml:</h3>
					<pre>#htmlEditFormat(bodyXML)#</pre>
					<br />
				</cfif>
				<h3>error-struct:</h3>
				<cfdump var="#arguments.errorStruct#" />
				<br />
			</cfif>
		</cfoutput>
		<!--- <comment author="P. Klinkenberg"> stop processing </comment> --->
		<cfabort />
		
	</cffunction>
	

	<cffunction name="_convertXmlToQuery" access="private" returntype="query" output="false" hint="I convert (a branch of) xml to query records">
		<cfargument name="xmlRoot" type="xml" required="yes" hint="The branch which holds the tags (XmlChildren) with the values (we are not going to recursively loop here;only root elements are used)" />
		<cfargument name="theQuery" type="query" required="yes" hint="The query with the columns we need to fill with the xmlRooot's data." />
		<cfargument name="useXMLChildren" type="boolean" required="no" default="true" hint="Whether we use the xmlRoot itself or it's xmlChildren." />
		<cfset var rowNr = 0 />
		<cfset var nameNow = "" />
		<cfset var xml_arr = iif(arguments.useXMLChildren, "arguments.xmlRoot.XmlChildren", "arguments.xmlRoot") />

		<cfloop from="1" to="#arrayLen(xml_arr)#" index="rowNr">
			<cfset queryAddRow(theQuery) />
			<cfloop list="#theQuery.columnList#" index="nameNow">
				<cfif structKeyExists(xml_arr[rowNr].xmlAttributes, nameNow)>
					<cfset querySetCell(theQuery, nameNow, xml_arr[rowNr].xmlAttributes[nameNow]) />
				<cfelseif structKeyExists(xml_arr[rowNr], nameNow)>
					<cfset querySetCell(theQuery, nameNow, xml_arr[rowNr][nameNow].xmlText) />
				<!--- <comment author="P. Klinkenberg"> if we want the xmlText of the current object itself </comment> --->
				<cfelseif xml_arr[rowNr].XmlName eq nameNow>
					<cfset querySetCell(theQuery, nameNow, xml_arr[rowNr].xmlText) />
				</cfif>
			</cfloop>
		</cfloop>
		<cfreturn theQuery />
	</cffunction>
	
	
	<cffunction name="_convertTextileQuery2HTML" access="private" returntype="query" output="false" hint="I convert (a branch of) xml to query records">
		<cfargument name="theQuery" type="query" required="yes" hint="The query with the columns we have to convert" />
		<cfargument name="columnNames" type="string" required="yes" hint="Names of the columns we have to convert from textile to html." />
		<cfset var colName = "" />
		<cfoutput query="theQuery">
			<cfloop list="#arguments.columnNames#" index="colName">
				<cfset querySetCell(theQuery, colName, variables._textileConverter_obj.textile2HTML(theQuery[colName][currentrow]), currentrow) />
			</cfloop>
		</cfoutput>
		<cfreturn theQuery />
	</cffunction>
	

	<cffunction name="_orderQuery" access="private" returntype="query" description="orders a given query with the given order clause" output="false">
		<cfargument name="theQuery" type="query" required="yes" />
		<cfargument name="orderBy" type="string" required="yes" />
		<cfset var ordered_qry = "" />
		<cfset var qry_pointer = arguments.theQuery />
		<!--- <comment author="P. Klinkenberg"> check sql injection </comment> --->
		<cfif reFind("[^a-z0-9 ,\.\[\]_]", arguments.orderBy)>
			<cfthrow message="OrderBy clause not allowed: '#arguments.orderBy#'!" detail="Possible sql injection attempt." />
		</cfif>
		<cfquery name="ordered_qry" dbtype="query">
			SELECT *
			FROM qry_pointer
			ORDER BY #arguments.orderBy#;
		</cfquery>
		<cfreturn ordered_qry />
	</cffunction>
	
	
	<cffunction name="_addListNamesToListItemsQuery" access="private" returntype="query" output="false">
		<cfargument name="theQuery" type="query" required="yes" hint="The query with required columns 'list_id' and 'list_name'" />
		<cfargument name="id" type="string" required="yes" hint="ID of the item with the given list items" />
		<cfset var lists_arr = getPageLists(id=arguments.id).response.lists.xmlChildren />
		<cfset var listNames_struct = structNew() />
		<cfset var arrNr = 0 />

		<!--- <comment author="P. Klinkenberg"> now create a struct with the list id/names </comment> --->
		<cfloop from="1" to="#arraylen(lists_arr)#" index="arrNr">
			<cfset structInsert(listNames_struct, lists_arr[arrNr].xmlAttributes.id, lists_arr[arrNr].xmlAttributes.name) />
		</cfloop>

		<!--- <comment author="P. Klinkenberg"> set the list names in the query </comment> --->
		<cfoutput query="theQuery">
			<!--- <comment author="P. Klinkenberg">
			there seems to be a bug with the backpack example pages, which also returns items without a list id :-/
			check: http://www.backpackit.com/forum/viewtopic.php?id=1932 </comment> --->
			<cfif len(theQuery.list_id)>
				<cfset querySetCell(theQuery, "list_name", listNames_struct[theQuery.list_id], theQuery.currentrow) />
			</cfif>
		</cfoutput>
		
		<cfreturn theQuery />
	</cffunction>


</cfcomponent>
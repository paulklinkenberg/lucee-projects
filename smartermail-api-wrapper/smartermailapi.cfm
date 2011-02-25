<!---
/*
 * smartermailapi.cfm, developed by Paul Klinkenberg
 * http://www.railodeveloper.com/post.cfm/smartermail-api-wrapper-coldfusion
 *
 * Date: 2010-12-01 20:19:00 +0100
 * Revision: 1.2
 *
 * Copyright (c) 2010 Paul Klinkenberg, Ongevraagd Advies
 * Licensed under the GPL license.
 *
 *    This program is free software: you can redistribute it and/or modify
 *    it under the terms of the GNU General Public License as published by
 *    the Free Software Foundation, either version 3 of the License, or
 *    (at your option) any later version.
 *
 *    This program is distributed in the hope that it will be useful,
 *    but WITHOUT ANY WARRANTY; without even the implied warranty of
 *    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *    GNU General Public License for more details.
 *
 *    You should have received a copy of the GNU General Public License
 *    along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 *    ALWAYS LEAVE THIS COPYRIGHT NOTICE IN PLACE!
 */
--->

<!--- if not yet lofgged in, create the smartermail-object without login credentials --->
<cfif not structKeyExists(session, "username")>
	<cfset variables.smartermail_obj = createObject("component", "Smartermail") />
<cfelse>
	<cfset variables.smartermail_obj = createObject("component", "Smartermail").init(serverURL=session.serverURL, wsUsername=session.username, wsPassword=session.password, debugMode=session.debugMode, debugDataScopeName="request") />
	
	<cfif not structKeyExists(session, "domainsList_str")>
		<!--- get all domains (this is also the check to see if the login credentials are right) --->
		<cftry>
			<cfset domains_xml = variables.smartermail_obj.callWs(page='svcDomainAdmin', method='GetAllDomains') />
			<!--- -20=No permissions. Maybe we do have a domain admin here... --->
			<cfif findNoCase('<ResultCode>-20</ResultCode>', domains_xml)>
				<cfset temp = variables.smartermail_obj.callWs(page='svcDomainAdmin', method='GetDomainInfo', domainName=listLast(session.username, '@')) />
				<!---  if we got a succesfull response, then create a bogus xml so we'll use the user's domain name in the rest of the pages. --->
				<cfif find("<ResultCode>0</ResultCode>", temp)>
					<cfset domains_xml = "<GetAllDomainsResult><ResultCode>0</ResultCode><DomainNames><string>#listLast(session.username, '@')#</string></DomainNames></GetAllDomainsResult>" />
				</cfif>
			</cfif>
			<cfcatch>
				<cfset domains_xml = "<ResultCode>-1</ResultCode>" />
				<p class="error">Error occured in smartermail.cfc:<br />
					<cfoutput><em>#cfcatch.Message# #cfcatch.detail#</em></cfoutput>
				</p>
				<cfdump var="#cfcatch#" />
			</cfcatch>
		</cftry>
		<cfif not findNoCase('<ResultCode>0</ResultCode>', domains_xml)>
			<p class="error">Your login details seem to be incorrect! Please try again.</p>
			<cfset structClear(session) />
			<cfinclude template="includes/inc_loginform.cfm" />
			<cfoutput>
				<br /><br />
				<pre><strong>XML returned from the webservice:</strong><div>#htmleditformat(domains_xml)#</div></pre>
			</cfoutput>
		<cfelse>
			<h3>Welcome, you are now logged in.</h3>
			<p>Please choose one of the options at the left-hand side.</p>
			<!--- make an ordered list of all available domains, and save in session. --->
			<cfset variables.domains_arr = xmlSearch(domains_xml, "//GetAllDomainsResult/DomainNames/string/") />
			<cfset variables.domainsList_str = "" />
			<cfloop from="1" to="#arrayLen(variables.domains_arr)#" index="i">
				<cfset variables.domainsList_str = listAppend(variables.domainsList_str, variables.domains_arr[i].xmlText) />
			</cfloop>
			<cfset session.domainsList_str = listSort(variables.domainsList_str, 'textNoCase') />
		</cfif>
	</cfif>
</cfif>

<cfif structKeyExists(url, 'method') and structKeyExists(url, 'page')>
	<cfif not structKeyExists(application.methods_struct, url.page) or not structKeyExists(application.methods_struct[url.page], url.method)>
		<p class="error">The method you requested does not exist!</p>
		<cfexit method="exittemplate" />
	</cfif>
	
	<cfset soapArguments_xml = xmlParse("<root>"&application.methods_struct[url.page][url.method]&"</root>") />
	<cfset args_arr = XMLSearch(soapArguments_xml, "//root/*") />
	
	<cfoutput>
		<h2>#url.page#.#url.method#()</h2>
		
		<cfif structKeyExists(session, "username") and structKeyExists(form, "submitted")>
			<cfif structKeyExists(form, 'loopDomainNames')>
				<cfset domList = form.domainName />
				<cfloop list="#domList#" index="dom">
					<h3>Calling the webservice for domain <em>#dom#</em>...</h3>
					<cfset form.domainName = dom />
					<cfset return_xml = variables.smartermail_obj.callWs(page=url.page, method=url.method, args=form) />
					<cfset xml_str = variables.smartermail_obj.indentXML(toString(return_xml)) />
					<cfif findNoCase("<ResultCode>-1</ResultCode>", xml_str)>
						<p class="error">The web-service says an error has occured! <em>(resultCode should be 0)</em></p>
					</cfif>
					<pre><strong>XML returned from the webservice:</strong><div>#htmleditformat(xml_str)#</div></pre>
				</cfloop>
			<cfelseif structKeyExists(form, 'loopEmailAddresses')>
				<cfset emailList = form.EmailAddress />
				<cfloop list="#emailList#" index="email">
					<h3>Calling the webservice for email address <em>#email#</em>...</h3>
					<cfset form.EmailAddress = email />
					<cfset return_xml = variables.smartermail_obj.callWs(page=url.page, method=url.method, args=form) />
					<cfset xml_str = variables.smartermail_obj.indentXML(toString(return_xml)) />
					<cfif findNoCase("<ResultCode>-1</ResultCode>", xml_str)>
						<p class="error">The web-service says an error has occured! <em>(resultCode should be 0)</em></p>
					</cfif>
					<pre><strong>XML returned from the webservice:</strong><div>#htmleditformat(xml_str)#</div></pre>
				</cfloop>
			<cfelse>
				<h3>Calling the webservice...</h3>
				<cfif structKeyExists(form, 'domainName')>
					<cfset form.domainName = replace(form.domainName, ',', chr(10), 'all') />
				</cfif>
				<cfset return_xml = variables.smartermail_obj.callWs(page=url.page, method=url.method, args=form) />
				<cfset xml_str = variables.smartermail_obj.indentXML(toString(return_xml)) />
				<cfif findNoCase("<ResultCode>-1</ResultCode>", xml_str)>
					<p class="error">The web-service says an error has occured! <em>(resultCode should be 0)</em></p>
				</cfif>
				<pre><strong>XML returned from the webservice:</strong><div>#htmleditformat(xml_str)#</div></pre>
			</cfif>
			<hr />
		</cfif>
		
		<form action="?page=#url.page#&amp;method=#url.method#" id="wsfrm" method="post">
			<input type="hidden" name="submitted" value="1" />
			<cfif not structKeyExists(session, "username")>
				<p class="error">This form can not yet be submitted, since you have not logged in.</p>
				<script type="text/javascript">
					$(function(){
						$('##wsfrm input,##wsfrm select,##wsfrm textarea').attr('disabled', true);
					});
				</script>
			</cfif>
			<cfif not arrayLen(args_arr)>
				<em>There are no extra arguments necessary</em><br />
			</cfif>
			<cfloop from="1" to="#arrayLen(args_arr)#" index="arrIndex">
				<label for="#args_arr[arrIndex].xmlName#">#args_arr[arrIndex].xmlName#</label>
				<cfif args_arr[arrIndex].xmlName eq 'domainName' and structKeyExists(session, "domainsList_str") and listLen(session.domainsList_str)>
					<select name="#args_arr[arrIndex].xmlName#" id="#args_arr[arrIndex].xmlName#"<cfif structKeyExists(args_arr[arrIndex].xmlAttributes, "multiline") or structKeyExists(form, 'loopDomainNames')> multiple="true" size="10"</cfif>>
						<cfif structKeyExists(session, "username")>
							<cfloop list="#session.domainsList_str#" index="dom">
								<option value="#dom#"<cfif structKeyExists(form, args_arr[arrIndex].xmlName) and findNoCase(dom, form[args_arr[arrIndex].xmlName])> selected="selected"</cfif>>#dom#</option>
							</cfloop>
						<cfelse>
							<option value="">your domains will appear here</option>
						</cfif>
					</select>
				<cfelseif args_arr[arrIndex].xmlName eq 'EmailAddress' and structKeyExists(session, "domainsList_str") and listLen(session.domainsList_str)>
					<select name="#args_arr[arrIndex].xmlName#" id="#args_arr[arrIndex].xmlName#"<cfif structKeyExists(args_arr[arrIndex].xmlAttributes, "multiline") or structKeyExists(form, 'loopEmailAddresses')> multiple="true" size="10"</cfif>>
						<cfif structKeyExists(session, "username")>
							<cfloop list="#session.domainsList_str#" index="dom">
								<!--- get current email addresses --->
								<cfset variables.args = structNew() />
								<cfset variables.args['DomainName'] = dom />
								<cfset emails_xml = variables.smartermail_obj.callWs(page='svcDomainAdmin', method='GetDomainUsers', args=variables.args) />
								<cfset users_arr = xmlSearch(emails_xml, "//Users/string/") />
								<cfloop from="1" to="#arrayLen(variables.users_arr)#" index="i">
									<cfset user = users_arr[i].xmlText & "@#dom#" />
									<option value="#user#"<cfif structKeyExists(form, args_arr[arrIndex].xmlName) and findNoCase(user, form[args_arr[arrIndex].xmlName])> selected="selected"</cfif>>#user#</option>
								</cfloop>
							</cfloop>
						<cfelse>
							<option value="">your e-mail addresses will appear here</option>
						</cfif>
					</select>
				
				<cfelse>
					<cfif structKeyExists(args_arr[arrIndex].xmlAttributes, "multiline")>
						<textarea name="#args_arr[arrIndex].xmlName#" id="#args_arr[arrIndex].xmlName#" cols="30" rows="5"><cfif structKeyExists(form, args_arr[arrIndex].xmlName)>#htmleditformat(form[args_arr[arrIndex].xmlName])#</cfif></textarea>
						<em>One item per line!</em>
					<cfelseif findNoCase("description", args_arr[arrIndex].xmlName)>
						<textarea name="#args_arr[arrIndex].xmlName#" id="#args_arr[arrIndex].xmlName#" cols="30" rows="3"><cfif structKeyExists(form, args_arr[arrIndex].xmlName)>#htmleditformat(form[args_arr[arrIndex].xmlName])#</cfif></textarea>
					<cfelse>
						<input type="text" name="#args_arr[arrIndex].xmlName#" id="#args_arr[arrIndex].xmlName#" size="30" value="<cfif structKeyExists(form, args_arr[arrIndex].xmlName)>#htmleditformat(form[args_arr[arrIndex].xmlName])#</cfif>" />
					</cfif>
				</cfif>
				<br />
			</cfloop>
			<input type="submit" value="Do the webservice call" />	
		</form>
		
		<div id="helptext">
			<cftry>
				<cfinclude template="documentation/#url.page#-#url.method#.html" />
				<cfcatch>
					<p class="error">Documentation not available: #cfcatch.message#</p>
				</cfcatch>
			</cftry>
		</div>
		<!---
		<pre><strong>Example SOAP packet:</strong>#htmleditformat(variables.smartermail_obj.createSoapBody(page=url.page, method=url.method, args=form, defaultArgValue="your-value"))#</pre>
		--->
	</cfoutput>
</cfif>

<cfif (structKeyExists(session, "debugMode") and session.debugMode)
or structKeyExists(form, "debugMode") and form.debugMode eq 1>
	<hr style="margin-top:50px;" />
	<p><strong>Debug information</strong></p>
	<cfset debugData = variables.smartermail_obj.getDebugData() />
	<cfoutput>
		<cfloop array="#debugData#" index="arr">
			<pre><strong>#arr.title# (#dateformat(arr.date, 'mmm. d, ')# #timeformat(arr.date, 'HH:mm:ss')#)</strong><div>#htmleditformat(variables.smartermail_obj.indentXML(arr.data))#</div></pre>
		</cfloop>
	</cfoutput>
</cfif>
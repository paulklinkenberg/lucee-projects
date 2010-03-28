<!--- if not yet lofgged in, create the smartermail-object without login credentials --->
<cfif not structKeyExists(session, "username")>
	<cfset variables.smartermail_obj = createObject("component", "Smartermail") />
<cfelse>
	<cfset variables.smartermail_obj = createObject("component", "Smartermail").init(serverURL=session.serverURL, wsUsername=session.username, wsPassword=session.password) />
	
	<cfif not structKeyExists(session, "domainsList_str")>
		<!--- get all domains (this is also the check to see if the login credentials are right) --->
		<cftry>
			<cfset domains_xml = variables.smartermail_obj.callWs(page='svcDomainAdmin', method='GetAllDomains') />
			<cfcatch>
				<cfset domains_xml = "<ResultCode>-1</ResultCode>" />
				<p class="error">Error occured in smartermail.cfc:<br />
					<cfoutput><em>#cfcatch.Message# #cfcatch.detail#</em></cfoutput>
				</p>
				<cfdump var="#cfcatch#" />
			</cfcatch>
		</cftry>
		<cfif findNoCase('<ResultCode>-1</ResultCode>', domains_xml)>
			<p class="error">Your login details seem to be incorrect! Please try again.</p>
			<cfset structClear(session) />
			<cfinclude template="includes/inc_loginform.cfm" />
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
					<pre><strong>XML returned from the webservice:</strong>#htmleditformat(xml_str)#</pre>
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
					<pre><strong>XML returned from the webservice:</strong>#htmleditformat(xml_str)#</pre>
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
				<pre><strong>XML returned from the webservice:</strong>#htmleditformat(xml_str)#</pre>
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
				<cfif args_arr[arrIndex].xmlName eq 'domainName'>
					<select name="#args_arr[arrIndex].xmlName#" id="#args_arr[arrIndex].xmlName#"<cfif structKeyExists(args_arr[arrIndex].xmlAttributes, "multiline") or structKeyExists(form, 'loopDomainNames')> multiple="true" size="10"</cfif>>
						<cfif structKeyExists(session, "username")>
							<cfloop list="#session.domainsList_str#" index="dom">
								<option value="#dom#"<cfif structKeyExists(form, args_arr[arrIndex].xmlName) and findNoCase(dom, form[args_arr[arrIndex].xmlName])> selected="selected"</cfif>>#dom#</option>
							</cfloop>
						<cfelse>
							<option value="">your domains will appear here</option>
						</cfif>
					</select>
				<cfelseif args_arr[arrIndex].xmlName eq 'EmailAddress'>
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
						<textarea name="#args_arr[arrIndex].xmlName#" id="#args_arr[arrIndex].xmlName#" cols="30" rows="5"><cfif structKeyExists(form, args_arr[arrIndex].xmlName)>#form[args_arr[arrIndex].xmlName]#</cfif></textarea>
						<em>One item per line!</em>
					<cfelse>
						<input type="text" name="#args_arr[arrIndex].xmlName#" id="#args_arr[arrIndex].xmlName#" size="30" value="<cfif structKeyExists(form, args_arr[arrIndex].xmlName)>#form[args_arr[arrIndex].xmlName]#</cfif>" />
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
		<pre><strong>Example SOAP packet:</strong>#htmleditformat(variables.smartermail_obj.createSoapBody(page=url.page, method=url.method, args=form, defaultArgValue="your-value"))#</pre>
	</cfoutput>
</cfif>
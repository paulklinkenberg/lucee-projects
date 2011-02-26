<cfcomponent output="false" displayname="Smartermail API interface by Paul Klinkenberg">
<!---
/*
 * Smartermail.cfc, developed by Paul Klinkenberg
 * http://www.railodeveloper.com/post.cfm/smartermail-api-wrapper-coldfusion
 *
 * Date: 2011-02-26 01:13:00 +0100
 * Revision: 1.3.0
 *
 * Copyright (c) 2011 Paul Klinkenberg, Ongevraagd Advies
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
	<cfset this.serverURL = "" />
	<cfset this.wsPassword = "" />
	<cfset this.wsUsername = "" />
	<cfset this.debugMode = false />
	<cfset this.debugDataScopeName = "" />
	
	
	<cffunction name="init" returntype="any" access="public" hint="Sets the webservice variables and returns this object" output="no">
		<cfargument name="serverURL" type="string" required="yes" hint="http://www.yoursite.com" />
		<cfargument name="wsUsername" type="string" required="yes" />
		<cfargument name="wsPassword" type="string" required="yes" />
		<cfargument name="debugMode" type="boolean" required="no" default="false" hint="When debugging, all requests and responses are logged to the given scope (key='SMDebugData')" />
		<cfargument name="debugDataScopeName" type="string" required="no" default="this" hint="this/request/application/server" />
		<cfset var key = "" />
		<!--- CF7 has a stupid fault: when looping through the arguments collection, even undefined arguments are looped over.
		So we need to check if the key actually exists ;-/ --->
		<cfloop collection="#arguments#" item="key"><cfif structKeyExists(arguments, key)>
			<cfset this[key] = arguments[key] />
		</cfif></cfloop>
		
		<cfif refind("/$", this.serverURL)>
			<cfset this.serverURL = rereplace(this.serverURL, "^(https?://[^/]+).*", "$1") />
		</cfif>
		<cfreturn this />
	</cffunction>
		
	
	<cffunction name="getDebugData" access="public" returntype="array" output="no">
		<cfset var theScope = evaluate(this.debugDataScopeName) />
		<cfset var theKey = "SMDebugData" />
		<cfset var returnData = arrayNew(1) />
		<cfset var theData = structNew() />
		<cfif not this.debugMode>
			<cfset theData.date = now() />
			<cfset theData.title = "debugging disabled" />
			<cfset theData.data = "Debugging is currently disabled. You should set the argument 'debugMode' to TRUE in the init function." />
			<cfset arrayAppend(returnData, theData) />
			<cfreturn returnData />
		</cfif>
		<cfif not structKeyExists(theScope, theKey)>
			<cfreturn returnData />
		<cfelse>
			<cfreturn theScope[theKey] />
		</cfif>
	</cffunction>
	
	
	<cffunction name="callWs" returntype="any" access="public" hint="Calls the webservice method, and returns the http-struct or xml" output="no">
		<cfargument name="page" type="string" required="yes" hint="svcAliasAdmin,svcDomainAdmin,svcMailListAdmin,svcProductInfo,svcGlobalUpdate,svcDomainAliasAdmin,svcUserAdmin,svcServerAdmin,svcOutlookAddin" />
		<cfargument name="method" type="string" required="yes" />
		<cfargument name="args" type="struct" required="no" default="#structNew()#" hint="Struct with all attributes (must be the right CasE!!!)" />
		<cfargument name="returnXml" type="boolean" default="true" hint="return complete cfhttp-structure, or cleaned soap-xml?" />
		<cfset var soapBody = createSoapBody(argumentCollection=arguments) />
		<cfset var cfhttpReturn_struct = structNew() />

		<cfhttp method="post" url="#this.serverURL#/Services/#arguments.page#.asmx" throwonerror="yes" result="cfhttpReturn_struct">
			<!--- ACF (7? &8?) has a bug with faulty compression headers, which can be fixed by adding these headers: --->
			<cfhttpparam type="header" name="Accept-Encoding" value="deflate;q=0" />
			<cfhttpparam type="header" name="TE" value="deflate;q=0" />
			
			<cfhttpparam type="header" name="Content-Type" value="application/soap+xml" />
			<cfhttpparam type="body" value="#soapBody#" />
		</cfhttp>
		
		<!--- debug? log! --->
		<cfif this.debugMode>
			<cfset _logDebugData("Request data", soapBody) />
			<cfset _logDebugData("Response data", cfhttpReturn_struct.filecontent.toString()) />
		</cfif>
		
		<cfif arguments.returnXml>
			<cfreturn xmlParse( _cleanXml(cfhttpReturn_struct.filecontent.toString()) ) />
		<cfelse>
			<cfreturn cfhttpReturn_struct />
		</cfif>
	</cffunction>

	
	<cffunction name="createSoapBody" returntype="string" access="public" output="no" hint="Creates the soap body for the request you want">
		<cfargument name="page" type="string" required="yes" hint="svcAliasAdmin,svcDomainAdmin,svcMailListAdmin,svcProductInfo,svcGlobalUpdate,svcDomainAliasAdmin,svcUserAdmin,svcServerAdmin,svcOutlookAddin" />
		<cfargument name="method" type="string" required="yes" />
		<cfargument name="args" type="struct" required="no" default="#structNew()#" hint="Struct with all attributes (must be the right CasE!!!)" />
		<cfargument name="defaultArgValue" type="string" required="no" default="" hint="What value to fill in when there is no value given in the args" />
		<cfset var soapBody = "" />
		<!--- get any optional extra soap-body (all arguments besides the login data) --->
		<cfset var extraSoapBody = _getExtraSoapBody(page=arguments.page, method=arguments.method) />
		<cfset var currentArg = "" />
		<cfset var insertValue = "" />
		<cfset var ismultiline = false />
		
		<!--- Replace all value-placeholders with the given args --->
		<cfloop condition="refind('\[\$.*?\$\]', extraSoapBody)">
			<cfset currentArg = rereplace(extraSoapBody, '.*\[\$(.*?)\$\].*', '\1') />
			<cfset insertValue = iif(structKeyExists(arguments.args, currentArg), 'arguments.args[currentArg]', 'arguments.defaultArgValue') />
			<!--- removes all spaces and returns from start and end of string --->
			<cfset insertValue = rereplace(insertValue, '(^[\r\t\n ]+|[\r\t\n ]+$)', '', 'all') />
			<!--- if the arg is multi-line, it can have multiple answers, which are divided by returns,
			and enclosed in the xml as <string>value</string> --->
			<cfif findNoCase('<#currentArg# multiline="true">', extraSoapBody)>
				<cfset insertValue = "<string>" & rereplace(trim(insertValue), '[\r\n]+', '</string><string>', 'all') & "</string>" />
			</cfif>
			<cfset extraSoapBody = replaceNoCase(extraSoapBody, "[$#currentArg#$]", xmlFormat(insertValue), "all") />
		</cfloop>
		<cfset extraSoapBody = replaceNoCase(extraSoapBody, ' multiline="true"', '', 'all') />
		
		<cfsavecontent variable="soapBody"><cfoutput><?xml version="1.0" encoding="utf-8"?>
<soap12:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://www.w3.org/2003/05/soap-envelope">
	<soap12:Body>
		<#arguments.method# xmlns="http://tempuri.org/">
			<AuthUserName>#this.wsUsername#</AuthUserName>
			<AuthPassword>#this.wsPassword#</AuthPassword>
			#extraSoapBody#
		</#arguments.method#>
	</soap12:Body>
</soap12:Envelope></cfoutput></cfsavecontent>
				
		<cfreturn indentXML(soapBody) />
	</cffunction>
	

	<cffunction name="_cleanXml" returntype="string" access="private" hint="Removes namespace refererences from given xml" output="no">
		<cfargument name="xml_str" type="string" required="yes"/>
		<cfset var cleanedXml = rereplaceNoCase(xml_str, ' +xmlns(:[^=]+)?=[^ ><]+', '', 'all') />
		<cfset cleanedXml = rereplaceNoCase(cleanedXml, '(</?)[a-z0-9]+:([a-z0-9]+)', '\1\2', 'all') />
		<cfreturn cleanedXml />
	</cffunction>
	
	
	<cffunction name="_getExtraSoapBody" access="private" returntype="string" output="no">
		<cfargument name="page" type="string" required="yes" hint="svcAliasAdmin,svcDomainAdmin,svcMailListAdmin,svcProductInfo,svcGlobalUpdate,svcDomainAliasAdmin,svcUserAdmin,svcServerAdmin,svcOutlookAddin" />
		<cfargument name="method" type="string" required="yes" />
		<cfset var q = "" />
		<cfif not structKeyExists(variables, "methodArguments")>
			<cffile action="read" file="#expandPath('./wddx/methodArguments.wddx')#" variable="q" />
			<cfwddx action="wddx2cfml" input="#q#" output="variables.methodArguments" />
		</cfif>
		
		<cfif structKeyExists(variables.methodArguments, arguments.page) and structKeyExists(variables.methodArguments[page], arguments.method)>
			<cfreturn variables.methodArguments[page][arguments.method] />
		<cfelse>
			<cfreturn "" />
		</cfif>
	</cffunction>
	
	
	<cffunction name="indentXML" returntype="string" output="no" access="public">
		<cfargument name="code" type="string" />
		<cfset var indent = -1 />
		<cfset var findings = "" />
		<cfset var tag = "" />
		<cfset var lastTag = "" />
		<cfset var doIndent = false />
		<cfset var nextStartTagOnSameLine = false />
		
		<cfset arguments.code = rereplace(arguments.code, '[\n\r\t]+', '', 'all') />
		<cfloop condition="refind('<(.*?>)', code)">
			<cfset doIndent = false />
			<cfset findings = refind('<(.*?>)', code, 1, true) />
			<cfset tag = mid(code, findings.pos[2], findings.len[2]) />
			<!---end-tag--->
			<cfif find('/', tag) eq 1>
				<cfif lastTag neq rereplace(tag, '(/|>)', '', 'all')>
					<cfset indent-=1 />
					<cfset doIndent = true />
				<cfelse>
					<cfset nextStartTagOnSameLine = true />
				</cfif>
			<!--- self-closing tag --->
			<cfelseif find('/>', tag)>
				<cfset doIndent = true />
			<!--- start tag--->
			<cfelseif not find('?>', tag)>
				<cfif not nextStartTagOnSameLine>
					<cfset indent+=1 />
				</cfif>
				<cfset doIndent = true />
				<cfset nextStartTagOnSameLine = false />
			</cfif>
			<cfif doIndent and indent gt -1>
				<cfset code = replace(code, '<#tag#', '#chr(10)##repeatString('    ', indent)#±#tag#') />
			<cfelse>
				<cfset code = replace(code, '<#tag#', '±#tag#') />
			</cfif>
			<cfset lastTag = rereplace(tag, '(^/|[\?/]?>)', '', 'all') />
		</cfloop>
		<cfset code = replace(code, '±', '<', 'all') />
		<cfreturn code />
	</cffunction>
	
	
	<cffunction name="_logDebugData" access="private" returntype="void" output="no">
		<cfargument name="title" type="string" required="yes" />
		<cfargument name="data" type="any" required="yes" />
		<cfset var theScope = evaluate(this.debugDataScopeName) />
		<cfset var theKey = "SMDebugData" />
		<cfset var theData = structNew() />
		<cfset theData.date = now() />
		<cfset theData.title = arguments.title />
		<cfset theData.data = arguments.data />
		<cfif not structKeyExists(theScope, theKey)>
			<cfset theScope[theKey] = arrayNew(1) />
		</cfif>
		<cfset arrayAppend(theScope[theKey], theData) />
		<!--- max 100 debug items --->
		<cfloop condition="arrayLen(theScope[theKey]) gt 100">
			<cfset arrayDeleteAt(theScope[theKey], 1) />
		</cfloop>
	</cffunction>
	
	
</cfcomponent>
<!--- /*		
Project:	 CFHONEYPOT  
Author:		 Paul Klinkenberg <paul@coldfusiondeveloper.nl>
Version:	 0.1.1
Build Date:  Monday July 12, 2010
Build:		 02

Copyright 2010 Paul Klinkenberg

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.	
			
<!-- - if key 'variable' is ommitted, the link html will be directly outputted to stdout - -->
<cfhoneypot action="createLink"
	url="http://www.fff.nl/dfff.cfm"
	variable="linkhtml"
/>

<!-- -
Optional attributes:
  - variable; default: 'cfhoneypot'
- -->
<cfhoneypot action="getThreatRating"
	httpblkey="ascv"
	ip="123.123.123.123"
	variable="structname"
/>

<!-- -
Optional attributes:
  - variable; default: 'cfhoneypot'
  - threatnrs; default: 4,5,6,7
  - maxdaysago; default: 20
  - minimalThreatIndex; default: 5
- -->
<cfhoneypot action="isThreat"
	httpblkey="ascv"
	ip="123.123.123.123"
	variable="structname"
	threatnrs="4,5,6,7"
	maxdaysago="20"
	minimalThreatIndex="5"
/>

<!-- -
Optional attributes:
  - threatnrs; default: 4,5,6,7
  - maxdaysago; default: 20
  - minimalThreatIndex; default: 5
  - blocktext; default: "<h1>Blocked due to spam check</h1>
<p>You are not allowed to visit this website due to spamming on this and/or other websites</p>"
- -->
<cfhoneypot action="BlockThreat"
	httpblkey="ascv"
	ip="123.123.123.123"
	threatnrs="4,5,6,7"
	maxdaysago="20"
	minimumThreatIndex="5"
	blocktext="you are locked out of this website due to spamming"
/>

*/--->
<cfcomponent name="Honeypot">

	<!--- Meta data --->
	<cfset this.metadata.attributetype="fixed" />
	<cfset this.metadata.attributes={
		action:					{required:true,type:"string"}
		
		, variable:				{required:false,type:"string"}
		, url:					{required:false,type:"string"}
		, httpblkey:			{required:false,type:"string"}
		, ip:					{required:false,type:"string"}
		, threatnrs:			{required:false,type:"string"}
		, maxdaysago:			{required:false,type:"number"}
		, minimumThreatIndex:	{required:false,type:"number"}
		, blocktext:			{required:false,type:"string"}
	}>


	<cffunction name="init" output="no" returntype="void"
		hint="invoked after tag is constructed">
		<cfargument name="hasEndTag" type="boolean" required="yes" />
		<cfargument name="parent" type="component" required="no" hint="the parent cfc custom tag, if there is one" />
		<cfset variables.hasEndTag = arguments.hasEndTag />
		<cfset variables.parent = arguments.parent />
	</cffunction> 
	
	<cffunction name="onStartTag" output="yes" returntype="boolean">
		<cfargument name="attributes" type="struct" />
		<cfargument name="caller" type="struct" />
 		<cfset variables.attributes = arguments.attributes />
		<cfset var key = "" />
		<cfset var action = getAttribute('action') />
		
		
		<!--- check type --->
		<cfif action eq "createlink">
			<cfif not attributeExists('url')>
				<cfthrow message="cfhoneypot: when action is '#action#', the atribute [url] is required!" />
			</cfif>
		<cfelseif action eq "isThreat" or action eq "BlockThreat" or action eq "getThreatRating">
			<cfloop list="httpblkey,ip" index="key">
				<cfif not attributeExists(key)>
					<cfthrow message="cfhoneypot: when action is '#action#', the atribute [#key#] is required!" />
				</cfif>
			</cfloop>
		<cfelse>
			<cfthrow message="cfhoneypot does not have an action '#htmleditformat(type)#'!" />
		</cfif>
		
		<!--- do action --->
		<cfif action eq "createLink">
			<cfset _createLink(caller=arguments.caller) />
		<cfelseif action eq "getThreatRating">
			<cfset _getIPThreat(caller=arguments.caller) />
		<cfelseif action eq "BlockThreat">
			<cfset _blockThreatIP(caller=arguments.caller) />
		<cfelseif action eq "isThreat">
			<cfset _isIPThreat(caller=arguments.caller) />
		</cfif>
		
		<cfreturn true />
	</cffunction>
	
	
	<cffunction name="_blockThreatIP" access="private" returntype="void">
		<cfargument name="caller" type="struct" required="yes" />
		<cfset var SpamBlocker = _getInitializedSpamBlockerCFC() />
		<cfset SpamBlocker.blockThreatUser(getAttribute('IP')) />
	</cffunction>
	
	
	<cffunction name="_isIPThreat" access="private" returntype="void">
		<cfargument name="caller" type="struct" required="yes" />
		<cfset var SpamBlocker = _getInitializedSpamBlockerCFC() />
		<cfset var stCheck = SpamBlocker.getUserThreat(getAttribute('IP')) />
		<cfset _insertValueIntoCaller(caller, stCheck) />
	</cffunction>


	<cffunction name="_getIPThreat" access="private" returntype="void">
		<cfargument name="caller" type="struct" required="yes" />
		<cfset var SpamBlocker = _getInitializedSpamBlockerCFC() />
		<cfset var stCheck = SpamBlocker.getThreatData(getAttribute('IP')) />
		<cfset _insertValueIntoCaller(caller, stCheck) />
	</cffunction>
	
	
	<cffunction name="_createLink" access="private" returntype="void">
		<cfargument name="caller" type="struct" required="yes" />
		<cfset var LinkGenerator = createObject("component", "components.LinkGenerator").init(honeyPotURL=getAttribute('url')) />
		<cfset var linkHtml = LinkGenerator.getHTML() />
		<cfset _insertValueIntoCaller(caller=caller, value=linkHtml, optionalToSTDOUT=true) />
	</cffunction>
	
	
	<cffunction name="onEndTag" output="yes" returntype="boolean">
		<cfargument name="attributes" type="struct">
		<cfargument name="caller" type="struct">				
  		<cfargument name="generatedContent" type="string">
		<cfreturn false/>	
	</cffunction>


	<cffunction name="_getInitializedSpamBlockerCFC" access="private" returntype="components.SpamBlocker">
		<cfset var SpamBlocker = createObject("component", "components.SpamBlocker") />
		<cfset SpamBlocker.honeypotKey = getAttribute('httpblkey') />
		<cfif attributeExists('threatnrs')>
			<cfset SpamBlocker.lsAbsoluteThreatNrs = getAttribute('threatnrs') />	
		</cfif>
		<cfif attributeExists('maxdaysago')>
			<cfset SpamBlocker.nIsNoThreatAfterDayNum = getAttribute('maxdaysago') />	
		</cfif>
		<cfif attributeExists('minimumThreatIndex')>
			<cfset SpamBlocker.nMinimumThreatScore = getAttribute('minimumThreatIndex') />	
		</cfif>
		<cfif attributeExists('blocktext')>
			<cfset SpamBlocker.sBlockText = getAttribute('blocktext') />	
		</cfif>
		<cfreturn SpamBlocker />
	</cffunction>
	
	
	<cffunction name="_insertValueIntoCaller" access="private" returntype="void">
		<cfargument name="caller" type="struct" required="yes" />
		<cfargument name="value" type="any" required="yes" hint="The value to insert into the caller page" />
		<cfargument name="optionalToSTDOUT" type="boolean" required="no" default="false" hint="If no 'variable' attr. is given, should we output the value to STDOUT or to a variable called 'cfhoneypot'" />
		<cfif attributeExists('variable')>
			<cfset arguments.caller[getAttribute('variable')] = arguments.value />
		<cfelseif arguments.optionalToSTDOUT>
			<cfoutput>#arguments.value#</cfoutput>
		<cfelse>
			<cfset arguments.caller["cfhoneypot"] = arguments.value />
		</cfif>
	</cffunction>
	

	<!---   attributes   --->
	<cffunction name="getAttribute" output="false" access="public" returntype="any">
		<cfargument name="key" required="true" type="String" />
		<cfreturn variables.attributes[key] />
	</cffunction>

	<cffunction name="attributeExists" output="false" access="public" returntype="boolean">
		<cfargument name="key" required="true" type="String" />
		<cfreturn structKeyExists(variables.attributes, key) />
	</cffunction>

</cfcomponent>
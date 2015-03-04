<cfcomponent name="cfdns" output="no">
<!---
	>> ALSO SEE THE COPYRIGHT LICENSE AT ./cfdns/DNS.cfc and other files within ./cfdns
	
	This software is licensed under the BSD license. See http://www.opensource.org/licenses/bsd-license.php
	Project page: http://www.lucee.nl/post.cfm/railo-custom-tag-cfdns
	Version: 1.0
	Copyright (c) 2011, Paul Klinkenberg (paul@ongevraagdadvies.nl)
	All rights reserved.
	
	Redistribution and use in source and binary forms, with or without modification,
	are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice, this list
	  of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright notice, this
	  list of conditions and the following disclaimer in the documentation and/or
	  other materials provided with the distribution.
    * Neither the name of the <ORGANIZATION> nor the names of its contributors may be
	  used to endorse or promote products derived from this software without specific
	  prior written permission.

	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY
	EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
	OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
	SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
	INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
	TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
	BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
	CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY
	WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
--->

	<!--- Meta data --->
	<cfset this.metadata.attributetype="fixed" />
	<cfset this.metadata.attributes={
		action:					{required:true,type:"string"}
		
		, variable:				{required:false,type:"string"}
		, output:				{required:false,type:"string", default:"query"}
		, host:					{required:false,type:"string"}
		, ip:					{required:false,type:"string"}
		, type:					{required:false,type:"string", default:"A"}
		, class:				{required:false,type:"string", default:"IN"}
		, server:				{required:false,type:"string"}
		, port:					{required:false,type:"number", default:53}
		, tcp:					{required:false,type:"boolean", default:0}
		, retries:				{required:false,type:"number", default:3}
		, timeout:				{required:false,type:"number", default:5}
	}>
	<cfset this.metadata.requiredAttributesPerAction = {
		getaddress: ['host']
		, gethostname: ['ip']
		, getdata: ['host']
		, lookup: ['host']
		, gettypes:[]
		, getclasses:[]
	} />
	
	<!--- explanations of these abbreviations can be found in the functions
	_getQueryTypes()and _getQueryClasses() within this cfc. --->
	<cfset variables.queryTypes = "ANY,A,IPSECKEY,LOC,MX,NS,PTR,SIG,SOA,SPF,SSHFP,TXT" />
	<cfset variables.queryClasses = "ANY,IN,CH,CHAOS,HS,HESIOD" />


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
		<cfset var action = getAttribute('action') />
		<cfset var outputFormat = getAttribute('output') />
		<cfset var DNSObj = _getDNSObject(arguments.attributes) />
		
		
		<!--- check type --->
		<cfif structKeyExists(this.metadata.requiredAttributesPerAction, action)>
			<cfset var attrName = "" />
			<cfloop array="#this.metadata.requiredAttributesPerAction[action]#" index="attrName">
				<cfif not attributeExists(attrName)>
					<cfthrow message="cfdns: when action is '#action#', the atribute [#attrName#] is required!" />
				</cfif>
			</cfloop>
		<cfelse>
			<cfthrow message="cfdns does not have an action '#htmleditformat(action)#'!" detail="Only actions '#structKeyList(this.metadata.requiredAttributesPerAction)#' are available." />
		</cfif>
		<!---  class correct? --->
		<cfif not listfind(variables.queryClasses, getAttribute('class'))>
			<cfthrow message="cfdns: atribute [class] can only be one of the values [#variables.queryClasses#]" />
		</cfif>
		<!---  type correct? --->
		<cfif not listfind(variables.queryTypes, getAttribute('type'))>
			<cfthrow message="cfdns: atribute [type] can only be one of the values [#variables.queryTypes#]" />
		</cfif>
		
		
		<!--- do action --->
		<cfset var returnedData = "" />
		
		<cfif action eq "gethostname">
			<cfinvoke component="#DNSObj#" method="getHostName" address="#getAttribute('ip')#" returnvariable="returnedData" />
			<cfset _insertValueIntoCaller(arguments.caller, returnedData, false) />
		<cfelseif action eq "gettypes">
			<cfset returnedData = _getQueryTypes() />
			<cfset _insertValueIntoCaller(arguments.caller, returnedData, false) />
		<cfelseif action eq "getclasses">
			<cfset returnedData = _getQueryClasses() />
			<cfset _insertValueIntoCaller(arguments.caller, returnedData, false) />
		<cfelse>
			<cftry>
				<cfinvoke component="#DNSObj#" method="doQuery" returnvariable="returnedData">
					<cfinvokeargument name="name" value="#getAttribute('host')#" />
					<cfinvokeargument name="type" value="#getAttribute('type')#" />
					<cfinvokeargument name="class" value="#getAttribute('class')#" />
					<cfif action neq "getdata" or outputFormat neq "xml">
						<cfinvokeargument name="returnRawResponse" value="true" />
					</cfif>
				</cfinvoke>
				<cfif action eq "getaddress" or action eq "lookup">
					<cfset var tmpRecords = returnedData.getSectionArray(javaCast("int", 1)) />
					<cfif not arrayLen(tmpRecords)>
						<cfset returnedData = "notfound"/>
					<cfelse>
						<cfset returnedData = ""/>
						<cfset var i = 0 />
						<!--- only 1 record, because the requested action expects one usable answer --->
						<cfloop from="1" to="1" index="i"><!--- #arrayLen(tmpRecords)# --->
							<cfset var type = DNSObj.getDNSTypeName(tmpRecords[i].getType())/>
							<cfif type eq "SOA">
								<cfset returnedData = tmpRecords[i].getHost()/>
							<cfelseif type eq "A">
								<cfset returnedData = tmpRecords[i].getAddress().getHostAddress()/>
							<cfelseif structKeyExists(tmpRecords[i], "getHost")>
								<cfset returnedData = tmpRecords[i].getHost()/>
							<cfelse>
								<cftry>
									<cfset returnedData = tmpRecords[i].getTarget()/>
									<cfcatch>
										<cfthrow message="cfdns: action [#action#] is invalid with type [#type#]" />
									</cfcatch>
								</cftry>
							</cfif>
							
							<cfset returnedData = rereplace(returnedData, "\.$", "") />
						</cfloop>
					</cfif>
				<cfelseif action eq "getdata">
					<cfif outputFormat eq "xml">
						<cfset returnedData = returnedData.getXMLDoc() />
					<cfelseif outputFormat eq "raw">
						<cfset returnedData = returnedData.toString() />
					<cfelse>
						<cfset var ra = returnedData.getSectionArray(javaCast("int", 1)) />
						<cfif outputFormat eq "array">
							<cfset returnedData = [] />
						<cfelse>
							<cfset returnedData = queryNew("") />
						</cfif>
						<cfset var j = 0 />
						<cfset var record = {} />
						
						<cfloop from="1" to="#arrayLen(ra)#" index="j">
							<cfset var record = {} />
							<cfset var type = DNSObj.getDNSTypeName(ra[j].getType())/>
							<cfset var class = DNSObj.getDNSClassName(ra[j].getDClass())/>
							<cfif ra[j].getTTL() gt 0>
								<cfset record["ttl"] = ra[j].getTTL()/>
							</cfif>
							<cfset record["type"] = type/>
							<cfset record["class"] = class/>
							<cfset record["name"] = ra[j].getName().toString() />
							<cfif isSimpleValue(ra[j].getAdditionalName()) and ra[j].getAdditionalName() neq "">
								<cfset record["additionalName"] = ra[j].getAdditionalName()/>
							</cfif>
							<cfif type eq "SOA">
								<cfset record["admin"] = ra[j].getAdmin().toString() />
								<cfset record["expire"] = ra[j].getExpire()/>
								<cfset record["host"] = ra[j].getHost().toString() />
								<cfset record["minimum"] = ra[j].getMinimum()/>
								<cfset record["refresh"] = ra[j].getRefresh()/>
								<cfset record["retry"] = ra[j].getRetry()/>
								<cfset record["serial"] = ra[j].getSerial()/>
							<cfelseif type eq "MX">
								<cfset record["priority"] = ra[j].getPriority()/>
								<cfset record["target"] = ra[j].getTarget().toString() />
							<cfelseif type eq "NS" or type eq "PTR">
								<cfset record["target"] = ra[j].getTarget().toString() />
							<cfelseif type eq "A">
								<cfset record["address"] = ra[j].getAddress().getHostAddress()/>
							<cfelseif type eq "CNAME">
								<cfset record["alias"] = ra[j].getAlias().toString() />
								<cfset record["target"] = ra[j].getTarget().toString() />
							</cfif>
							<cfif outputFormat eq "array">
								<cfset arrayAppend(returnedData, record) />
							<cfelse>
								<cfset queryAddRow(returnedData) />
								<cfset var key = "" />
								<cfloop collection="#record#" item="key">
									<cfif not structKeyExists(returnedData, key)>
										<cfset var tmpArr = [] />
										<cfset var i = 0 />
										<cfloop from="1" to="#returnedData.recordcount#" index="i"><cfset tmpArr[i] = '' /></cfloop>
										<cfset queryAddColumn(returnedData, key, "varchar", tmpArr) />
									</cfif>
									<cfset querySetCell(returnedData, key, record[key]) />
								</cfloop>
							</cfif>
						</cfloop>
					</cfif>
				</cfif>
				<cfset _insertValueIntoCaller(arguments.caller, returnedData, false) />
				<cfcatch>
					<cfdump eval=cfcatch />
					<cfthrow message="cfdns: error caught while doing a DNS query. Error details: #cfcatch.message# #cfcatch.detail#" />
				</cfcatch>
			</cftry>
		</cfif>
		
		<cfreturn true />
	</cffunction>


	<cffunction name="onEndTag" output="yes" returntype="boolean">
		<cfargument name="attributes" type="struct">
		<cfargument name="caller" type="struct">				
  		<cfargument name="generatedContent" type="string">
		<cfreturn false/>	
	</cffunction>


	<!---  TODO: cache this DNS object with the arguments as cache key --->
	<cffunction name="_getDNSObject" access="private" returntype="any" output="no">
		<cfargument name="resolverProperties" type="struct" required="no" default="#{}#" />
		<cfset var javaLoader = createObject("component", "cfdns.javaloader.JavaLoader").init(loadPaths=[getDirectoryFromPath(getCurrentTemplatePath()) & "cfdns#server.separator.file#lib#server.separator.file#dnsjava-2.0.3.jar"]) />
		<cfset var DNSObj = createObject("component", "cfdns.DNS").init(javaLoader=javaLoader, resolverProperties=arguments.resolverProperties) />
		<cfif structKeyExists(arguments.resolverProperties, "server") and len(arguments.resolverProperties.server)>
			<cfset DNSObj.setResolverProperty("servers", arguments.resolverProperties.server) />
		</cfif>
		<cfreturn DNSObj />
	</cffunction>
	

	<cffunction name="_getQueryTypes" access="private" returntype="array">
		<cfset var queryTypes = arrayNew(1)/>
		<cfset arrayAppend(queryTypes, listToArray("ANY,Any"))/>
		<cfset arrayAppend(queryTypes, listToArray("A,Address (A)"))/>
		<cfset arrayAppend(queryTypes, listToArray("IPSECKEY,IPSEC Key"))/>
		<cfset arrayAppend(queryTypes, listToArray("LOC,Location"))/>
		<cfset arrayAppend(queryTypes, listToArray("MX,Mail Exchanger (MX)"))/>
		<cfset arrayAppend(queryTypes, listToArray("NS,Name Server (NS)"))/>
		<cfset arrayAppend(queryTypes, listToArray("PTR,Pointer Record (PTR)"))/>
		<cfset arrayAppend(queryTypes, listToArray("SIG,Signature"))/>
		<cfset arrayAppend(queryTypes, listToArray("SOA,Start of Authority (SOA)"))/>
		<cfset arrayAppend(queryTypes, listToArray("SPF,Sender Policy Framework"))/>
		<cfset arrayAppend(queryTypes, listToArray("SSHFP,SSH Key Fingerprint"))/>
		<cfset arrayAppend(queryTypes, listToArray("TXT,Text"))/>
		<cfreturn queryTypes />
	</cffunction>

	<cffunction name="_getQueryClasses" access="private" returntype="array">
		<cfset var queryClasses = arrayNew(1)/>
		<cfset arrayAppend(queryClasses, listToArray("ANY,Any"))/>
		<cfset arrayAppend(queryClasses, listToArray("IN,Internet (IN)"))/>
		<cfset arrayAppend(queryClasses, listToArray("CH,Chaos (CH)"))/>
		<cfset arrayAppend(queryClasses, listToArray("CHAOS,Chaos (CHAOS)"))/>
		<cfset arrayAppend(queryClasses, listToArray("HS,Hesiod (HS)"))/>
		<cfset arrayAppend(queryClasses, listToArray("HESIOD,Hesiod (HESIOD)"))/>
		<cfreturn queryClasses />
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
			<cfset arguments.caller["cfdns"] = arguments.value />
		</cfif>
	</cffunction>


	<!---   attributes   --->
	<cffunction name="getAttribute" output="false" access="private" returntype="any">
		<cfargument name="key" required="true" type="String" />
		<cfreturn variables.attributes[arguments.key] />
	</cffunction>

	<cffunction name="setAttribute" output="false" access="private" returntype="void">
		<cfargument name="key" required="true" type="String" />
		<cfargument name="value" required="true" type="any" />
		<cfset variables.attributes[arguments.key] = arguments.value />
	</cffunction>

	<cffunction name="attributeExists" output="false" access="private" returntype="boolean">
		<cfargument name="key" required="true" type="String" />
		<cfreturn structKeyExists(variables.attributes, arguments.key) />
	</cffunction>

</cfcomponent>
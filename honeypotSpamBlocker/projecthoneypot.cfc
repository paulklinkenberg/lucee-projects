<cfcomponent displayname="Project honeypot functions">
	
	<cfset this.honeypotKey = "" />
	<!--- for next variables, see text underneath the cfc --->
	<cfset this.nIsNoThreatAfterDayNum = 60 />
	<cfset this.nMinimumThreatScore = 5 />
	<cfset this.lsAbsoluteThreatNrs = "4,5,6,7" />
	<cfset this.lsPossibleThreatNrs = "1,2,3" />
	<cfset this.sBlockText = '<h1>Blocked due to spam check</h1>
<p>You are not allowed to visit this website due to spamming on this and/or other websites</p>' />
	<cfset this.sNoticesMailAddress = "" />
	<cfset this.sLogTypes = "blocked,error,suspicious,lowthreatnumber,threattoomanydaysago" />
	
	<cfset variables.oInetAddress = CreateObject("java", "java.net.InetAddress") />
	<cfset variables.stCachedResults = structNew() />
	
	
	<cffunction name="blockThreatUser" returntype="void" access="public">
		<cfargument name="testIP" type="string" required="no" hint="When given, we use this IP instead of the cgi.remote_addr" />
		<cfset var stHoneypotScore = "" />
		<cfset var sIP = iif(structKeyExists(arguments, "testIP"), 'arguments.testIP', 'cgi.REMOTE_ADDR') />
		<cfif not len(this.honeypotKey)>
			<cfreturn />
		</cfif>
		
		<!--- if we already checked this user (and was not blocked), then stop here--->
		<cfif structKeyExists(session, "honeypotcheckdone") and session.honeypotcheckdone eq sIP and not structKeyExists(arguments, "testIP")>
			<cfreturn />
		</cfif>
		<!--- get the honeypot data for this IP --->
		<cfset stHoneypotScore = honeypotcheck(sIP) />
		
		<cfif listFind(this.lsAbsoluteThreatNrs, stHoneypotScore.type)>
			<!--- check extra refinement settings --->
			<cfif stHoneypotScore.threat lt this.nMinimumThreatScore>
				<cfset _addToLog(type="lowthreatnumber", text="NOT Blocked, because current threat number was #stHoneypotScore.threat#, and your required threat number is #this.nMinimumThreatScore#", score=stHoneypotScore, IP=sIP) />
			<cfelseif stHoneypotScore.days gte this.nIsNoThreatAfterDayNum>
				<cfset _addToLog(type="threattoomanydaysago", text="NOT Blocked, because last reported activity was #stHoneypotScore.days# days ago, and your setting is max. #this.nIsNoThreatAfterDayNum# ago", score=stHoneypotScore, IP=sIP) />
			<cfelse>
				<cfset _addToLog(type="blocked", text="", score=stHoneypotScore, IP=sIP) />
				<cfcontent reset="yes" type="text/html" />
				<cfoutput>#this.sBlockText#</cfoutput>
				<cfabort />
			</cfif>
		<cfelseif listFind(this.lsPossibleThreatNrs, stHoneypotScore.type)>
			<cfset _addToLog(type="suspicious", text="Not blocked", score=stHoneypotScore, IP=sIP) />
		</cfif>

		<!--- remember this check in session --->
		<cfif not structKeyExists(arguments, "testIP")>
			<cfset session.honeypotcheckdone = sIP />
		</cfif>
	</cffunction>
	
	
	<cffunction name="_addToLog" access="private" returntype="void" output="no">
		<cfargument name="type" type="string" required="yes" />
		<cfargument name="text" type="string" required="no" default="" />
		<cfargument name="HPScore" type="struct" required="no" />
		<cfargument name="IP" type="string" required="no" default="#cgi.REMOTE_ADDR#" />
		<cfset var sLogFilePath = GetCurrentTemplatePath() & ".#arguments.type#.log" />
		<cfset var sLogLine = now() & "	" & arguments.type & "	" & arguments.IP & "	" & arguments.text />
		<!--- only log it if the setting says so --->
		<cfif listFind(this.sLogTypes, arguments.type)>
			<cfif structKeyExists(arguments, "HPScore")>
				<cfset sLogLine = sLogLine & "	" & structToList(arguments.HPScore) />
			</cfif>
			<cflock name="#sLogFilePath#" timeout="5" throwontimeout="no">
				<cffile action="append" file="#sLogFilePath#" output="#sLogLine#" addnewline="yes" />
			</cflock>
		</cfif>
		
		<!--- mail admin? --->
		<cfif arguments.type eq "blocked" and len(this.sNoticesMailAddress)>
			<cfmail to="#this.sNoticesMailAddress#" from="#this.sNoticesMailAddress#"
			subject="honeypotSpamBlocker #arguments.type# #cgi.HTTP_HOST#" type="html">
				date: #dateformat(now(), 'long')#<br />
				ip address: #arguments.IP#<br />
				<cfdump var="#arguments#" label="arguments" />
				<cfdump var="#form#" label="form" />
				<cfdump var="#url#" label="url" />
				<cfdump var="#cgi#" label="cgi" />
			</cfmail>
		</cfif>
	</cffunction>
	
	
	<cffunction name="gethostaddress" returntype="string">
		<cfargument name="host" required="Yes" type="string" />
		<cfset var sHostAddress = "" />
		<!--- Get the different IP values --->
		<cfif not structKeyExists(variables.stCachedResults, arguments.host)>
			<!--- adding a lock per ip address, so simultanious requests can't go into a race condition --->
			<cflock name="gethostaddress_#arguments.host#" timeout="5" throwontimeout="yes">
				<!--- clear cache? --->
				<cfif not structKeyExists(variables.stCachedResults, "cacheQuantity")
				or variables.stCachedResults.cacheQuantity gt 10*1000>
					<cfset variables.stCachedResults = structNew() />
					<cfset variables.stCachedResults.cacheQuantity = 0 />
				</cfif>
				<cftry>
					<cfset sHostAddress = variables.oInetAddress.getByName(arguments.host).getHostAddress() />
					<cfcatch>
						<cfif cfcatch.Type eq "Java.net.unknownhostexception">
							<cfset sHostAddress = "127.0.0.255" />
						<cfelse>
							<cfrethrow />
						</cfif>
					</cfcatch>
				</cftry>
				<cfset structInsert(variables.stCachedResults, arguments.host, sHostAddress, true) />
				<cfset variables.stCachedResults.cacheQuantity = variables.stCachedResults.cacheQuantity+1 />
			</cflock>
		</cfif>
		<!--- Return result --->
		<cfreturn variables.stCachedResults[arguments.host] />
	</cffunction>


	<cffunction name="reverseip" returntype="string">
		<cfargument name="ip" required="Yes" type="string" />
		<cfset var aIp = listToArray(arguments.ip,".")>
		<!--- Return IP reversed --->
		<cfreturn aIp[4] & "." & aIp[3] & "." & aIp[2] & "." & aIp[1] />
	</cffunction>
	
	
	<cffunction name="honeypotcheck" returntype="struct" hint="Check Project HoneyPot http:BL">
		<cfargument name="ip" required="yes" type="string">
		<cfset var aVal = "">
		<cfset var stRet = structNew() />
		<cfset var sDnsAddress = "#this.honeypotKey#.#reverseip(arguments.ip)#.dnsbl.httpbl.org." />

		<!--- Get the different IP values --->
		<cfset aVal = listToArray(gethostaddress(sDnsAddress),".")>
  
		<!--- if an error was returned from PH --->
		<cfif aVal[1] neq "127">
			<cfset _addToLog(type="error", text="Checking #sDnsAddress#, result should start with '127.', but instead was: '#arrayToList(aVal, '.')#'", ip=arguments.IP) />
			<cfset aVal = listToArray("0.0.0.255", ".") />
		</cfif>
		
		<!--- Set the return values --->
		<cfset stRet.days = aVal[2]>
		<cfset stRet.threat = aVal[3]>
		<cfset stRet.type = aVal[4]>
		
		<!--- Get the HP info message --->
		<cfswitch expression="#stRet.type#">
			<cfcase value="0">
				<cfset stRet.message = "Search Engine (0)">
			</cfcase>
			<cfcase value="1">
				<cfset stRet.message = "Suspicious (1)">
			</cfcase>
			<cfcase value="2">
				<cfset stRet.message = "Harvester (2)">
			</cfcase>
			<cfcase value="3">
				<cfset stRet.message = "Suspicious & Harvester (1+2)">
			</cfcase>
			<cfcase value="4">
				<cfset stRet.message = "Comment Spammer (4)">
			</cfcase>
			<cfcase value="5">
				<cfset stRet.message = "Suspicious & Comment Spammer (1+4)">
			</cfcase>
			<cfcase value="6">
				<cfset stRet.message = "Harvester & Comment Spammer (2+4)">
			</cfcase>
			<cfcase value="7">
				<cfset stRet.message = "Suspicious & Harvester & Comment Spammer (1+2+4)">
			</cfcase>
			<cfdefaultcase>
				<cfset stRet.message = "IP-Address not known">
			</cfdefaultcase>
		</cfswitch> 
		
		<cfreturn stRet>
	</cffunction>


<cfscript>
	/**
	* Converts struct into delimited key/value list.
	*
	* @param s      Structure. (Required)
	* @param delim      List delimeter. Defaults to a comma. (Optional)
	* @return Returns a string.
	* @author Greg Nettles (gregnettles@calvarychapel.com)
	* @version 2, July 25, 2006
	*/
	function structToList(s) {
		var delim = "&";
		var i = 0;
		var newArray = structKeyArray(arguments.s);
		
		if (arrayLen(arguments) gt 1) delim = arguments[2];
		
		for(i=1;i lte structCount(arguments.s);i=i+1) newArray[i] = newArray[i] & "=" & arguments.s[newArray[i]];
		
		return arraytoList(newArray,delim);
	}
</cfscript>

</cfcomponent> 
<!--- documentation from http://www.projecthoneypot.org/httpbl_api.php:

		this.nIsNoThreatAfterDayNum
The second octet (3  in the example above) represents the number of days since last activity. 
In the example above, it has been 3 days since the last time the queried IP address saw activity 
on the Project Honey Pot network. This value ranges from 0 days to 255 days. This value is useful 
in helping you assess how "stale" the information provided by http:BL is and therefore the extent 
to which you should rely on it.

		this.nMinimumThreatScore:
The third octet (5  in the example above) represents a threat score for IP. 
This score is assigned internally by Project Honey Pot based on a number of factors including
the number of honey pots the IP has been seen visiting, the damage done during those visits
 (email addresses harvested or forms posted to), etc. The range of the score is from 0 to 255,
  where 255 is extremely threatening and 0 indicates no threat score has been assigned. In the 
  example above, the IP queried has a threat score of "5", which is relatively low. While a rough
   and imperfect measure, this value may be useful in helping you assess the threat posed by a visitor to your site.

		this.lsAbsoluteThreatNrs:
		this.lsPossibleThreatNrs:
The fourth octet (1  in the example above) represents the type of visitor. Defined types include: 
"search engine," "suspicious," "harvester," and "comment spammer." Because a visitor may belong to 
multiple types (e.g., a harvester that is also a comment spammer) this octet is represented as a bitset 
with an aggregate value from 0 to 255. In the example above, the type is listed as 1, which means 
the visitor is merely "suspicious." A chart outlining the different types appears below. This value 
is useful because it allows you to treat different types of robots differently.
Value	Meaning
0	Search Engine (0)
1	Suspicious (1)
2	Harvester (2)
3	Suspicious & Harvester (1+2)
4	Comment Spammer (4)
5	Suspicious & Comment Spammer (1+4)
6	Harvester & Comment Spammer (2+4)
7	Suspicious & Harvester & Comment Spammer (1+2+4)
>7	[Reserved for Future Use]
--->
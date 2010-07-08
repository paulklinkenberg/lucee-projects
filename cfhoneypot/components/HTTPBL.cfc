<cfcomponent displayname="Project honeypot HTTP:BL functionality">
	
	<cfset this.honeypotKey = "" />

	<cfset variables.oInetAddress = CreateObject("java", "java.net.InetAddress") />
	<cfset variables.stCachedResults = structNew() />
	
	
	<cffunction name="gethostaddress" returntype="string">
		<cfargument name="host" required="Yes" type="string" />
		<cfset var sHostAddress = "" />
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
		<!--- Return result --->
		<cfreturn sHostAddress />
	</cffunction>


	<cffunction name="reverseip" returntype="string">
		<cfargument name="ip" required="Yes" type="string" />
		<cfset var aIp = listToArray(arguments.ip,".")>
		<!--- Return IP reversed --->
		<cfreturn aIp[4] & "." & aIp[3] & "." & aIp[2] & "." & aIp[1] />
	</cffunction>
	
	
	<cffunction name="honeypotcheck" returntype="struct" hint="Check Project HoneyPot http:BL">
		<cfargument name="ip" required="yes" type="string" />
		<cfset var aVal = "">
		<cfset var stRet = structNew() />
		<cfset var sDnsAddress = "#this.honeypotKey#.#reverseip(arguments.ip)#.dnsbl.httpbl.org." />

		<!--- Get the different IP values --->
		<cfset aVal = listToArray(gethostaddress(sDnsAddress),".")>
  
		<!--- if an error was returned from PH --->
		<cfif aVal[1] neq "127">
			<cfset stRet.error = "Checking #sDnsAddress#, result should start with '127.', but instead was: '#arrayToList(aVal, '.')#'" />
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
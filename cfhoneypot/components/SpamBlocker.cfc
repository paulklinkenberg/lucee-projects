<cfcomponent displayname="Project honeypot functions">
	
	<cfset variables.oHTTPBL = createObject("component", "HTTPBL") />
	
	<cfset this.honeypotKey = "" />
	
	<!--- for next variables, see text underneath the cfc --->
	<cfset this.nIsNoThreatAfterDayNum = 60 />
	<cfset this.nMinimumThreatScore = 5 />
	<cfset this.lsAbsoluteThreatNrs = "4,5,6,7" />
	<cfset this.sBlockText = '<h1>Blocked due to spam check</h1>
<p>You are not allowed to visit this website due to spamming on this and/or other websites</p>' />
	
	<cfset variables.oInetAddress = CreateObject("java", "java.net.InetAddress") />
	
	
	<cffunction name="blockThreatUser" returntype="void" access="public">
		<cfargument name="IP" type="string" required="yes" />
		<cfset var stThreat = getUserThreat(arguments.IP) />
		<cfif stThreat.isthreat>
			<cfcontent reset="yes" type="text/html" />
			<cfoutput>#this.sBlockText#</cfoutput>
			<cfabort />
		</cfif>
	</cffunction>
	
	
	<cffunction name="getThreatData" returntype="struct" access="public">
		<cfargument name="IP" type="string" required="yes" />
		<cfset var stHoneypotScore = "" />
		<cfset var stReturn = {} />
		<cfif not len(this.honeypotKey)>
			<cfthrow message="HoneypotKey is required!" />
		</cfif>
		
		<!--- get the honeypot data for this IP --->
		<cfset variables.oHTTPBL.honeypotKey = this.honeypotKey />
		<cfset stHoneypotScore = variables.oHTTPBL.honeypotcheck(arguments.IP) />
		
		<cfreturn {threatlevel=stHoneypotScore.threat
			, daysago=stHoneypotScore.days
			, typenr=stHoneypotScore.type
			, description=stHoneypotScore.message
			, IP=arguments.IP} />
	</cffunction>
	
	<cffunction name="getUserThreat" returntype="struct" access="public">
		<cfargument name="IP" type="string" required="yes" />
		<cfset var stHoneypotScore = "" />
		<cfset var stReturn = {} />
		<cfif not len(this.honeypotKey)>
			<cfthrow message="HoneypotKey is required!" />
		</cfif>
		
		<!--- get the honeypot data for this IP --->
		<cfset variables.oHTTPBL.honeypotKey = this.honeypotKey />
		<cfset stHoneypotScore = variables.oHTTPBL.honeypotcheck(arguments.IP) />
		
		<cfset stReturn = {isthreat=false
			, threatlevel=stHoneypotScore.threat
			, daysago=stHoneypotScore.days
			, typenr=stHoneypotScore.type
			, description=stHoneypotScore.message
			, IP=arguments.IP} />
		<cfif structKeyExists(stHoneypotScore, "error")>
			<cfset stReturn.error = stHoneypotScore.error />
		</cfif>
		
		<cfif listFind(this.lsAbsoluteThreatNrs, stHoneypotScore.type)>
			<!--- check extra refinement settings --->
			<cfif stHoneypotScore.threat lt this.nMinimumThreatScore>
				<cfset stReturn.warning = "NOT Blocked, because current threat number was #stHoneypotScore.threat#, and your required threat number is #this.nMinimumThreatScore#" />
			<cfelseif stHoneypotScore.days gte this.nIsNoThreatAfterDayNum>
				<cfset stReturn.warning = "NOT Blocked, because last reported activity was #stHoneypotScore.days# days ago, and your setting is max. #this.nIsNoThreatAfterDayNum# ago" />
			<cfelse>
				<cfset stReturn.isthreat = true />
			</cfif>
		</cfif>

		<cfreturn stReturn />
	</cffunction>


</cfcomponent><!--- documentation from http://www.projecthoneypot.org/httpbl_api.php:

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
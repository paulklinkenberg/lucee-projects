<cfcomponent output="no">
	<!---
		Known Contributors
		Dain Anderson - Inital Version
		Ray Camden - Enhanced for BlogCFC
		Dale Fraser - Converted to Tag Based for learncf.com added Line numbering option
		Steve Onnis - Fixed some problems with the regular expressions
		
		March 9, 2009, Paul Klinkenberg, www.coldfusiondeveloper.nl
		- totally updated the code, added css / function names / green quoted strings / regex safety / keepTabs arg. / quotes within quotes, and the caching mechanism.
		April 14, 2009, Paul Klinkenberg, www.coldfusiondeveloper.nl
		- Fixed a bug which impacted the way in which quoted elements of css strings were shown, i.e. <b style="font-family: 'Arial'">
	--->

	<!--- Color Code From File --->
	<cffunction name="colorFile" output="false" returntype="string" access="public">
		<cfargument name="fileName" type="string" required="true" />
		<cfargument name="lineNumbers" type="boolean" default="true" />
		<cfargument name="keepTabs" type="boolean" default="true" hint="Do we need to convert tabs to spaces, or keep em as is?" />
		<cfargument name="useCaching" type="boolean" default="true" />
		<cfset var local = structNew() />
		<!--- read the file --->
		<cffile action="read" file="#arguments.fileName#" variable="local.fileContents" />
		
		<!--- get and return the colored data --->
		<cfif arguments.useCaching>
			<cfreturn cachedColorString(dataString=local.fileContents, lineNumbers=arguments.lineNumbers, keepTabs=arguments.keepTabs) />
		<cfelse>
			<cfreturn colorString(dataString=local.fileContents, lineNumbers=arguments.lineNumbers, keepTabs=arguments.keepTabs, useCaching=false) />
		</cfif>
	</cffunction>
	

	<!--- cachedColorString --->
	<cffunction name="cachedColorString" output="false" returntype="string" access="public" hint="Returns a color-coded string, and also caches the colored result, for much improved performance.">
		<cfargument name="dataString" type="string" required="true" />
		<cfargument name="lineNumbers" type="boolean" default="true" />
		<cfargument name="keepTabs" type="boolean" default="true" hint="Do we need to convert tabs to spaces, or keep em as is?" />
		<cfset var local = structNew() />

		<!--- max. amount of cached strings --->
		<cfset local.maxCached_num = 10 />
		<cfset local.cache_str = "lineNumbers=#lineNumbers#|keepTabs=#keepTabs#|#dataString#" />
		<!--- we'll try to set it to application where possible --->
		<cfset local.cacheScope_struct = server />
		
		<!--- check if an application scope is available --->
		<cfif isDefined("application") and isStruct(application) and structKeyExists(application, "applicationName")>
			<cfset local.cacheScope_struct = application />
		</cfif>
		<cfparam name="local.cacheScope_struct.cachedColorStrings" default="#arrayNew(1)#" />
		
		<!---if url.killCache, then ... kill the cache --->
		<cfif structKeyExists(url, "killCache")>
			<cfset local.cacheScope_struct.cachedColorStrings = arrayNew(1) />
		</cfif>
		
		<!---check the cache for the existence of the requested dataString --->
		<cfloop from="1" to="#arrayLen(local.cacheScope_struct.cachedColorStrings)#" index="local.arrIndex">
			<cfif local.cacheScope_struct.cachedColorStrings[local.arrIndex].original eq local.cache_str>
				<cfreturn local.cacheScope_struct.cachedColorStrings[local.arrIndex].colored & "<!-- retrieved from cache -->" />
			</cfif>
		</cfloop>
		
		<!---not found eey? Then we'll get it now, and set it in a struct which we will cache. --->
		<cfset local.cache_struct = structNew() />
		<cfset local.colored_str = colorString(dataString=arguments.dataString, lineNumbers=arguments.lineNumbers, keepTabs=arguments.keepTabs, useCaching=false) />
		<cfset structInsert(local.cache_struct, "colored", local.colored_str) />
		<cfset structInsert(local.cache_struct, "original", local.cache_str) />

		<!--- add it as the first of the array --->
		<cfset arrayPrepend(local.cacheScope_struct.cachedColorStrings, local.cache_struct) />
		
		<!--- delete any cached elements which exceed the max-cache-num --->
		<cfloop condition="local.maxCached_num lt arrayLen(local.cacheScope_struct.cachedColorStrings)">
			<cfset arrayDeleteAt(local.cacheScope_struct.cachedColorStrings, local.maxCached_num+1) />
		</cfloop>

		<cfreturn local.colored_str & "<!-- added to cache -->" />
	</cffunction>
	
	
	<cffunction name="_giveTimer" access="private" returntype="string">
		<cfargument name="text" type="string" required="no" default="" />
		<cfargument name="init" type="boolean" default="false" />
		<cfset var local = structNew() />

		<cfif init>
			<cfset request.lastTimer = getTickCount() />
		</cfif>
		
		<cfset local.return_str = " #text# #getTickCount()-request.lastTimer# ms." />
		<cfset request.lastTimer = getTickCount() />
		<cfreturn local.return_str />
	</cffunction>
	
	<!--- Color Code From String --->
	<cffunction name="colorString" output="false" returntype="string" access="public">
		<cfargument name="dataString" type="string" required="true" />
		<cfargument name="lineNumbers" type="boolean" default="true" />
		<cfargument name="keepTabs" type="boolean" default="true" hint="Do we need to convert tabs to spaces, or keep em as is?" />
		<cfargument name="useCaching" type="boolean" default="true" />
		<cfset var local = structNew() />
		
		<cfset local.startTimer = getTickCount() />
		<cfset local.timerText_str = "" />
		<cfset _giveTimer(init=true) />
		<cfset local.data = arguments.dataString />
		<!---these two arrays will temp. contain all comments and quoted strings
		, so we won't use them in other replacements further on in the code. --->
		<cfset local.quotedStrings_arr = arrayNew(1) />
		<cfset local.comments_arr = arrayNew(1) />
		
		<cfif arguments.useCaching>
			<cfreturn cachedColorString(argumentCollection=arguments) />
		</cfif>
		
		<!--- replace 4 spaces with tab --->
		<cfif not arguments.keepTabs or arguments.lineNumbers>
			<cfset local.data = rereplace(local.data, " {3,4}", chr(9), "all") />
		</cfif>
		
		<!---replace all ampersands, so they are always shown in the html. --->
		<cfset local.data = replace(local.data, "&", "&amp;", "all") />
		
		<!--- since we're using raquo's and laquo's, we must first eliminate them from the original string  --->
		<cfset local.data = replaceList(local.data, "«,»", "&laquo;,&raquo;") />
		
		<!--- Convert special characters so they do not get interpreted literally italicize and boldface --->
		<cfset local.data = REReplaceNoCase(local.data, "(&amp;[a-z0-9]{2,};)", "«strong»«em»\1«/em»«/strong»", "all") />
		
		<!---timer--->
		<cfset local.timerText_str = listAppend(local.timerText_str, _giveTimer("ampersands and tabs")) />
		
		<!--- Convert all multi-line script comments to yellow background --->
		<!--- also, temp. save them in a different array, so we don't use it's contents in the rest of this script. --->
		<cfset local.reg = "(<\!\-\-\-.*?\-\-\->)" />
		<cfloop condition="refind(local.reg, local.data)">
			<cfset local.found_struct = refind(local.reg, local.data, 1, true) />
			<cfset local.found_str = mid(local.data, local.found_struct.pos[1], local.found_struct.len[1]) />
			<cfset arrayAppend(local.comments_arr, "«span style=""color:##333333;background-color:##ffff99""»" & local.found_str & "«/span»") />
			<cfset local.data = replace(local.data, local.found_str, "__PLACEHOLDER_COMMENT_#arrayLen(local.comments_arr)#__") />
		</cfloop>
		<!---get all html comments --->
		<!--- except for the comments in script and style tags --->
		<cfset local.data = reReplaceNoCase(local.data, "(<(script|style)[^>]*>[[:space:]]*(//)?[[:space:]]*)<!\-\-", "\1&lt;!--", "all") />
		
		<cfset local.reg = "(<\!\-\-.*?\-\->)" />
		<cfloop condition="refind(local.reg, local.data)">
			<cfset local.found_struct = refind(local.reg, local.data, 1, true) />
			<cfset local.found_str = mid(local.data, local.found_struct.pos[1], local.found_struct.len[1]) />
			<cfset arrayAppend(local.comments_arr, "«span style=""color:##9a9a9a""»" & local.found_str & "«/span»") />
			<cfset local.data = replace(local.data, local.found_str, "__PLACEHOLDER_COMMENT_#arrayLen(local.comments_arr)#__") />
		</cfloop>
		
		<!--- Convert all single-line script comments to gray --->
		<cfset local.reg = "([\r\n][[:space:]]*//[^\r\n]*)" />
		<cfloop condition="refind(local.reg, local.data)">
			<cfset local.found_struct = refind(local.reg, local.data, 1, true) />
			<cfset local.found_str = mid(local.data, local.found_struct.pos[1], local.found_struct.len[1]) />
			<cfset arrayAppend(local.comments_arr, "«span style=""color:##9a9a9a""»«em»" & local.found_str & "«/em»«/span»") />
			<cfset local.data = replace(local.data, local.found_str, "__PLACEHOLDER_COMMENT_#arrayLen(local.comments_arr)#__") />
		</cfloop>

		<!--- Convert all multi-line script comments to gray --->
		<cfset local.reg = "(/\*.*?\*/)" />
		<cfloop condition="refind(local.reg, local.data)">
			<cfset local.found_struct = refind(local.reg, local.data, 1, true) />
			<cfset local.found_str = mid(local.data, local.found_struct.pos[1], local.found_struct.len[1]) />
			<cfset arrayAppend(local.comments_arr, "«span style=""color:##808080""»«em»" & local.found_str & "«/em»«/span»") />
			<cfset local.data = replace(local.data, local.found_str, "__PLACEHOLDER_COMMENT_#arrayLen(local.comments_arr)#__") />
		</cfloop>

		<!---timer--->
		<cfset local.timerText_str = listAppend(local.timerText_str, _giveTimer("stripped all comments")) />

		<!--- replace single quotes within double quoted strings in cf-tags to html entities, i.e. myvar="one 'big' var" --->
		<cfset local.reg = "(<[a-z0-9_]+[[:space:]][^'"">]*" & "([^'"">]*(['""])[^'""]*\3)*[^'"">]*""[^'""]*)'" />
		<cfloop condition="reFindNoCase(local.reg, local.data)">
			<cfset local.data = REReplaceNoCase(local.data, local.reg, "\1&acute;", "all") />
		</cfloop>
		<!--- replace double quotes within single quoted strings in cf-tags to html entities, i.e. myvar='one "big" var' --->
		<cfset local.reg = "(<[a-z0-9_]+[[:space:]][^'"">]*" & "([^'"">]*(['""])[^'""]*\3)*[^'"">]*'[^'""]*)""" />
		<cfloop condition="reFindNoCase(local.reg, local.data)">
			<cfset local.data = REReplaceNoCase(local.data, local.reg, "\1&quot;", "all") />
		</cfloop>
		
		<!---timer--->
		<cfset local.timerText_str = listAppend(local.timerText_str, _giveTimer("quotes within quotes")) />

		<!--- replace double double quotes within double quoted strings in cf-tags to html entities, i.e. myvar="one ""big"" var" --->
		<!--- This one is mucho faster, but can give inaccurate results (i.e. <cfset t = """" />)
		: <cfset local.reg = """""([^""]+""[^""])" /> --->
		<cfset local.reg = "(<[a-z0-9_]+[[:space:]][^'"">]*" & "([^'"">]*(['""])[^'""]*\3)*[^'"">]*""[^""]*)""""" />
		<cfloop condition="reFindNoCase(local.reg, local.data)">
			<cfset local.data = REReplaceNoCase(local.data, local.reg, "\1&quot;&quot;", "all") />
		</cfloop>
		
		<!--- replace double single quotes within single quoted strings in cf-tags to html entities, i.e. myvar='one ''big'' var' --->
		<!--- This one is mucho faster, but can give inaccurate results (i.e. <cfset t = '''' />)
		: <cfset local.reg = "''([^']+'[^'])" /> --->
		<cfset local.reg = "(<[a-z0-9_]+[[:space:]][^'"">]*" & "([^'"">]*(['""])[^'""]*\3)*[^'"">]*'[^']*)''" />
		<cfloop condition="reFindNoCase(local.reg, local.data)">
			<cfset local.data = REReplaceNoCase(local.data, local.reg, "\1&acute;&acute;", "all") />
		</cfloop>

		<!---timer--->
		<cfset local.timerText_str = listAppend(local.timerText_str, _giveTimer("2 quotes within quotes")) />

		<!--- replace '<' within quotes to html entities --->
		<cfset local.reg = "(<[^>'""]+(([""'])[^'""]*\3[^""'>]+)*['""][^'""]*)<" />
		<cfloop condition="reFindNoCase(local.reg, local.data)">
			<cfset local.data = REReplaceNoCase(local.data, local.reg, "\1&lt;", "all") />
		</cfloop>
		<!--- replace '>' within quotes to html entities --->
		<cfset local.reg = "(<[^>'""]+(([""'])[^'""]*\3[^""'>]+)*['""][^'""]*)>" />
		<cfloop condition="reFindNoCase(local.reg, local.data)">
			<cfset local.data = REReplaceNoCase(local.data, local.reg, "\1&gt;", "all") />
		</cfloop>

		<!---timer--->
		<cfset local.timerText_str = listAppend(local.timerText_str, _giveTimer("lt and gt within strings")) />
		
		<!--- Convert many standalone (not within quotes) numbers to red, ie. myValue = 0 and myArr[a+1] = 17*3/34 --->
		<cfset local.reg = "(<[^>]+)(((gt|lt|eq|is|or|=)[[:space:]]|[,\(\)/\-\+*\[\{])[[:space:]]*)([0-9]+)([^'""])" />
		<cfloop condition="refind(local.reg, local.data)">
			<cfset local.data = REReplaceNoCase(local.data, local.reg, "\1\2«span style=$color:##ff0000$»\5«/span»\6", "all") />
		</cfloop>
		
		<!---convert coldfusion operators to blue --->
		<cfset local.reg = "(<cf(if|elseif|set)[^>]*?[[:space:]])(not|gte?|lte?|n?eq|is|or|=)([[:space:]])" />
		<cfloop condition="reFindNoCase(local.reg, local.data)">
			<cfset local.data = REReplaceNoCase(local.data, local.reg, "\1«span style=$color:##0000ff$»\3«/span»\4", "all") />
		</cfloop>

		<!---timer--->
		<cfset local.timerText_str = listAppend(local.timerText_str, _giveTimer("numbers and operators")) />
		
		<!--- quoted function variables: green. To make it a bit simpler, I don't expect breaks in the argument list of a called function. --->
		<cfset local.reg = "([[:space:]\(=][a-z0-9_\.]+\(([^\r\n>]*?,)?[[:space:]]*)(['""])([^\r\n>]*?)\3([[:space:]\),])" />
		<cfloop condition="reFindNoCase(local.reg, local.data)">
			<cfset local.found_struct = refindNoCase(local.reg, local.data, 1, true) />
			<cfset local.foundStart_str = mid(local.data, local.found_struct.pos[2], local.found_struct.len[2]) />
			<cfset local.found_str = mid(local.data, local.found_struct.pos[4], 2+local.found_struct.len[5]) />
			<cfset arrayAppend(local.quotedStrings_arr, "«span style=""color:##006600""»" & local.found_str & "«/span»") />
			<cfset local.data = replace(local.data, local.foundStart_str & local.found_str, local.foundStart_str & "__PLACEHOLDER_STRING_#arrayLen(local.quotedStrings_arr)#__", "all") />
		</cfloop>

		<!--- Convert all other quoted values to blue (other = not the green ones) --->
		<cfset local.reg = "(['""])[^'""]*\1" />
		<cfloop condition="reFind(local.reg, local.data)">
			<cfset local.found_struct = refind(local.reg, local.data, 1, true) />
			<cfset local.found_str = mid(local.data, local.found_struct.pos[1], local.found_struct.len[1]) />
			<cfset arrayAppend(local.quotedStrings_arr, "«span style=""color:##0000ee""»" & local.found_str & "«/span»") />
			<cfset local.data = replace(local.data, local.found_str, "__PLACEHOLDER_STRING_#arrayLen(local.quotedStrings_arr)#__", "all") />
		</cfloop>
		
		<!---reset the removed quotes --->
		<cfset local.data = REReplaceNoCase(local.data, "style=\$color(.*?)\$", "style=""color\1""", "ALL") />
		
		<!---timer--->
		<cfset local.timerText_str = listAppend(local.timerText_str, _giveTimer("quoted strings")) />

		<!--- Convert function names to blue, and it's brackets dark blue --->
		<cfset local.reg = "([[:space:]\(=,])(«/span»)?([a-z0-9_\.]+)\((|.*?[^«])\)" />
		<cfloop condition="reFindNoCase(local.reg, local.data)">
			<!---one of the span's is not ended correctly. This is on purpose, and will be reset later on. --->
			<cfset local.data = reReplaceNoCase(local.data, local.reg, "\1\2«span style=""color:##0000ff""»\3«/span»«span style=""color:##000099""»(«/span»\4«span style=""color:##000099""«)«/span»", "all") />
		</cfloop>
		<cfset local.data = replace(local.data, """«)«/span»", """»)«/span»", "all") />
		
		<!---timer--->
		<cfset local.timerText_str = listAppend(local.timerText_str, _giveTimer("function names")) />

		<!--- Convert normal tags to navy blue --->
		<cfset local.data = REReplaceNoCase(local.data, "<(/?)((a[a-z]|b|c(e|i|od|om)|!?d|e|f[ron]|h|i|[k-s]|t[eit]|[u-x])[^>]*)>", "«span style=""color:##000080""»<\1\2>«/span»", "all") />
	
		<!--- Convert all table-related tags to teal --->
		<cfset local.data = REReplaceNoCase(local.data, "(</?(t[ardbfh]|c(ap|ol))[^>]*>)", "«span style=""color:##008080""»\1«/span»", "all") />
	
		<!--- Convert all form-related tags to orange --->
		<cfset local.data = REReplaceNoCase(local.data, "(</?(bu|f(i|or)|i[ns]|l[ae]|se|op|te)[^>]*>)", "«span style=""color:##ff8000""»\1«/span»", "all") />
	
		<!--- Convert all 'a' tags to green --->
		<cfset local.data = REReplaceNoCase(local.data, "(</?a([[:space:]][^>]*)?>)", "«span style=""color:##008000""»\1«/span»", "all") />
	
		<!--- Convert all image and style tags to purple --->
		<cfset local.data = REReplaceNoCase(local.data, "(</?(img|style)([[:space:]][^>]*)?>)", "«span style=""color:##800080""»\1«/span»", "all") />
	
		<!--- Convert all ColdFusion, SCRIPT and WDDX tags to maroon --->
		<cfset local.data = REReplaceNoCase(local.data, "(</?(cf|scrip|wdd)[^[:space:]>]+[^>]*>)", "«span style=""color:##800000""»\1«/span»", "all") />
		<!--- but for some tags, only color the tags themselves --->
		<cfset local.data = REReplaceNoCase(local.data, "(<cf(set|if|elseif))([[:space:]][^>]+?)(/?>)", "\1«/span»\3«span style=""color:##800000""»\4", "all") />
		
		<!---timer--->
		<cfset local.timerText_str = listAppend(local.timerText_str, _giveTimer("all other tags")) />

		<!--- css style: pink --->
		<cfset local.reg = "(<style[^>]*>(«[^»]+»)*)(.*?)((«[^»]+»)*</style>)" />
		<cfset local.findpos = 0 />
		<cfloop condition="refindNoCase(local.reg, local.data, local.findpos+1)">
			<cfset local.found_arr = refindNoCase(local.reg, local.data, local.findpos+1, true) />
			<!---remember the 'findpos', so we don't enter eternal loop --->
			<cfset local.findpos = local.found_arr.pos[1] />
			<!--- get the found css --->
			<cfset local.startStyle_str = mid(local.data, local.found_arr.pos[2], local.found_arr.len[2]) />
			<cfset local.style_str = mid(local.data, local.found_arr.pos[4], local.found_arr.len[4]) />
			<cfset local.endStyle_str = mid(local.data, local.found_arr.pos[5], local.found_arr.len[5]) />
			
			<cfset local.data = replace(local.data, local.startStyle_str & local.style_str & local.endStyle_str, local.startStyle_str & _formatCss(local.style_str) & local.endStyle_str) />
		</cfloop>

		<!---timer--->
		<cfset local.timerText_str = listAppend(local.timerText_str, _giveTimer("css")) />

		<!---now re-add all quoted strings we erased from the data --->
		<cfloop to="1" from="#arrayLen(local.quotedStrings_arr)#" step="-1" index="local.arrIndex">
			<cfset local.data = replace(local.data, "__PLACEHOLDER_STRING_#local.arrIndex#__", local.quotedStrings_arr[local.arrIndex], "all") />
		</cfloop>

		<!---now re-add all comments we erased from the data --->
		<cfloop to="1" from="#arrayLen(local.comments_arr)#" step="-1" index="local.arrIndex">
			<cfset local.data = replace(local.data, "__PLACEHOLDER_COMMENT_#local.arrIndex#__", local.comments_arr[local.arrIndex], "all") />
		</cfloop>

		<!---timer--->
		<cfset local.timerText_str = listAppend(local.timerText_str, _giveTimer("re-added strings and comments")) />
		
		<!--- color all style attributes of html tags --->
		<cfset local.reg = "(<[^>]+[[:space:]]style[[:space:]]*=[[:space:]]*«[^»]+»(['""]))(.*?)(\2)" />
		<cfset local.foundPos = 0 />
		<cfloop condition="reFindNoCase(local.reg, local.data, local.foundPos+1)">
			<cfset local.found_struct = refindNoCase(local.reg, local.data, local.foundPos+1, true) />
			<cfset local.foundPos = local.found_struct.pos[1] />
			<cfset local.startFound_str = mid(local.data, local.found_struct.pos[2], local.found_struct.len[2]) />
			<cfset local.found_str = mid(local.data, local.found_struct.pos[4], local.found_struct.len[4]) />
			<cfset local.data = replace(local.data, local.startFound_str & local.found_str, local.startFound_str & _formatCss(local.found_str)) />
		</cfloop>

		<!---timer--->
		<cfset local.timerText_str = listAppend(local.timerText_str, _giveTimer("style attributes")) />

		<!--- Convert lt and gt to their ASCII equivalent --->
		<!--- &acute; is not the single quote we want, so change it back --->
		<cfset local.data = replaceList(local.data, "<,>,&acute;", "&lt;,&gt;,'") />
		
		<!--- tabs to spaces? --->
		<cfif not arguments.keepTabs or arguments.lineNumbers>
			<cfset local.data = replace(local.data, chr(9), "&nbsp;&nbsp;&nbsp;&nbsp;", "all") />
		</cfif>
		
		<!--- Line Numbers --->
		<cfif arguments.lineNumbers>
			<cfset local.tempData = "" />
			<cfloop index="local.i" from="1" to="#listLen(local.data, chr(13))#">
				<cfset local.line = listGetAt(local.data, local.i, "#chr(13)#") />
				<cfset local.line = replace(local.line, "#chr(10)#", "", "all") />
				<cfset local.tempData = local.tempData & "«span style=""color:##444444; background-color:##EEEEEE""»#repeatString("&nbsp;", 4-len(local.i))##local.i#:«/span»«span style=""background-color:##FFFFFF""»&nbsp;</span>#local.line#<br />" />
			</cfloop>
			<cfset local.data = local.tempData />
		<cfelse>
			<cfset local.data = "<pre>#local.data#</pre>" />
		</cfif>

		<!--- Revert all pseudo-containers back to their real values to be interpreted literally (revised) --->
		<cfset local.data = replaceList(local.data, "«,»", "<,>") />

		<!---timer--->
		<cfset local.timerText_str = listAppend(local.timerText_str, _giveTimer("line numbering and/or some last replacements")) />
		
		<cfset local.data = local.data & "<!-- Coloring took #getTickCount()-local.startTimer# msecs.:#chr(10)##replace(local.timerText_str, ',', chr(10), 'all')# -->" />
		<cfreturn local.data />
	</cffunction>


	<cffunction name="_formatCss" access="private" returntype="string" output="no">
		<cfargument name="style_str" type="string" required="yes" />
		
		<!--- all css selectors dark blue, and all css values lighter blue --->
		<cfset var reg = "((^|{)[^}{]*?[[:space:]]*)([^:;{}«»]+)(:[[:space:]]*)([^;«]+)([«;]|$)" />
		
		<!--- css trings can contain quotes (i.e. for font-names). They mess up the color-coding, so we'll temp-replace them here. --->
		<cfset arguments.style_str = replace(arguments.style_str, "&acute;", "QuOT", "ALL") />
		
		<cfloop condition="refind(reg, arguments.style_str)">
			<cfset arguments.style_str = rereplace(arguments.style_str, reg, "\1«span style=""color@##000099""»\3«/span»\4«span style=""color@##0000ff""»\5«/span»\6", "all") />
		</cfloop>

		<!--- now re-add all colons. They would otherwise have messed up our regexes. --->
		<cfset arguments.style_str = replace(arguments.style_str, "color@", "color:", "all") />

		<!---now set the style's inner content as pink by default --->
		<cfset arguments.style_str = "«span style=""color:##ff00ff""»" & arguments.style_str & "«/span»" />
		
		<!--- re-add any quotes --->
		<cfset style_str = replace(style_str, "QuOT", "&acute;", "ALL") />

		<cfreturn arguments.style_str />
	</cffunction>
	
</cfcomponent>
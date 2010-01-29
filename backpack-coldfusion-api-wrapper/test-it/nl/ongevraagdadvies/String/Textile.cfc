<cfcomponent output="no" displayname="nl.ongevraagdadvies.String.Textile">
<!---
* Copyright (c) 2009 Paul Klinkenberg
* Blog: http://www.coldfusiondeveloper.nl/post.cfm/backpack-api-wrapper-for-coldfusion
* Licensed under the GPL license v 3.0, see http://www.gnu.org/copyleft/gpl.html
*
* Date: 2009-06-13
--->

	<cfset variables.paramsRegExp = "([^\.\{\(\[ 	#chr(10)##chr(13)#]+|\{[^\}]*\}|\([^\)]*\)|\[[^\]]*\])*" />

	<!--- <comment author="P. Klinkenberg"> this one at the end, since we don't want to be replacing within html tags </comment> --->
	<cfset variables.TextTag2HtmlTags_struct = structNew() />
	<cfset TextTag2HtmlTags_struct['cite'] = "\?\?" />
	<!---<cfset TextTag2HtmlTags_struct['strike'] = "\-" />--->
	<cfset TextTag2HtmlTags_struct['ins'] = "\+" />
	<cfset TextTag2HtmlTags_struct['sup'] = "\^" />
	<cfset TextTag2HtmlTags_struct['sub'] = "\~" />
	<cfset TextTag2HtmlTags_struct['strong'] = "\*" />
	<cfset TextTag2HtmlTags_struct['em'] = "_" />


	<cffunction name="textile2HTML" output="false" returntype="string" hint="Converts textile formatted text to HTML">
		<cfargument name="text" type="string" required="true" />
		<cfargument name="wrapInParagraph" type="boolean" required="no" default="false" hint="Should the text be wrapped in &lt;p&gt;TEXT&lt;/p&gt; tags. Only happens when text is not empty." />
		<cfreturn textile(text=arguments.text, wrapInParagraph=arguments.wrapInParagraph) />
	</cffunction>
	
	
	<cffunction name="textile" output="false" returntype="string" hint="Converts plain text to html using textile formatting.">
		<cfargument name="text" type="string" required="true">
		<cfargument name="wrapInParagraph" type="boolean" required="no" default="true" />
		<cfset var html = "" />
		<cfset var inUL = false>
		<cfset var inOL = false>
		<cfset var inP = false>
		<cfset var inTable = false>
		<cfset var index = 0 />
		<cfset var valNow = "">
		<cfset var lineNow = "" />
		<cfset var dontCloseTable = false />
		<cfset var htmlTags = "" />
		<cfset var key = "" />
		<cfset var tagNow = "" />
		
		<cfset var preformattedCode_arr = arrayNew(1) />
		
		<!--- remove all \r's so we just have \n ended lines --->
		<cfset arguments.text = Replace(arguments.text, Chr(13), "", "ALL") />

		<!--- <comment author="P. Klinkenberg"> if the text consists of only space characters, then leave </comment> --->
		<cfif not reFind("[^#chr(10)##chr(13)# 	]", arguments.text)>
			<cfreturn arguments.text />
		</cfif>
		
		<!--- <comment author="P. Klinkenberg"> remember all <preformatted pieces of text, and temp. remove them from the string </comment> --->
		<cfloop condition="reFindNoCase('^.*?<code[^>]*>(.*?)</code>.*$', arguments.text)">
			<cfset arrayAppend(preformattedCode_arr, reReplaceNoCase(arguments.text, '^.*?<code[^>]*>(.*?)</code>.*$', '\1')) />
			<cfset arguments.text = reReplaceNoCase(arguments.text, '<code([^>]*>).*?(</code>)', '<QQcode\1PlAcePreCodeBacKHerE</QQcode>') />
		</cfloop>
		<cfset arguments.text = reReplace(arguments.text, "(</?)QQcode", "\1code", "ALL") />

		<!--- <comment author="P. Klinkenberg"> to make sure empty lines are treated as breaks, we will give them a space as value here </comment> --->
		<cfloop condition="find('#chr(10)##chr(10)#', arguments.text)">
			<cfset arguments.text = replace(arguments.text, "#chr(10)##chr(10)#", "#chr(10)# #chr(10)#", "ALL") />
		</cfloop>
		
		<cfloop list="#arguments.text#" index="lineNow" delimiters="#chr(10)##chr(13)#">
			
			<cfset dontCloseTable = false />
			
			<cfif Left(lineNow, 1) IS "*">
				<cfset lineNow = rereplace(lineNow, "^\*(\**)(#paramsRegExp#)?(.*)$", "<li ATTR=""\2"">\1\4</li>") />
				<!---<cfset lineNow = " <li>" & Mid(lineNow, 2, Len(lineNow)-1) & "</li>">--->
				<cfif NOT inUL>
					<cfif inOl>
						<cfset html = html & "</ol>" & chr(10) />
						<cfset inOl = false />
					</cfif>
					<cfset lineNow = "<ul>" & Chr(10) & lineNow>
					<cfset inUL = true>
				</cfif>
			<cfelseif Left(lineNow, 1) IS "##">
				<cfset lineNow = rereplace(lineNow, "^##(##*)(#paramsRegExp#)?(.*)$", "<li ATTR=""\2"">\1\4</li>") />
				<!---<cfset lineNow = " <li>" & Mid(lineNow, 2, Len(lineNow)-1) & "</li>">--->
				<cfif NOT inOL>
					<cfif inUL>
						<cfset html = html & "</ul>" & chr(10) />
						<cfset inUl = false />
					</cfif>
					<cfset lineNow = "<ol>" & Chr(10) & lineNow>
					<cfset inOL = true>
				</cfif>
			<cfelseif Left(lineNow, 1) IS "|" or (find("|", lineNow) and inTable)>
				<cfif NOT inTable>
					<cfset html = html & "<br /><table>" & Chr(10) />
					<cfset inTable = true>
				</cfif>
				
				<!--- <comment author="P. Klinkenberg"> this is a real mess, but have no time to clean up... :-/ </comment> --->
				<cfset lineNow = _createTableRow(lineNow) />
				
			<cfelseif not inTable and ReFind("^table(#paramsRegExp#)?\.", lineNow)>
				<cfset lineNow = rereplace(lineNow, "^table(#paramsRegExp#)?\.(.*)$", "<br /><table ATTR=""\1"">\3") />
<!---
				<cfset html = html & rereplace(lineNow, "^table(\{([^\}]+)\})?\.(.*$)", "<br /><table style=""\2"">") & chr(10) />
--->
				<cfset inTable = true />
				<cfset dontCloseTable = true />
				<cfset valNow = rereplace(lineNow, "^<table .*?>(.*)$", "\1") />
				<cfif find("|", valNow)>
					<cfset lineNow = replace(lineNow, valNow, "") & _createTableRow(valNow) />
<!---					<cfset html = html & " <tr>" & Chr(10) />
					<cfloop list="#lineNow#" index="valNow" delimiters="|">
						<cfset html = html & "  <td>" & valNow & "</td>" & Chr(10) />
					</cfloop>
					<cfset lineNow = " </tr>">
					--->
				</cfif>
			<cfelseif ReFind("^h[0-9](#paramsRegExp#)?\.", lineNow)>
				<cfset lineNow = rereplace(lineNow, "^h([0-9])(#paramsRegExp#)?\.(.*)$", "<h\1 ATTR=""\2"">\4</h\1>") />
<!---				<cfset lineNow = rereplace(lineNow, "^h([0-9])(\{([^\}]+)\})?\.(.*)$", "<h\1 style=""\3"">\4</h\1>") />--->
			<cfelseif ReFind("^bq(#paramsRegExp#)?\.", lineNow)>
				<cfset lineNow = rereplace(lineNow, "^bq(#paramsRegExp#)?\.(.*)$", "<blockquote ATTR=""\1"">\3</blockquote>") />
<!---			<cfelseif ReFind("^bq(\{[^\}]+\})?\.", lineNow)>
				<cfset lineNow = rereplace(lineNow, "^bq(\{([^\}]+)\})?\.(.*$)", "<blockquote style=""\2"">\3</blockquote>") />--->
			<cfelseif ReFind("^p(#paramsRegExp#)?\.", lineNow)>
				<cfset lineNow = rereplace(lineNow, "^p(#paramsRegExp#)?\.(.*)$", "<p ATTR=""\1"">\3") />
<!---			<cfelseif ReFind("^p(\{[^\}]+\})?\.", lineNow)>
				<cfset lineNow = rereplace(lineNow, "^p(\{([^\}]+)\})?\.(.*$)", "<p style=""\2"">\3") />--->
				<cfif inP>
					<cfset lineNow = "</p>" & chr(10) & lineNow />
				</cfif>
				<cfset inP = true />
			<cfelseif len(html)>
				<cfset lineNow = "<br />" & lineNow />
			</cfif>
			
			<!--- <comment author="P. Klinkenberg"> end the list if we don't have a list item now </comment> --->
			<cfif inUl and not find("<li ", lineNow)>
				<cfset lineNow = "</ul>" & chr(10) & lineNow />
				<cfset inUl = false />
			<cfelseif inOl and not find("<li ", lineNow)>
				<cfset lineNow = "</ol>" & chr(10) & lineNow />
				<cfset inOl = false />
			<cfelseif inTable and not find("</tr>", lineNow) and not dontCloseTable>
				<cfset lineNow = "</table>" & Chr(10) & lineNow />
				<cfset inTable = false>
			<cfelseif inP and reFind("<(ul|ol|block|h|table)", lineNow)>
				<cfset lineNow = "</p>" & chr(10) & lineNow />
				<cfset inP = false />
			</cfif>

			<cfset html = html & lineNow & chr(10) />
		</cfloop>
		
		<!--- <comment author="P. Klinkenberg"> remove (max. 3) line breaks after: headings, uls, ols, code, pre </comment> --->
		<cfset html = rereplace(html, "(</h[0-9]>|</[ou]l>|</?pre>|</?code>)([ #chr(10)#]*<br />){1,3}", "\1", "ALL") />
		<cfset html = rereplace(html, "([ #chr(10)#]*<br />){1,2}(<pre>|<code>)", "\2", "ALL") />

		<!--- <comment author="P. Klinkenberg"> optional style formatting, which is now at the right of the tag it belongs to, will be set within the tag.
		i.e. original textile: p{color:red} hello world!
		after parsing: <p>{color:red}hello world!</p>
		will change to: <p style="color:red">hello world!</p>
		</comment> --->
		<cfset html = rereplace(html, ">\{([^\}#chr(10)##chr(13)#<>]+)\}", " style=""\1"">", "ALL" ) />
		 
		<!--- !http://site.com/image.jpg(optional alt text)! --->
		<cfset html = ReReplaceNoCase(html, "\!([^<> 	,\:\!\(\)]+)(\(([^\)\(\!]*)\))?!", "<img src=""\1"" alt=""\3"" />", "all")>

		<!--- "link text":http://www.link.com --->
		<cfset html = ReReplaceNoCase(html, """([^""]+?)( ?\((.*?)\))?"":(((https?|s?ftp|mailto)://)?[^\< #chr(10)##chr(13)#	'"",\:]+)", "<a href=""\4"" title=""\3"">\1</a>", "all")>
		
		<!--- bare link: http://www.link.com --->
		<cfset html = ReReplace(html, "([^""'])((https?|s?ftp|mailto)://[^< #chr(10)##chr(13)#	,\:]+)", "\1<a href=""\2"">\2</a>", "all")>
		
		<!--- %{color:green}colored text%) --->
		<cfset html = reReplaceNoCase(html, "%\{ *([a-z\-0-9]+ *: *[^;\}\{]+ *;?)+ *\}([^\}\{\%]*)\%", "<span style=""#replace('\1', '""', '''', 'ALL')#"">\2</span>", "ALL") />
		
		<!--- bare email addresses --->
		<cfset html = reReplaceNoCase(html, "(^|[^\:])([a-z0-9\-_\.\&]+@[a-z0-9\-_\.\&]+\.[a-z0-9]{2,})", "\1<a href=""mailto:\2"">\2</a>", "ALL") />
		
		<!--- <comment author="P. Klinkenberg"> style: {color:red} </comment> --->
		<cfset html = rereplace(html, "(ATTR=""[^""]*?)\{([^\}""]*)\}", "style=""\2"" \1", "ALL") />
		<!--- <comment author="P. Klinkenberg"> lang: [en] </comment> --->
		<cfset html = rereplace(html, "(ATTR=""[^""]*?)\[([^\]""]*)\]", "lang=""\2"" \1", "ALL") />
		<!--- <comment author="P. Klinkenberg"> classes and ID's </comment> --->
		<cfset html = rereplace(html, "(ATTR=""[^""]*?)\(([^##\)""]*)(##([\)""]*))\)", "class=""\2"" id=""\4"" \1", "ALL") />

		<!--- <comment author="P. Klinkenberg"> we will now remove all empty ATTR tags </comment> --->
		<cfset html = replace(html, " ATTR=""""", "", "ALL") />
		
		<cfset htmlTags = rereplace(html, "(<[^>]+>)[^<]*", "\1", "ALL") />
		<cfset htmlTags = rereplace(htmlTags, "^[^<]*", "") />
		<cfset htmlTags = rereplace(htmlTags, ">[^<]+<", "><", "ALL") />
		<cfset html = reReplace(html, "<[^>]+>", "@isTaG@", "ALL") />
		
		<cfloop collection="#TextTag2HtmlTags_struct#" item="key">
			<cfset html = reReplace(html, "#TextTag2HtmlTags_struct[key]#([^#chr(10)##chr(13)#]*?)#TextTag2HtmlTags_struct[key]#", "<#key#>\1</#key#>", "ALL") />
		</cfloop>

		<cfloop list="#htmlTags#" index="tagNow" delimiters="<>">
			<cfset html = replace(html, "@isTaG@", "<#tagNow#>", "one") />
		</cfloop>
		
		<!--- <comment author="P. Klinkenberg"> put all <preformatted pieces of text back in the text </comment> --->
		<cfloop from="1" to="#arrayLen(preformattedCode_arr)#" index="valNow">
			<cfset html = replace(html, 'PlAcePreCodeBacKHerE', htmlEditFormat(preformattedCode_arr[valNow])) />
		</cfloop>
		
		<cfreturn html>
	</cffunction>


	<cffunction name="_createTableRow" access="private" returntype="string" hint="I transform a textile tableRow to a html tableRow (with td's)">
		<cfargument name="lineNow" type="string" required="yes" hint="The line with the tr and td data" />
		<cfset var htmlString = "" />
		<cfset var trDone = false />
		<cfset var valNow = "" />
		<cfset var specialPart = "" />
		<cfset var tdTag = "td" />
		<cfset var className = "" />
		<cfset var idName = "" />
		<cfset var style = "" />
		<cfset var lang = "" />
		<cfset var colspan = 1 />
		<cfset var rowspan = 1 />
		<cfset var tdString = "" />
		
		<cfloop list="#lineNow#" index="valNow" delimiters="|">
			<cfset specialPart = rereplace(valNow, "^((#paramsRegExp#)\.)?.*$", "\2") />

			<cfif len(specialPart) and (specialPart neq valNow or right(specialPart,1) eq '.')>
				<cfset valNow = ltrim(replace(valNow, specialPart & ".", '')) />
				
				<cfset tdTag = "td" />
				<cfset className = reReplace(specialPart, "^.*?(\(([^##].+?)\))?.*?$", "\2") />
				<cfif find("##", className)>
					<cfset idName = reReplace(classname, "^[^##]+##", "") />
					<cfset className = replace(className, "###idName#", "") />
				<cfelse>
					<cfset idName = reReplace(specialPart, "^[^\(]*(\((##.+?)\))?.*?$", "\2") />
				</cfif>
				<cfset style = reReplace(specialPart, "^[^\{]*(\{([^\}]*)\})?.*$", "\2") />
				<cfset lang = reReplace(specialPart, "^[^\[]*(\[(.*?)\])?.*?$", "\2") />
				<!--- <comment author="P. Klinkenberg"> remove all parts within brackets etc. </comment> --->
				<cfset specialPart = rereplace(specialPart, "(\{[^\}]*\}|\([^\)]*\)|\[[^\]]*\])", "", "ALL") />
				
				<cfif find("<>", specialPart)><cfset style = listAppend(style, "text-align:justify", ";") />
				<cfelseif find("<", specialPart)><cfset style = listAppend(style, "text-align:left", ";") />
				<cfelseif find(">", specialPart)><cfset style = listAppend(style, "text-align:right", ";") />
				<cfelseif find("=", specialPart)><cfset style = listAppend(style, "text-align:center", ";") />
				</cfif>

				<cfif find("^", specialPart)><cfset style = listAppend(style, "vertical-align:top", ";") />
				<cfelseif find("~", specialPart)><cfset style = listAppend(style, "vertical-align:bottom", ";") />
				</cfif>
				
				<cfset colspan = 1 />
				<cfif reFind("\\([0-9]+)", specialPart)>
					<cfset colspan = rereplace(specialPart, "^.*?\\([0-9]+).*?$", "\1") />
				</cfif>
				<cfset rowspan = 1 />
				<cfif reFind("/([0-9]+)", specialPart)>
					<cfset rowspan = rereplace(specialPart, "^.*?/([0-9]+).*?$", "\1") />
				</cfif>

				<cfif find("_", specialPart)>
					<cfset tdTag = "th" />
				</cfif>
				
				<cfset tdString = '<#tdTag# class="#className#" id="#idName#" style="#style#" lang="#lang#" colspan="#colspan#" rowspan="#rowspan#">' />
				<cfset tdString = rereplace(tdString, ' ?[a-z]+=""', '', 'ALL') />
				<cfset tdString = rereplace(tdString, ' ?(col|row)span="1"', '', 'ALL') />
				<cfset tdString = tdString & valNow & "</#tdTag#>" />
			<cfelse>
				<cfset tdString = "<td>#valNow#</td>" />
			</cfif>
			
			<cfif not trDone>
				<cfset trDone = true />
				<cfif left(lineNow,1) eq "|">
					<cfset htmlString = htmlString & " <tr>" & Chr(10) />
				<cfelse>
					<!--- <comment author="P. Klinkenberg"> create a TR instead of a TD </comment> --->
					<cfset tdString = replace(tdString, "<td", "<tr") />
					<cfset tdString = replace(tdString, "</td>", "") />
					<cfset htmlString = htmlString & tdString & Chr(10) />
					<cfset tdString = "" />
				</cfif>
			</cfif>
			<cfset htmlString = htmlString & "  #tdString#" & Chr(10) />
		</cfloop>
		<cfset htmlString = htmlString & "</tr>" />
		
		<cfreturn htmlString />
	</cffunction>


</cfcomponent>
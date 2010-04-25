<cfsavecontent variable="txt"><cfinclude template="SmarterMail6x_Automation_with_WebServices.html" /></cfsavecontent>

<cfset pieces = arrayNew(1) />
<cfset startpos = 1 />
<cfloop condition="refind('<div style=""position:absolute;top:[0-9]+;left:162""><nobr><b>[A-Z][a-zA-Z]+', txt, startpos+1)">
	<cfset findings = refind('<div style="position:absolute;top:[0-9]+;left:162"><nobr><b>[A-Z][a-zA-Z]+', txt, startpos+1, true) />
	<cfset arrayAppend(pieces, mid(txt, startpos, findings.pos[1]-startpos)) />
	<cfset startpos = findings.pos[1] />
</cfloop>
<cfset arrayAppend(pieces, right(txt, len(txt)-startpos)) />

<cfset docsdir = expandpath('../documentation/') />
<cfloop from="1" to="#arraylen(pieces)#" index="i">
	<cfset piece = pieces[i] />
	
	<cfif findNoCase('.asmx', piece)>
		<cfset page = rereplace(piece, '^.*?left:108"><nobr><i>Services/([a-zA-Z0-9]+)\.asmx.*$', '\1') />
		<cfset name = "main" />
		<cfoutput><strong>PAGE #page#</strong><br /></cfoutput>
<!---		<cfoutput><pre style="border:2px solid black; padding:10px;">#htmleditformat(piece)#</pre></cfoutput>--->
	<cfelse>
		<cfset name = rereplace(piece, '.*?<b>([a-zA-Z0-9 ]+)(: ?)?</b>.*$', '\1') />
	</cfif>
	<cfif name eq piece>
		No name found!<br />
		<cfoutput><pre style="border:2px solid black; padding:10px;">#htmleditformat(piece)#</pre></cfoutput>
		<br />
	<cfelse>
		<cfoutput>#name#<br /></cfoutput>
		<cfloop list="189,243,270,216,162,324,297" index="nr">
			<cfset piece = rereplaceNoCase(piece, ' style="position:absolute;top:[0-9]+ ?;left:#nr#"', ' style="margin-left:#nr-162#px"', 'all') />
		</cfloop>
		<cfset piece = rereplaceNoCase(piece, '</?font.*?>', '', 'all') />
		<cfset piece = rereplaceNoCase(piece, '</?span[^>]*>', '', 'all') />
		<cfset piece = rereplaceNoCase(piece, ' style="position:absolute;top:[0-9]+ ?;left:108"', '', 'all') />
		<cfset piece = replaceNoCase(piece, '<div><nobr>SmarterMail 6.x Automation with Web Services </nobr></div>', '', 'all') />
		<cfset piece = rereplaceNoCase(piece, '<div style="position:absolute;top:[0-9]+ ?;left:(135|774|0|767)".*?</div>', '', 'all') />
		<!---<cfset piece = rereplaceNoCase(piece, ' style="position:absolute;top:[0-9]+ ?;left:[0-9]+"', '', 'all') />
--->		<cffile action="write" file="#docsdir##page#-#trim(name)#.html" output="#piece#" />
	</cfif>
</cfloop>
<!---
/*
 * viewsource.cfm code by Paul Klinkenberg
 * http://www.leeftpaulnog.nl/
 *
 * Date: 2009-04-17 20:35:00 +0100
 * Revision: 1
 *
 * Copyright (c) 2009 Paul Klinkenberg, Ongevraagd Advies
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

<!---
	Advice for users of this code:
	** By default, THIS FILE can be viewed! So be carefull about modifying this; the security
	   will otherwise become only as good as your coding skills are ;-)
	** By default, all files in the same directory as this file can be viewed!
	   If you want to be certain that only certain files can be viewed, then fill the list 'viewablefiles' underneath.
	** If you want more directories to be viewable, then add them to the 'variables.viewablePaths' list.
	   By default, this variable must hold './', which means the current directory.
--->

<!--- usage: leave empty if all files of the directory/ies may be viewed. Otherwise, use a comma-delimited list. --->
<cfset variables.viewablefiles = "plugin.xml,PluginHandler.cfc,settingsForm.cfm" />
<!--- usage: leave empty if all file-extensions may be viewed. Otherwise, use a comma-delimited list. --->
<cfset variables.viewableExtensions = "cfm,cfc,cfml,txt,js,htm,html,xml" />
<!--- usage: absolute path from site-root, or relative from THIS directory. It will be expanded by expandPath() function.
Example: <cfset variables.viewablePaths = "./,/javascript/,/css/,../scripts/" /> --->
<cfset variables.viewablePaths = "./,admin/" />

<!---------------------------------- DON'T MODIFY UNDERNEATH THIS LINE ------------------------------------>
<!---create the codecoloring object --->
<cfset variables.codeColoring_obj = CreateObject("component", "xitesystem.code.CodeColoring") />

<!---create the full paths --->
<cfset variables.viewablePaths_arr = arrayNew(1) />
<cfloop list="#variables.viewablePaths#" delimiters="," index="itemNow">
	<cfset arrayAppend(variables.viewablePaths_arr, expandPath(itemNow)) />
</cfloop>

<!---create necessary request-based vars--->
<cfset request.filepath = replace(url.file, "\", "/", "all") />
<cfset request.filename = listLast(url.file, "/") />
<cfset request.codeFile = "" />

<!--- security 1: viewableFiles list--->
<cfif len(variables.viewablefiles) and not listFindNoCase(variables.viewablefiles, request.filename)>
	<cfthrow message="The file you wanted to view is not allowed!" detail="requested file: #url.file#" />
</cfif>
<!--- security 2: viewablePaths list--->
<cfif find("/", request.filepath)>
	<cfif not listFindNoCase(variables.viewablePaths, GetDirectoryFromPath(request.filepath), ",")>
		<cfthrow message="Security error: you are not allowed to view the file you requested!" detail="requested file: #url.file#" />
	</cfif>
</cfif>
<!--- security 3: extension allowed?--->
<cfif len(variables.viewableExtensions) and not listFindNoCase(variables.viewableExtensions, listLast(request.filepath, "."), ",")>
	<cfthrow message="Security error: the extension of the file you requested is not allowed!" detail="requested file: #url.file#" />
</cfif>
<!--- security 4: check if the requested file is available/exists --->
<cfif find("/", request.filepath)>
	<cfif fileExists(expandPath(request.filepath))>
		<cfset request.codeFile = expandPath(request.filepath) />
	</cfif>
<cfelse>
	<cfloop from="1" to="#arrayLen(variables.viewablePaths_arr)#" index="arrIndex">
		<cfif not len(request.codeFile) and fileExists(variables.viewablePaths_arr[arrIndex] & request.filename)>
			<cfset request.codeFile = variables.viewablePaths_arr[arrIndex] & request.filename />
		</cfif>
	</cfloop>
</cfif>
<cfif not len(request.codeFile)>
	<cfthrow message="The file you requested does not exist!" detail="requested file: #url.file#" />
</cfif>


<cftry>
	<cffile action="read" file="#request.codeFile#" variable="txt" charset="utf-8" />
	<cfcatch>
		<cfthrow message="The requested file could not be read!" detail="#cfcatch.detail#" />
	</cfcatch>
</cftry>

<cfcontent reset="yes" type="text/html; charset=utf-8"/><!---

---><!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
	<cfoutput><title>Source view: #request.filepath#</title></cfoutput>
</head>
<body>
	<p style="border:1px solid #000;padding:10px;margin: 10px 5px;text-align:center; font:12px Arial;">
		<cfoutput>This is the source code of <strong>#request.filepath#</strong>.<br /><br /></cfoutput>
		<!--- Please, leave the next line intact; thee are my credits ;-)  Thanks, Paul. --->
		This file is part of the <a href="http://www.coldfusiondeveloper.nl/post.cfm/mangoblog-plugin-viewcount">Mangoblog viewCount plugin</a>!<br /><br />
		<em>The code is colored using the <a href="http://www.leeftpaulnog.nl/2009/03/my-supreme-coldfusion-code-coloring.html">Coldfusion code coloring component</a> by <a href="http://www.leeftpaulnog.nl/">Paul Klinkenberg</a>.</em>
	</p>
	<cfoutput>#codeColoring_obj.colorString(dataString=txt, lineNumbers=false)#</cfoutput></body>
</html>
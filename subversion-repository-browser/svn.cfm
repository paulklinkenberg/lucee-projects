<cfsetting enablecfoutputonly="Yes">
<!---
	svn browser
	Original Code by Rick Osborne: http://code.google.com/p/cfdiff/
	Yes, yes, I know.  Horrific caffeine code.  I bow down.  I'm so ashamed.

	License: Mozilla Public License (MPL) version 1.1 - http://www.mozilla.org/MPL/
	READ THE LICENSE BEFORE YOU USE OR MODIFY THIS CODE
	
	Edited by Paul Klinkenberg, www.coldfusiondeveloper.nl
	for project Subversion repository browser: http://www.coldfusiondeveloper.nl/post.cfm/subversion-repository-browser-in-coldfusion
	
	Version 1.0, March 2010
	Version 1.1, 12 July 2010
		Added option to view the latest version of a file, by setting 'HEAD' as the revision number.
--->

<!---
===============================================================
  BEGIN SITE-SPECIFIC SETTINGS
===============================================================
--->
<cfset RepositoryURL="svn://yourserver.com/projectname/trunk/">
<cfparam name="url.repositorypath" default="" />
<cfset RepositoryUsername="username" />
<cfset RepositoryPassword="password" />
<cfset variables.urlToThisFile = cgi.SCRIPT_NAME />
<!--- We don't want to provide the ability to diff everything, just certain file types --->
<cfset Diffable="cfc,cfm,cfml,txt,plx,php,php4,php5,asp,aspx,xml,html,htm,sql,css,js">
<cfset DiffGraphic='<img src="/cfdiff/images/diff.png" width="16" width="16" alt="View the difference between this file and the previous version" border="0" />'>

<!---
===============================================================
  END SITE-SPECIFIC SETTINGS
===============================================================
--->
<!--- You *probably* won't have to edit anything below this line.
When you did, you'd better call svn.cfm?init=1 in your browser afterwards. --->

<cflock scope="APPLICATION" type="EXCLUSIVE" timeout="30">
	<cfif NOT StructKeyExists(Application,"SVNBrowser") or structKeyExists(url, "init")>
		<cfset Application.SVNBrowser=CreateObject("component","svnbrowser").init(RepositoryURL,RepositoryUsername,RepositoryPassword)>
	</cfif>
</cflock>
<cfset sb=Application.SVNBrowser />
<cfset Version="">
<cfset PrevVersion="">
<cfset FullDiff=false>
<cfset FilePath = REReplace(REReplace(url.repositorypath, "\.\.+",".", "ALL"), "//+", "/", "ALL") />
<cfif FilePath CONTAINS ":">
	<!--- There is at least one revision number given --->
	<cfset Version=ListRest(FilePath,":")>
	<cfif Version CONTAINS ":">
		<!--- There's a left/right pair of revision numbers --->
		<cfset PrevVersion=ListFirst(Version,":")>
		<cfset Version=ListRest(Version,":")>
		<cfif Right(Version,1) EQ "f">
			<cfset FullDiff=true>
			<cfset Version=Val(Version)>
		</cfif>
	</cfif>
	<cfset FilePath=ListFirst(FilePath,":")>
</cfif>

<cfset variables.IsDir=False>
<cfif len(filepath) and (left(filepath, 1) eq "/" or left(filepath, 1) eq "\")>
	<cfset filepath = rereplace(filepath, "^[\\/]+", "") />
</cfif>
<cfif filepath eq "" or Right(FilePath,1) EQ "/">
	<cfset variables.IsDir=True>
</cfif>

<cfset TotalBytes=0>
<cfset TotalFiles=0>
<cfset TotalDirs=0>
<cfset EvenOdd=ListToArray("even,odd")>
<cfif variables.isDir>
	<cfset variables.action = "listing" />
	<!--- Get a directory listing --->
	<cfset f=sb.List(FilePath) />
<cfelseif IsNumeric(PrevVersion) AND IsNumeric(Version)>
	<!--- If we have two revision numbers, make a diff --->
	<cfset LeftQ=sb.FileVersion(FilePath,PrevVersion)>
	<cfset RightQ=sb.FileVersion(FilePath,Version)>

	<cfif IsQuery(LeftQ) AND IsQuery(RightQ) AND (LeftQ.RecordCount EQ 1) AND (RightQ.RecordCount EQ 1) AND IsBinary(LeftQ.Content[1]) AND IsBinary(RightQ.Content[1])>
		<!--- We got two files, build a diff --->
		<cfset LeftFile=ToString(LeftQ.Content[1])>
		<cfset RightFile=ToString(RightQ.Content[1])>

		<cfobject component="diff" name="cfcDiff" />
		<cfset diffHtml = cfcdiff.diffFormat(LeftFile,RightFile, fulldiff) />
	<cfelse>
		<cfthrow message="Something went wrong; the diff can't be done!" />
	</cfif>
	<cfset variables.action = "diff" />
<cfelseif IsNumeric(Version) or Version eq "HEAD">
	<!--- We only have one version number, so show the file --->
	<cfset f=sb.FileVersion(FilePath,Version)>
	<cfif f.RecordCount eq 0>
		<cfabort showerror="No such file or revision">
	<cfelseif structKeyExists(url, "download")>
		<cfset FileExt=LCase(ListLast(f.Name,".")) />
		<cfswitch expression="#FileExt#">
			<cfcase value="cfc,cfm,cfml,js,pl,plx,php,php4,php5,asp,aspx,sql">
				<cfheader name="Content-Disposition" value="attachment;filename=""#f.name#""" />
				<cfcontent type="text/plain" reset="yes" /><!---
				---><cfoutput><cfif isBinary(f.content[1])>#tostring(f.Content[1])#<cfelse>#f.content[1]#</cfif></cfoutput><!---
				---><cfabort />
			</cfcase>
			<cfcase value="jpg,jpeg,png,gif,ico">
				<cfheader name="Content-Disposition" value="inline;filename=""#f.name#""" />
				<cfcontent variable="#f.Content[1]#" type="image/#FileExt#" reset="yes" />
			</cfcase>
			<cfcase value="xml,html,htm,css">
				<cfheader name="Content-Disposition" value="attachment;filename=""#f.name#""" />
				<cfcontent type="text/#FileExt#" reset="yes" /><!---
				---><cfoutput><cfif isBinary(f.content[1])>#tostring(f.Content[1])#<cfelse>#f.content[1]#</cfif></cfoutput><!---
				---><cfabort />
			</cfcase>
			<cfdefaultcase>
				<cfheader name="Content-Disposition" value="attachment;filename=""#f.name#""" />
				<cfcontent variable="#f.Content[1]#" type="application/octet-stream" reset="yes" />
			</cfdefaultcase>
		</cfswitch>
		<cfabort />
	<cfelse>
		<cfset variables.action = "showfile" />
	</cfif>
<cfelse>
	<!--- If all else fails, try to show a history of whatever we're looking at --->
	<cfset f=sb.History(FilePath)>
	<cfset variables.action = "listing" />
</cfif>

<cfsavecontent variable="headText"><cfoutput><link rel="stylesheet" href="cfdiff.css" type="text/css" />
</cfoutput></cfsavecontent>
<cfhtmlhead text="#headText#" />
<cfoutput>
	<h2>SVN browser: #RepositoryURL##filepath#</h2>
	<cfset dirs = "" />
	<h3>Path: <a href="#variables.urlToThisFile#?repositorypath=">[root]/</a>
		<cfif len(filepath)>
			<cfloop list="#getdirectoryFromPath(filepath)#" index="dir" delimiters="/">
				<a href="#variables.urlToThisFile#?repositorypath=#dirs##dir#/">#dir#/</a>
				<cfset dirs=dirs&dir&"/" />
			</cfloop>
		</cfif>
		<cfif not variables.isdir><a href="#variables.urlToThisFile#?repositorypath=#filepath#">#getFileFromPath(filepath)#</a></cfif>
	</h3>
</cfoutput>

<cffunction name="FreshnessRating" returntype="string" output="false">
	<cfargument name="Updated" type="any" required="true">
	<!--- Paul Klinkenberg: I think it is confusing if the dates in the table have different colors without an apparent reason.
	So I edited this fnc a bit.

	<cfset var Age=99>
	<cfif IsDate(Arguments.Updated)>
		<cfset Age=DateDiff("d",Arguments.Updated,Now())>
	</cfif>
	<cfif Age LTE 2><cfreturn "smokin">
	<cfelseif Age LTE 5><cfreturn "hot">
	<cfelseif Age LTE 10><cfreturn "fresh">
	<cfelseif Age LTE 30><cfreturn "fine">
	</cfif>
	--->
	<cfreturn "aged">
</cffunction>

<cfif variables.action eq "diff">
	<cfoutput>
		<p>You may also view the <cfif FullDiff><a href="#variables.urlToThisFile#?repositorypath=#Left(url.repositorypath,Len(url.repositorypath)-1)#">unified diff</a><cfelse><a href="#variables.urlToThisFile#?repositorypath=#url.repositorypath#f">full diff</a></cfif>.</p>
		<table class="diff" cellspacing="0">
			<tr>
				<th colspan="2" nowrap="nowrap" style="border-left:none;">Revision #NumberFormat(PrevVersion)#</th>
				<th colspan="2" nowrap="nowrap" style="border-left:none;">Revision #NumberFormat(Version)#</th>
			</tr>
			#diffHtml#
		</table>
		<br />
	</cfoutput>
<cfelseif variables.action eq "showfile">
	<cfoutput>
		<p>You are viewing the contents of #FilePath#, revision #Version#
			<br />
			<a href="#variables.urlToThisFile#?repositorypath=#filePath#">&laquo; back to the file's overview page</a>
			&nbsp;
			<a href="#variables.urlToThisFile#?repositorypath=#filePath#:#version#&amp;download=1">download this file</a>
		</p>
		
		<cfif listFindNoCase("cfc,cfm,cfml,htm,html", listLast(filepath, '.'))>
			<!---create the codecoloring object --->
			<cfoutput>#CreateObject("component", "CodeColoring").colorString(dataString=tostring(f.content[1]), lineNumbers=false)#</cfoutput>
		<cfelse>
			<pre>#HTMLEditFormat(tostring(f.content[1]))#</pre>
		</cfif>
	</cfoutput>
<cfelse>
	<!--- Show our generic file list or history list --->
	<cfoutput>
		<table border="0" width="100%" class="list">
			<thead>
				<tr>
					<cfif variables.isDir><th align="left">Name</th></cfif>
					<th align="right">Revision</th>
					<cfif NOT variables.isDir><th align="center">Diff</th></cfif>
					<cfif variables.isDir><th align="right">Size</th></cfif>
					<th align="center">Date</th>
					<th align="left">Author</th>
					<cfif NOT variables.isDir><th align="left">Message</th></cfif>
				</tr>
			</thead>
			<tbody>
				<cfloop query="f">
					<cfif IsNumeric(Size)><cfset TotalBytes=TotalBytes+Size></cfif>
					<cfset FileExt=LCase(ListLast(Name,"."))>
					<cfset CanDiff=false> 
					<cfif Kind EQ "file"><cfset TotalFiles=TotalFiles+1><cfif ListFindNoCase(Diffable,FileExt) GT 0><cfset CanDiff=true></cfif><cfelseif Kind EQ "dir"><cfset TotalDirs=TotalDirs+1></cfif>
					<tr class="#EvenOdd[IncrementValue(CurrentRow MOD 2)]#" valign="top">
				
						<cfif variables.isDir><td>#HTMLEditFormat(Name)#</td></cfif>
						<td nowrap="nowrap" class="num links">
							<cfif kind eq "file">
								<a href="#variables.urlToThisFile#?repositorypath=#FilePath#<cfif variables.isDir>#f.Path#</cfif>:#Revision#&amp;download=1">download</a>
							</cfif>
							<cfif variables.isDir>
								<a href="#variables.urlToThisFile#?repositorypath=#FilePath##f.path#<cfif Kind EQ 'dir'>/</cfif>"><cfif Kind EQ 'dir'>Open folder<cfelse>log</cfif></a>
							</cfif>
							<cfif listfindnocase("xml,html,htm,css,cfc,cfm,cfml,js,pl,plx,php,php4,php5,asp,aspx,sql,as,mxml", listlast(f.path, '.'))>
								<a href="#variables.urlToThisFile#?repositorypath=#FilePath#<cfif variables.isDir>#f.Path#</cfif>:HEAD">view</a>
							</cfif>
							#NumberFormat(Revision)#
						</td>
						<cfif NOT variables.isDir><td align="center"><cfif CanDiff AND (CurrentRow LT RecordCount)><a href="#variables.urlToThisFile#?repositorypath=#Path#:#f.Revision[IncrementValue(CurrentRow)]#:#Revision#f">#DiffGraphic#</a><cfelse> </cfif></td></cfif>
				
						<cfif variables.isDir><td nowrap="nowrap" class="num"><cfif (Kind EQ 'file') AND IsNumeric(Size)>#NumberFormat(Size)#</cfif></td></cfif>
						<td class="date<cfif IsDate(Date)> #FreshnessRating(Date)#</cfif>" nowrap="nowrap"><cfif IsDate(Date)>#DateFormat(Date,"yyyy-mm-dd")# #TimeFormat(Date,"HH:mm:ss")#<cfelse>#HTMLEditFormat(Date)#</cfif></td>
						<td>#HTMLEditFormat(Author)#</td>
						<cfif NOT variables.isDir><td>#HTMLEditFormat(Message)#</td></cfif>
					</tr>
				</cfloop>
			</tbody>
			<tfoot>
				<tr>
					<cfif variables.isDir>
					<td colspan="5">#NumberFormat(TotalBytes)# byte<cfif TotalBytes NEQ 1>s</cfif> in <cfif TotalFiles GT 0>#NumberFormat(TotalFiles)# file<cfif TotalFiles NEQ 1>s</cfif><cfif TotalDirs GT 0> and </cfif></cfif><cfif TotalDirs GT 0>#NumberFormat(TotalDirs)# director<cfif TotalDirs NEQ 1>ies<cfelse>y</cfif></cfif>.</td>
					<cfelse>
					<td colspan="5">#f.RecordCount# revision<cfif f.RecordCount NEQ 1>s</cfif> found.</td>
					</cfif>
				</tr>
			</tfoot>
		</table>
	</cfoutput>
</cfif>

<cfsetting enablecfoutputonly="No" />
<!---
jQuery File Tree
ColdFusion connector script
By Tjarko Rikkerink (http://carlosgallupa.com/)

Modified by Paul Klinkenberg for the Filemanager CFM connector
 *
 *	@license	MIT License
 *	@author		Paul Klinkenberg, www.railodeveloper.com/post.cfm/ckeditor-3-with-coldfusion-filemanager-version-2-0-for-free
 *  @date		March 19, 2011
 *  @version	2.1: Added support for network share storage; merged setting files into one Application.cfm; revised some internal functions (path checking etc.); fixed a bug with non-displayed error output when using Quick Upload (i.e. when uploading wrong file type, no error msg was returned) 
 				2.0.1 February 26, 2011: Added debug text to the json output, if an error occured.
 				2.0 November 17, 2010: see change list at http://www.railodeveloper.com/post.cfm/ckeditor-3-with-coldfusion-filemanager-version-2-0-for-free
 				1.1 April 25, 2010: Fixed some bugs and added some functionality
 *	@copyright	Authors
---><cfcontent reset="yes" type="text/html" />
<cfif not structKeyExists(variables, "jqueryFileTree_webroot")>
	<ul class="jqueryFileTree">
		<li style="color:red;font-size:10px;">CFM developer: see Application.cfm for security instructions!</li>
	</ul>
	<cfabort />
</cfif>
<cfif structKeyExists(form, 'dir') and len(form.dir)>
	<cfset variables.absDirectory = application.filemanager_obj.getFullPath(form.dir) />
	<cfset variables.webDirectory = application.filemanager_obj.getWebPath(variables.absDirectory) />
	
	<cftry>
		<cfdirectory action="LIST" directory="#variables.absDirectory#" name="qDir" sort="type, name" />
		<cfcatch>
			<cfset variables.qDir = queryNew("") />
		</cfcatch>
	</cftry>
	
	<ul class="jqueryFileTree" style="display: none;">
		<cfif not qDir.recordcount>
			<li><em>No files found</em></li>
		</cfif>
		<cfoutput query="qDir"><cfif find(".", qDir.name) neq 1>
			<cfif type eq "dir">
				<li class="directory collapsed"><a href="##" rel="#webDirectory##name#/">#name#</a></li>
			<cfelseif type eq "file">
				<li class="file ext_#lCase(listLast(name,'.'))#"><a href="##" rel="#webDirectory##name#">#name# (#round(size/1024)#KB)</a></li>
			</cfif>
		</cfif></cfoutput>
	</ul>
</cfif>
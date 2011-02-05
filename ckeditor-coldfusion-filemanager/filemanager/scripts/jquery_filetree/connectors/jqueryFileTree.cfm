<!---
jQuery File Tree
ColdFusion connector script
By Tjarko Rikkerink (http://carlosgallupa.com/)

Modified by Paul Klinkenberg for the Filemanager CFM connector
 *
 *	@license	MIT License
 *	@author		Paul Klinkenberg, www.railodeveloper.com/post.cfm/cfm-connector-for-ckeditor-corefive-Filemanager
 *  @date		February 28, 2010
 *  @version	1.0
 *	@copyright	Authors
---><!---

		!!!!!!!!!!!!!!SECURITY INSTRUCTIONS!!!!!!!!!!
The script underneath can potentially list all the files within your webroot. This is a pretty big security issue.
So you have to tell this script which starting directory within your webroot to use.

To do that, add the following line to your Application.cfm/cfc file:

	<cfset variables.jqueryFileTree_webroot = "/the-allowed-root-folder/" />

If you want to allow all files within your website, then use: 

	<cfset variables.jqueryFileTree_webroot = "/" />
---><cfcontent reset="yes" />
<cfif not structKeyExists(variables, "jqueryFileTree_webroot")>
	<ul class="jqueryFileTree">
		<li style="color:red;font-size:10px;">CFM developer: see <cfoutput>#rereplace(getCurrentTemplatePath(), "([/\\])", "\1 ", "all")#</cfoutput> for security instructions!</li>
	</ul>
	<cfabort />
</cfif>
<cfif structKeyExists(form, 'dir') and len(form.dir)>
	<!--- remove references to underlying directories (to prevent listing unwanted directories) --->
	<cfset form.dir = rereplace(URLDecode(form.dir), "\.\.[/\\]", "", "all") />
	<!--- check if the allowed webroot is included in the given form.dir--->
	<cfif findNoCase(variables.jqueryFileTree_webroot, form.dir) eq 1>
		<cfset variables.absDirectory = expandPath(form.dir) />
		<cfset form.dir = replaceNoCase(form.dir, variables.jqueryFileTree_webroot, "/") />
	<cfelse>
		<cfset variables.absDirectory = expandPath(variables.jqueryFileTree_webroot & form.dir) />
	</cfif>
	<cfif right(form.dir, 1) neq "/">
		<cfset form.dir = form.dir & "/" />
	</cfif>
	
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
				<li class="directory collapsed"><a href="##" rel="#form.dir##name#/">#name#</a></li>
			<cfelseif type eq "file">
				<li class="file ext_#lCase(listLast(name,'.'))#"><a href="##" rel="#form.dir##name#">#name# (#round(size/1024)#KB)</a></li>
			</cfif>
		</cfif></cfoutput>
	</ul>
</cfif>
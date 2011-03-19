<!---
 *	Filemanager CFM connector
 *
 *	filemanager.config.cfm
 *	use for ckeditor filemanager plug-in by Core Five - http://labs.corefive.com/Projects/FileManager/
 *
 *	@license	MIT License
 *	@author		Paul Klinkenberg, www.railodeveloper.com/post.cfm/cfm-connector-for-ckeditor-corefive-Filemanager
 *  @date		March 19, 2011
 *  @version	2.1: Added support for network share storage; merged setting files into one Application.cfm; revised some internal functions (path checking etc.); fixed a bug with non-displayed error output when using Quick Upload (i.e. when uploading wrong file type, no error msg was returned) 
 				2.0 November 17, 2010: see change list at http://www.railodeveloper.com/post.cfm/ckeditor-3-with-coldfusion-filemanager-version-2-0-for-free
 				1.1 April 25, 2010: Fixed some bugs and added some functionality
 				2.0 November 17, 2010: Lots of changes and bugfixes in the javascript code
 *	@copyright	Authors
--->
<cfapplication name="app_#hash(getCurrentTemplatePath())#" applicationtimeout="#createTimeSpan(1,0,0,0)#" sessionmanagement="no" clientmanagement="no" />

<!--- initialize the cached filemanager object.
You can reload it by calling yoursite.com/ckeditor/filemanager/connectors/cfm/filemanager.cfm?init=1--->
<cfif true or not structKeyExists(application, "filemanager_obj") or structKeyExists(url, "init")>
	<cfset application.filemanager_obj = createObject('component', 'connectors.cfm.filemanager-functions') />
	<cfif structKeyExists(url, "init")>
		<h1>Filemanager cache has been flushed!</h1>
		<em>Aborting your request now...</em>
		<cfabort />
	</cfif>
</cfif>

<!--- see directory 'lang' --->
<cfset request.language = "en" />
<!--- max. upload file size, in KiloBytes (1.000 KB = 1 MB) --->
<cfset request.maxFileSizeKB = 10000 />
<cfset request.onlyImageUploads = false />
<cfset request.allowedImageExtensions = "jpg,jpeg,gif,png" />
<!--- should we allow all files? If true, we do not check the extension. --->
<cfset request.allowAllFiles = false />
<cfset request.allowedExtensions = "zip,rar,psd,tif,gz,odf,odt,ods,txt,csv,pdf,doc,docx,xls,xlsx,ppt,pptx,odf,odt" & ",#request.allowedImageExtensions#" />
<!--- If a file is uploaded with a name which already exists, should we rename it or overwrite it? --->
<cfset request.uploadCanOverwrite = true />
<!--- this path must start with a "/", so it is always calculated from your website's root. --->
<cfset request.uploadWebRoot = "/uploads/" />
<cfset request.uploadRootPath = expandPath(request.uploadWebRoot) />

<!--- icons --->
<cfset request.directoryIcon = "images/fileicons/_Open.png" />
<cfset request.defaultIcon = "images/fileicons/default.png" />

<!--- it's your function: how do you determine when a user can add/edit files?
Some options:
- check for the existence of a specific cookie
	<cfif structKeyExists(cookie, "userLoggedIn")><cfreturn true /><cfelse><cfreturn false /></cfif>
- first include the Application.cfm from your website here, and then check if the user isLoggedIn()
	<cfinclude template="/Application.cfm" />
	<cfif isUserLoggedIn()><cfreturn true /><cfelse><cfreturn false /></cfif>
- check on IP
	<cfif cgi.remote_addr eq "123.45.67.89"><cfreturn true /><cfelse><cfreturn false /></cfif>
 --->
<cffunction name="isAllowed" access="public" returntype="boolean">
	<cfreturn true />
</cffunction>

<!---  used in /scripts/jquery_filetree/ --->
<cfset variables.jqueryFileTree_webroot = request.uploadWebRoot />
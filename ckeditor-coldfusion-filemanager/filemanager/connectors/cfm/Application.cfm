<!---
 *	Filemanager CFM connector
 *
 *	Application.cfm
 *	use for ckeditor filemanager plug-in by Core Five - http://labs.corefive.com/Projects/FileManager/
 *
 *	@license	MIT License
 *	@author		Paul Klinkenberg, www.coldfusiondeveloper.nl/post.cfm/cfm-connector-for-ckeditor-corefive-Filemanager
 *  @date		February 28, 2010
 *  @version	1.0
 *	@copyright	Authors
--->
<cfapplication name="filemanager_#cgi.http_host#" applicationtimeout="#createTimeSpan(1,0,0,0)#" sessionmanagement="no" clientmanagement="no" />

<!--- initialize the filemanager object if not yet existent --->
<cfif not structKeyExists(application, "filemanager_obj") or structKeyExists(url, "init")>
	<cfset application.filemanager_obj = createObject('component', 'filemanager-functions') />
</cfif>

<!--- include the config data --->
<cfinclude template="filemanager.config.cfm" />

<!--- it's your function: how do you determine when a user can add/edit files? --->
<cffunction name="isAllowed" access="public" returntype="boolean">
	<cfreturn true />
</cffunction>
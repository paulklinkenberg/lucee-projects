<!---
 *	Filemanager CFM connector
 *
 *	Application.cfm
 *	use for ckeditor filemanager plug-in by Core Five - http://labs.corefive.com/Projects/FileManager/
 *
 *	@license	MIT License
 *	@author		Paul Klinkenberg, www.railodeveloper.com/post.cfm/cfm-connector-for-ckeditor-corefive-Filemanager
 *  @date		February 28, 2010
 *  @version	1.0
 				1.1 April 25, 2010: Fixed some bugs and added some functionality
 *	@copyright	Authors
--->
<cfapplication name="filemanager_#cgi.http_host#" applicationtimeout="#createTimeSpan(1,0,0,0)#" sessionmanagement="no" clientmanagement="no" />

<!--- initialize the filemanager object if not yet existent --->
<cfif not structKeyExists(application, "filemanager_obj") or structKeyExists(url, "init")>
	<cfset application.filemanager_obj = createObject('component', 'filemanager-functions') />
</cfif>

<!--- include the config data --->
<cfinclude template="filemanager.config.cfm" />

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
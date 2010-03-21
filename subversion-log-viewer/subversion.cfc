<cfcomponent output="false">
<!---
/*
 * subversion.cfc, originally developed by Carlos Gallupa BV, http://carlosgallupa.com/
 * Edited by Paul Klinkenberg, http://www.coldfusiondeveloper.nl/post.cfm/subversion-log-viewer-in-coldfusion
 *
 * Date: 2009-11-27 22:39:00 +0100
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
	<!--- By default, I expect you to have this file (subversion.cfc) in a subdirectory of the versioned root --->
	<cfset variables.defaultSvnPath = replace(expandpath('../'), '\', '/', 'all') />
	<cfset variables.settings = structNew() />
	<cfset variables.settings.user = "" />
	<cfset variables.settings.pass = "" />
	<cfset variables.settings.svnPath = variables.defaultSvnPath />

	<!--- Local svn executable on windows --->
	<cfif fileExists('C:/subversion/svn.exe')>
		<cfset variables.settings.executable = "C:/subversion/svn.exe" />
	<!--- otherwise, I expect you to have the directory with the subversion executable in your class path --->
	<cfelse>
		<cfset variables.settings.executable = "svn" />
	</cfif>
	<cfset variables.userAndPasswordArgument = "" />	
	
	
	<cffunction name="init" returntype="any">
		<cfargument name="svnPath" type="string" required="no" />
		<cfargument name="user" type="string" required="no" />
		<cfargument name="pass" type="string" required="no" />
		<cfset var key = "" />
		<!--- CF7 has a stupid fault: when looping through the arguments collection, even undefined arguments are looped over.
		So we need to check if the key actually exists ;-/ --->
		<cfloop collection="#arguments#" item="key"><cfif structKeyExists(arguments, key)>
			<cfset variables.settings[key] = arguments[key] />
		</cfif></cfloop>
		
		<cfif len(variables.settings.user)>
			<cfset variables.userAndPasswordArgument = " --username #variables.settings.user# --password #variables.settings.pass#" />
		<cfelse>
			<cfset variables.userAndPasswordArgument = "" />	
		</cfif>
		<cfif not len(variables.settings.svnPath)>
			<cfset variables.settings.svnPath = variables.defaultSvnPath />
		</cfif>
		<cfreturn this />
	</cffunction>
	
	
	<cffunction name="getinfo" returntype="struct">
		<cfargument name="svnPath" type="string" required="no" default="#variables.settings.svnPath#" />
		<cfset var stInfo = structNew() />
		<cfset var line = "" />
		<cfset var strInfo = "" />
		
		<!--- Get the current working copy info --->
		<cfexecute name="#variables.settings.executable#" arguments="info #arguments.svnPath##variables.userAndPasswordArgument#" variable="strInfo" timeout="60"></cfexecute>

		<cfif len(strInfo) neq 0>
			<cfloop list="#strInfo#" delimiters="#chr(10)##chr(13)#" index="line">
				<cfset line = trim(line) />

				<cfset stInfo[trim(listFirst(line,":"))] = trim(ListRest(line,":")) />
			</cfloop>
		</cfif>

		<cfreturn stInfo />
	</cffunction>

	<cffunction name="getlog" returntype="string">
		<cfargument name="startRev" required="yes" type="numeric" />
		<cfargument name="endRev" required="yes" type="any" hint="Enter a number or 'HEAD'" />
		<cfargument name="svnPath" type="string" required="no" default="#variables.settings.svnPath#" />
		<cfset var msg = "" />

		<!--- Get the current working copy info --->
		<cfexecute name="#variables.settings.executable#" arguments="log #arguments.svnPath# -r #arguments.startRev#:#arguments.endRev# -v#variables.userAndPasswordArgument#" variable="msg" timeout="60"></cfexecute>

		<cfreturn msg />
	</cffunction>

	<cffunction name="update" returntype="string">
		<cfargument name="revision" required="no" type="any" default="HEAD" hint="a rev.nr. or HEAD" />
		<cfargument name="svnPath" type="string" required="no" default="#variables.settings.svnPath#" />
		<cfset var msg = "" />
		
		<cfif not refind("^([0-9]+|HEAD)$", arguments.revision)>
			<cfthrow message="Illegal revision argument '#arguments.revision#'! Only numbers or 'HEAD' is supported." />
		</cfif>
		
		<cfif arguments.revision eq "HEAD">
			<!--- Update the current working copy to the repository state --->
			<cfexecute name="#variables.settings.executable#" arguments="update #arguments.svnPath##variables.userAndPasswordArgument#" variable="msg" timeout="60"></cfexecute>
		<cfelse>
			<!--- Update to another revision --->
			<cfexecute name="#variables.settings.executable#" arguments="update -r #arguments.revision# #arguments.svnPath##variables.userAndPasswordArgument#" variable="msg" timeout="60"></cfexecute>
		</cfif>

		<cfreturn msg />
	</cffunction>

	<cffunction name="status" returntype="string">
		<cfargument name="svnPath" type="string" required="no" default="#variables.settings.svnPath#" />
		<cfset var msg = "" />

		<!--- Get the current working copy info --->
		<cfexecute name="#variables.settings.executable#" arguments="status -u #arguments.svnPath##variables.userAndPasswordArgument#" variable="msg" timeout="60"></cfexecute>

		<cfreturn msg />
	</cffunction>

</cfcomponent>
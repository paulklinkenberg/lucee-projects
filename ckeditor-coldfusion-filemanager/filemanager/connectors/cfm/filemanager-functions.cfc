<!---
 *	Filemanager CFM connector
 *
 *	filemanager-functions.cfc
 *	use for ckeditor filemanager plug-in by Core Five - http://labs.corefive.com/Projects/FileManager/
 *
 *	@license	MIT License
 *	@author		Paul Klinkenberg, www.railodeveloper.com/post.cfm/cfm-connector-for-ckeditor-corefive-Filemanager
 *  @date		November 17, 2010
 *  @version	2.0
 				1.1 April 25, 2010: Fixed some bugs and added some functionality
 				2.0 November 17, 2010: Lots of changes and bugfixes in the javascript code
 				2.0.1 February 26, 2011: Added debug text to the json output, if an error occured.
 *	@copyright	Authors
---><cfcomponent output="no" hint="functions for the cfml filemanager connector">
	
	<cfset variables.translations = structNew() />
	<cfset variables.separator = createObject("java", "java.io.File").separator />
	<cfset variables.imageInfo_struct = structNew() />
		
	
	<cffunction name="translate" access="public" returntype="string">
		<cfargument name="key" type="string" required="yes" />
		<cfset var lang = structNew() />
		<cfset var ret_str = "" />
		<cfset var findCount = 0 />
		<cfset var pathFromWebRoot = "" />
		
		<cfif not structKeyExists(variables.translations, request.language)>
			<cfinclude template="lang/#request.language#.cfm" />
			<cfset structInsert(variables.translations, request.language, lang, true) />
		</cfif>
		
		<cfset ret_str = variables.translations[request.language][arguments.key] />
		<cfloop condition="refind('\%s', ret_str)">
			<cfset findCount=findCount+1 />
			<cfset ret_str = replace(ret_str, '%s', arguments[findCount+1]) />
		</cfloop>
		<cfreturn ret_str />
	</cffunction>
	
	
	<cffunction name="returnError" returntype="void" access="public">
		<cfargument name="str" required="yes" type="string" />
		<cfargument name="textarea" type="boolean" required="no" default="false" />
		<cfargument name="debugText" required="no" type="string" />
		<cfset var returnData_struct = structNew() />
		<cfset structInsert(returnData_struct, "Error", arguments.str) />
		<cfset structInsert(returnData_struct, "Code", -1) />
		<cfif structKeyExists(arguments, "debugText")>
			<cfset structInsert(returnData_struct, "DebugData", arguments.debugText) />
		</cfif>
		<cfset _doOutput(jsonData=returnData_struct, textarea=arguments.textarea) />
	</cffunction>
	
	
	<cffunction name="download" returntype="void" access="public">
		<cfargument name="path" type="string" required="yes" />
		<cfset var absPath = _getPath(arguments.path) />
		<!--- check if file exists --->
		<cfif not fileExists(absPath)>
			<cfset returnError(translate('FILE_DOES_NOT_EXIST', arguments.path)) />
		</cfif>
		<!--- pass the file through for download --->
		<cfheader name="Content-Disposition" value="attachment;filename=#listLast(absPath, '/\')#" />
		<cfcontent reset="yes" type="application/x-download-#listLast(absPath, '.')#" file="#absPath#" deletefile="no" />
	</cffunction>
	
	
	<cffunction name="delete" returntype="void" access="public">
		<cfargument name="path" type="string" required="yes" />
		<cfset var absPath = _getPath(arguments.path) />
		<cfset var parentPath = _getParentPath(absPath) />
		<cfset var filename = listLast(absPath, variables.separator) />
		<cfset var isDir = _isDirectory(absPath) />
		<cfset var dirlist_qry = "" />
		<cfset var jsondata_struct = "" />
		<cfset var shortenedWebPath = replaceNoCase(arguments.path, request.uploadWebRoot, "/") />
		
		<cfif isDir>
			<!--- check if dir exists --->
			<cfif not DirectoryExists(absPath)>
				<cfset returnError(translate('DIRECTORY_NOT_EXIST', arguments.path)) />
			</cfif>
			<!--- check if directory is empty --->
			<cfdirectory action="list" directory="#absPath#" name="dirlist_qry" />
			<cfloop query="dirlist_qry">
				<cfif not listfind(".,..", dirlist_qry.name, ",")>
					<cfset returnError(translate('DIRECTORY_NOT_EMPTY', arguments.path)) />
				</cfif>
			</cfloop>
			<!--- delete dir --->
			<cftry>
				<cfdirectory action="delete" directory="#absPath#" />
				<cfcatch>
					<cfset returnError(translate('DIRECTORY_NOT_DELETED', arguments.path), false, cfcatch.message & " - " & cfcatch.detail) />
				</cfcatch>
			</cftry>
		<cfelse>
			<!--- check if file exists --->
			<cfif not fileExists(absPath)>
				<cfset returnError(translate('FILE_DOES_NOT_EXIST', arguments.path)) />
			</cfif>
			<!--- delete file --->
			<cftry>
				<cffile action="delete" file="#absPath#" />
				<cfcatch>
					<cfset returnError(translate('FILE_NOT_DELETED', arguments.path, cfcatch.message & " - " & cfcatch.detail)) />
				</cfcatch>
			</cftry>
			<cfset _clearImageInfoCache(arguments.path) />
		</cfif>
		
		<cfset jsondata_struct = structNew() />
		<cfset structInsert(jsondata_struct, "Error", "") />
		<cfset structInsert(jsondata_struct, "Code", 0) />
		<cfset structInsert(jsondata_struct, "Path", shortenedWebPath) />
		<cfset _doOutput(jsondata_struct) />
	</cffunction>
	
	
	<cffunction name="getInfo" returntype="void" access="public">
		<cfargument name="path" type="string" required="yes" />
		<cfargument name="getsize" type="boolean" required="no" default="true" />
		<cfset var dirPath = _getParentPath(arguments.path) />
		<cfset var filename = listLast(arguments.path, "/") />
		<cfset var data_arr = _getDirectoryInfo(path=dirPath, getsizes=arguments.getsize, filter=filename) />
		<cfset var key = "" />
		
		<cfif arrayIsEmpty(data_arr)>
			<cfset returnError(translate('FILE_DOES_NOT_EXIST', arguments.path)) />
		</cfif>
		
		<cfset _doOutput(data_arr[1]) />
	</cffunction>
	
	
	<cffunction name="getFolder" returntype="void" access="public">
		<cfargument name="path" type="string" required="yes" />
		<cfargument name="getsizes" type="boolean" required="no" default="true" />
		<cfset var data_arr = _getDirectoryInfo(argumentcollection=arguments) />
		
		<cfset _doOutput(data_arr) />
	</cffunction>
	
	
	<cffunction name="_getDirectoryInfo" returntype="array" access="private">
		<cfargument name="path" type="string" required="yes" />
		<cfargument name="getsizes" type="boolean" required="yes" />
		<cfargument name="filter" type="string" required="no" default="" />
		<cfset var dirPath = _getPath(arguments.path) />
		<cfset var dirlist_qry = "" />
		<cfset var data_arr = arrayNew(1) />
		<cfset var currData_struct = "" />
		<cfset var imageData_struct = "" />
		<cfset var webDirPath = _getWebPath(path) />
		<cfset var displayWebPath = _getWebPath(path=arguments.path, includeUploadRoot=false) />
		
		<cfif not DirectoryExists(dirPath)>
			<cfset returnError(translate('DIRECTORY_NOT_EXIST', dirPath)) />
		</cfif>
		
		<cftry>
			<cfdirectory action="list" directory="#dirPath#" name="dirlist_qry" sort="type,name" filter="#arguments.filter#" />
			<cfcatch>
				<cfset returnError(translate('UNABLE_TO_OPEN_DIRECTORY', arguments.path, cfcatch.message & " - " & cfcatch.detail)) />
			</cfcatch>
		</cftry>
		
		<cfloop query="dirlist_qry"><cfif find('.', dirlist_qry.name) neq 1>
			<cfset currData_struct = structNew() />
			<cfset arrayAppend(data_arr, currData_struct) />

			<cfset structInsert(currData_struct, "Filename", dirlist_qry.name) />
			<cfset structInsert(currData_struct, "Error", "") />
			<cfset structInsert(currData_struct, "Code", 0) />
			<cfset structInsert(currData_struct, "Properties", structNew()) />
				<cfset structInsert(currData_struct.Properties, "Date Created", "") />
				<cfset structInsert(currData_struct.Properties, "Date Modified", "#lsdateformat(dateLastModified, 'medium')# #timeformat(dateLastModified, 'HH:mm:ss')#") />
				<cfset structInsert(currData_struct.Properties, "Height", "") />
				<cfset structInsert(currData_struct.Properties, "Width", "") />
			<cfif dirlist_qry.type eq "DIR">
				<cfset structInsert(currData_struct, "Path", webDirPath & dirlist_qry.name & "/") />
				<cfset structInsert(currData_struct, "VisiblePath", displayWebPath & dirlist_qry.name & "/") />
				<cfset structInsert(currData_struct, "File Type", "dir") />
				<cfset structInsert(currData_struct, "Preview", request.directoryIcon) />
				<cfset structInsert(currData_struct.Properties, "Size", "") />
			<cfelse>
				<cfset structInsert(currData_struct, "Path", webDirPath & dirlist_qry.name) />
				<cfset structInsert(currData_struct, "VisiblePath", displayWebPath & dirlist_qry.name) />
				<cfset structInsert(currData_struct, "File Type", lCase(listlast(dirlist_qry.name, '.'))) />
				<cfset structInsert(currData_struct.Properties, "Size", dirlist_qry.size) />
				<cfif _isImage(dirlist_qry.directory & variables.separator & dirlist_qry.name)>
					<cfset structInsert(currData_struct, "Preview", webDirPath & dirlist_qry.name) />
					<cfif arguments.getsizes>
						<cfset imageData_struct = _getImageInfo(dirlist_qry.directory & variables.separator & dirlist_qry.name) />
						<cfset structInsert(currData_struct.Properties, "Height", imageData_struct.height, true) />
						<cfset structInsert(currData_struct.Properties, "Width", imageData_struct.width, true) />
					</cfif>
				<cfelse>
					<cfset structInsert(currData_struct, "Preview", request.defaultIcon) />
				</cfif>
			</cfif>
		</cfif></cfloop>
		
		<cfreturn data_arr />
	</cffunction>
	
	
	<cffunction name="rename" returntype="void" access="public">
		<cfargument name="oldPath" type="string" required="yes" />
		<cfargument name="newName" required="yes" type="string" />
		<cfset var oldDirPath = _getPath(arguments.oldPath) />
		<cfset var oldParentPath = _getParentPath(arguments.oldPath) />
		<cfset var parentDirPath = _getPath(oldParentPath) />
		<cfset var fileOrDirName = listlast(oldDirPath, variables.separator) />
		<cfset var isDir = _isDirectory(oldDirPath) />
		<cfset var dirList_qry = "" />
		<cfset var returnData_struct = structNew() />

		<!--- make sure the newName has no illegal characters--->
		<cfset arguments.newName = rereplace(arguments.newName, "[^a-zA-Z0-9\-_]+", "-", "ALL") />
		
		<cfif isDir>
			<cfif not DirectoryExists(oldDirPath)>
				<cfset returnError(translate('DIRECTORY_NOT_EXIST', arguments.oldPath)) />
			<cfelseif directoryExists(parentDirPath & arguments.newName)>
				<cfset returnError(translate('DIRECTORY_ALREADY_EXISTS', oldParentPath & arguments.newName)) />
			<cfelseif listLast(oldDirPath, variables.separator) neq arguments.newName>
				<cftry>
					<cfdirectory action="rename" directory="#oldDirPath#" newdirectory="#arguments.newName#" />
					<cfcatch>
						<cfset returnError(translate('ERROR_RENAMING_DIRECTORY', arguments.oldPath, arguments.newName), false, cfcatch.message & " - " & cfcatch.detail) />
					</cfcatch>
				</cftry>
			</cfif>
		<cfelse>
			<!--- re-add file extension, if the extension is still the same --->
			<cfif refindNoCase("\.[a-z0-9]+$", oldPath)>
				<cfset arguments.newName = rereplaceNoCase(arguments.newName, "\-(#listLast(oldPath, '.')#)$", ".\1") />
				<!--- check if extension is still the same --->
				<cfif listLast(oldPath, '.') neq listLast(arguments.newName, '.')>
					<cfset arguments.newName = arguments.newName & "." & listLast(oldPath, '.') />
				</cfif>
			</cfif>
			<cfif not fileExists(oldDirPath)>
				<cfset returnError(translate('FILE_DOES_NOT_EXIST', oldParentPath & arguments.newName)) />
			<cfelseif fileExists(parentDirPath & arguments.newName)>
				<cfset returnError(translate('FILE_ALREADY_EXISTS', parentDirPath & arguments.newName)) />
			<cfelseif listLast(oldDirPath, variables.separator) neq arguments.newName>
				<cftry>
					<cffile action="rename" source="#oldDirPath#" destination="#parentDirPath##arguments.newName#" />
					<cfcatch>
					<cfrethrow />
						<cfset returnError(translate('ERROR_RENAMING_FILE', arguments.oldPath, arguments.newName), false, cfcatch.message & " - " & cfcatch.detail) />
					</cfcatch>
				</cftry>
				<cfset _clearImageInfoCache(arguments.oldPath) />
			</cfif>
		</cfif>

		<!--- response to client --->
		<cfset returnData_struct = structNew() />
		<cfset structInsert(returnData_struct, "Error", "") />
		<cfset structInsert(returnData_struct, "Code", 0) />
		<cfset structInsert(returnData_struct, "Old Path", arguments.oldPath) />
		<cfset structInsert(returnData_struct, "Old Name", fileOrDirName) />
		<cfset structInsert(returnData_struct, "New Path", "#_getWebPath(path=oldParentPath, includeUploadRoot=false)##arguments.newName##iif(isDir, de('/'), de(''))#") />
		<cfset structInsert(returnData_struct, "New Name", arguments.newName) />
		<cfset _doOutput(returnData_struct) />
	</cffunction>
	
	
	<cffunction name="addFolder" returntype="void" access="public">
		<cfargument name="path" type="string" required="yes" />
		<cfargument name="dirname" required="yes" type="string" />
		<cfset var newDirPath = "" />
		<cfset var returnData_struct = structNew() />
		
		<cfset arguments.dirName = rereplace(arguments.dirName, "[^a-zA-Z0-9-_]+", "-", "ALL") />
		<cfset newDirPath = _getPath(arguments.path, arguments.dirname) />

		<cfif directoryExists(newDirPath)>
			<cfset returnError(translate('DIRECTORY_ALREADY_EXISTS', arguments.path & arguments.dirname)) />
		</cfif>
		<cftry>
			<cfdirectory action="create" directory="#newDirPath#" recurse="no" />
			<cfcatch>
				<cfset returnError(translate('UNABLE_TO_CREATE_DIRECTORY', arguments.dirname), false, cfcatch.message & " - " & cfcatch.detail) />
			</cfcatch>
		</cftry>
		
		<!--- response to client --->
		<cfset returnData_struct = structNew() />
		<cfset structInsert(returnData_struct, "Error", "") />
		<cfset structInsert(returnData_struct, "Code", 0) />
		<cfset structInsert(returnData_struct, "Parent", arguments.path) />
		<cfset structInsert(returnData_struct, "Name", arguments.dirName) />
		<cfset _doOutput(returnData_struct) />
	</cffunction>
	
	
	<cffunction name="addFile" returntype="void" access="public">
		<cfargument name="path" type="string" required="yes" />
		<cfargument name="formfieldname" required="yes" type="string" />
		<cfargument name="textarea" required="yes" type="boolean" default="true" />
		<cfset var file_struct = "" />
		<cfset var newFileName = "" />
		<cfset var loopCounter_num = 0 />
		<cfset var returnData_struct = structNew() />
		<cfset var imageData = "" />
		<cfset var cfcatch = "" />

		<!--- upload the file --->
		<cftry>
			<cffile action="upload" destination="#getTempDirectory()#" filefield="#formfieldname#" nameconflict="makeunique" result="file_struct" />
			<cfcatch>
				<cfset returnError(str=translate('INVALID_FILE_UPLOAD'), textarea=arguments.textarea, debugText=cfcatch.message & " - " & cfcatch.detail) />
			</cfcatch>
		</cftry>
		<!--- check for max file size --->
		<cfif file_struct.filesize gt request.maxFileSizeKB*1024>
			<cfset returnError(str=translate('UPLOAD_FILES_SMALLER_THAN', request.maxFileSizeKB & "KB"), textarea=arguments.textarea) />
		</cfif>
		<!--- check for allowed extensions --->
		<cfif not request.allowAllFiles and not listFindNoCase(request.allowedExtensions, file_struct.serverfileExt)>
			<cfset returnError(str=translate('INVALID_FILE_UPLOAD'), textarea=arguments.textarea) />
		</cfif>
		<!--- check if it is/should be an image --->
		<cfif request.onlyImageUploads or (structKeyExists(form, "type") and form.type eq "Images")>
			<cfif not listFindNoCase(request.allowedImageExtensions, file_struct.serverfileExt)>
				<cfset returnError(str=translate('UPLOAD_IMAGES_TYPES_ABC', request.allowedImageExtensions), textarea=arguments.textarea) />
			</cfif>
		</cfif>
		<cfset newFileName = rereplace(file_struct.serverfileName, "[^a-zA-Z0-9-_]+", "-", "all") & ".#file_struct.serverFileExt#" />
		<!--- if overwriting an existing file --->
		<cfif fileExists(_getPath(arguments.path, newFileName))>
			<cfif request.uploadCanOverwrite>
				<cffile action="delete" file="#_getPath(arguments.path, newFileName)#" />
				<cfset _clearImageInfoCache(arguments.path & newFileName) />
			<cfelse>
				<cfloop condition="fileExists(_getPath(arguments.path, newFileName))">
					<cfset loopCounter_num=loopCounter_num+1 />
					<cfset newFileName = rereplace(newFileName, "(#loopCounter_num-1#)?\.", "#loopCounter_num#.") />
				</cfloop>
			</cfif>
		</cfif>
		<!--- create the destination directory if it does not exist yet --->
		<cfif not DirectoryExists(_getPath(arguments.path))>
			<cfdirectory action="create" directory="#_getPath(arguments.path)#" recurse="yes" />
		</cfif>
		<!--- move the file from Temp to the actual dir. --->
		<cffile action="move" source="#file_struct.serverDirectory##variables.separator##file_struct.serverFile#"
		destination="#_getPath(arguments.path, newFileName)#" />
		
		<!--- response to client --->
		<cfif arguments.textarea>
			<cfset returnData_struct = structNew() />
			<cfset structInsert(returnData_struct, "Error", "") />
			<cfset structInsert(returnData_struct, "Code", 0) />
			<cfset structInsert(returnData_struct, "Path", arguments.path) />
			<cfset structInsert(returnData_struct, "Name", newFileName) />
			<cfset _doOutput(jsondata=returnData_struct, textarea=true) />
		<!--- hacker-the-hack: a quick fix for the Quick-upload function within CKEDITOR. --->
		<cfelse>
			<cfcontent type="text/html" reset="yes" />
			<cfoutput><script type="text/javascript">
				window.parent.CKEDITOR.tools.callFunction(#url.CKEditorFuncNum#, '#jsStringFormat(_getWebPath(arguments.path, newFilename))#');
			</script></cfoutput>
			<cfabort />
		</cfif>
	</cffunction>
	
	
	<cffunction name="_getPath" access="private" returntype="string">
		<cfargument name="path" type="string" required="yes" />
		<cfargument name="filename" type="string" required="no" default="" />
		<cfset var newPath_str = "" />
		<!--- remove any "../" and "..\" from the given path --->
		<cfset arguments.path = rereplace(arguments.path, "\.\.+([/\\])", "\1", "all") />
		
		<!--- if the given (web) path starts with the upload webroot--->
		<cfif findNoCase(request.uploadWebRoot, arguments.path) eq 1>
			<cfset newPath_str = request.uploadRootPath & variables.separator & replaceNoCase(arguments.path, request.uploadWebRoot, "/") />
		<cfelse>
			<cfset newPath_str = request.uploadRootPath & variables.separator & arguments.path />
		</cfif>
		
		<cfif len(filename)>
			<cfset newPath_str = newPath_str & variables.separator & arguments.filename />
		<!--- if not a specific file given, check if the given path ends with a slash or a name with a dot in it --->
		<cfelseif not refind("[/\\][^/\\\.]+$", newPath_str)>
			<cfset newPath_str = newPath_str & variables.separator />
		</cfif>
		<cfset newPath_str = rereplace(newPath_str, '[/\\]+', variables.separator, "all") />
		<cfreturn newPath_str />
	</cffunction>
	

	<cffunction name="_getWebPath" access="private" returntype="string" output="no">
		<cfargument name="path" type="string" required="yes" />
		<cfargument name="filename" type="string" required="no" default="" />
		<cfargument name="includeUploadRoot" type="boolean" required="no" default="true" />
		<cfset var webPath = "" />
		<!--- remove any "../" and "..\" from the given path --->
		<cfset arguments.path = rereplace(arguments.path, "\.\.+([/\\])", "\1", "all") />
		<cfif findNoCase(request.uploadWebRoot, arguments.path) eq 1>
			<cfset webPath = arguments.path & variables.separator & arguments.filename />
		<cfelse>
			<cfset webPath = request.uploadWebRoot & variables.separator & arguments.path & variables.separator & arguments.filename />
		</cfif>
		<cfset webpath = rereplace(webPath, "[/\\]+", "/", "all") />
		<cfif not arguments.includeUploadRoot>
			<cfset webPath = replaceNoCase(webPath, request.uploadWebRoot, "/") />
		</cfif>
		<cfreturn webPath />
	</cffunction>
	
	
	<cffunction name="_isImage" access="private" returntype="boolean">
		<cfargument name="path" required="yes" type="string" />
		<cfreturn (listFindNoCase("png,jpg,jpeg,gif", listlast(path, '.')) gt 0) />
	</cffunction>


	<cffunction name="_getImageInfo" access="private" returntype="struct">
		<cfargument name="path" required="yes" type="string" />
		<cfset var cfimagedata_struct = "" />
		<cfset var cfimage_struct = "" />
		<cfset var imageData_struct = structNew() />
		<cfif not structKeyExists(variables.imageInfo_struct, arguments.path)>
			<cftry>
				<!--- use a temp variable name for the cfimage data, so in case the cfimage read goes wrong, the variable we will keep on using will not become unscoped. --->
				<cfimage action="info" source="#arguments.path#" structname="cfimagedata_struct" />
				<cfset cfimage_struct = cfimagedata_struct />
				<cfcatch>
					<cfset cfimage_struct = structNew() />
					<cfset cfimage_struct['width'] = 'Error ' />
					<cfset cfimage_struct['height'] = jsstringformat("#getfilefrompath(arguments.path)#: #cfcatch.message#") />
				</cfcatch>
			</cftry>
			<!--- workaround for railobug #611: https://jira.jboss.org/jira/browse/RAILO-611 --->
			<cfif structKeyExists(server, "Railo")>
				<cfset cfimage_struct = duplicate(cfimage_struct) />
			</cfif>
			<cfset structInsert(imageData_struct, "Width", cfimage_struct.width) />
			<cfset structInsert(imageData_struct, "Height", cfimage_struct.height) />
			<cfset structInsert(variables.imageInfo_struct, arguments.path, imageData_struct, true) />
		</cfif>
		<cfreturn variables.imageInfo_struct[arguments.path] />
	</cffunction>
	
	
	<cffunction name="_clearImageInfoCache" access="private" returntype="void">
		<cfargument name="path" required="no" type="string" />
		<cfif structKeyExists(arguments, "path")>
			<cfset StructDelete(variables.imageInfo_struct, arguments.path, false) />
		<cfelse>
			<cfset structClear(variables.imageInfo_struct) />
		</cfif>
	</cffunction>
	

	<cffunction name="_isDirectory" access="private" returntype="boolean">
		<cfargument name="absPath" type="string" required="yes" />
		<cfset var parentPath = _getParentPath(arguments.absPath) />
		<cfset var fileOrDirName = listlast(arguments.absPath, variables.separator) />
		<cfset var dirList_qry = "" />
		<!--- check if it is a directory --->
		<cfdirectory action="list" name="dirList_qry" directory="#parentPath#" filter="#fileOrDirName#" />
		<cfreturn (dirlist_qry.recordcount and dirList_qry.type eq "DIR") />
	</cffunction>


	<cffunction name="_doOutput" access="public" returntype="void">
		<cfargument name="jsonData" type="any" required="yes" />
		<cfargument name="textarea" type="boolean" required="no" default="false" />
		<cfset var ret_str = SerializeJSON(jsonData) />
		<cfif arguments.textarea>
			<cfset ret_str = "<textarea>" & ret_str & "</textarea>" />
		</cfif>
		<!--- the real output to screen --->
		<cfcontent reset="yes" type="#iif(arguments.textarea, de('text/html'), de('application/json'))#" /><!---
		---><cfoutput>#ret_str#</cfoutput><!---
		---><cfabort />
	</cffunction>
	
	
	<cffunction name="_getParentPath" access="private" returntype="string">
		<cfreturn rereplace(arguments[1], '[^/\\]+[/\\]?$', '') />
	</cffunction>
	

</cfcomponent>
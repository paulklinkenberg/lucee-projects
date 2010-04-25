<!---
 *	Filemanager CFM connector
 *
 *	filemanager.config.cfm
 *	use for ckeditor filemanager plug-in by Core Five - http://labs.corefive.com/Projects/FileManager/
 *
 *	@license	MIT License
 *	@author		Paul Klinkenberg, www.coldfusiondeveloper.nl/post.cfm/cfm-connector-for-ckeditor-corefive-Filemanager
 *  @date		February 28, 2010
 *  @version	1.0
 				1.1 April 25, 2010: Fixed some bugs and added some functionality
 *	@copyright	Authors
--->
<cfset request.language = "nl" /><!--- see directory 'lang' --->
<cfset request.maxFileSizeKB = 10000 /><!--- max. upload file size, in KiloBytes (1.000 KB = 1 MB) --->
<cfset request.onlyImageUploads = false />
<cfset request.allowedImageExtensions = "jpg,jpeg,gif,png" />
<cfset request.allowAllFiles = false /><!--- should we allow all files? If true, we do not check the extension. --->
<cfset request.allowedExtensions = "zip,rar,psd,tif,gz,odf,odt,ods,txt,csv,pdf,doc,docx,xls,xlsx,ppt,pptx" & ",#request.allowedImageExtensions#" />
<cfset request.uploadCanOverwrite = true /><!--- If a file is uploaded with a name which already exists, should we rename it or overwrite it? --->
<cfset request.uploadWebRoot = "/uploads/" />
<cfset request.uploadRootPath = expandPath(request.uploadWebRoot) />

<!--- icons --->
<cfset request.directoryIcon = "images/fileicons/_Open.png" />
<cfset request.defaultIcon = "images/fileicons/default.png" />
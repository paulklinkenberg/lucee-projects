<!---
 *	Filemanager CFM connector
 *
 *	filemanager.config.cfm
 *	use for ckeditor filemanager plug-in by Core Five - http://labs.corefive.com/Projects/FileManager/
 *
 *	@license	MIT License
 *	@author		Paul Klinkenberg, www.railodeveloper.com/post.cfm/cfm-connector-for-ckeditor-corefive-Filemanager
 *  @date		November 17, 2010
 *  @version	2.0
 				1.1 April 25, 2010: Fixed some bugs and added some functionality
 				2.0 November 17, 2010: Lots of changes and bugfixes in the javascript code
 *	@copyright	Authors
--->
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
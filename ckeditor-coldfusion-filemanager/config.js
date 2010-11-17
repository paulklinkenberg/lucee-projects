/*
Copyright (c) 2003-2010, CKSource - Frederico Knabben. All rights reserved.
For licensing, see LICENSE.html or http://ckeditor.com/license
*/

CKEDITOR.editorConfig = function( config )
{
	// Define changes to default configuration here. For example:
	// config.language = 'fr';
	// config.uiColor = '#AADC6E';
	config.skin = 'v2';
	
	config.extraPlugins = 'MediaEmbed';
	
	config.resize_maxWidth = "100%";
	config.language = 'en';
	
	config.toolbar = 'Default';
	
	config.toolbarCanCollapse = false;
	
	config.toolbar_Default = [
		['Source','-','Preview','-','Cut','Copy','Paste','PasteText','PasteFromWord','RemoveFormat'],
		['Undo','Redo','-','Bold','Italic','Underline'],
		['Strike','Subscript','Superscript'],
		['NumberedList','BulletedList','-','Outdent','Indent'],
		['JustifyLeft','JustifyCenter','JustifyRight','JustifyBlock'],
		['Link','Unlink'],
		['Image','Flash','MediaEmbed','Table'],
		['HorizontalRule','SpecialChar'],
		['Format'],
		//['FontSize'],
		['TextColor','BGColor']
	];
	
	config.toolbar_Basic = [
		['Source','-','Cut','Copy','PasteText'],
		['Bold', 'Italic', '-', 'NumberedList', 'BulletedList', '-', 'Link', 'Unlink','-','RemoveFormat']
	];
	
// the 'currentfolder' is relative to the path 'request.uploadWebRoot' which is set in
// /filemanaer/connectors/cfm/filemanager.config.cfm. So, if your uploadWebroot is '/uploads/',
// and the 'currentFolder is '/Image/', then the files will be uploaded to /uploads/Image/.
	config.filebrowserBrowseUrl = 'filemanager/index.html';
 	config.filebrowserImageBrowseUrl = 'filemanager/index.html?type=Images&currentFolder=/Image/';
 	config.filebrowserFlashBrowseUrl = 'filemanager/index.html?type=Flash&currentFolder=/Flash/';
 	config.filebrowserUploadUrl = 'filemanager/connectors/cfm/filemanager.cfm?mode=add&type=Files&currentFolder=/File/';
 	config.filebrowserImageUploadUrl = 'filemanager/connectors/cfm/filemanager.cfm?mode=add&type=Images&currentFolder=/Image/';
 	config.filebrowserFlashUploadUrl = 'filemanager/connectors/cfm/filemanager.cfm?mode=add&type=Flash&currentFolder=/Flash/';
};
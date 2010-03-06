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
	config.language = 'nl';
	
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
	

	config.filebrowserBrowseUrl = '/ckeditor/filemanager/index.html';
 	config.filebrowserImageBrowseUrl = '/ckeditor/filemanager/index.html?type=Images&currentFolder=/Image/';
 	config.filebrowserFlashBrowseUrl = '/ckeditor/filemanager/index.html?type=Flash&currentFolder=/Flash/';
 	config.filebrowserUploadUrl = '/ckeditor/filemanager/connectors/cfm/filemanager.cfm?command=QuickUpload&type=Files&currentFolder=/';
 	config.filebrowserImageUploadUrl = '/ckeditor/filemanager/connectors/cfm/filemanager.cfm?command=QuickUpload&type=Images&currentFolder=/Image/';
 	config.filebrowserFlashUploadUrl = '/ckeditor/filemanager/connectors/cfm/filemanager.cfm?command=QuickUpload&type=Flash&currentFolder=/Flash/';
};

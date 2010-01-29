/*
* MultipleSelectPicker, a different interface for using multiple-selects
*
* Copyright (c) 2009 Paul Klinkenberg
* blog: http://www.coldfusiondeveloper.nl/
* Licensed under the GPL license v 3.0, see http://www.gnu.org/copyleft/gpl.html
*
* Date: 2009-05-08 17:56:00 +0100
* Usage:
* <html><head>
*	<script type="text/javascript" src="JQUERY.js"></script>
*	<script type="text/javascript" src="MultipleSelectPicker.js"></script>
*	<script type="text/javascript">
*		var multiSelectPicker = new MultipleSelectPicker();
*		$(document).ready(multiSelectPicker.init);
*	</script>
* </head>
* <body>...</body></html>

*/
function MultipleSelectPicker()
{
	var translations = {
		'nl': {
			'add':		'voeg toe'
			, 'remove':	'verwijder'
		},
		'default': {
			'add':		'add'
			, 'remove':	'remove'
		}
	};
	// this is the lang to use when no lang is given via the init(lng) function
	var lang = 'default';
	this.init = function(lng)
	{
		// set the language
		if (lng && lng in translations)
			lang = lng;
		$('select[multiple]').each(function(){
			var sel = $(this);
			var width = sel.width() - 5;
			sel.css({'width': width/2 + 'px', 'float': 'left'});
			// give the select an id if it didn't have one
			if (sel.attr('id')=='')
				sel.attr('id', sel.attr('name')+'__MultipleSelectPicker');
			var newSel = sel.clone();
			// set new attributes for the sel select (= the left one)
			sel.attr('id', sel.attr('id')+'_choose');
			sel.attr('name', '_xx_');
			sel.css('margin-right', '5px');
			// have the selects point at eachother
			sel.attr('rel', newSel.attr('id'));
			newSel.attr('rel', sel.attr('id'));
			newSel.insertAfter(sel);
			$("<br clear='all' \/>" +
			"<input type='button' style='width:"+(width/2)+"px;margin:5px 5px 0px 0px;' value='"+translate('add')+"&raquo;' class='selectMove_btn' rel='"+sel.attr('id')+"' \/>" +
			"<input type='button' style='width:"+(width/2)+"px;margin:0px;' value='&laquo;"+translate('remove')+"' class='selectMove_btn' rel='"+newSel.attr('id')+"' \/>").insertAfter(newSel);
			// number the options from 1 to n
			sel.find('option').each(function(num){$(this).attr('rel', num)});
			newSel.find('option').remove();
			moveOptions(sel);
			newSel.dblclick( dblClick );
			sel.dblclick( dblClick );
			// timeout is necessary to accomodate clicking the 'remove' button
			newSel.blur(function(evt){
				setTimeout(function(){selectOptions(evt.currentTarget)}, 200) });
		});
		$('.selectMove_btn').click( btnClick );
	};
	var dblClick = function(evt)
	{
		moveOptions(evt.currentTarget);
	};
	var btnClick = function(evt)
	{
		var btn = $(evt.currentTarget);
		var sel = $('#'+btn.attr('rel'));
		moveOptions(sel);
	};
	var moveOptions = function(from)
	{
		from = $(from);
		var to = $("#"+from.attr('rel'));
		from.find('option:selected').remove().appendTo(to);
		sortSelect(to);
		selectOptions(from, to);
	};
	// select the options in the select
	var selectOptions = function(selects)
	{
		for (var i=0; i<arguments.length;i++)
		{
			var sel = $(arguments[i]);
			sel.find('option').attr('selected', (sel.attr('name')!='_xx_'));
		}
	};
	var sortSelect = function(sel)
	{
		sel = $(sel);
		var sortedVals = $.makeArray(sel.find('option')).sort(function(a,b){
			return parseInt($(a).attr('rel')) > parseInt($(b).attr('rel')) ? 1: -1;
		});
		sel.empty().append(sortedVals);
	};
	var translate = function(name)
	{
		return translations[lang][name];
	};
}

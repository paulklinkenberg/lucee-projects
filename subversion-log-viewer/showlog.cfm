<!---
/*
 * showlog.cfm, developed by Paul Klinkenberg
 * http://www.coldfusiondeveloper.nl/post.cfm/subversion-log-viewer-in-coldfusion
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
<cfset setLocale("English (US)") />
<cfset variables.datePickerDateFormat = "m/d/yy" />

<cfparam name="form.startRev" default="" />
<cfparam name="form.endRev" default="HEAD" />
<cfparam name="form.fromDate" default="" />
<cfparam name="form.toDate" default="" />
<cfparam name="form.byName" default="" />
<cfparam name="form.showAllFiles" default="0" type="boolean" />
<cfparam name="form.svnPath" default="http://svn.apache.org/repos/asf/activemq/trunk" />
<cfparam name="form.user" default="" />
<cfparam name="form.pass" default="" />

<cfset variables.subversion_obj = createObject("component","subversion").init(user=form.user, pass=form.pass, svnPath=form.svnPath) />

<!--- get repository info --->
<cfset variables.revInfo = variables.subversion_obj.getInfo() />
<cfset variables.svnPath = rereplace(variables.revInfo.url, '^((svn|https?)(\+ssh)?://)([^@/]+@)', '\1') />

<cfset pageTitle_str = "Subversion log viewer for #variables.svnPath#" />

<cfcontent reset="yes" type="text/html;charset=UTF-8" /><!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
	<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
	<cfoutput><title>#pageTitle_str#</title></cfoutput>
	<script type="text/javascript" src="jquery-1.3.2.min.js"></script>
	<script type="text/javascript" src="jquery-ui-1.7.2.custom.min.js"></script>
	<link href="custom-theme/jquery-ui-1.7.2.custom.css" type="text/css" rel="stylesheet" />
	<cfoutput>
		<script type="text/javascript">
			$(function(){
				$('input.date').datepicker({ dateFormat: '#variables.datePickerDateFormat#', buttonImage: 'calendar.png', buttonImageOnly: true, showOn: 'button' });
				$('##frm').submit(function(e){
					if ($('##startRev').val()=='')
					{
						alert('You haven\'t filled in a start-revision yet!');
						e.preventDefault();
					}
				});
			});
		</script>
	</cfoutput>
	<cfif form.showAllFiles>
		<script type="text/javascript">
			$(function(){
				var $filenumTds = $('td.filenum');
				$('td.filenum').each(function(){
					var $this = $(this);
					var $a = $('<a href="#">'+$this.text()+'</a>').click(filenumClk);
					$this.html($a);
					$('#'+this.id.replace('td_', '')).hide();
				});
				
				$('<br /><a href="#">show all</a>').click(showAllFiles).appendTo($('th#numfilesTh'));
			});
			function filenumClk(e)
			{
				e=e||event;
				$('#'+$(this).parent('td').attr('id').replace('td_', '')).toggle();
				e.preventDefault();
			}
			function showAllFiles(e)
			{
				e=e||event;
				var $this=$(this);
				var show = ($this.text() == 'show all');
				$('tr.files').css('display', (show ? '':'none'));
				$this.text((show ? 'hide all' : 'show all'));
				e.preventDefault();
			}
		</script>
	</cfif>
	<!--- the css is also saved in a variable, because we need to put it into the pdf input as well. --->
	<cfsavecontent variable="cssStyle_str">
		<style type="text/css">
			body {
				font-family:Verdana, Geneva, sans-serif;
				font-size: 12px;
				width:1000px;
			}
			h1, h3 { font-size: 17px; font-weight:bold; text-align:center; padding: 15px 0px; margin: 0px; clear:both }
			table { width: 100%; border:1px solid #999; border-collapse:collapse }
			th, td { border-bottom:1px solid #ddd; padding: 3px 4px; vertical-align:top; font-size:12px;}
			th { background-color:#ddd; border:1px solid #aaa; white-space:nowrap; text-align:left; font-size:13px;}
			td { border-right:1px solid #ddd; }
			td.filesTableHolder { padding: 0px; }
			tr.files table { margin-bottom:25px; }
			td.attr, th.attr { width: 60px; }
			p.error { border:2px solid red; font-weight:bold; color: #900; padding:5px; }
			form * { float:left; }
			form hr { width:600px; color: #999; }
			form br { clear:both }
			form input { margin:1px 2px 1px 10px; }
			label.first { width:180px;padding-left:0px; }
			label { padding-top:2px; padding-left:10px; border-bottom:1px solid #fff; }
			label:hover { border-bottom:1px dotted #999; }
		</style>
	</cfsavecontent>
	<cfoutput>#cssStyle_str#</cfoutput>
</head>
<body>
<!--- some extra info which should only be displayed on coldfusiondeveloper.nl --->
<cfif find("coldfusiondeveloper.nl", cgi.HTTP_HOST)>
	<p style="border:1px solid #000;padding:10px;margin: 10px 5px;font-size:14px;">
		You are viewing the <em>showlog.cfm</em> file of the Subversion log viewer, created  by <a href="http://www.coldfusiondeveloper.nl/" style="font-size:14px;">Paul Klinkenberg</a>.
		<br />
		<strong>Project page:</strong> <a href="http://www.coldfusiondeveloper.nl/post.cfm/subversion-log-viewer-in-coldfusion" style="font-size:14px;"><strong>Subversion log viewer in Coldfusion</strong></a>
		<br /><br />
		You are welcome to use this component for your own subversion log generating, but for private use only.
		If you want to use the Subversion log Viewer for professional use, please <a href="http://www.ongevragdadvies.nl/contact/" style="font-size:14px;">contact me</a> for all options!
	</p>
</cfif>

<cfoutput>
	<h1>#pageTitle_str#</h1>
	<form action="#cgi.SCRIPT_NAME#" method="post" id="frm">
		<label for="svnPath" class="first">Subversion url or directory path:</label>
		<input type="text" id="svnPath" name="svnPath" value="#variables.svnPath#" size="40" />
		<br />
		<label for="user" class="first">Username:</label>
		<input type="text" id="user" name="user" value="#form.user#" size="12" />
		<label for="pass">Password:</label>
		<input type="text" id="pass" name="pass" value="#form.pass#" size="12" />
		<br /><hr /><br />
		<label for="startRev" class="first">Retrieve log from revision*:</label>
		<input type="text" id="startRev" name="startRev" value="#form.startRev#" size="5" />
		<label for="endRev">untill*:</label>
		<input type="text" name="endRev" id="endRev" value="#form.endRev#" size="5" /> &nbsp;(last revision nr.: #variables.revInfo.Revision#)
		<br />
		<label for="fromDate" class="first">Only output from date:</label>
		<input type="text" name="fromDate" id="fromDate" class="date" value="#form.fromDate#" size="8" />
		<label for="toDate">untill:</label>
		<input type="text" name="toDate" id="toDate" class="date" value="#form.toDate#" size="8" />
		<em>&nbsp;(#variables.datePickerDateFormat#)</em>
		<br />
		<label for="byName" class="first">Committed by:</label>
		<input type="text" name="byName" id="byName" value="#form.byName#" size="8" />
		<br />
		<label for="showAllFiles" class="first">Show all committed files:</label>
		<input type="checkbox" name="showAllFiles" id="showAllFiles" value="1"<cfif form.showAllFiles eq 1> checked="checked"</cfif> />
		<br />
		<label class="first">&nbsp;</label>
		<input type="submit" value="View log" />
		<input type="submit" name="pdf" value="Download log as PDF" />
		
	</form>
	<br clear="all" />
	<em>*: required fields</em>
</cfoutput>

<cfif len(form.startRev)>
	<cftry>
		<cfinvoke component="#variables.subversion_obj#" method="getlog" returnvariable="rev_data">
			<cfinvokeargument name="startRev" value="#form.startRev#" />
			<cfinvokeargument name="endRev" value="#form.endRev#" />
		</cfinvoke>
		<cfcatch>
			<p class="error">An error occured while trying to retrieve the subversion log...<br />
				<cfoutput>Error details: <em>#cfcatch.message#<br />#cfcatch.detail#</em></cfoutput>
			</p>
			<cfset rev_data = "" />
		</cfcatch>
	</cftry>
	
	<cfsilent>
		<cfset rev_data_orig = rev_data />
		
		<cfset revs_qry = queryNew("rev,name,date,msg,numfiles", "varchar,varchar,date,varchar,integer") />
		<cfset revFiles_qry = queryNew("rev,path,attr", "varchar,varchar,varchar") />
		
		<!--- create an array with all the separate revisions (as text) --->
		<cfset delimiter = "------------------------------------------------------------------------" />
		<cfset revData_arr = arrayNew(1) />
		<cfloop condition="reFind('#delimiter#.*?#delimiter#', rev_data)">
			<cfset revData_str = reReplaceNoCase(rev_data, '^.*?#delimiter#(.*?)#delimiter#.*$', '\1') />
			<cfset arrayAppend(revData_arr, revData_str) />
			<cfset rev_data = replace(rev_data, '#delimiter##revData_str##delimiter#', '') />
		</cfloop>
		
		<cfloop from="1" to="#arrayLen(revData_arr)#" index="arrIndex_num">
			<cfset revData_str = revData_arr[arrIndex_num] />
			<cfset position_str = "first" />
			<cfset mymsg = "" />
			<cfset files_num = 0 />
			<cfloop list="#replace(revData_arr[arrIndex_num], chr(10), '#chr(10)# ', 'all')#" delimiters="#chr(10)##chr(13)#" index="line_str">
				<cfif refind("^ *r[0-9]+", line_str)>
					<cfset line_str = trim(line_str) />
					<cfset queryAddRow(revs_qry) />
					<cfloop from="1" to="#listlen(line_str, '|')#" index="linePos_str">
						<cfset lineItem_str = trim(listGetAt(line_str, linePos_str, '|')) />
						<cfif linePos_str eq 1>
							<cfset querySetCell(revs_qry, 'rev', lineItem_str) />
							<cfset revision_str = lineItem_str />
						<cfelseif linePos_str eq 2>
							<cfset querySetCell(revs_qry, 'name', lineItem_str) />
						<cfelseif linePos_str eq 3>
							<cfset querySetCell(revs_qry, 'date', ParseDateTime(listFirst(lineItem_str, ' ') & ' ' & listGetAt(lineItem_str, 2, ' '))) />
						</cfif>
					</cfloop>
				<cfelseif refind("^ *Changed paths?: *$", line_str)>
					<cfset position_str = "paths" />
				<cfelseif refind("^ +$", line_str)>
					<cfset position_str = "msg" />
				<cfelse>
					<cfset line_str = replace(line_str, ' ', '') />
					<cfif position_str eq "paths">
						<cfset files_num += 1 />
						<cfset queryAddRow(revFiles_qry) />
						<cfset querySetCell(revFiles_qry, "rev", revision_str) />
						<cfset querySetCell(revFiles_qry, "path", rereplace(line_str, '^[ A-Z]+ ', '')) />
						<cfset querySetCell(revFiles_qry, "attr", rereplace(line_str, '^([ A-Z]+) .*$', '\1')) />
					<cfelseif position_str eq "msg">
						<cfif len(trim(line_str))>
							<cfset mymsg = listAppend(mymsg, line_str, chr(10)) />
						</cfif>
					<cfelse>
						<cfthrow message="unknown position!? Line = '#line_str#'" />
					</cfif>
				</cfif>
			</cfloop>
			<cfset querySetCell(revs_qry, 'msg', mymsg) />
			<cfset querySetCell(revs_qry, 'numfiles', files_num) />
		</cfloop>
		
		<cfif form.showAllFiles>
			<cfset revFilesRevNrsList_str = valueList(revFiles_qry.rev) />
		</cfif>
		
		<cfif lsIsDate(form.fromDate)>
			<cfset form.fromDate = lsParseDateTime(form.fromDate) />
		<cfelse>
			<cfset form.fromDate = "" />
		</cfif>
		<cfif lsIsDate(form.toDate)>
			<cfset form.toDate = lsParseDateTime(form.toDate) />
		<cfelse>
			<cfset form.toDate = "" />
		</cfif>
	</cfsilent>
	
	<cfsavecontent variable="htmlText">
		<cfoutput>
			<h3>Subversion log for #variables.svnPath#, revision #form.startRev#-#form.endRev#<!---
				---><cfif len(form.fromDate)>, from #lsdateFormat(form.fromdate, 'short')#<cfif len(form.toDate)> to #lsdateFormat(form.todate, 'short')#</cfif></cfif><!---
				---><cfif len(form.byName)>, user<cfif listlen(form.byname) gt 1>s</cfif> #form.byName#</cfif>
			</h3>
		</cfoutput>
		<table>
			<thead>
				<tr>
					<th>Revision nr.</th>
					<th>Date</th>
					<th>By</th>
					<th>Description</th>
					<th id="numfilesTh">Nr. of<br />files</th>
				</tr>
			</thead>
			<tbody>
				<cfoutput query="revs_qry"><cfif (not len(form.fromDate) or dateDiff('n', form.fromDate, date) gte 0)
				and (not len(form.toDate) or dateDiff('n', form.toDate, date) lt 0)
				and (not len(byName) or listFindNoCase(byName, name))>
					<tr>
						<td>#rev#</td>
						<td nowrap="nowrap">#lsdateFormat(date, 'short')# #lstimeFormat(date, 'medium')#</td>
						<td>#name#</td>
						<td>#replace(htmleditformat(msg), chr(10), '<br />', 'all')#</td>
						<td style="text-align:right" class="filenum" id="td_files#revs_qry.currentrow#">#numfiles#</td>
					</tr>
					<cfif form.showAllFiles>
						<tr class="files" id="files#revs_qry.currentrow#"><td colspan="5" class="filesTableHolder"><table>
							<thead>
								<tr>
									<th>Path</th>
									<th class="attr">Attr.</th>
								</tr>
							</thead>
							<tbody>
								<cfloop query="revFiles_qry" startrow="#listFind(revFilesRevNrsList_str, revs_qry.rev)#" endrow="#iif(revs_qry.currentrow eq revs_qry.recordcount, 'revFiles_qry.recordcount', 'listFind(revFilesRevNrsList_str, revs_qry.rev[revs_qry.currentrow+1])-1')#">
									<tr>
										<td>#revFiles_qry.path#</td>
										<td class="attr">#replace(revFiles_qry.attr, ' ', '&nbsp;', 'all')#</td>
									</tr>
								</cfloop>
							</tbody>
						</table></td></tr>
					</cfif>
				</cfif></cfoutput>
			</tbody>
		</table>
	</cfsavecontent>
	
	<cfif structKeyExists(form, 'pdf')>
		<cfheader name="Content-disposition" value="attachment;filename=svn-log-viewer.pdf" />
		<cfdocument format="PDF" pagetype="A4" orientation="portrait"><cfoutput><html><head>#cssStyle_str#</head><body>#htmlText#</body></html></cfoutput></cfdocument>
	<cfelse>
		<cfoutput>#htmlText#</cfoutput>
	</cfif>
</cfif>

</body>
</html>
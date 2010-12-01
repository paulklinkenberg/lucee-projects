<!---
/*
 * index.cfm, developed by Paul Klinkenberg
 * http://www.railodeveloper.com/post.cfm/smartermail-api-wrapper-coldfusion
 *
 * Date: 2010-12-01 20:19:00 +0100
 * Revision: 1.2
 *
 * Copyright (c) 2010 Paul Klinkenberg, Ongevraagd Advies
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
<cfparam name="url.fuseaction" default="" />
<cfparam name="url.id" default="" />

<cfcontent reset="yes" type="text/html; charset=utf-8" /><!---

---><!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
	<title>Coldfusion Smartermail&reg; API wrapper</title>
	<link rel="stylesheet" type="text/css" href="styles/screen.css" />
	<script type="text/javascript" src="js/jquery-1.3.2.min.js"></script>
	<script type="text/javascript">
		$(function(){
			$('#nav h3')
			.css({cursor:'pointer',textDecoration:'underline'})
			.attr('title', 'Click to show/hide all items')
			.click(function(){
				$('#ul_'+this.id).slideToggle();
			})
			.each(function(){
				var $ul = $('#ul_'+this.id);
				if (!$('a.current', $ul).length)
					$ul.hide();
			});
			$('select#DomainName').each(function(){
				var $this=$(this);
				if (!$this.attr('multiple'))
				{
					$('<input type="checkbox" name="loopDomainNames" id="loopDomainNames" value="1" /><label for="loopDomainNames" style="display:inline;float:none;width:auto;clear:none;"> use multiple domains?</label>').insertAfter($this);
				}
				$('input#loopDomainNames').click(function(){
					var $sel = $('select#DomainName');
					$sel.attr('size', (this.checked?10:1)).attr('multiple', this.checked);
				});
			});
			$('select#EmailAddress').each(function(){
				var $this=$(this);
				if (!$this.attr('multiple'))
				{
					$('<input type="checkbox" name="loopEmailAddresses" id="loopEmailAddresses" value="1" /><label for="loopEmailAddresses" style="display:inline;float:none;width:auto;clear:none;"> use multiple email addresses?</label>').insertAfter($this);
				}
				$('input#loopEmailAddresses').click(function(){
					var $sel = $('select#EmailAddress');
					$sel.attr('size', (this.checked?10:1)).attr('multiple', this.checked);
				});
			});
		});
	</script>
</head>
<body>
	<div id="holder">
		<div id="header" style="background-color:#E8E8E8;border-bottom:1px solid #999;">
			<a href="http://www.smartertools.com/SmarterMail/"><img src="images/smartermail-icon.png" width="81" height="56" alt="Smartermail icon" style="float:left;margin:10px 0 0 15px;" /></a>
			<a href="http://www.ongevraagdadvies.nl/" title="Code created by Paul Klinkenberg, Ongevraagd Advies"><img src="images/logo-Ongevraagd-Advies.png" style="float:right;margin:10px 15px 0 0;" alt="Logo Ongevraagd Advies" /></a>
			<h1>UI for the Coldfusion Smartermail<sup><small>&reg;</small></sup> API wrapper</h1>
			<a href="http://www.railodeveloper.com/post.cfm/smartermail-api-wrapper-coldfusion">See the project's blog post at www.railodeveloper.com/post.cfm/smartermail-api-wrapper-coldfusion</a>
		</div>
		
		<div id="content">
			<!--- logged in? --->
			<cfif not structKeyExists(session, "username") or structKeyExists(form, "serverURL")>
				<!--- when logged-in, set the login values in the session scope. --->
				<cfif structKeyExists(form, "serverURL")>
					<cfset structClear(session) />
					<cfparam name="form.debugMode" default="0" />
					<cfloop collection="#form#" item="key">
						<cfset structInsert(session, key, form[key], true) />
					</cfloop>
					<cfset variables.checkWSLogin = true />
				<cfelse>
					<cfinclude template="includes/inc_loginform.cfm" />
				</cfif>
			</cfif>
			
			<cfparam name="url.action" default="" />
			<cfswitch expression="#url.action#">
				<cfcase value="howto,about,field-formats" delimiters=",">
					<cfinclude template="includes/#url.action#.html" />
				</cfcase>
				<cfcase value="logout">
					<cfinclude template="includes/#url.action#.cfm" />
				</cfcase>
				<cfdefaultcase>
					<cfinclude template="smartermailapi.cfm" />
				</cfdefaultcase>
			</cfswitch>
		</div>
	
		<div id="nav">
			<cfif structKeyExists(session, "username")>
				<ul><li><a href="index.cfm?action=logout">Log out</a></li></ul>
			</cfif>
			<h2>About and Help</h2>
			<ul>
				<li><a href="index.cfm?action=howto">How-to</a></li>
				<li><a href="index.cfm?action=field-formats">Help with the form</a></li>
				<li><a href="index.cfm?action=about">About</a></li>
				<li><a href="http://www.railodeveloper.com/post.cfm/smartermail-api-wrapper-coldfusion">View the blog post</a></li>
			</ul>
			<h2>Web service methods</h2>
			<cfinclude template="includes/createnav.cfm" />
		</div>
			
		<br clear="all" />
	</div>
</body>
</html>
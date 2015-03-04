<!---
/*
 * this file was created by Paul Klinkenberg
 * http://www.lucee.nl/post.cfm/railo-tasks-viewer-extension
 *
 * Date: 2012-10-01
 * Revision: 1.2.6
 *
 * Copyright (c) 2012 Paul Klinkenberg, lucee.nl
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
<cfset thispageaction = rereplace(action('overview'), "^[[:space:]]+", "") />

<cfset qAllSchedules = getAllSchedules() />

<cfsavecontent variable="headText">
	<style type="text/css">
		#stasks li {
			margin-bottom: 8px;
			list-style-type:none;
		}
		#stasks .title {
			cursor:pointer;
			color:#568BC1;
			padding-left:10px;
			background:url("<cfoutput>#arguments.app.currPath#</cfoutput>arrow_right.png") no-repeat left center;
		}
		#stasks strong.down {
			background-image:url("<cfoutput>#arguments.app.currPath#</cfoutput>arrow_down.png");
		}
		#stasks .details {
			display:none;
			padding-left:15px;
			line-height:120%;
		}
		#stasks div.show {
			display:block;
		}
	</style>
	<script type="text/javascript" src="<cfoutput>#arguments.app.currPath#</cfoutput>flot/jquery.min.js"></script>
	<script type="text/javascript">
		$(function(){
			$('#stasks li .title').click(function(){
				$(this).toggleClass('down').parent().find('div.details').toggleClass('show');
			});
		});
	</script>
</cfsavecontent>
<cfhtmlhead text="#headText#" />

<h1>Scheduled tasks overview</h1>
<cfif not qAllSchedules.recordcount>
	<p class="error">No scheduled tasks were found</p>
<cfelse>
	<h2>Alerter service</h2>
	<p>With the Alerter Service, you can get periodic emails about failed and missed scheduled tasks.<br />
		<cfif getConfigData('email') neq "">
			The Alerter Service is active; <cfoutput><a href="#action('alertservice')#">Click here</a> to manage it.</cfoutput>
		<cfelse>
			<cfoutput><a href="#action('alertservice')#">Click here</a> for more info.</cfoutput>
		</cfif>
	</p>
	<p>&nbsp;</p>
</cfif>

<cfoutput query="qAllSchedules" group="webContext">
	<h2>Web context <em>#qAllSchedules.webContext#</em></h2>
	<ul id="stasks">
		<cfoutput>
			<li<cfif qAllSchedules.paused eq true> class="paused"</cfif>>
				#showScheduleDetails(qAllSchedules, qAllSchedules.currentrow)#
			</li>
		</cfoutput>
	</ul>
</cfoutput>

<!---<?xml version="1.0"?>
<schedule>
    <task endDate="{d '2013-12-12'}" endTime="{t '21:23:34'}"
        file="/qwe.xcf" hidden="false" interval="3360" name="test task"
        password="dsasdasdasdas" paused="false" port="80"
        proxyHost="x.y.com" proxyPassword="dfsdfsdfs" proxyPort="876"
        proxyUser="dfsdfs" publish="true" readonly="false"
        resolveUrl="false" startDate="{d '2012-03-07'}"
        startTime="{t '01:02:03'}" timeout="50000"
        url="http://127.0.0.1:80/" username="dsadas"/>
</schedule>
<railo-configuration version="2.0">
	<scheduler directory="{railo-web}/scheduler/" log="{railo-web}/logs/scheduler.log"/>
--->

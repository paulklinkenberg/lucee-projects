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
function _d()
{
	var a=arguments;
	return (new Date(a[0],a[1],a[2],a[3],a[4],a[5])).getTime();
}

var plot;
function plotchart(chart, data)
{
	plot = $.plot(chart, data,
		{
			xaxis: { mode: "time", ticks: 10, zoomRange: null, panRange: null }
			, yaxis: {
				  tickLength:0
				, ticks: [[0, ""], [1, "Unscheduled"], [2, "Error"], [3, "Missed"], [4, "Success"], [5, ""]]
				, zoomRange: [1,1], panRange: [0,5]
			}
			, grid: { hoverable: true }
			, legend: { show: false }
			, series: {
				points: { show: true, radius: 2, shadowSize: 0 }
			}
			, zoom: {
				interactive: true
				, trigger: "dblclick"
			}
			, pan: {
				interactive: true
			}
		}
	);
	chart.bind("plothover", plothover);

    // add zoom out button 
    $('<div class="button" style="right:5px;top:3px">zoom out</div>').appendTo(chart).click(function (e) {
        e.preventDefault();
        plot.zoomOut();
    });
}

var tooltipEl = null;
function showchartTooltip(x, y, contents)
{
	var width = $(document).width();
	if (x+200 > width)
	{
		x = x - 200;
	}
	if (!tooltipEl)
	{
		tooltipEl = $('<div id="charttooltip"></div>').css( {
			width: 200,
			position: 'absolute',
			display: 'none',
			top: y + 5,
			left: x + 5,
			border: '1px solid #fdd',
			padding: '2px',
			'background-color': '#fee',
			opacity: 0.95,
			display:'none'
		}).appendTo("body");
	}
	tooltipEl.html(contents).fadeIn(200);
}

var previousPoint = null;
function plothover(event, pos, item) {
   if (item) {
	   if (previousPoint != item.dataIndex)
	   {
		   var data = item.series.data[item.dataIndex];
		   previousPoint = item.dataIndex;
		   var label = item.series.label;
		   var date = formatDate(new Date( data[0] ));
		   showchartTooltip(item.pageX, item.pageY, label + " on " + date + (data[2]==''?'':"<br>") + data[2]);
	   }
   }
   else if (previousPoint != null)
   {
	   tooltipEl.hide();
	   previousPoint = null;
   }
}

var months = ["January","February","March","April","May","June","July","August","September","October","November","December"];
function formatDate(d)
{
	return months[d.getMonth()] + ' ' + d.getDate() + ' ' + d.getFullYear() + ', ' + twodigit(d.getHours()) +':' + twodigit(d.getMinutes()) + ':' + twodigit(d.getSeconds());
}

function twodigit(nr)
{
	return nr<10 ? '0'+nr:nr;
}

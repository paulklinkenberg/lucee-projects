<!---
/*
 * LinkGenerator.cfc, developed by Paul Klinkenberg
 * http://www.coldfusiondeveloper.nl/post.cfm/link-generator-coldfusion-project-honeypot
 *
 * Date: 2010-06-20 22:23:00 +0100
 * Revision: 1.0
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
---><cfcomponent output="no" hint="Honeypot random html link generator" displayname="project-honeypot.LinkGenerator">
	
	<cfset variables.aHoneyPotURLs = [] /><!--- example: ['http://site.com/bla.cfm'] , or ['http://site1.com/bla.cfm', 'http://site2.edu/page.cfm']--->
	
	<!---
		The following variables are replaced:
		$url$ : the honeypot URL
		$word$ : 1 or 2 randomly chosen words
		$extratagStart$ and $extratagEnd$: 50% chance of being replaced by a start and end html tag (<tag> and </tag>)
	--->
	<cfset variables.aHTMLParts = ['<a href="$url$"><!-- $extratagStart$$word$$extratagEnd$ --></a>'
		, '<a href="$url$"><img src="$word$.gif" height="1" width="1" border="0"></a>'
		, '<a href="$url$" style="display: none;">$extratagStart$$word$$extratagEnd$</a>'
		, '<div style="display: none;">$extratagStart$<a href="$url$">$word$</a>$extratagEnd$</div>'
		, '<a href="$url$">$extratagStart$$extratagEnd$</a>'
		, '<!-- $extratagStart$<a href="$url$">$word$</a>$extratagEnd$  -->'
		, '<div style="position: absolute; top: -250px; left: -250px;"><a href="$url$">$word$</a></div>'
		, '<a href="$url$"><span style="display: none;">$word$</span></a>'
		, '<a href="$url$"><div style="height: 0px; width: 0px;overflow:hidden" title="$word$"></div></a>'] />
	
	<!--- You can leave these two arrays empty if you don't want them to add extra anchor tags/extra tags --->
	<cfset variables.aExtraAnchorAttributes = ['title="$word$"', 'rel="$word$"', 'name="$word$"'] />
	<cfset variables.aExtraTags = ['strong', 'em', 'span'] />
	
	<cfset variables.aWords = ['adult', 'aeroplane', 'air', 'aircraft carrier', 'airforce', 'airport', 'album', 'alphabet', 'apple', 'arm', 'army', 'baby', 'baby', 'backpack', 'balloon', 'banana', 'bank', 'barbecue', 'bathroom', 'bathtub', 'bed', 'bed', 'bee', 'bible', 'bible', 'bird', 'bomb', 'book', 'boss', 'bottle', 'bowl', 'box', 'boy', 'brain', 'bridge', 'butterfly', 'button', 'cappuccino', 'car', 'car-race', 'carpet', 'carrot', 'cave', 'chair', 'chess board', 'chief', 'child', 'chisel', 'chocolates', 'church', 'church', 'circle', 'circus', 'circus', 'clock', 'clown', 'coffee', 'coffee-shop', 'comet', 'compact disc', 'compass', 'computer', 'crystal', 'cup', 'cycle', 'data base', 'desk', 'diamond', 'dress', 'drill', 'drink', 'drum', 'dung', 'ears', 'earth', 'egg', 'electricity', 'elephant', 'eraser', 'explosive', 'eyes', 'family', 'fan', 'feather', 'festival', 'film', 'finger', 'fire', 'floodlight', 'flower', 'foot', 'fork', 'freeway', 'fruit', 'fungus', 'game', 'garden', 'gas', 'gate', 'gemstone', 'girl', 'gloves', 'god', 'grapes', 'guitar', 'hammer', 'hat', 'hieroglyph', 'highway', 'horoscope', 'horse', 'hose', 'ice', 'ice-cream', 'insect', 'jet fighter', 'junk', 'kaleidoscope', 'kitchen', 'knife', 'leather jacket', 'leg', 'library', 'liquid', 'magnet', 'man', 'map', 'maze', 'meat', 'meteor', 'microscope', 'milk', 'milkshake', 'mist', 'money $$$$', 'monster', 'mosquito', 'mouth', 'nail', 'navy', 'necklace', 'needle', 'onion', 'paintbrush', 'pants', 'parachute', 'passport', 'pebble', 'pendulum', 'pepper', 'perfume', 'pillow', 'plane', 'planet', 'pocket', 'post-office', 'potato', 'printer', 'prison', 'pyramid', 'radar', 'rainbow', 'record', 'restaurant', 'rifle', 'ring', 'robot', 'rock', 'rocket', 'roof', 'room', 'rope', 'saddle', 'salt', 'sandpaper', 'sandwich', 'satellite', 'school', 'ship', 'shoes', 'shop', 'shower', 'signature', 'skeleton', 'slave', 'snail', 'software', 'solid', 'space shuttle', 'spectrum', 'sphere', 'spice', 'spiral', 'spoon', 'sports-car', 'spot light', 'square', 'staircase', 'star', 'stomach', 'sun', 'sunglasses', 'surveyor', 'swimming pool', 'sword', 'table', 'tapestry', 'teeth', 'telescope', 'television', 'tennis racquet', 'thermometer', 'tiger', 'toilet', 'tongue', 'torch', 'torpedo', 'train', 'treadmill', 'triangle', 'tunnel', 'typewriter', 'umbrella', 'vacuum', 'vampire', 'videotape', 'vulture', 'water', 'weapon', 'web', 'wheelchair', 'window', 'woman', 'worm', 'x-ray'] />

	
	<cffunction name="init" returntype="any" hint="Reminds given honeypot-url(s), and returns instance of itself">
		<cfargument name="honeyPotURL" type="any" hint="String or array of strings" required="yes" />
		<cfif isArray(arguments.honeyPotURL)>
			<cfset variables.aHoneyPotURLs = arguments.honeyPotURL />
		<cfelse>
			<cfset arrayAppend(variables.aHoneyPotURLs, arguments.honeyPotURL) />
		</cfif>
		<cfreturn this />
	</cffunction>
	
	
	<cffunction name="getHTML" returntype="string" output="no" hint="Creates and returns html with an invisible honeypot url">
		<cfset var sUrl = _getRandom(variables.aHoneyPotURLs) />
		<cfset var sHTML = _getRandom(variables.aHTMLParts) />
		<cfset var nExtraAnchorAttributes = randRange(0, arrayLen(variables.aExtraAnchorAttributes)) />
		<cfset var currentTag = "" />
		<cfset var nIndex = -1 />
		<cfset var aExtraAttrDone = [] />
		<cfif sURL eq "">
			<cfreturn "<!-- Project honeypot LinkGenerator: you must invoke LinkGenerator.cfc by using LinkGenerator.init(yourURL), or manually add honeypot links into the cfc itself. -->" />
		</cfif>
		<!--- add the url to the html piece --->
		<cfset sHTML = replace(sHTML, '$url$', sURL, 'all') />
		<!---add extra html tags (with 50% chance of not adding a new tag) --->
		<cfloop condition="find('$extratagStart$', sHTML)">
			<cfset currentTag = "" />
			<cfif randRange(0,1) and arrayLen(variables.aExtraTags)>
				<cfset currentTag = "<" & _getRandom(variables.aExtraTags) & ">" />
			</cfif>
			<cfset sHTML = replace(sHTML, '$extratagStart$', currentTag) />
			<cfset sHTML = rereplace(sHTML, '(.*)\$extratagEnd\$', '\1#replace(currentTag, "<", "</")#') />
		</cfloop>
		<!---add extra attributes to the anchor tag --->
		<cfloop from="1" to="#nExtraAnchorAttributes#" index="nIndex">
			<cfset currentAttr = _getRandom(variables.aExtraAnchorAttributes) />
			<cfif not arrayFind(aExtraAttrDone, currentAttr)>
				<cfset arrayAppend(aExtraAttrDone, currentAttr) />
				<cfif randRange(0,1)>
					<cfset sHTML = replace(sHTML, '<a', '<a #currentAttr#') />
				<cfelse>
					<cfset sHTML = rereplace(sHTML, '(<a [^>]+)', '\1 #currentAttr#') />
				</cfif>
			</cfif>
		</cfloop>
		<!--- add random words to the url --->
		<cfloop condition="find('$word$', sHTML)">
			<cfset sHTML = replace(sHTML, '$word$', _getRandomWord()) />
		</cfloop>
		<!--- replace double to single quotes (sometimes) --->
		<cfif not randRange(0,3)>
			<cfset sHTML = replace(sHTML, '"', "'", "all") />
		</cfif>
		
		<cfreturn sHTML />
	</cffunction>
	
	
	<cffunction name="_getRandom" access="private" returntype="any" hint="Returns one random item from the given array">
		<cfargument name="fromArray" type="array" required="yes" />
		<cfset var nArrLen = arrayLen(arguments.fromArray) />
		<cfif nArrLen eq 0>
			<cfreturn "" />
		</cfif>
		<cfreturn arguments.fromArray[randRange(1, nArrLen)] />
	</cffunction>
	

	<cffunction name="_getRandomWord" access="private" returntype="string" hint="Returns one random word">
		<cfset var sWord = _getRandom(variables.aWords) />
		<cfif randRange(0,2)>
			<cfset sWord = sWord & " " & _getRandom(variables.aWords) />
		</cfif>
		<cfif not randRange(0,2)>
			<cfreturn uCase(sWord) />
		<cfelse>
			<cfreturn sWord />
		</cfif>
	</cffunction>
	
	
</cfcomponent>
<cfcomponent output="no">

	<!--- This function accepts 2 arrays of lines, compares them and adds empty lines where needed --->
	<cffunction name="compareArray" returntype="struct" output="false" access="public">
		<cfargument name="arg_aLeft" required="yes" type="array" />
		<cfargument name="arg_aRight" default="#arraynew(1)#" required="no" type="array" />
		<cfset var stRet = structnew() />
		<cfset var local = structNew() />
		<cfset var aRight = arrayNew() />
		<cfset var aLeft = arrayNew() />
		<cfset var l="l">
		<cfset var r="r">
		<cfset var placeHolder_struct = structNew()>
		<cfset var i=0 />
		<cfset var numberofrows = 0 />
		<cfset var linestoadd = 0 />
		<cfset var rightIDX = 0 />
		<cfset var j = "" />

		<cfset placeHolder_struct.txt = "">
		<cfset placeHolder_struct.line = 0>
		<cfset placeHolder_struct.same = 0>
		<cfset placeHolder_struct.realline = 0>
		
		
		<!--- Loop over the both arrays and fill in the default information struct 
		
		aLeft[i].txt : The actual text txt>
		aLeft[i].line : The original line number>
		aLeft[i].realline : 1=Line from original code 0=Line inserted by CompareArray()>
		aLeft[i].same : Line is the same as the one on the right>
		--->
		<cfloop from="1" to="#arraylen(arg_aLeft)#" index="i">
			<cfset aLeft[i] = structNew()>
			<cfset aLeft[i].txt = arg_aLeft[i]>
			<cfset aLeft[i].line = i>
			<cfset aLeft[i].realline = 1>
			<cfset aLeft[i].same = 0>
		</cfloop>
		
		<cfloop from="1" to="#arraylen(arg_aRight)#" index="i">
			<cfset aRight[i] = structNew()>
			<cfset aRight[i].txt = arg_aRight[i]>
			<cfset aRight[i].line = i>
			<cfset aRight[i].realline = 1>
			<cfset aRight[i].same = 0>
		</cfloop>
		
		
		<!--- Loop over the left array to check it against the right one. --->
		<cfset i=1>
		<cfset local.linesNotFoundNum = 0 />
		
		<!--- A while condition is used because the value of 'i' might be changed in the function --->
		<cfloop condition="i lt #arraylen(aLeft)#">
			<!--- If the text is the same --->
			<cfif  i-local.linesNotFoundNum lt arraylen(aRight) and trim(aRight[i-local.linesNotFoundNum].txt) is trim(aLeft[i].txt)>
				<cfset aLeft[i].same = 1>
				
			<!--- If the text is not the same (make sure we don't try to compare empty indices in the right array) --->
			<cfelseif i-local.linesNotFoundNum lt arraylen(aRight)><!--- /cfif  i lt arraylen(aRight) and trim(aRight[i].txt) is trim(aLeft[i].txt) --->
				<cfset local.found=false />
				<cfoutput>not found:<br />
					trim(aRight[i-local.linesNotFoundNum].txt)=#HTMLEditFormat(trim(aRight[i-local.linesNotFoundNum].txt))#<br />
					trim(aLeft[i].txt)=#HTMLEditFormat(trim(aLeft[i].txt))#<br />
					i=#i#<br />
					local.linesNotFoundNum=#local.linesNotFoundNum#
					<br />
				</cfoutput>
				<!--- Loop over the right one and try to find the same line --->
				<cfloop from="#i-local.linesNotFoundNum#" to="#arraylen(aRight)#" index="rightIDX">
					<!--- If you find the same line in another line --->
					<cfif trim(aLeft[i].txt) is trim(aRight[rightIDX].txt)>
						<cfoutput><strong>Found at line #rightIDX#</strong><hr /></cfoutput>
						<cfset aLeft[i].same = 1 />
						<cfset local.found=true />
						<!--- Find out how many lines to add to the left side --->
						<cfset numberofrows = rightIDX-i />
						
						<cfif numberofrows gt 0>
							<!--- Insert empty rows on the left --->
							<cfloop from="1" to="#numberofrows#" index="j">
								<cfset ArrayInsertAt(aLeft, i, placeHolder_struct)>
								<cfset i=i+1>
							</cfloop>
						<cfelse>
							<!--- Insert empty rows on the right --->
							<cfloop from="1" to="#abs(numberofrows)#" index="j">
								<cfset ArrayInsertAt(aRight, rightIDX, placeHolder_struct)>
							</cfloop>
						</cfif>
						<cfset local.linesNotFoundNum = 0 />
						<cfbreak />
					</cfif>
				</cfloop>
				<cfif not local.found>
						<cfoutput><strong>NOT found</strong><hr /></cfoutput>
					<cfset local.linesNotFoundNum = local.linesNotFoundNum + 1 />
				</cfif>
			</cfif><!--- /cfif  i lt arraylen(aRight) and trim(aRight[i].txt) is trim(aLeft[i].txt) --->
			
			<cfset i=i+1>
		</cfloop><!--- /cfloop condition="i lt #arraylen(aLeft)#" --->
		
		<!--- Loop over the right array to check it against the left one. --->
		<cfloop from="1" to="#arraylen(aRight)#" index="i">
			<!--- Only compare real lines, not ones added by the function --->
			<cfif i lt arraylen(aLeft) and aLeft[i].realline is 1 and trim(aLeft[i].txt) is trim(aRight[i].txt)>
				<cfset aRight[i].same = 1>
			</cfif>
		</cfloop>
		
		<!--- Make the two arrays the same size --->
		<cfscript>
			if(arraylen(aLeft) lt arraylen(aRight))
			{
				linestoadd = arraylen(aRight)-arraylen(aLeft);
				for(i=1;i lte linestoadd;i=i+1)
				{
					ArrayAppend(aLeft, placeHolder_struct);
				}
			} else
			{
				linestoadd = arraylen(aLeft)-arraylen(aRight);
				for(i=1;i lte linestoadd;i=i+1)
				{
					ArrayAppend(aRight, placeHolder_struct);
				}
			}
		</cfscript>
		<cfset stRet.aLeft = aLeft>
		<cfset stRet.aRight = aRight>

		<cfreturn stRet />
	</cffunction>
	
	
	<!--- This function accepts 2 strings of text (possibly code), compares them, then returns a query with the data --->
	<cffunction name="compareText" returntype="query" access="public" output="false">
		<cfargument name="txt1" required="yes" type="string">
		<cfargument name="txt2" required="yes" type="string">
		<cfset var leftside = listtoarray(txt1,chr(10)&chr(13))>
		<cfset var rightside = listtoarray(txt2,chr(10)&chr(13))>
		<cfset var diff =  compareArray(leftside,rightside)>
		<cfset var q = querynew("l_line,l_txt,r_line,r_txt,same")>
		<cfset var y = 0 />
		
		<!--- Put the information in a query --->
		<cfloop from="1" to="#arraylen(diff.aLeft)-1#" index="y">
			<cfset QueryAddRow(q)>
			<!--- Same --->
			<cfif diff.aLeft[y].same or (y lte arraylen(diff.aRight) and diff.aRight[y].same) or (y lte arraylen(diff.aRight) and trim(diff.aRight[y].txt) is trim(diff.aLeft[y].txt))>
				<cfset QuerySetCell(q,"same",1)>
			<cfelse>
				<cfset QuerySetCell(q,"same",0)>
			</cfif>
			
			<!--- Line numbers --->
			<cfif diff.aLeft[y].line gt 0>
				<cfset QuerySetCell(q,"l_line",diff.aLeft[y].line)>
			<cfelse>
				<cfset QuerySetCell(q,"l_line",".")>
			</cfif>
			
			<!--- Text --->
			<cfset QuerySetCell(q,"l_txt",diff.aLeft[y].txt)>
			
			<cfif y lt arraylen(diff.aRight)>
				<!--- Line numbers --->
				<cfif diff.aRight[y].line gt 0>
					<cfset QuerySetCell(q,"r_line",diff.aRight[y].line)>
				<cfelse>
					<cfset QuerySetCell(q,"r_line",".")>
				</cfif>
				<!--- Text --->
				<cfset QuerySetCell(q,"r_txt",diff.aRight[y].txt)>
			<cfelse>
				<!--- Line numbers --->
				<cfset QuerySetCell(q,"r_line",".")>
				<!--- Text --->
				<cfset QuerySetCell(q,"r_txt","")>
			</cfif>
			
		</cfloop>
	
		<cfreturn q>
	</cffunction>
	
	
	<cffunction name="compareLine"  returntype="query" access="public" output="false">
		<cfargument name="txt1" required="yes" type="string">
		<cfargument name="txt2" required="yes" type="string">
		<!--- TODO: for some reason the function drops the last element of the array 
		band aid solution is to add _stringtoerase_ but I really need to find out the problem
		--->
		<cfset var leftside = listtoarray(txt1 & "  _stringtoerase_"," ")>
		<cfset var rightside = listtoarray(txt2 & "  _stringtoerase_"," ")>
		<cfset var diff =  compareArray(leftside,rightside)>
		<cfset var q = querynew("l_line,l_txt,r_line,r_txt,l_txtFormatted,r_txtFormatted,same")>
		<cfset var y = 0 />
		
		<!--- Put the information in a query --->
		<cfloop from="1" to="#arraylen(diff.aLeft)#" index="y">
			<cfset QueryAddRow(q)>
			<!--- Same --->
			<cfif diff.aLeft[y].same or (y lte arraylen(diff.aRight) and diff.aRight[y].same) or (y lte arraylen(diff.aRight) and trim(diff.aRight[y].txt) is trim(diff.aLeft[y].txt))>
				<cfset QuerySetCell(q,"same",1)>
			<cfelse>
				<cfset QuerySetCell(q,"same",0)>
			</cfif>
			
			<!--- Line numbers --->
			<cfif diff.aLeft[y].line gt 0>
				<cfset QuerySetCell(q,"l_line",diff.aLeft[y].line)>
			<cfelse>
				<cfset QuerySetCell(q,"l_line",".")>
			</cfif>
			
			<!--- Text --->
			<cfset QuerySetCell(q,"l_txt",replacenocase(diff.aLeft[y].txt,"_stringtoerase_",""))>
			
			<cfif y lt arraylen(diff.aRight)>
				<!--- Line numbers --->
				<cfif diff.aRight[y].line gt 0>
					<cfset QuerySetCell(q,"r_line",diff.aRight[y].line)>
				<cfelse>
					<cfset QuerySetCell(q,"r_line",".")>
				</cfif>
				<!--- Text --->
				<cfset QuerySetCell(q,"r_txt",replacenocase(diff.aRight[y].txt,"_stringtoerase_",""))>
			<cfelse>
				<!--- Line numbers --->
				<cfset QuerySetCell(q,"r_line",".")>
				<!--- Text --->
				<cfset QuerySetCell(q,"r_txt","")>
			</cfif>
			
		</cfloop><!--- cfloop from="1" to="#arraylen(diff.aLeft)-1#" index="y" --->
	
	
	
	
		<cfreturn q>
	</cffunction>
	
	
	<cffunction name="diffFormat" access="public" returntype="string" output="true">
	<cfargument name="txt1" type="string" required="yes">
	<cfargument name="txt2" type="string" required="yes">
	<cfargument name="fullDiff" type="boolean" required="no" default="true" />
	<cfset var qDiff = compareText(arguments.txt1,arguments.txt2)>
	<cfset var diffFormatRet = "" />
	<cfset var ql = "" />
	<cfset var shownextline = false />
	
	<cfsavecontent variable="diffFormatRet"><cfoutput>
		<cfloop query="qDiff"><cfif shownextline or arguments.fullDiff or not qDiff.same
		or (qdiff.currentrow neq qdiff.recordcount and qdiff.same[qdiff.currentrow+1] neq 1)>
			<tr<cfif currentrow mod 2> class="odd"</cfif>>
				<cfif not qDiff.same and len(trim(qDiff.l_txt)) and len(trim(qDiff.r_txt))>
					<cfset ql=compareLine(qDiff.l_txt,qDiff.r_txt)>
					<td class="linenum upd">#qDiff.l_line#</td>
					<td class="code upd"><cfloop query="ql"><span class="<cfif not ql.same>not</cfif>same">#replace(htmleditformat(ql.l_txt), chr(9), '&nbsp; &nbsp;')# </span></cfloop></td>
					<td class="linenum upd">#qDiff.r_line#</td>
					<td class="code upd"><cfloop query="ql"><span class="<cfif not ql.same>not</cfif>same">#replace(htmleditformat(ql.r_txt), chr(9), '&nbsp; &nbsp;')# </span></cfloop></td>
				<cfelse>
					<td class="linenum">#qDiff.l_line#<cfif not len(qdiff.l_line)>&nbsp;</cfif></td>
					<td class="code<cfif not qDiff.same and len(qDiff.l_txt)> del</cfif>">#replace(htmleditformat(qDiff.l_txt), chr(9), '&nbsp; &nbsp;')#<cfif not len(qdiff.l_txt)>&nbsp;</cfif></td>
					<td class="linenum">#qDiff.r_line#<cfif not len(qdiff.r_line)>&nbsp;</cfif></td>
					<td class="code<cfif not qDiff.same and len(qDiff.r_txt)> ins</cfif>">#replace(htmleditformat(qDiff.r_txt), chr(9), '&nbsp; &nbsp;')#<cfif not len(qdiff.r_txt)>&nbsp;</cfif></td>
				</cfif>
			</tr>
			<cfif not arguments.fullDiff and (shownextline and qdiff.same and (qdiff.currentrow eq qdiff.recordcount or qdiff.same[qdiff.currentrow+1] eq 1))>
				<tr class="sep"><td colspan="4">&nbsp;</td></tr>
			</cfif>
			<cfset shownextline = (not qdiff.same) />
		</cfif></cfloop>
	</cfoutput></cfsavecontent>
	<cfreturn diffFormatRet>
	</cffunction>
</cfcomponent>
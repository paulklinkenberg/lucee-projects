<!---
	** contents edited by Paul Klinkenberg, 2008 **
	
	This library is part of the Common Function Library Project. An open source
	collection of UDF libraries designed for ColdFusion 5.0. For more information,
	please see the web site at:
		
		http://www.cflib.org
		
	Warning:
	You may not need all the functions in this library. If speed
	is _extremely_ important, you may want to consider deleting
	functions you do not plan on using. Normally you should not
	have to worry about the size of the library.
		
	License:
	This code may be used freely. 
	You may modify this code as you see fit, however, this header, and the header
	for the functions must remain intact.
	
	This code is provided as is.  We make no warranty or guarantee.  Use of this code is at your own risk.
---><cfcomponent output="false">

	<!---
	 Returns the mime type of the specified file.
	 
	 @param filePath 	 The file to examine, (Required)
	 @return Returns a string. 
	 @author Ben Rogers (&#98;&#101;&#110;&#64;&#99;&#52;&#46;&#110;&#101;&#116;) 
	 @version 1, July 19, 2005 
	--->
	<!--- <comment author="P. Klinkenberg"> edited: if getMimeType() returns null, return 'application/x-unknown' </comment> --->
	<cffunction name="getFileMimeType" returntype="string" output="no">
		<cfargument name="filePath" type="string" required="yes" />
		<cfset var testStruct = structNew() />
		<cfset testStruct.fileExt_str = getPageContext().getServletContext().getMimeType(arguments.filePath) />
		<cfif structIsEmpty(testStruct) or not len(testStruct.fileExt_str)>
			<cfset testStruct.fileExt_str = "application/x-unknown" />
		</cfif>
		<cfreturn testStruct.fileExt_str />
	</cffunction>


</cfcomponent>
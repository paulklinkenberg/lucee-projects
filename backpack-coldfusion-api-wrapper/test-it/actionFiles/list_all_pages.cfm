
<h2>Retrieving all page titles</h2>

<p>
	Retrieving all page titles is supported in 2 ways:
</p>
<ol>
	<li>listAllPages([returnType:string]):any<br />
		This function will give you the response xml, except if you set the optional argument <em>returnType</em> to 'query', when it will return a recordset.<br />
	</li>
	<li>getAllPages([orderBy:string]):query<br />
		This function will return a recordset, optionally sorted by the argument value.
	</li>
</ol>

<h3>listAllPages()</h3>
<cfset page_xml = application.backPack_obj.listAllPages() />
<cfoutput><pre>#htmlEditFormat(toString(page_xml))#</pre></cfoutput>
<br />

<h3>getAllPages() &nbsp;/&nbsp; listAllPages(returnType='query')</h3>
<cfset page_qry = application.backPack_obj.getAllPages() />
<cfdump var="#page_qry#" />
<br />

<h3>getAllPages(orderBy='id')</h3>
<cfset page_qry = application.backPack_obj.getAllPages(orderBy='id') />
<cfdump var="#page_qry#" />
<br />

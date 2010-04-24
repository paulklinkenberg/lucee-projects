<cfheader name="Expires" value="#GetHttpTimeString(Now())#" />
<cfheader name="Pragma" value="no-cache" />
<cfheader name="Cache-control" value="no-cache" />

<!--- here, you can i.e. do a cfquery to retrieve all the website's articles, 
and then loop through them underneath.

For now, this page returns an empty array ( "[  ]" ), which makes sure that there
is NO extra 'choose website link' selectbox visible in the Link dialog. --->

<cfcontent type="application/x-javascript" reset="yes" /><!---

--->[
	<!---
		  ['page 1 title', '/page1/link.html']
		, ['page2 title', '/page2.html']
	--->
]
<cfabort />
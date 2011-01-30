<cfcsv action="parse" file="testdata.csv" variable="myQuery" delimiter=";" />
<cfdump eval=myQuery />

<cfset myData = "test,test2
data 1,data 2
'quoted here, with a
line break',second col

" />
<cfcsv action="parse" data="#myData#" variable="parsedDataQuery" textqualifier="'" />
<cfdump eval=parsedDataQuery />

<cfcsv action="create" query="#parsedDataQuery#" variable="csvData" />
<pre><cfoutput>#htmleditformat(csvData)#</cfoutput></pre>

<cfcsv action="create" query="#parsedDataQuery#" variable="csvData" includeColumnNames=false />
<pre><cfoutput>#htmleditformat(csvData)#</cfoutput></pre>


<cfcsv action="parse" file="testdata.csv" variable="myArray" output="array" delimiter=";" />
<cfdump eval=myArray />

<cfcsv action="parse" file="testdata.csv" variable="myArray" output="array" trimendoffile=false delimiter=";" />
<cfdump eval=myArray />

<cfcsv action="parse" file="testdata.csv" variable="myQuery" output="query" trimendoffile=false delimiter=";" />
<cfdump eval=myQuery />

<cfcsv action="parse" file="testdata.csv" variable="myQuery" hascolumnnames=false delimiter=";" />
<cfdump eval=myQuery />


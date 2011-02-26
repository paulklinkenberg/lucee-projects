<!--- Parse a csv file, and return the resulting query into 'variables.myQuery'.
Also note the relative file path usage! --->
<cfcsv action="parse" file="testdata.csv" variable="myQuery" delimiter=";" />
<cfdump eval=myQuery />

<!---  some test data, ending with extra line breaks --->
<cfset myData = "test,test2
data 1,data 2
'quoted here, with a
line break',second col

" />
<!--- Parse a string of CSV data. The text qualifier is a single quote --->
<cfcsv action="parse" data="#myData#" variable="parsedDataQuery" textqualifier="'" />
<cfdump eval=parsedDataQuery />

<!--- Create CSV data from a query, returning it as 'variables.csvData' --->
<cfcsv action="create" query="#parsedDataQuery#" variable="csvData" />
<pre><cfoutput>#htmleditformat(csvData)#</cfoutput></pre>

<!---  Create CSV data from a query, without a first line of headers (query column names) --->
<cfcsv action="create" query="#parsedDataQuery#" variable="csvData" includeColumnNames=false />
<pre><cfoutput>#htmleditformat(csvData)#</cfoutput></pre>

<!--- Create CSV data from a query, using non-default delimiter and text-qualifier --->
<cfcsv action="create" query="#parsedDataQuery#" variable="csvData" delimiter="|" textqualifier="'" />
<pre><cfoutput>#htmleditformat(csvData)#</cfoutput></pre>

<!--- Parse a csv file, returning it as an array of arrays --->
<cfcsv action="parse" file="testdata.csv" variable="myArray" output="array" delimiter=";" />
<cfdump eval=myArray />

<!--- Return results as an array of arrays, and not removing optional trailing line breaks.
This will result in a few extra empty arrays, because every line will be seen as a row of data. --->
<cfcsv action="parse" file="testdata.csv" variable="myArray" output="array" trimendoffile=false delimiter=";" />
<cfdump eval=myArray />

<!--- Not removing optional trailing line breaks.
This will result in a few extra query rows, because every line will be seen as a row of data. --->
<cfcsv action="parse" file="testdata.csv" variable="myQuery" output="query" trimendoffile=false delimiter=";" />
<cfdump eval=myQuery />

<!--- Do not use first line as headers. This will give the query column names called 'col1', 'col2', etc. --->
<cfcsv action="parse" file="testdata.csv" variable="myQuery" hascolumnnames=false delimiter=";" />
<cfdump eval=myQuery />


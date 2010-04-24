<!--- SECURITY INSTRUCTIONS

The script at /filemanager/scripts/jquery.filetree/connectors/jqueryFiletree.cfm
can potentially list all the files within your webroot. This is a pretty big security issue.
So you have to tell this script which starting directory within your webroot to use.
btw: if you want to allow all files within your website, then use: <cfset variables.jqueryFileTree_webroot = "/" />
---><cfset variables.jqueryFileTree_webroot = "/uploads/" />
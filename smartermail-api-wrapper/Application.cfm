<cfapplication name="smadmin" sessionmanagement="yes" clientmanagement="yes" />

<cfif not structKeyExists(application, "methods_struct") or structKeyExists(url, "reset")>
	<cffile action="read" file="#expandPath('./wddx/methodArguments.wddx')#" variable="q" />
	<cfwddx action="wddx2cfml" input="#q#" output="application.methods_struct" />
</cfif>
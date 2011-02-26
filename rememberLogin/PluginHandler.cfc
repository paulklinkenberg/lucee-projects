<cfcomponent name="extrahtmlcontent" extends="BasePlugin">


	<cfset variables.name = "rememberLogin" />
	<cfset variables.package = "nl/coldfusiondeveloper/mango/plugins/rememberLogin" />
	<cfset variables.cookieName = "rememberlogin" />
	<cfset variables.encryptKeyPath = GetDirectoryFromPath(GetCurrentTemplatePath()) & "encryptkey.cfm" />

<!--- :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: --->
	<cffunction name="init" access="public" output="false" returntype="any">
		<cfargument name="mainManager" type="any" required="true" />
		<cfargument name="preferences" type="any" required="true" />
		<cfset var blogid = arguments.mainManager.getBlog().getId() />
		<cfset var path = blogid & "/" & variables.package />
		<cfset var tmpEncryptKey = "" />
		
		<cfset variables.preferencesManager = arguments.preferences />
		<cfset variables.manager = arguments.mainManager />
		
		<!--- create a file with the encrypt key if it doesn't exist yet --->
		<cfif not fileExists(variables.encryptKeyPath)>
			<cffile action="write" file="#variables.encryptKeyPath#" output="<cfabort />#createUUID()#" addnewline="no" />
		</cfif>
		<!--- read the encryptKey, and set it in variables scope (yes, I know the key will consist of the tag cfabort, but who cares) --->
		<cffile action="read" file="#variables.encryptKeyPath#" variable="tmpEncryptKey" />
		<cfset variables.encryptKey = tmpEncryptKey />
		
		<cfreturn this />
	</cffunction>
	

<!--- :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: --->	
	<cffunction name="setup" hint="This is run when a plugin is activated" access="public" output="false" returntype="any">
		<cfreturn "rememberLogin plugin activated. <br />You can go <a href='/admin/index.cfm?logout=1'>to the login screen</a> to see it (you will be logged out)" />
	</cffunction>
	
<!--- :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: --->	
	<cffunction name="processEvent" hint="Synchronous event handling" access="public" output="false" returntype="any">
		<cfargument name="event" type="any" required="true" />
		<cfset var headText = "" />
		<cfset var eventName = arguments.event.getName() />
		<cfset var aLogindata = "" />
				
		<cfif eventname eq "mainNav">
			<!--- remember login in an encrypted cookie --->
			<cfif structKeyExists(form, "rememberlogin")
			and structKeyExists(form, "username") and structKeyExists(form, "password")>
				<cfcookie name="#variables.cookieName#"
				value="#encrypt('#form.username##chr(10)##form.password#', variables.encryptKey)#"
				expires="never" />
			</cfif>
		<cfelseif eventname eq "beforeAdminLoginTemplate">
			<!--- delete logincookie if they actually wanted to logout --->
			<cfif (structKeyExists(url, "logout") and cgi.REQUEST_METHOD neq "POST")>
				<cfif structKeyExists(cookie, variables.cookieName)>
					<cfcookie expires="now" name="#variables.cookieName#" />
				</cfif>
			</cfif>
			
			<!--- auto-login if they have a cookie --->
			<cfif structKeyExists(cookie, variables.cookieName)
			and (not structKeyExists(url, "autologin") or cgi.REQUEST_METHOD neq "POST")>
				<cfset aLogindata = listToArray(decrypt(cookie[variables.cookieName], variables.encryptKey), chr(10)) />
				<cfsavecontent variable="headText"><cfoutput>
					<script type="text/javascript" src="http://code.jquery.com/jquery-1.4.2.min.js"></script>
					<script type="text/javascript">
						$(function(){
							var $theform = $('form:first');
							if ($theform.attr('action').indexOf('?') > -1)
								$theform.attr('action', $theform.attr('action') + '&autologin=1');
							else
								$theform.attr('action', $theform.attr('action') + '?autologin=1');
							$("##login h2").text("Submitting auto-login...");
							jQuery('##username').val('#JSStringFormat(aLogindata[1])#').css("background-color", "##bbb");
							jQuery('##password').val('#JSStringFormat(aLogindata[2])#').css("background-color", "##bbb");
							if(typeof document.forms[0].submit=="function")
								document.forms[0].submit();
							else if(typeof document.forms[0].submit.click=="function")
								document.forms[0].submit.click();
							else
								alert('Sorry, the rememberlogin plugin doesn\'t work with your browser!');
						});
					</script>
				</cfoutput></cfsavecontent>
				<cfhtmlhead text="#headText#" />
			<cfelse>
				<cfsavecontent variable="headText"><cfoutput>
					<script type="text/javascript" src="http://code.jquery.com/jquery-1.4.2.min.js"></script>
					<script type="text/javascript">
						$(function(){
							$('<br /><label for="rememberlogin"><input type="checkbox" name="rememberlogin" id="rememberlogin" value="1"<cfif structKeyExists(url, "autologin")> checked="checked"</cfif> /> Remember my login</label>')
								.insertAfter('##submit');
						});
					</script>
				</cfoutput></cfsavecontent>
				<cfhtmlhead text="#headText#" />
			</cfif>
		</cfif>
		
		<cfreturn arguments.event />
	</cffunction>
		
</cfcomponent>
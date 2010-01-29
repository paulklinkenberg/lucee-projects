<cfcomponent output="false">
	
	<!--- these keys are given to you by your bank --->
	<cfset variables.hashKey = "dfdg" />
	<cfset variables.merchantID = "fdgdfgdf" />
	<!--- subID = Een getal van 0 tot 999999 waarbij elke waarde is gerelateerd aan een bij de acquirer geregistreerde handelsnaam. Standaardwaarde is ‘0’. In dit geval geldt: Merchant.tradeName = Merchant.legalName. --->
	<cfset variables.subID = "0" />
	<!--- don't chnage; is used in the hash string --->
	<cfset variables.paymentType = "ideal" />
		
	
	<cffunction name="getVar" returntype="any" output="false" hint="A bit sleazy function to get the vars set in the variables scope">
		<cfargument name="varName" type="string" required="yes" />
		<cfreturn variables[varName] />
	</cffunction>


	<cffunction name="getIdealTimeStamp" returntype="string" output="false" description="Converts the validUntill date to the format requested by ideal">
		<cfargument name="theDate" type="date" required="yes" />
		<cfreturn dateFormat(arguments.theDate, "yyyy-MM-DD") & "T" & timeFormat(arguments.theDate, "HH:mm:ss") & ".000Z" />
	</cffunction>
	
	
	<cffunction name="getSHACode" output="false" returntype="string">
		<cfargument name="ordernr" type="string" required="yes" hint="purchaseID; your own unique order number. Uniek kenmerk van de order/bestelling binnen het systeem van de acceptant. Verschijnt uiteindelijk op betaalbewijs (afschrift/overzicht)." />
		<cfargument name="validUntill" type="date" required="yes" hint="When must the payment have been done. This date is also set in the form." />
		<cfargument name="products" type="query" required="yes" hint="required columns: prodID, productName, quantity, price" />
		<cfset var sha1_str = "" />
		<cfset var theDate = getIdealTimeStamp(arguments.validUntill) />
		<cfset var amount = 0 />
		<cfset var concatString = "" />
		
		<!--- check if the hashKey and merchantKey are present. If not, throw an error, because it has no use then anyway. --->
		<cfif not len(variables.hashKey) or not len(variables.merchantID)>
			<cfthrow message="Please check ideal.cfc; hashKey and/or merchantID are not yet given!" />
		</cfif>
		
		<!--- add all products to the encrypted string--->
		<cfloop query="products">
			<cfset amount += price*quantity />
			<cfset concatString = concatString & products.prodID & products.productName & products.quantity & products.price />
		</cfloop>
		
		<!---add first part of the encrypted string (only now we have the total amount, so we do it after the loop) --->
		<cfset concatString = hashKey & merchantID & subID & amount & arguments.orderNr & variables.paymentType & theDate & concatString />

		<!--- <comment author="Paul"> remove spaces etc.</comment> --->
		<cfset concatString = rereplace(concatString, "[ \t\n]+", "", "ALL") />
		<!--- <comment author="Paul"> remove html markup</comment> --->
		<cfset concatString = replaceList(concatString, "&amp;,&gt;,&lt;,&quot;", "&,>,<,""") />
		<!--- <comment author="Paul"> now create the sha1 key </comment> --->
		<cfset sha1_str = hash(concatString, "SHA") />
		
		<cfreturn sha1_str />
	</cffunction>

<!---ideal payment, creating sha 1 key:
concatString = hashKey
+ merchantID
+ subID
+ amount
+ purchaseID
+ paymentType
+ validUntil
+ itemNumber1
+ itemDescription1
+ itemQuantity1
+ itemPrice1
(+ itemNumber2
+ itemDescription2
+ itemQuantity2
+ itemPrice2
+ itemNumber3
+ item...)
--->
</cfcomponent>
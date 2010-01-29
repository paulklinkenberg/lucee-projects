<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
	<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
	<title>Ideal cfc test page</title>
	<!--- some jQuery code for duplication of the products in the form --->
	<script type="text/javascript" src="jquery-1.3.2.min.js"></script>
	<script type="text/javascript">
		$(function(){
			$('#duplicateBtn').click(function(){
				var $newfieldset = $('fieldset:first').clone();
				var newnr = $('fieldset').length + 1;
				$('input,label', $newfieldset).each(function(){
					var $this = $(this);
					var attr = ['for','name','id'];
					for (var w in attr)
					{
						if ($this.attr(attr[w]))
							$this.attr(attr[w], $this.attr(attr[w]).replace(/_[0-9]+$/, '_'+newnr));
					}
				});
				$newfieldset.insertAfter($('fieldset:first'));
			})
		});
	</script>
	<style type="text/css">
		body { font-size:0.8em; }
		* { font-family: Verdana, Geneva, sans-serif; color: #000; }
		fieldset label { float:left; clear: both; width: 200px; padding-top:5px; }
		fieldset input { float: left; }
		pre {
			white-space: pre-wrap;       /* css-3 */
			white-space: -moz-pre-wrap;  /* Mozilla, since 1999 */
			white-space: -pre-wrap;      /* Opera 4-6 */
			white-space: -o-pre-wrap;    /* Opera 7 */
			word-wrap: break-word;       /* Internet Explorer 5.5+ */
			background-color:#eee;
			padding:5px;
			font-size:1.0em;
		}
		p { margin: 0px 0px 15px 0px; padding:0; }
		h3 {margin:30px 0px 5px 0px; padding:0; }
	</style>
</head>

<!--- create the ideal cfc object--->
<cfset variables.ideal_obj = createObject("component","ideal") />

<body>
	<p style="position:absolute;top:3px;right:5px;color:#999;text-align:right">Code and examples created by <a href="http://www.coldfusiondeveloper.nl/" style="color:#999;">Paul Klinkenberg</a>
		<br />If you need help, you can <a href="http://www.ongevraagdadvies.nl/contact/" style="color:#999;">hire me</a>!
		<br /><a href="http://www.coldfusiondeveloper.nl/post.cfm/ideal-integration-code-in-coldfusion">Check out the blog post!</a>
	</p>
	<h1 style="line-height:40px;">Test page for iDeal payments with Coldfusion</h1>
	<h3>No warranty!</h3>
	<p>Even though I have done my best to create these pages as good as possible,
		I can give you no warranty whatsoever about the correctness of this code.<br />
		So if your eshop gets robbed, your bank account gets plundered, or your dog is suddenly missing after install, don't blame me.
		<br />I have tested this code only with ING bank, but at least Rabobank also has the same implementation, so that should work as well.
		<br />Questions? Need help? Want me to do it? You can <a href="http://www.ongevraagdadvies.nl/contact/">hire me</a>!
	</p>
	
	<h3>Explanation and necessary steps</h3>
	<p>
		Before you can correctly use this form, you need to <span style="border-bottom:1px dashed #000">set values 'hashKey' and 'merchantID' in ideal.cfc</span>
		<cfif variables.ideal_obj.getVar('hashKey') neq "">(hashKey is set)</cfif>
		<cfif variables.ideal_obj.getVar('merchantID') neq "">(merchantID is set)</cfif>
		<br />
		How the procedure works:
	</p>
	<ol>
		<li>Create a query with the products (price, name, id, quantity).<br />
			<em>(this step is now done with the form underneath)</em>
		</li>
		<li>
			Create a form with all the necessary values for iDeal.
			This is done with the code of this page, so just copy, paste, and tweak where necessary.
		</li>
		<li>Create a page where users go when their payment succeeded (for example, see paid.cfm)<br />
			Optionally, also create a page where the customer goes to when an error occurs, and when they hit the cancel button on the iDeal site.
			This is not required, and if you want to save yourself some work, you could also decide to leave these pages out.
			In the latter case, the customer will just leave the ideal environment, and (hopefully) go back to your site.
		</li>
	</ol>
	
	<cfif not structKeyExists(form, "productName_1")>
		<h3>Step 1: create some products with this form:</h3>
		<form action="?" method="post" id="productForm">
			<input type="button" id="duplicateBtn" value="Add another product" />
			<fieldset>
				<label for="productname_1">productname</label>
				<input type="text" name="productname_1" id="productname_1" value="Pizza ham and mushrooms" size="40" />
				<label for="prodid_1">prodid</label>
				<input type="text" name="prodid_1" id="prodid_1" size="10" value="3457" />
				<label for="quantity_1">quantity<em> (number &gt; 0)</em></label>
				<input type="text" name="quantity_1" id="quantity_1" value="1" size="3" />
				<label for="price_1">price <em>(in euro-cents)</em></label>
				<input type="text" name="price_1" id="price_1" value="1150" size="6" />
			</fieldset>
			<label>&nbsp;</label>
			<input type="submit" value="send" />
		</form>
	<cfelse>
		<p>
			<a href="?">&laquo; back to step 1: the products form</a>
		</p>
		<!--- determine the valid-untill time (here, it is set as 60 minutes after now) --->
		<cfset variables.validUntill = dateAdd('n', 50, now()) />
		<!--- you can set this order-nr to whatever you want --->
		<cfset variables.ordernr = "ORDER#getTickCount()#" />

		<!---create a query with the given values from the form --->
		<cfset idealProducts = queryNew("productname,prodid,quantity,price", "varchar,varchar,number,number") />
		<cfset nrnow = 1 />
		<cfloop condition="structKeyExists(form, 'productname_'&nrnow)">
			<cfif len(form['productname_'&nrnow])>
				<cfset queryAddRow(idealProducts) />
				<!--- ideal requires you to remove all spaces from product name, and max length of 32 --->
				<cfset cleanedProductName = trim(rereplace(rereplaceNoCase(form['productname_'&nrnow], "[^a-z0-9 \-_\.]+", " ", "ALL"), "  +", " ", "ALL")) />
				<cfset querySetCell(idealProducts, "productname", left(cleanedProductName, 32)) />
				<cfset querySetCell(idealProducts, "prodid", form['prodid_'&nrnow]) />
				<cfset querySetCell(idealProducts, "quantity", form['quantity_'&nrnow]) />
				<cfset querySetCell(idealProducts, "price", form['price_'&nrnow]) />
			</cfif>
			<cfset nrnow += 1 />
		</cfloop>
		
		<!--- calculate the total price--->
		<cfset variables.totalAmount = 0 />
		<cfoutput query="idealProducts">
			<cfset totalAmount += price*quantity />
		</cfoutput>
		<!--- have the cfc calculate the SHA1 code --->
		<cfset variables.sha1Code = ideal_obj.getSHACode(ordernr = variables.ordernr, validUntill=variables.validUntill, products=idealProducts) />
		
		<!---output to screen --->
		<cfoutput>
			<h3>Step 2: the form</h3>
			<p>Underneath, a complete (hidden) form is put. When you click the ideal button/logo, the form will be sent.</p>
			<p>The current form will post to the <em>ING bank</em> implementation of iDeal.<br />
				See the documentation of your own bank which url to use.
			</p>

			<cfsavecontent variable="idealFormHtml">
				<form action="https://idealtest.secure-ing.com/ideal/mpiPayInitIng.do" method="post" target="_blank">
					<input type="hidden" name="merchantID" value="#ideal_obj.getVar('merchantID')#" />
					<input type="hidden" name="subID" value="#ideal_obj.getVar('subID')#" />
					<input type="hidden" name="amount" value="#variables.totalAmount#" />
					<input type="hidden" name="purchaseID" value="#variables.ordernr#" />
					<input type="hidden" name="language" value="nl" />
					<input type="hidden" name="currency" value="EUR" />
					<input type="hidden" name="description" value="#left('Order #orderNr#', 32)#" />
					<input type="hidden" name="hash" value="#lCase(variables.sha1Code)#" />
					<input type="hidden" name="paymentType" value="#ideal_obj.getVar('paymentType')#" />
					<input type="hidden" name="validUntil" value="#ideal_obj.getIdealTimeStamp(variables.validuntill)#" />
					<input type="hidden" name="urlSuccess" value="http://#cgi.server_name##GetDirectoryFromPath(cgi.script_name)#paid.cfm?ordernr=#variables.ordernr#" />
					<input type="hidden" name="urlCancel" value="http://#cgi.server_name##GetDirectoryFromPath(cgi.script_name)#cancelled.cfm?ordernr=#variables.ordernr#" />
					<input type="hidden" name="urlError" value="http://#cgi.server_name##GetDirectoryFromPath(cgi.script_name)#errored.cfm?ordernr=#variables.ordernr#" />
					<cfloop query="idealProducts">
						<input type="hidden" name="itemNumber#currentrow#" value="#prodid#" />
						<input type="hidden" name="itemDescription#currentrow#" value="#left(productname, 32)#" />
						<input type="hidden" name="itemQuantity#currentrow#" value="#quantity#" />
						<input type="hidden" name="itemPrice#currentrow#" value="#price#" />
					</cfloop>
					<input type="image" name="img" src="ideal_icon.gif" width="53" height="47" alt="click here to pay with iDeal" border="1" style="padding:5px;" />
				</form>
			</cfsavecontent>

			<div style="border:2px dashed silver;padding:10px;">
				#idealFormHtml#
			</div>
		
			<p>Underneath here, you see a html representation of the (hidden) form, which is inside the dashed area above.</p>
			<pre>#htmlEditFormat(rereplace(idealFormHtml, '([\r\n])\t{3}', '\1', 'all'))#</pre>
		</cfoutput>
	</cfif>
</body>
</html>
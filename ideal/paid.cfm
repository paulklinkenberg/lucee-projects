<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
	<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
	<title>Thank you! Your order has been paid!</title>
	<style type="text/css">
		body { font-size:0.8em; }
		* { font-family: Verdana, Geneva, sans-serif; color: #000; }
	</style>
</head>
<body>
	<h1>Thank you for your payment!</h1>
	<p>Order id: <cfoutput>#url.ordernr#</cfoutput></p>
	
	<p>Developer: it looks like the order has been paid.
		But don't trust it yet, because this url could easily be read from the page source of the form.
		<br />
		You should send the ideal owner a mail here, indicating the probable payment, and tell them to check
		their bank account before sending any products.
	</p>
</body>
</html>
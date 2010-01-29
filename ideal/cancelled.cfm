<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
	<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
	<title>Oops, an error occured while paying</title>
	<style type="text/css">
		body { font-size:0.8em; }
		* { font-family: Verdana, Geneva, sans-serif; color: #000; }
	</style>
</head>
<body>
	<h1>Your payment was not successfull...</h1>
	<p>Order id: <cfoutput>#url.ordernr#</cfoutput></p>
	
	<p>Developer: when the customer hits the cancel button while in iDeal, they come here.
	What you should do here, is redirect them back to the payment form, so they can try again.
	</p>
</body>
</html>
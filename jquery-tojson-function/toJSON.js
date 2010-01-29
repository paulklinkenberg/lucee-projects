/*
 * jQuery JSON Plugin
 * version: 1.0 (2008-04-17)
 *
 * This document is licensed as free software under the terms of the
 * MIT License: http://www.opensource.org/licenses/mit-license.php
 *
 * Brantley Harris technically wrote this plugin, but it is based somewhat
 * on the JSON.org website's http://www.json.org/json2.js, which proclaims:
 * "NO WARRANTY EXPRESSED OR IMPLIED. USE AT YOUR OWN RISK.", a sentiment that
 * I uphold.  I really just cleaned it up.
 *
 * It is also based heavily on MochiKit's serializeJSON, which is
 * copywrited 2005 by Bob Ippolito.
 * 
 * 13 june 2009: file revised and enhanced by Paul Klinkenberg
 * added recursion, indentation, toString() when a function is encountered, and some more things.
 * url: http://www.coldfusiondeveloper.nl/post.cfm/recursive-jquerytojson-function
 */
(function($) {
	function toIntegersAtLease(n)
	// Format integers to have at least two digits.
	{	
		return n < 10 ? '0' + n : n;
	}

	Date.prototype.toJSON = function(date)
	// Yes, it polutes the Date namespace, but we'll allow it here, as
	// it's damned usefull.
	{
		return this.getUTCFullYear()	+ '-' +
			 toIntegersAtLease(this.getUTCMonth()) + '-' +
			 toIntegersAtLease(this.getUTCDate());
	};

	var escapeable = /["\\\x00-\x1f\x7f-\x9f]/g;
	var meta = {	// table of character substitutions
			'\b': '\\b',
			'\t': '\\t',
			'\n': '\\n',
			'\f': '\\f',
			'\r': '\\r',
			'"' : '\\"',
			'\\': '\\\\'
		};
		
	$.quoteString = function(string)
	// Places quotes around a string, inteligently.
	// If the string contains no control characters, no quote characters, and no
	// backslash characters, then we can safely slap some quotes around it.
	// Otherwise we must also replace the offending characters with safe escape
	// sequences.
	{
		if (escapeable.test(string))
		{
			return '"' + string.replace(escapeable, function (a)
			{
				var c = meta[a];
				if (typeof c === 'string') {
					return c;
				}
				c = a.charCodeAt();
				return '\\u00' + Math.floor(c / 16).toString(16) + (c % 16).toString(16);
			}) + '"';
		}
		return '"' + string + '"';
	};
	
	$.toJSON = function(o, compact, indent, depth)
	{
		var indent = !!(indent);
		var type = typeof(o), ret, k, name, val, i;
		var maxDepth = 500;
		var optionalSpace = !!(compact) ? '' : ' ';
		depth = depth || 0;
		++depth;

		if (type == "undefined")
		{
			if ("nodeType" in o)
				type = "object";
			else
			{
				console.log(depth + ' type is undefined: ', o);
				return "undefined";
			}
		}
		
		if (type == "number" || type == "boolean")
			return o + "";
		else if (o === null)
			return "null";
		// Is it a string?
		else if (type == "string")
			return $.quoteString(o);
		// Does it have a .toJSON function?
		else if (type == "object" && typeof o.toJSON == "function")
			return o.toJSON(compact, indent, depth);
		// If it's a function, we return it as string
		else if (type == "function")
			return $.quoteString(o.toString());
			// throw new TypeError("Unable to convert object of type 'function' to json.");
		// Is it an array?
		else if (typeof(o.length) == "number" && (o instanceof Array || o.length > 0 && "item" in o))
		{
			ret = [];
			for (i=0; i<o.length; i++)
				ret.push( $.toJSON(o[i], compact, indent, depth) );
			if (indent)
			{
				var preindentation = new Array(depth).join('  ');
				var indentation = new Array(depth+1).join('  ');
				return "[\n" + indentation + ret.join(",\n" + indentation) + "\n" + preindentation + "]";
			}
			else
				return "[" + ret.join("," + optionalSpace) + "]";
		// It's some sort of other object, i.e. html elements
		} else
		{
			if (depth>=maxDepth)
			{
				return "{'maxdepth':'reached'}";
			}
			ret = [];

			if ("nodeType" in o)
			{
				for each (k in ['nodeName'])// ,'nodeType'
					ret.push('"' + k + '":' + optionalSpace + $.quoteString(o[k]) );
				k='nodeValue';
				if (o[k])
					ret.push('"' + k + '":' + optionalSpace + $.quoteString(o[k]) );
				// var nodeTypes = ['unknown', 'ELEMENT_NODE', 'ATTRIBUTE_NODE', 'TEXT_NODE', 'CDATA_SECTION_NODE', 'ENTITY_REFERENCE_NODE', 'ENTITY_NODE', 'PROCESSING_INSTRUCTION_NODE', 'COMMENT_NODE', 'DOCUMENT_NODE', 'DOCUMENT_TYPE_NODE', 'DOCUMENT_FRAGMENT_NODE', 'NOTATION_NODE'];
				// ret.push('"nodeDescription":' + optionalSpace + $.quoteString(nodeTypes[o.nodeType]) );
				if (o.attributes)
				{
					for (i=0; i<o.attributes.length; i++)
						ret.push($.quoteString(o.attributes[i].nodeName) + ':' + optionalSpace + $.quoteString(o.attributes[i].nodeValue) );
				}
				
				if (o.childNodes && o.childNodes.length)
				{
					name = "childNodes";
					val = $.toJSON(o.childNodes, compact, indent, depth);
					ret.push(name + ":" + optionalSpace + val);
				}
			} else
			{
				for (k in o)
				{
					type = typeof(k);
					
					// create the key part of the object [key:value]
					if (type == "number" || type == "string")
						name = $.quoteString(k);
					else
						name = $.toJSON(k, compact, indent, depth);
				
					// console.log(depth + " - in object: " + name + ':' + o[k] );
					val = $.toJSON(o[k], compact, indent, depth);
					
					if (val != 'undefined' && val != null)
						ret.push(name + ":" + optionalSpace + val);
				}
			}
			if (indent)
			{
				var preindentation = new Array(depth).join('  ');
				var indentation = new Array(depth+1).join('  ');
				return "{\n" + indentation + ret.join(",\n" + indentation) + "\n" + preindentation + "}";
			}
			else
				return "{" + ret.join("," + optionalSpace) + "}";
		}
	};
	
	$.compactJSON = function(o)
	{
		return $.toJSON(o, true);
	};
	
	$.evalJSON = function(src)
	// Evals JSON that we know to be safe.
	{
		return eval("(" + src + ")");
	};
	
	$.secureEvalJSON = function(src)
	// Evals JSON in a way that is *more* secure.
	{
		var filtered = src;
		filtered = filtered.replace(/\\["\\\/bfnrtu]/g, '@');
		filtered = filtered.replace(/"[^"\\\n\r]*"|true|false|null|-?\d+(?:\.\d*)?(?:[eE][+\-]?\d+)?/g, ']');
		filtered = filtered.replace(/(?:^|:|,)(?:\s*\[)+/g, '');
		
		if (/^[\],:{}\s]*$/.test(filtered))
			return eval("(" + src + ")");
		else
			throw new SyntaxError("Error parsing JSON, source is not valid.");
	};
})(jQuery);
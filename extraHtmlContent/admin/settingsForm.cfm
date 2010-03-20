<style type="text/css">
	div.grippie {
		background:#EEEEEE url(/components/plugins/user/extraHtmlContent/admin/grippie.png) no-repeat scroll center 2px;
		border-color:#DDDDDD;
		border-style:solid;
		border-width:0pt 1px 1px;
		cursor:s-resize;
		height:9px;
		overflow:hidden;
	}
	.resizable-textarea textarea {
		display:block;
		margin-bottom:0pt;
		width:95%;
		height: 20%;
	}
</style>
<script type="text/javascript" src="/components/plugins/user/extraHtmlContent/admin/jquery.textarearesizer.compressed.js"></script>
<script type="text/javascript">
	/* jQuery textarea resizer plugin usage */
	$(function() {
		$('textarea').TextAreaResizer();
	});
</script>
<cfoutput>
	<form method="post" action="#cgi.script_name#">
		<p>The extra html will be placed at the end of the head/body.</p>
		<p>
			<label for="headhtml">Extra &lt;head&gt; html</label>
			<span class="field"><textarea name="headhtml" id="headhtml" cols="100" rows="6">#htmleditformat(getSetting('headhtml'))#</textarea></span>
		</p>
		<p>
			<label for="bodyhtml">Extra &lt;body&gt; html</label>
			<span class="field"><textarea name="bodyhtml" id="bodyhtml" cols="100" rows="4">#htmleditformat(getSetting('bodyhtml'))#</textarea></span>
		</p>
		
		<div class="actions">
			<input type="submit" class="primaryAction" value="Submit"/>
			<input type="hidden" value="event" name="action" />
			<input type="hidden" value="showextrahtmlcontentSettings" name="event" />
			<input type="hidden" value="true" name="apply" />
			<input type="hidden" value="extrahtmlcontent" name="selected" />
		</div>
	</form>
</cfoutput>
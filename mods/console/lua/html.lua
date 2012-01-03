-- copy all globals into locals, some locals are prefixed with a G to reduce name clashes
local coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,Gload,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require=coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,load,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require


local sys=require("wetgenes.www.any.sys")

local wet_html=require("wetgenes.html")

local html=require("html")


module("console.html")

setmetatable(_M,{__index=html}) -- use a meta table to also return html base 


-----------------------------------------------------------------------------
--
-- overload footer
--
-----------------------------------------------------------------------------
footer=function(d)

	d=d or {}
	
	d.mod_name="console"
	d.mod_link="http://boot-str.appspot.com/about/mod/console"
	
	return html.footer(d)
end


-----------------------------------------------------------------------------
--
-- display main input/output form
--
-----------------------------------------------------------------------------
console_form=function(d)

	return wet_html.replace([[
	
<div class="#dice_title">
<h1>This console is live, be careful what you type!</h1>
</div>

<form class="jNice" name="console_form" id="console_form" action="" method="POST" enctype="multipart/form-data">
<div class="#console_form">
<div class="#console_form_output" >
<textarea cols="40" rows="5" name="output" id="console_form_output_text" readonly="true" style="width:950px;height:150px" class="field" >{output}</textarea>
</div>
<div class="#console_form_input" >
<textarea cols="40" rows="5" name="input" id="console_form_input_text" style="width:950px;height:150px" class="field" >{input}</textarea>
</div>
<div class="#console_form_submit" style="clear:both" >
<input type="submit" name="submit" class="button" value="Execute Lua Code!"/>
</div>
</form>

<script type="text/javascript">

$(function(){
var $t = $("#console_form_output_text")[0];
$t.scrollTop=$t.scrollHeight;
$t = $("#console_form_input_text")[0];
$t.scrollTop=$t.scrollHeight;
});

</script>

]],d)

end
			
			



-- copy all globals into locals, some locals are prefixed with a G to reduce name clashes
local coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,Gload,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require=coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,load,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require


local sys=require("wetgenes.www.any.sys")

local wet_html=require("wetgenes.html")
local replace=wet_html.replace

local html=require("base.html")


--module
local M={ modname=(...) } ; package.loaded[M.modname]=M


setmetatable(M,{__index=html}) -- use a meta table to also return html base 


function M.fill_cake(srv,refined)
	local cake=refined.cake or {}
	refined.cake=cake
	
	cake.dimeload={}

	cake.dimeload.tabs=[[
{-cake.dimeload.needlogin}
{cake.dimeload.menu}
{-cake.dimeload.error}
{cake.dimeload.download}
{cake.dimeload.sponsor}
{cake.dimeload.buy}
{-cake.dimeload.about}
]]

	cake.dimeload.menu=[=[
<div class="sponsor_wrap land">
	Would you like to 
	<a href="#" onclick="return dimeload.goto('buy');">Buy Dimes</a> ,
	<a href="#" onclick="return dimeload.goto('download');">Download</a> or
	<a href="#" onclick="return dimeload.goto('sponsor');">Sponsor</a>
	this project?
</div>
]=]

	cake.dimeload.buy=[[
<div class="dimeload_tabs" id="dimeload_tab_buy" style="display:none;">
<div class="sponsor_wrap land">
	<a href="/dl/paypal">Buy some dimes using paypal.</a><br/>
	Every dime is worth one download, you may either use them yourself
	or create a sponsored page to share with your friends.
</div>
</div>
]]

	cake.dimeload.sponsor=[=[
<div class="dimeload_tabs" id="dimeload_tab_sponsor" style="display:none;">
	<form action="{cake.url}" method="POST" enctype="multipart/form-data">
<div class="dime-game_main">
	<div class="dime-game_txt">Sponsorship information:</div>
	<div>
		<div class="dimeload_page_secret">
			Secret name: <input class="dimeload_page_secret_input" type="text" name="code" placeholder="This will be your secret link, ie. http://dime.lo4d.net/dl/project/secretname" value="{.cake.dimeload.post_code}" />
			<span> You may only use numbers, letters and underscore. </span>
		</div>
		<div class="dimeload_page_dimes">
			{-cake.dimeload.available}
			<div class="dimeload_page_add">
			Add <input name="dimes" placeholder="How many?"> dimes.
			Once added you may not remove them.
			</div>
		</div>
		<div class="dimeload_page_text">
			<textarea rows="10" cols="50" name="about" placeholder="Tell us all about yourself and why you are sponsoring this project, if you want to. Go on, go on, go on, go on.">{.cake.dimeload.post_about}</textarea>
			<div class="dimeload_page_markdown">
				markdown syntax is allowed.<br/>
				//italics// **bold** ##monospace##<br/>
				\\* Bullet list\\* Second item\\** Sub item\\<br/>
				[[http://google.com|Google]]<br/>
				Force\\linebreak<br/>
				<a href="#">click for more</a> (opens in new window)
				<input type="submit" value="sponsor" name="sponsor" class="dime-butt more" />
			</div>
		</div>
	</div>
</div>
	</form>
</div>
]=]

	cake.dimeload.login=[[
<div class="sponsor_wrap login">
	Hello, you are not logged in.
	<div class="dl_log login">
		Logging in will allow you to dimeload this project.
	</div>
	<a href="/dumid/login/?continue={.cake.urlesc}" class="dime-butt more">Login</a>
</div>
]]

	cake.dimeload.item=[[
	<div class="dl-list">
		<div class="dl-list_name">
			{it.desc}
		</div>
		<div class="dl-list_butt_wrap">
			<a href="?download={it.versions.1}" class="dime-butt list"> {it.versions.1} </a>
		</div>
	</div>
]]

	cake.dimeload.available=[[
<div class="dimeload_left">
	There are currently <span class="dl_dimes">{cake.dimeload.page.available} dimes</span> available.<br/>
	Any downloads you make will use dimes from this pool.
</div>
]]
	cake.dimeload.mydimes=[[
<div class="dimeload_left">
	You have <span class="dl_dimes">{cake.dimeload.mydimes_available} dimes</span> available.<br/>
	Any downloads you make will use your dimes.
</div>
]]
	cake.dimeload.download=[[
<div class="dimeload_tabs" id="dimeload_tab_download" style="display:none;">
<div class="sponsor_wrap land">
	{cake.dimeload.dimecount}
	{cake.dimeload.list}
</div>
</div>
]]

	cake.dimeload.error=[[
<div class="sponsor_wrap land">
	{cake.dimeload.error_text}
</div>
]]

	cake.dimeload.about=[[
<div class="dimeload_about dimeload_autoembed">
	{.cake.dimeload.waka_about}
</div>
]]



	cake.dimeload.goto="download"
	cake.dimeload.js=[[
<script>
head.js( head.fs.jquery_js , head.fs.jquery_wet_js , "/js/dimeload/dimeload.js",function(){

	$(".dimeload_autoembed a").autoembedlink({width:640,height:480});

	dimeload.goto("{cake.dimeload.goto}");
	
	$('.dimeload_page_secret input').keyup(function () {     
		var t=this.value.replace(/[^0-9_a-zA-Z]/g,'');
		if(t!=this.value) { this.value = t; }
	});
	
	$('.dimeload_page_add input').keyup(function () {     
		var t=this.value.replace(/[^0-9]/g,'');
		if(t!=this.value) { this.value = t; }
	});
	

});
</script>
]]

	return cake
end

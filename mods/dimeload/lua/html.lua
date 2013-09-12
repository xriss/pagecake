-- copy all globals into locals, some locals are prefixed with a G to reduce name clashes
local coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,Gload,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require=coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,load,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require


local sys=require("wetgenes.www.any.sys")

local wet_html=require("wetgenes.html")
local replace=wet_html.replace

local html=require("base.html")


--module
local M={ modname=(...) } ; package.loaded[M.modname]=M


setmetatable(M,{__index=html}) -- use a meta table to also return html base 


-----------------------------------------------------------------------------
--
-- overload footer
--
-----------------------------------------------------------------------------
M.footer=function(d)

	d=d or {}
	
	d.mod_name="dimeload"
	d.mod_link="https://bitbucket.org/xixs/pagecake/src/tip/mods/dimeload"
	
	return html.footer(d)
end

-----------------------------------------------------------------------------
--
-- control bar
--
-----------------------------------------------------------------------------
M.dimeload_bar=function(d)


	d.admin=""
	if d.srv and d.srv.user and d.srv.user.cache and d.srv.user.cache.admin then -- admin
		d.admin=replace([[
	<div class="aelua_admin_bar">
		<a href="/?cmd=edit&page={pagename}" class="button" > Edit </a>
		<a href="/?cmd=edit&page=dl" class="button" > Admin </a>
	</div>
]],d)
	end
	
	return (d.admin)

end



-----------------------------------------------------------------------------
--
-- sponsor form and links
--
-----------------------------------------------------------------------------
M.sponsor=function(d)

	return replace([[
	<div>
	<form action="?sponsor" method="post" >
	 PROJECT:<input type="text" name="project" value="{project}"/> <br/>
	 CODE:<input type="text" name="code" value="{code}"/> <br/>
	 DIMES:<input type="text" name="dimes" value="{dimes}"/> <br/>
	 ABOUT:<textarea rows="20" cols="80" name="about">{about}</textarea> <br/>
	 <input type="submit" value="Update" /> <br/>
	</form>
	</div>
]],d)


end

function M.fill_cake(srv,cake)
	
	cake.dimeload={}

	cake.dimeload.tabs=[[
{-cake.dimeload.needlogin}
{cake.dimeload.menu}
{cake.dimeload.download}
{cake.dimeload.sponsor}
{cake.dimeload.buy}
{cake.dimeload.error}
]]

	cake.dimeload.menu=[=[
<div class="sponsor_wrap land">
	Would you like to 
	<a href="#" onclick="dimeload.goto('buy');">Buy Dimes</a> ,
	<a href="#" onclick="dimeload.goto('download');">Download</a> or
	<a href="#" onclick="dimeload.goto('sponsor');">Sponsor</a>
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
<div class="dime-game_main">
	<div class="dime-game_txt">Sponsorship information:</div>
	<div>
		<div>
			Secret name: <input type="text" name="projectname" placeholder="This will be your secret link, ie. http://dime.lo4d.net/dl/project/secretname">
			<span> You may only use numbers and letters. </span>
		</div>
		<div>
			<div>
				There are currently <span class="dl_dimes">{cake.dimeload.page.available}</span> dimeloads for this sponsored page.
			</div>
			Add <input type="text" name="dimes" placeholder="How many?"> dimes.
			Once added you may not remove them.
		</div>
		<div>
			<textarea name="aboutproject" placeholder="Tell us all about yourself and why you are sponsoring this project, if you want to. Go on, go on, go on, go on."></textarea>
			<div>
				markdown syntax is allowed.<br/>
				//italics// **bold** ##monospace##<br/>
				\\* Bullet list\\* Second item\\** Sub item\\<br/>
				[[http://google.com|Google]]<br/>
				Force\\linebreak<br/>
				<a href="#">click for more</a> (opens in new window)
				<input type="submit" class="dime-butt more">
			</div>
		</div>
	</div>
</div>
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
	There are currently <span class="dl_dimes">{cake.dimeload.page.available} dimes</span> available.<br/>
	Any downloads you make will use dimes from this pool.
]]
	cake.dimeload.download=[[
<div class="dimeload_tabs" id="dimeload_tab_download" style="display:none;">
<div class="sponsor_wrap land">
	{-cake.dimeload.available}
	{cake.dimeload.list}
</div>
</div>
]]

	cake.dimeload.error=[[
<div class="dimeload_tabs" id="dimeload_tab_error" style="display:none;">
<div class="sponsor_wrap land">
	{cake.dimeload.error_text}
</div>
</div>
]]

	cake.dimeload.goto="download"
	cake.dimeload.js=[[
<script>
head.js( head.fs.jquery_js , "/js/dimeload/dimeload.js",function(){
	dimeload.goto("{cake.dimeload.goto}");
});
</script>
]]

	return cake
end

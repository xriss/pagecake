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

function fill_cake(srv,cake)
	
	cake.dimeload={}

	cake.dimeload.tabs=[[
{login}
{sponsor}
{download}
]]

	cake.dimeload.sponsor=[=[
<div class="dime-game_main">
	<div class="dime-game_txt">Sponsorship information:</div>
	<div style="width:880px; padding:40px; margin:0 auto;">
		<div style="color:#fff; font-size:20px; width:880px; padding:10px 0; line-height:1.75em;">
			Secret name: <input type="text" style="min-width:705px; color:#666; font-size:18px; line-height:1.5em;" name="projectname" placeholder="This will be your secret link, ie. http://dime.lo4d.net/dl/project/secretname">
		</div>
		<div style="color:#fff; font-size:20px; width:880px; padding:10px 0; line-height:1.75em;">
			<span style="padding-right:20px; display:inline-block;">
				There are currently <span class="dl_dimes">0</span> dimeloads for this sponsored page.
			</span>
			<input type="text" style="min-width:300px; color:#666; font-size:18px; line-height:1.5em;" name="dimes" placeholder="How many are you adding?">
		</div>
		<div style="color:#fff; font-size:20px; width:880px; padding:10px 0; line-height:1.75em;">
			<textarea style="width:550px; height:350px; color:#666; font-size:18px; text-align:left;" name="aboutproject" placeholder="Tell us all about yourself and why you are sponsoring this project, if you want to. Go on, go on, go on, go on."></textarea>
			<span style="display:inline-block; vertical-align:top; text-align:left; font-size:12px; line-height:1.45em; padding:10px 0 0 20px;">
				markdown syntax is allowed.<br/>
				//italics// **bold** ##monospace##<br/>
				\\* Bullet list\\* Second item\\** Sub item\\<br/>
				[[http://google.com|Google]]<br/>
				Force\\linebreak<br/>
				<a href="#" style="color:#00ff00;">click for more</a> (opens in new window)
				<input type="submit" class="dime-butt more" style="margin-top:40px;" value="Sponsor this, bitches!">
			</span>
		</div>
	</div>
</div>
]=]

	cake.dimeload.login=[[
<div class="sponsor_wrap login">
	Hello, you are not logged in.
	<div class="dl_log login">
		Logging in will allow you to buy and get dimeloads for yourself and your friends.
	</div>
	<a href="http://dime.lo4d.net/dumid/login/?continue=http://dime.lo4d.net/welcome" class="dime-butt more">Login</a>
	<div class="dl_log now">
		There are currently <span class="dl_dimes">85 dimeloads</span> available for this project.
	</div>
</div>
]]

	cake.dimeload.download=[[
<div class="sponsor_wrap land">
	There are currently <span class="dl_dimes">85 dimeloads</span> available for this project.
	<div class="dl-list">
		<div class="dl-list_name">
			Windows EXE installer
		</div>
		<div class="dl-list_butt_wrap">
			<a href="?download={it.versions.1}" class="dime-butt list"> bulbaceous.v13.655.exe </a>
		</div>
		<div class="clear"></div>
	</div>
	<div class="dl-list">
		<div class="dl-list_name">
			Ubuntu or Windows or Raspberry Pi ZIP
		</div>
		<div class="dl-list_butt_wrap">
			<a href="?download={it.versions.1}" class="dime-butt list"> bulbaceous.v13.655.zip </a>
		</div>
		<div class="clear"></div>
	</div>
	<div class="dl-list">
		<div class="dl-list_name">
			Android APK for phones/tablets/consoles
		</div>
		<div class="dl-list_butt_wrap">
			<a href="?download={it.versions.1}" class="dime-butt list"> bulbaceous.v13.655.apk </a>
		</div>
		<div class="clear"></div>
	</div>
</div>
]]

	return cake
end

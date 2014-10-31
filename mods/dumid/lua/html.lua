-- copy all globals into locals, some locals are prefixed with a G to reduce name clashes
local coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,Gload,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require=coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,load,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require

local sys=require("wetgenes.www.any.sys")
local wet_html=require("wetgenes.html")
local replace=wet_html.replace
local url_esc=wet_html.url_esc

local html=require("base.html")

local ngx=ngx

module("dumid.html")

setmetatable(_M,{__index=html}) -- use a meta table to also return html base 



-----------------------------------------------------------------------------
--
-- special popup header
--
-----------------------------------------------------------------------------
dumid_header=function(d)

	d.title=d.title or "Choose your dum id!"
	
	d.jquery_js="http://ajax.googleapis.com/ajax/libs/jquery/1.4.2/jquery.min.js"
		
	if d.srv.url_slash[3]=="host.local:8080" then -- a local shop only servs local people
		d.jquery_js="/js/jquery-1.4.2.min.js"
	end

	return replace([[
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html>
 <head>
<title>{title}</title>

<link REL="SHORTCUT ICON" HREF="/favicon.ico">
<link rel="stylesheet" type="text/css" href="/css/dumid/popup.css" /> 
<script type="text/javascript" src="{jquery_js}"></script>

 </head>
<body>
<div class="dum-wrap">
<div class="dum-main">
	
]],d)

end


-----------------------------------------------------------------------------
--
-- special popup footer
--
-----------------------------------------------------------------------------
dumid_footer=function(d)
	
	return replace([[

		<div class="dum-foot">
			This is a <a href="http://www.wetgenes.com/">dumid</a> login system.
		</div>
	</div>
</div>

</body>
</html>
]],d)

end


-----------------------------------------------------------------------------
--
-- special popup footer
--
-----------------------------------------------------------------------------
dumid_choose=function(d)

	local more="" -- more logins that may not be available
	
	
	if d.twitter then
more=more..[[
	<div class="dum-butt_wrap"><a class="dum-butt" href="{srv.url_base}login/twitter/?continue={continue}">Twitter</a></div>
]]
	end

	if d.facebook then
more=more..[[
	<div class="dum-butt_wrap"><a class="dum-butt" href="{srv.url_base}login/facebook/?continue={continue}">Facebook</a></div>
]]
	end

more=more..[[
	<div class="dum-butt_wrap"><a class="dum-butt" href="{srv.url_base}login/jedi/?continue={continue}">Jedi</a></div>
	<div class="dum-butt_wrap"><a class="dum-butt" href="{srv.url_base}login/email/?continue={continue}">Email</a></div>
]]

	d.continue=url_esc(d.continue)
	return replace([[
<div class="dum-head">Login with</div>
<div class="dum-butts">
	<div class="dum-butt_wrap"><a class="dum-butt" href="{srv.url_base}login/genes/?continue={continue}">Wetgenes</a></div>
	<div class="dum-butt_wrap"><a class="dum-butt" href="{srv.url_base}login/steam/?continue={continue}">Steam</a></div>
	<div class="dum-butt_wrap"><a class="dum-butt" href="{srv.url_base}login/google/?continue={continue}">Google</a></div>
]]..more..
[[	<div class="clear"></div>
</div>]]
,d)

end


-----------------------------------------------------------------------------
--
-- please enter email
--
-----------------------------------------------------------------------------
dumid_email=function(d)

	d.continue=url_esc(d.continue)

	return replace([[
<div class="dum-mail_txt">
	Please enter the email address you wish to login with and we will send you a login token. Beware that we use this email as your <b>public</b> identity so it will be visible to everyone on the internets.
	<br/><br/>
	If you are Batman and fear this may expose your true identity then please use one of the other login methods.
	<br/><br/>
	Better still just make a new "public" email address that you do not feel so precious about.
</div>
<div class="dum-mail_form">

<form action="{srv.url_base}token/send/?continue={continue}" method="get">
<input type="text" name="email" value="" maxlength="128" style="width:80%" class="txt"/>
<input type="submit" value="Send" class="form"/>
</form>

</div>
]]
,d)

end

-----------------------------------------------------------------------------
--
-- please enter email
--
-----------------------------------------------------------------------------
dumid_wetgenes=function(d)

	d.continue=url_esc(d.continue)

	return replace([[
<div class="dum-genes_txt">

	Please enter your wetgenes username and password to log in.

	<br/><br/>

	If you do no have a wetgenes user account and wish to create one 
	then please also enter the email address you wish to link your 
	account to. A verification email will be sent to this email 
	address to finish the creation of the account.

</div>
<div class="dum-genes_form">

<form action="{srv.url_base}token/send/?continue={continue}" method="get">
<input type="text" name="username" value="" maxlength="128" style="width:80%" class="txt"/>
<input type="text" name="password" value="" maxlength="128" style="width:80%" class="txt"/>
<input type="text" name="email"    value="" maxlength="128" style="width:80%" class="txt"/>
<input type="submit" value="Send" class="form"/>
</form>

</div>
]]
,d)

end

-----------------------------------------------------------------------------
--
-- please enter token
--
-----------------------------------------------------------------------------
dumid_token=function(d)

	d.continue=url_esc(d.continue)

	return replace([[
<div class="dum-mail_txt">
	Please check your email ( It might be marked as spam, so look there ) and either click on the link we sent you or if that link does not work then try entering the token here.
</div>
<div class="dum-mail_form">

<form action="{srv.url_base}token/check" method="get">
<input type="text" name="token" value="" maxlength="128" style="width:80%" class="txt"/>
<input type="submit" value="Use Token" class="form"/>
</form>

</div>
]]
,d)


end


dumid_jedi=function(d)

	d.continue=url_esc(d.continue)

	return replace([[
	
		<div class="dum-jedi">
			Use the force.
		</div>
		
	<div class="dum-butts">
	<div class="dum-butt_wrap"><a class="form" style="color:#777777;" href="{srv.url_base}login/?continue={continue}">I accept that I am not a Jedi :(</a></div>
	<div class="clear"></div>
	</div>
]]
,d)


end

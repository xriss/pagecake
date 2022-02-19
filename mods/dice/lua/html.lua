-- copy all globals into locals, some locals are prefixed with a G to reduce name clashes
local coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,Gload,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require=coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,load,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require


local sys=require("wetgenes.www.any.sys")

local wet_html=require("wetgenes.html")

local html=require("base.html")

-- replacement version of module that does not global
local module=function(modname, ...)
	local ns={ _NAME = modname , _PACKAGE = string.gsub (modname, "[^.]*$", "") }
	ns._M = ns
	package.loaded[modname] = ns
	setfenv (2, ns)
	for _,f in ipairs({...}) do f(ns) end
end
module("dice.html")

setmetatable(_M,{__index=html}) -- use a meta table to also return html base 


-----------------------------------------------------------------------------
--
-- overload footer
--
-----------------------------------------------------------------------------
footer=function(d)

	d=d or {}
	
	d.mod_name="dice"
	d.mod_link="https://bitbucket.org/xixs/pagecake/src/tip/mods/dice"
	
	return html.footer(d)
end


-----------------------------------------------------------------------------
--
--
-----------------------------------------------------------------------------
dice_form=function(d)

	local cs=[[
<div><input type="radio" name="count" value="{v}" {checked} />{v}x</div>
]]
	local ds=[[
<div><input type="radio" name="side" value="{v}" {checked} />d{v}</div>
]]
	local ss=[[
<div><input type="radio" name="style" value="{v}" {checked} />{v}</div>
]]
	d.line1=""
	for i=1,#d.counts do local v=d.counts[i]
		local checked=""
		if v==d.count then checked="checked=\"checked\"" end
		d.line1=d.line1..wet_html.replace(cs,{v=v,checked=checked})
--		if (i%2)==0 then d.line1=d.line1.."<br/>" end
	end
		
	d.line2=""
	for i=1,#d.sides do local v=d.sides[i]
		local checked=""
		if v==d.side then checked="checked=\"checked\"" end
		d.line2=d.line2..wet_html.replace(ds,{v=v,checked=checked})
	end
	
	d.line3=""
	for i=1,#d.styles do local v=d.styles[i]
		local checked=""
		if v==d.style then checked="checked=\"checked\"" end
		d.line3=d.line3..wet_html.replace(ss,{v=v,checked=checked})
	end
	
	return wet_html.replace([[
	
<div class="dice_title">
<h1>Choose your god!</h1>
</div>

<form class="dice_form" name="dice_form" id="dice_form" action="" method="post">
	<div class="dice_div">
		<div class="dice_div_line1" >
			{line1}
		</div>
		<div class="dice_div_line2" >
			{line2}
		</div>
		<div class="dice_div_line3" >
			{line3}
		</div>
		<div class="dice_div_submit" >
			<input type="submit" name="submit" value="Roll dice!"/>
		</div>
	</div>
</form>


]],d)

end
			
			



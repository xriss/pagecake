

local sys=require("wetgenes.aelua.sys")

local wet_html=require("wetgenes.html")
local replace=wet_html.replace

local html=require("html")

local setmetatable=setmetatable

module("score.html")

setmetatable(_M,{__index=html}) -- use a meta table to also return html base 


-----------------------------------------------------------------------------
--
-- overload footer
--
-----------------------------------------------------------------------------
footer=function(d)

	d=d or {}
	
	d.mod_name="score"
	d.mod_link="http://boot-str.appspot.com/about/mod/score"
	
	return html.footer(d)
end

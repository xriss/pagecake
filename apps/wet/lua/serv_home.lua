

-- load up html template strings
local html=require("html")
local wet_html=require("wetgenes.html")

local sys=require("wetgenes.www.any.sys")

local dat=require("wetgenes.www.any.data")

local users=require("wetgenes.www.any.users")


local wet_string=require("wetgenes.string")
local str_split=wet_string.str_split
local serialize=wet_string.serialize

module("serv_home")

-----------------------------------------------------------------------------
--
-- the serv function, named the same as the file it is in
--
-----------------------------------------------------------------------------
function serv(srv)
local sess,user=users.get_viewer_session(srv)

local function put(a,b)
	b=b or {}
	b.srv=srv
	srv.put(wet_html.get(html,a,b))
end

--	loadfile("dash.lua")

	srv.set_mimetype("text/html")
	
	put("header",{})
	put("home_bar",{})
	put("user_bar",{user=user})
	
	put("mainpage".."<br/>")
	put("<a href='/test'>/test</a>".."<br/>")
	put("<a href='/chan'>/chan</a>".."<br/>")
	put("<a href='/dice'>/dice</a>".."<br/>")
	put("<a href='/console'>/console</a>".."<br/>")
	put("<a href='/thumbcache'>/thumbcache</a>".."<br/>")
	
	put("about",{})
	
	put("footer",{})

end



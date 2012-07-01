

-- load up html template strings
local html=require("html")
local wet_html=require("wetgenes.html")

local sys=require("wetgenes.www.any.sys")

local dat=require("wetgenes.www.any.data")

local users=require("wetgenes.www.any.users")

local log=require("wetgenes.www.any.log").log -- grab the func from the package

local wet_string=require("wetgenes.string")
local str_split=wet_string.str_split
local serialize=wet_string.serialize

local diff=require("wetgenes.diff")
local waka=require("wetgenes.waka")

local Json=require("Json")

local tostring=tostring

module("serv_test")

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


--	log("REQ: "..srv.url)
	
--	srv.set_cookie({name="poop",value="now",live=60,domain=nil,path="/"})
	
	srv.set_mimetype("text/html")
	put("header",{})
	put("home_bar",{})
	put("user_bar",{user=user})
	
	local form=[[
<form name="post" id="post" action="" method="post" enctype="multipart/form-data">

<textarea name="text" cols="80" rows="8" accesskey="m">
A serious young man found the conflicts of mid 20th Century America confusing. He went to many people seeking a way of resolving within himself the discords that troubled him, but he remained troubled.

One night in a coffee house, a self-ordained Zen Master said to him, "go to the dilapidated mansion you will find at this address which I have written down for you. Do not speak to those who live there; you must remain silent until the moon rises tomorrow night. Go to the large room on the right of the main hallway, sit in the lotus position on top of the rubble in the northeast corner, face the corner, and meditate."

He did just as the Zen Master instructed. His meditation was frequently interrupted by worries. He worried whether or not the rest of the plumbing fixtures would fall from the second floor bathroom to join the pipes and other trash he was sitting on. He worried how would he know when the moon rose on the next night. He worried about what the people who walked through the room said about him.

His worrying and meditation were disturbed when, as if in a test of his faith, ordure fell from the second floor onto him. At that time two people walked into the room. The first asked the second who the man was sitting there was. The second replied "Some say he is a holy man. Others say he is a shithead."

Hearing this, the man was enlightened.
</textarea> <br/>

	<input type="submit" value="Post" accesskey="z"> <br/>
	
</form>
]]
	

	srv.put( form.."<br/><br/>")
	
	if srv.posts.text then

--	srv.put("<br/><br/>"..tostring(srv.posts.text).."<br/><br/>")
	
	local chunks=waka.text_to_chunks(srv.posts.text)
	
	local s=waka.chunk_to_html(chunks.body,"")
	
--log(s)

	srv.put("<br/><br/>"..tostring(s).."<br/><br/>")
	
	end
	
	
--[[	

	local d=diff.diff(s1,s2,"\n")
	srv.put( Json.Encode(d).."<br/><br/>")
	local s3=diff.unpatch(s2,d)
	local s4=diff.patch(s1,d)
	
	srv.put("s1==s3<br/>"..tostring(s1==s3).."<br/>"..s3.."<br/><br/>")
	
	srv.put("s2==s4<br/>"..tostring(s2==s4).."<br/>"..s4.."<br/><br/>")
	
	srv.put( tostring(user).."<br/><br/>")
	
	srv.put( tostring(srv).."<br/><br/>")
	
	srv.put( tostring(package.path) .."<br/>" )
	
	srv.put( tostring(dat.str) .."<br/>" )

	srv.put( tostring(wetgenes.aelua) .."<br/>" )
	
	
	local ent={}
	

	ent.props={
		email="poo poo head",
		num=23,
		text="nobody here",
		}
	
	ent.key={kind="test",id=1}
	ent.props.num=0;
	local key=dat.put(ent)
	
	ent.key={kind="test",id=1,parent=key}
	ent.props.num=5;
	dat.put(ent)
	
	ent.key={kind="test",id="plop1"}
	ent.props.num=19;
	dat.put(ent)

	ent.key={kind="test",id="plop2"}
	ent.props.num=23;
	dat.put(ent)
	
	ent.key={kind="test",id="plop3"}
	ent.props.num=42;
	dat.put(ent)
	
	local t=dat.query({
		kind="test",
		limit=2,
		offset=0,
			{"filter","num",">=",0},
			{"filter","num","<=",23},
			{"sort","num",">"},
		})
		
	srv.put( tostring(t.code).."<br/>" )
	srv.put( tostring(t.error or "").."<br/>" )
	srv.put( tostring(t.cursor or "").."<br/>" )
	srv.put( tostring(t.count or "").."<br/>" )
	for i,v in  ipairs(t) do
		srv.put( tostring(v).."<br/>" )
	end
	
	local t=dat.query({
		parent=key,
		kind="test",
		limit=2,
		offset=0,
			{"filter","num",">=",0},
			{"filter","num","<=",23},
			{"sort","num",">"},
		})
		
	srv.put( tostring(t.code).."<br/>" )
	srv.put( tostring(t.error or "").."<br/>" )
	srv.put( tostring(t.cursor or "").."<br/>" )
	srv.put( tostring(t.count or "").."<br/>" )
	for i,v in  ipairs(t) do
		srv.put( tostring(v).."<br/>" )
	end
	
	
	srv.put( "Time elapsed : " .. math.ceil((os.clock()-srv.clock)*1000) .."ms<br/>" )
]]

	put("footer",{})
	
end


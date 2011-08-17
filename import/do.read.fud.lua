
exec("mkdir cache")

require("socket")
require("socket.http")

local grd=require("grd")

local sxml=require("wetgenes.simpxml")
local json=require("wetgenes.json")
local wetstring=require("wetgenes.string")

local ssplit=wetstring.str_split

local feedurl="http://www.wetgenes.com/forum/feed.php"


local jsoncachename="cache/note.cache.json"
local cache=getcache(jsoncachename)
local putcache=function() putcache(jsoncachename,cache) end

cache.msgs=cache.msgs or {}


-- pull in forums
local groups={
	{
		name="ASL",
		id=23,
	},
	{
		name="Wet-Alert",
		id=12,
	},
	{
		name="Wet-Help",
		id=14,
	},
	{
		name="Wet-Requests",
		id=10,
	},
	{
		name="Wet-Spam",
		id=11,
	},
	{
		name="Wet-Fiction",
		id=9,
	},
	{
		name="Fuck-Mails",
		id=17,
	},
	{
		name="Moar-Games",
		id=20,
	},
	{
		name="Wet-Fart",
		id=26,
	},
	{
		name="Hoe-House",
		id=29,
	},
	{
		name="Shadow-News",
		id=15,
	},
	{
		name="Shadow-Active",
		id=16,
	},
	{
		name="Shadow-Archive",
		id=19,
	},
	{
		name="Wet-Bugs",
		id=13,
	},
	{
		name="Wet-Bugs-Done",
		id=18,
	},
	{
		name="Wet-Requests-Done",
		id=21,
	},
	{
		name="Wet-Test",
		id=2,
	},
	{
		name="Wet-Flash",
		id=8,
	},
	{
		name="Wet-Wank",
		id=22,
	},
	{
		name="Trash",
		id=30,
	},
}

-- small test
local tgroups={
	{
		name="Wet-Flash",
		id=8,
	},
}

function build_query_url(base,opts)

	local tab={}
	for n,v in pairs(opts) do
		tab[#tab+1]=n.."="..v -- we should really escape this stuff
	end
	return base.."?"..table.concat(tab,"&")

end

for _,group in pairs(groups) do

	local mstart=0
	local mstep=100 -- ask for but may not get
	local mfinished=false
	local mgot=0
	
	local opts={}
	
	opts.format="rdf"
	opts.mode="m"
	
	opts.frm=group.id -- which forum id to import
	opts.o=mstart
	opts.n=mstep
	
	local msgs=cache.msgs and cache.msgs[group.name]
		
	if not msgs then
		msgs={} 
		repeat
		
			opts.o=opts.o+mgot
			local url=build_query_url(feedurl,opts)
			mgot=0
			
			print(url)

			local body, headers, code = socket.http.request(url)
			put("Received "..#body.." bytes\n")


			local doc=sxml.parse(body)

			mfinished=true
			
			if doc and doc[1] then
				for i,v in ipairs(doc[1]) do
					if v[0]=="item" then
			--			put("\n"..tostring(v[0]).."\n\n")
						dat={}
						for i,v in ipairs(v) do
							local n=tonumber(v[1])
							if n then
								dat[tostring(v[0])]=n
							else
								dat[tostring(v[0])]=tostring(v[1])
							end
	--put(tostring(v[0]).." = "..tostring(v[1]):gsub("\r","\n").."\n")
						end
						msgs[ dat["message_id"] ]=dat
	--print(tostring(dat["message_id"]))
						mgot=mgot+1
						mfinished=false
					end
				end
			end
			
		until mfinished
		cache.msgs[group.name]=msgs -- save for later
		putcache()
	end
	
for i,v in pairs(msgs) do
--		print(i)
	if v and v.date and v.body then
		local ts=v.date or "2000-01-01T00:00:00"
		local ti=0
		local td={}
		
--"2006-03-03T13:19:24-00:00"
--[[
title = WetBio
topic_id = 46
topic_title = WetBio
message_id = 167
reply_to_id = 0
reply_to_title = nil
forum_id = 8
forum_title = WetFlash
category_title = WetGenes
author = XIX
author_id = 2
date = 2006-03-17T22:51:55-00:00
body = <br />
]]

		local _,_,y,n,d,h,m,s=ts:find("(%d+)-(%d+)-(%d+)T(%d+):(%d+):(%d+)")
		
		td.year=tonumber(y)
		td.month=tonumber(n)
		td.day=tonumber(d)
		td.hour=tonumber(h)
		td.min=tonumber(m)
		td.sec=tonumber(s)
		td.isdst=false
		
		ti=os.time(td)
		
		if v.author=="" then v.author="Anon" end

		v.time=ti -- sensible time value
--		v.uid="/forum/"..group.name..":"..tostring(v.author):lower() ..":".. v.time -- this should be a unique ID
		
		v.uid=tostring(v.author):lower() ..":".. v.time -- this should be a unique ID
		
				
--		print(v.message_id .." -> ".. tostring( (v.master and v.master.message_id) or 0) )
--		print(v.reply_to_id)
		
		
--		break

		v.text=v.title.."<br/><br/>"
		if v.text:sub(1,3):lower()=="re:" then v.text="" end -- ignore auto generated reply titles
		v.text=v.text..v.body
		
		v.text=v.text:gsub("%c","") -- kill any control codes
		v.text=v.text:gsub("%s+"," ") -- all spaces should be spaces
		v.text=v.text:gsub("<br />","\n") -- brs are new lines
		v.text=v.text:gsub("<br/>","\n")
		v.text=v.text:gsub("<.->","") -- remove any markup tags
		
-- unescape a few entities

		v.text=v.text:gsub("&gt;",">")
		v.text=v.text:gsub("&lt;","<")
		v.text=v.text:gsub("&amp;","&")
		v.text=v.text:gsub("&quot;","\"")
		v.text=v.text:gsub("&#(%d+);",function(n) n=tonumber(n) if n>255 then n=32 end return string.char(n) end)

--print(v.text)

		
	end	
end
	
	local upsearch
	upsearch=function(id)
		if id==0 then return nil end
		local t=msgs[id]
		if t.reply_to_id>0 then return upsearch(t.reply_to_id) end
		return t
	end
	
	local upsearch2
	upsearch2=function(id,tt)
		if id==0 then return nil end
		local t=msgs[id]
		if t.reply_to_id>0 then return upsearch2(t.reply_to_id,t) end
		return tt --we want the penaultiment
	end

	local notes={}
	for i,v in pairs(msgs) do
		if v.text then -- valid stuff only
			notes[#notes+1]=v
			v.master=upsearch( v.reply_to_id )
			v.parent=upsearch2( v.reply_to_id , v)
			
			v.master=v.master and v.master.uid
			v.parent=v.parent and v.parent.uid
		end
	end
	
	table.sort(notes,function(a,b)
	
		if a.master and not b.master then return false end
		if b.master and not a.master then return true end
		
		if a.parent and not b.parent then return false end
		if b.parent and not a.parent then return true end

		return a.time<b.time
		
	end)

	local tonote=function(t)
		return {
			uid=t.uid,
			url="/forum/"..group.name,
			text=t.text,
			updated=t.time,
			created=t.time,
			name=t.author,
			author=t.author_id.."@id.wetgenes.com",
			master=t.master and t.master.uid,

-- nobody replys properly in fud...
--			parent=t.parent and t.parent.uid,

		}
	end
	
	local threads={}
	for i,v in pairs(notes) do
	
		if not v.master then -- the start of the thread
		
			local thread={}
			
--			thread.url="forum/"..group.name
			
			threads[ v.uid ]=thread
			thread[#thread+1]=tonote(v)

		else

			local thread=threads[v.master]
			
			thread[#thread+1]=tonote(v)
		
		end
	
--		print(v.time.." : "..v.message_id .." -> ".. tostring( (v.master and v.master.message_id) or 0) )
		
	end

	for n,t in pairs(threads) do
		local v=t[1]
		print(v.created.." : "..v.uid .." -> ".. tostring( #t )  )
	end

	local fname="cache/note/forum/"..group.name..".json"
	create_dir_for_file(fname)

	writefile(fname,json.encode({threads=threads}))


--[[
	for i,v in pairs(notes) do
	
		print(v.time.." : "..v.message_id .." -> ".. tostring( (v.master and v.master.message_id) or 0) )
		
	end
]]	

end



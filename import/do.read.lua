
exec("mkdir cache")

require("socket")
require("socket.http")

local sxml=require("wetgenes.simpxml")
local json=require("wetgenes.json")
local wetstring=require("wetgenes.string")

local ssplit=wetstring.str_split

local body, headers, code = socket.http.request("http://4lfa.com/archive.php")
put("Received "..#body.." bytes\n")

local doc=sxml.parse(body)

local main=sxml.class(doc,"alfa_arc_all")

local jsoncachename="cache/cache.json"

local cache=getcache(jsoncachename)

local putcache=function() putcache(jsoncachename,cache) end

cache.comics=cache.comics or {}

local comics=cache.comics

if main then
	put("found a list of pages\n")

	for i,v in ipairs(main) do

		if type(v)=="table" then

			if v.href then
				put(v.href.."\n")
				local t={href=v.href}
				comics[v.href]=comics[v.href] or t
			end

		end

	end

putcache()

	for n,t in pairs(comics) do

		if t.href and t.title and t.text and t.img and t.time then -- already got

		else -- go fetch again

			put("Fetching "..t.href.."\n")

			local body, headers, code = socket.http.request("http://4lfa.com"..t.href)
			put("Received "..#body.." bytes\n")
			local page=sxml.parse(body)

			local metas=sxml.descendents(page,"meta")
			local links=sxml.descendents(page,"link")

			for i,v in ipairs(metas) do

				if v.name=="time" then
					t.time=tonumber(v.content or 0) or 0
					put(v.name .. "\n" )
				end
				if v.name=="title" then
					t.title=v.content
					put(v.name .. "\n" )
				end
				if v.name=="description" then
					t.text=v.content
					put(v.name .. "\n" )
				end

			end
			for i,v in ipairs(links) do

				if v.rel=="image_src" then
					t.img=v.href
					put(v.rel .. "\n" )
				end

			end

			putcache()
		end

		if t.img then
			local a=ssplit("/",t.img)
			t.icon=t.img.."_"
			t.name=a[#a-0]
			t.group=a[#a-1]
		end
		if t.href then
			local a=ssplit("/",t.href)
			t.name=a[#a-0]
		end

		put("GROUP: " .. (t.group or "" ).. "\n" )
		put("NAME:  " .. (t.name or "" ).. "\n" )
		put("TIME:  " .. (t.time or "" ).. "\n" )
		put("IMAGE: " .. (t.img or "" ).. "\n" )
		put("TITLE: " .. (t.title or "" ).. "\n" )
		put("TEXT:  " .. #(t.text or "" ).. "\n" )
		put("\n" )

--break
	end


	for n,t in pairs(comics) do

		if t.group and t.name then




			local fname="cache/data/"..t.group.."."..t.name..".png"
			if not file_exists(fname) then
put("downloading "..fname.."\n")
				local body, headers, code = socket.http.request(t.img..".png")		
				if body then
					create_dir_for_file(fname)
					writefile(fname,body)
				end
			end

			local fname="cache/data/"..t.group.."."..t.name..".icon.png"
			if not file_exists(fname) then
put("downloading "..fname.."\n")
				local body, headers, code = socket.http.request(t.img.."_.png")			
				if body then
					create_dir_for_file(fname)
					writefile(fname,body)
				end
			end


			local fname="cache/waka/"..t.group.."/"..t.name

			put("UPDATE: "..fname.."\n" )

			create_dir_for_file(fname)
			
			local width=100
			local height=100

			local s=""

			s=s.."#group trim=ends\n\n"
			s=s..t.group.."\n\n"
			s=s.."#name trim=ends\n\n"
			s=s..t.name.."\n\n"
			s=s.."#title trim=ends\n\n"
			s=s..t.title.."\n\n"
			s=s.."#width trim=ends\n\n"
			s=s..width.."\n\n"
			s=s.."#height trim=ends\n\n"
			s=s..height.."\n\n"
			s=s.."#image trim=ends\n\n"
			s=s.."/data/"..t.group.."."..t.name..".png\n\n"
			s=s.."#icon trim=ends\n\n"
			s=s.."/data/"..t.group.."."..t.name..".icon.png\n\n"
			s=s.."#body\n"
			s=s..t.text.."\n"

			writefile(fname..".txt",s)
			
			
		end
	end

else
	put("no pages found\n")
end

--for i,v in ipairs(ts) do
--put( (v.class or "") .. "\n")
--end

--put(body)

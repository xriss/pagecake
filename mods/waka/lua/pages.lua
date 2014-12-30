-- copy all globals into locals, some locals are prefixed with a G to reduce name clashes
local coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,Gload,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require=coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,load,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require


local wet_html=require("wetgenes.html")

local sys=require("wetgenes.www.any.sys")

local json=require("wetgenes.json")
local dat=require("wetgenes.www.any.data")
local cache=require("wetgenes.www.any.cache")

local users=require("wetgenes.www.any.users")

local fetch=require("wetgenes.www.any.fetch")

local img=require("wetgenes.www.any.img")

local log=require("wetgenes.www.any.log").log -- grab the func from the package

local wet_string=require("wetgenes.string")
local str_split=wet_string.str_split
local serialize=wet_string.serialize

local wet_diff=require("wetgenes.diff")
local wet_waka=require("wetgenes.waka")


-- require all the module sub parts
local html=require("waka.html")
local edits=require("waka.edits")




--
-- Which can be overeiden in the global table opts
--



module("waka.pages")
local _M=require(...)

default_props=
{
	layer=0,
	group="",
}

default_cache=
{
--	tags={},
	text="",
}


function kind(srv)
	if not srv or not srv.flavour or srv.flavour=="waka" then return "waka.pages" end
	return srv.flavour..".waka.pages"
end

--------------------------------------------------------------------------------
--
-- check that entity has initial data and set any missing defaults
-- the second return value is false if this is not a valid entity
--
--------------------------------------------------------------------------------
function check(srv,ent)
	if (not ent) or (not ent.cache) then return nil,false end
	
	local ok=true

	local c=ent.cache
	
	if c.id then -- build group from path, we might need to list all pages in a group
		local aa=str_split("/",c.id,true)
		aa[#aa]=nil
		local group="/" -- default master group
		if aa[1] and aa[2] then group=table.concat(aa,"/") end
		c.group=group
	end
	
	if c.text=="" then -- change empty value only
		local title=c.id or ""
		title=string.gsub(title,"/"," ")
		title=string.gsub(title,"([^%w%s]*)","")
		
		c.text="#title\n"..title.."\n#body\n".."MISSING CONTENT\n"
	end
		
	return ent
end

function default_manifest(srv,ent)
--	ent.cache.text=""--"#title\n"..string.gsub(id,"/"," ").."\n#body\n".."MISSING CONTENT\n"
	ent.key.notsaved=true -- flag as not saved yet, will get cleared on put
	return false -- no actual change so dont bother saving
end

--------------------------------------------------------------------------------
--
-- change the text of this page, creating it if necesary
--
--------------------------------------------------------------------------------
function edit(srv,id,by)

	local f=function(srv,e)
		local c=e.cache
	
		local text=by.text or c.text
		local author=by.author or ""
		local note=by.note or ""
		
	
		c.last=c.edit -- also remember the last edit, which may be null
		
		local d={}
		c.edit=d -- remember what we just changed in edit, 
		
		d.from=e.props.updated -- old time stamp
		d.time=e.cache.updated -- new time stamp
		
--[[
		if c.text==text then
			d.diff={0}
		else
			d.diff={0,text} -- dumb change
		end		
]]		
-- this is too slow for app engine?
		d.diff=wet_diff.diff(c.text, text,"\n") -- what was changed in last edit
		
		if #d.diff==1 then return false end-- no changes, no need to write, so return a fail to stop the update
		
		d.author=author
		d.note=note
		
		c.text=text -- change the actual text
		
--		c.tags=by.tags or c.tags -- remember updated tags in an index
		
		return true
	end		
	local ret=set(srv,id,f) -- create/get and also update
	if ret then
		add_edit_log(srv,ret) -- also adjust edits history
	else
		log("WAKA PAGE EDIT FAIL:"..id)
	end
	return ret
end

--------------------------------------------------------------------------------
--
-- create a new edit entry in the history, the entity will know what has just changed
-- we check that the last edit also exists (there are many reasons why it may not)
-- if it does we store a delta if it doesnt we store a delta AND current full text
-- as such there are technical limits to page sizes that are less than normal google limits.
-- So probably best to keep pages less than 500k I'd say 256k is a good maximum string size
-- to aim for and big enough for an entire book to be stored in one page.
--
--------------------------------------------------------------------------------
function add_edit_log(srv,e,fulltext)
local c=e.cache

	local edit
	
	if c.last then -- find old edit
		local old=edits.find(srv,{page=e.cache.id,from=c.last.from,time=c.last.time})
		if not old then fulltext=true end -- mising last edit 
	else
		fulltext=true -- flag a full text dump
	end
	
	if c.edit then -- what to save
		edit=edits.create(srv)
		edit.cache.page=e.cache.id
		edit.cache.group=e.cache.group
		edit.cache.layer=e.cache.layer
		edit.cache.from=c.edit.from
		edit.cache.time=c.edit.time
		edit.cache.diff=c.edit.diff
		edit.cache.author=c.edit.author
		
		if fulltext then -- include full text
			edit.cache.text=c.text
		end
		
		edits.put(srv,edit)
	end
	
	return edit -- may be null or maybe the edit we just created
end

--------------------------------------------------------------------------------
--
-- list pages
--
--------------------------------------------------------------------------------
function list(srv,opts,t)
	opts=opts or {} -- stop opts from being nil
	
	t=t or dat -- use transaction?
	
	local r=t.query({
		kind=kind(srv),
		limit=opts.limit or 100,
		offset=opts.offset or 0,
			{"filter","layer","==",0},
			{"sort","updated","DESC"},
		})
		
	for i=1,#r.list do local v=r.list[i]
		dat.build_cache(v)
	end

	return r.list
end



--------------------------------------------------------------------------------
--
-- like get but with as much cache as we can use so ( no transactions available )
--
--------------------------------------------------------------------------------
function cache_get(srv,id)
	local key=cache_key(id)
	local ent=cache.get(srv,key)

	if type(ent)=="boolean" then return nil end -- if cache is set to false then there is nothing to get
	
	if not ent then -- otherwise read from database
		ent=get(srv,id,dat) -- stop recursion by passing in dat as the transaction
		cache.put(srv,key,ent or false,60*60) -- and save into cache for an hour
	end

	return (check(srv,ent))
end


--------------------------------------------------------------------------------
--
-- load the page and all of its parent pages then build refined chunks.
-- return all the chunks, with the refined chunks found in [0]
-- unless unrefined is set in the opts, the opts are also passed into refine_chunks
--
--------------------------------------------------------------------------------
function load(srv,id,opts)
	opts=opts or {}

	local pages={}
	local chunks
	local name=id
	
	pages[#pages+1]=wet_waka.text_to_chunks( manifest(srv,name).cache.text ) -- start with main page	
	if id~="/" then -- if asking for root then no need to look for anything else
		while string.find(name,"/") do -- whilst there are still / in the name	
			name=string.gsub(name,"/[^/]*$","") -- remove the tail from the string			
			if name~="" then -- skip last empty one
				if srv.subdomain then -- special subdomain access
					pages[#pages+1]=wet_waka.text_to_chunks( manifest(srv,"/.subdomain/"..srv.subdomain.."/"..name).cache.text )
				end
				pages[#pages+1]=wet_waka.text_to_chunks( manifest(srv,name).cache.text )
			end
		end
		if srv.subdomain then -- special subdomain access
			pages[#pages+1]=wet_waka.text_to_chunks( manifest(srv,"/.subdomain/"..srv.subdomain).cache.text )
		end
		pages[#pages+1]=wet_waka.text_to_chunks( manifest(srv,"/").cache.text ) -- finally always include root
	end
	
-- merge all pages
	for i=#pages,1,-1 do
		chunks=wet_waka.chunks_merge(chunks,pages[i])
	end
	
 -- build refined chunks
	if not opts.unrefined then
		chunks[0]=wet_waka.refine_chunks(srv,chunks,opts)
	end
	
	return chunks
end


dat.set_defs(_M) -- create basic data handling funcs

dat.setup_db(_M) -- make sure DB exists and is ready

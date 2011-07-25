
local json=require("wetgenes.json")
local lfs=require("lfs")

-----------------------------------------------------------------------------
--
-- replace {tags} in the string with data provided
-- allow sub table look up with a.b.c.d.etc notation
--
-----------------------------------------------------------------------------
function replace(a,d)

	if not d then return a end -- no lookups possible

-- lookup function

	local replace_lookup
	replace_lookup=function(a,d) -- look up a in table d

		local t=d[a]
		if t then
			return tostring(t) -- simple find, make sure we return a string
		end
	
		local a1,a2=string.find(a, "%.") -- try and split on first "."
		if not a1 then return nil end -- didnt find a dot so return nil
	
		a1=string.sub(a,1,a1-1) -- the bit before the .
		a2=string.sub(a,a2+1) -- the bit after the .
	
		local dd=d[a1] -- use the bit before the dot to find the sub table
	
		if type(dd)=="table" then -- check we got a table
			return replace_lookup(a2,dd) -- tail call this function
		end
	
		return nil -- couldnt find anything return nil
	end

-- perform replace on {strings}

	return (string.gsub( a , "{([%w%._%-]-)}" , function(a)

		return replace_lookup(a,d) or ("{"..a.."}")
	
	end )) -- note gsub is in brackets so we just get its *first* return value

end


-- print a string with optional replacements

put=function(a,d)
	io.write(replace(a,d))
end


--a json cache read/write should be reasonably fast

getcache=function(name)
	local fp=io.open(name,"r")
	local d
	if fp then
		d=fp:read("*all")
		fp:close()
	end
	local r={}
	if d then r=json.decode(d) or {} end
	return r
end

putcache=function(name,tab)
	local s=json.encode(tab)
	local fp=io.open(name,"w")
	fp:write(s)
	fp:close()
	return d
end


-- get the text contents of a file

readfile=function(name)
	local fp=io.open(name,"r")
	local d=fp:read("*all")
	fp:close()
	return d
end

file_exists=function(name)
	local fp=io.open(name,"r")
--print(fp)
	if fp then fp:close() return true end
	return false
end

writefile=function(name,data)
	local fp=io.open(name,"w")
	fp:write(data)
	fp:close()
end

copyfile=function(frm,too)
	local text=readfile(frm)
	writefile(too,text)
end


exec=function(cmdline)
	print(cmdline)
	os.execute(cmdline)
end

--
-- given a filename make sure that its containing directory exists
--
create_dir_for_file=function(n)
	local t={}
	for w in string.gmatch(n, "[^/]+") do t[#t+1]=w end
	local s=""
	t[#t]=nil -- remove the filename
	for i,v in ipairs(t) do
		s=s..v
		lfs.mkdir(s)
		s=s.."/"
	end
end


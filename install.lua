#!/usr/bin/env gamecake

local bake=require("wetgenes.bake")
local wpath=require("wetgenes.path")

local lfs=require("lfs")
local wstr=require("wetgenes.string")

	
	-- where we are building from
	bake.cd_root	=	wpath.parse( wpath.resolve( arg[0] ) ).dir
	-- where we are building from
	bake.cd_app		=	wpath.parse( wpath.resolve( bake.cd_root , "apps/wet/" ) ).dir
	-- where we are building to
	bake.cd_out		=	arg[1]  or wpath.parse( wpath.resolve( bake.cd_root , "../wwwgenes/ngx/" ) ).dir

-- we need this one
	lfs.mkdir(bake.cd_out)
-- and these
	lfs.mkdir(bake.cd_out.."/conf")
	lfs.mkdir(bake.cd_out.."/logs")
	lfs.mkdir(bake.cd_out.."/sqlite")


-- combine all possible lua files into one lua dir in the .ngx output dir

	local opts={basedir=bake.cd_root.."../gamecake/",dir="lua",filter=""}
	local r=bake.findfiles(opts)
	for i,v in ipairs(r.ret) do
		local fname=wpath.resolve( bake.cd_out , v )
		print(fname)
		bake.create_dir_for_file(fname)
		bake.copyfile(opts.basedir.."/"..v,fname)
	end


	local opts={basedir=bake.cd_root,dir="lua",filter=""}
	local r=bake.findfiles(opts)
	for i,v in ipairs(r.ret) do
		local fname=wpath.resolve( bake.cd_out , v )
		print(fname)
		bake.create_dir_for_file(fname)
		bake.copyfile(opts.basedir.."/"..v,fname)
	end
	
	
	
	local opts={basedir=bake.cd_app,dir="public",filter=""}
	local r=bake.findfiles(opts)
	for i,v in ipairs(r.ret) do
		local fname=wpath.resolve( bake.cd_out , v )
		print(fname)
		bake.create_dir_for_file(fname)
		bake.copyfile(opts.basedir.."/"..v,fname)
	end

	local opts={basedir=bake.cd_app,dir="lua",filter=""}
	local r=bake.findfiles(opts)
	for i,v in ipairs(r.ret) do
		local fname=wpath.resolve( bake.cd_out , v )
		print(fname)
		bake.create_dir_for_file(fname)
		bake.copyfile(opts.basedir.."/"..v,fname)
	end


-- now do the same with the modules datas

	local modnames={}
	for v in lfs.dir(bake.cd_root.."/mods") do
		local a=lfs.attributes(bake.cd_root.."/mods/"..v)
		if a.mode=="directory" then
			if v:sub(1,1)~="." then
				modnames[#modnames+1]=v
			end
		end
	end

	for i,n in ipairs(modnames) do
		for i,s in ipairs{"art","css","js"} do
			local opts={basedir=bake.cd_root.."/mods/"..n.."/"..s,dir="",filter=""}
			local r=bake.findfiles(opts)
			for i,v in ipairs(r.ret) do
				local fname=wpath.resolve( bake.cd_out , "public" , s , n , v )
				print(fname)
				bake.create_dir_for_file(fname)
				bake.copyfile(opts.basedir.."/"..v,fname)
			end
		end
		
		local opts={basedir=bake.cd_root.."/mods/"..n.."/lua",dir="",filter=""}
		local r=bake.findfiles(opts)
		for i,v in ipairs(r.ret) do
			local fname=wpath.resolve( bake.cd_out , "lua" , n , v )
			print(fname)
			bake.create_dir_for_file(fname)
			bake.copyfile(opts.basedir.."/"..v,fname)
		end
	end

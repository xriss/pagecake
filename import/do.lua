#!../bin/exe/lua

-- load config
dofile("config.lua")

dofile("funcs.lua")

config.args={...}

local cmd=config.args[1]
local form=config.args[2]

if cmd=="read" then

	if form=="4lfa" then
		dofile("do.read.4lfa.lua")
	elseif form=="fud" then
		dofile("do.read.fud.lua")
	elseif form=="waka" then
		dofile("do.read.waka.lua")
	elseif form=="data" then
		dofile("do.read.data.lua")
	elseif form=="note" then
		dofile("do.read.note.lua")
	end
	
elseif cmd=="write" then

	if form=="comic" then
		dofile("do.write.comic.lua")
	elseif form=="note" then
		dofile("do.write.note.lua")
	elseif form=="waka" then
		dofile("do.write.waka.lua")
	end
	
elseif cmd=="clear" then

	exec("rm cache -Rf")
else

	put([[
Please choose one of the following to perform

clear -- clear all data in the local cache do this at the start unless you want to merge sites
read -- read data from a site into the local cache
read 4lfa -- my comic data (obsolete)
read fud -- my forum data, uses a fud forum xml feed
write -- write data to a site from the local cache
write comic -- upload some comics
write note -- upload notes/comments
]])

end


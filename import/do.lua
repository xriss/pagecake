#!../bin/exe/lua

-- load config
dofile("config.lua")

dofile("funcs.lua")

config.args={...}

local cmd=config.args[1]

if cmd=="read" then

	dofile("do.read.lua")

elseif cmd=="write" then

	dofile("do.write.lua")

else

	put([[
Please choose one of the following to perform

read -- read data from a site into the local cache
write -- write data to a site from the local cache

]])

end


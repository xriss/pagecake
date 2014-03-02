#!../../../bin/exe/gamecake.x64

print(os.time())
math.randomseed( os.time() )

local wstr=require("wetgenes.string")

local p=require("lua.plots_data")

local d=p.get()

print(d.plot,d.title)



-- build or serve an nginx version of an app

local codepath=require("apps").default_paths() -- default search paths so things can easily be found
--if codepath then print("Using code found at : "..codepath.."lua") end

local bake_ngx=require("wetgenes.bake.ngx")



local tab={"release"}
tab.arg={...}

tab.cd_out="~/hg/www/ngx"

tab.ngx_user="wet"
--tab.ngx_user="kriss"

tab.ngx_listen="80"

--tab.ngx_debug=""
--tab.ngx_debug="debug"

bake_ngx.build(tab)


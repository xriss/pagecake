#!../../bin/dbg/lua

local apps=require("apps")
apps.setpaths(nil,{apps.find_bin()})


print("test sql data")

local wsql=require("wetgenes.www.sqlite")


local sql=require("sqlite")
local db=assert(sql.open(".ngx/sqlite/test.sqlite"))
print("sqltest")
wsql.set_pragmas(db)


if db:exec([[
	DROP TABLE IF EXISTS t;
]])~=sql.OK then print(db:errmsg()) end


--	CREATE TABLE IF NOT EXISTS t(x INTEGER PRIMARY KEY, y UNIQUE, z DEFAULT 10 );
--	ALTER TABLE t ADD COLUMN n INTEGER DEFAULT 5;

	wsql.set_info(db,"t",{
		{name="x",INTEGER=true,PRIMARY=true},
		{name="y",UNIQUE=true},
		{name="z",DEFAULT=11},
	})


if db:exec([[
	INSERT INTO t VALUES(NULL,2,3);
	INSERT INTO t VALUES(NULL,5,6);
	INSERT INTO t VALUES(NULL,7,7);
	INSERT INTO t VALUES(NULL,8,8);
]])~=sql.OK then print(db:errmsg()) end

	wsql.set_info(db,"t",{
		{name="x",INTEGER=true,PRIMARY=true},
		{name="y",UNIQUE=true},
		{name="z",DEFAULT=11},
		{name="n",DEFAULT=5},
	})


if db:exec([[
	SELECT * FROM t;
]],
	function(udata,cols,values,names)
		local t={}
		for i=1,cols do t[#t+1]=' ' t[#t+1]=names[i] t[#t+1]=' = ' t[#t+1]=values[i] end
		print(table.concat(t))
		return 0
	end,0)~=sql.OK then error(db:errmsg()) end

if db:exec([[
select sql from sqlite_master where name = 't';
]],
	function(udata,cols,values,names)
		local t={}
		for i=1,cols do t[#t+1]=' ' t[#t+1]=names[i] t[#t+1]=' = ' t[#t+1]=values[i] end
		print(table.concat(t))
		return 0
	end,0)~=sql.OK then error(db:errmsg()) end
	
	
	wsql.get_info(db,"t")




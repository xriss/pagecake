-- copy all globals into locals, some locals are prefixed with a G to reduce name clashes
local coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,Gload,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require=coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,load,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require

local json=require("wetgenes.json")

local dat=require("wetgenes.www.any.data")
local cache=require("wetgenes.www.any.cache")

local log=require("wetgenes.www.any.log").log -- grab the func from the package

local fetch=require("wetgenes.www.any.fetch")
local sys=require("wetgenes.www.any.sys")

local whtml=require("wetgenes.html")

local wstr=require("wetgenes.string")
local d_sess =require("dumid.sess")
local dl_users=require("dimeload.users")

--module
local M={ modname=(...) } ; package.loaded[M.modname]=M
function M.kind(srv) return "dimeload.bitcoin" end

M.default_props=
{
-- use transaction index as the id
	value=0,		-- how much in BTC*100000000
	dimes=0,		-- how much in dimes (exchange may vary overtime, so trust this cached value)
	hash="",		-- transaction hash 
	dumid="",		-- id of the user account who gets credited with the dimes
	block=0,		-- the block (height) this transaction is in
	addr="",		-- the bitcoin address we received btc at (custom address per user)
}

M.default_cache=
{
}

--------------------------------------------------------------------------------
--
-- check that entity has initial data and set any missing defaults
-- the second return value is false if this is not a valid entity
--
--------------------------------------------------------------------------------
function M.check(srv,ent)

	local ok=true
	local c=ent.cache
		
	return ent
end

--------------------------------------------------------------------------------
--
-- Load a list
--
--------------------------------------------------------------------------------
function M.list(srv,opts)
opts=opts or {}

	local list={}
	
	local q={
		kind=M.kind(srv),
		limit=opts.limit or 10,
		offset=0,
		}
	q[#q+1]={"sort","updated","DESC"}
	if opts.dumid then
		q[#q+1]={"filter","dumid","==",opts.dumid}
	end
		
	local ret=dat.query(q)
		
	for i=1,#ret.list do local v=ret.list[i]
		dat.build_cache(v)
	end

	return ret.list
end


--------------------------------------------------------------------------------
--
-- build a htlm list of payments
--
--------------------------------------------------------------------------------
function M.paylist(srv,opts)

local t={}
local l=M.list(srv,{dumid=opts.dumid,limit=100})
			
	if l[1] then

		t[#t+1]=[[
		<ul class="paylist">
]]
		for i,v in ipairs(l) do
			local c=v.cache
			t[#t+1]=wstr.replace([[
			<li lass="paylist_item" >Sent {amount} BTC , ({dimes}d) on {date} <a href="https://blockchain.info/tx/{payer}">(view)</a></li>
]],{
	amount=c.value/100000000,
	dimes=c.dimes,
	payer=c.hash,
	date=os.date("%c",c.created),
})
		end
		t[#t+1]=[[
		</ul>
]]
	end

	return table.concat(t,"")

end


-- create a custom bitcoin address for the viewing user to pay into
-- the addrress will be saved in dl_user, if we havealready made an addr
-- then that addr will be returned and no new on will be created
function M.addr(srv)

local sess,user=d_sess.get_viewer_session(srv)
local dluser if user then dluser=dl_users.manifest(srv,user.cache.id) end

	if not dluser then return nil end
	
	if dluser.cache.bitcoin and dluser.cache.bitcoin~="" then return dluser.cache.bitcoin end
	
	local hook=srv.url_base.."bitcoin/hook?dumid="..user.cache.id

	local cb=fetch.get( "https://blockchain.info/api/receive?method=create&address="..srv.opts("bitcoin","address")..
		"&shared=false&callback="..whtml.url_esc(hook) )
	
	if cb and cb.body then cb=json.decode(cb.body) else cb=nil end
	
	if cb and cb.input_address then
		
		local t=dl_users.set(srv,user.cache.id,function(srv,e) -- create or update
			local c=e.cache
			c.bitcoin=cb.input_address
			return true
		end)
--log(wstr.dump(t))		
		return t.cache.bitcoin
	end

end

function M.hook(srv)

local dimes=srv.opts("bitcoin","dimes") -- current conversion rate

local dluser
local addr

	if srv.gets.dumid then -- this is who the dimes are for
		dluser=dl_users.manifest(srv,srv.gets.dumid)
		if dluser and dluser.cache.bitcoin then
			addr=dluser.cache.bitcoin
		end
	end


	local t={}
	t.value=0

local main_addr=srv.opts("bitcoin","address")
--log(addr)
	if addr and srv.gets.transaction_hash then -- we are being told to checkout this transaction (ignore all other inputs)
	
		t.hash=whtml.url_esc(srv.gets.transaction_hash)
	
		local tx=fetch.get( "https://blockchain.info/rawtx/"..whtml.url_esc(srv.gets.transaction_hash) )
		if tx and tx.body then
			tx=json.decode(tx.body)

			local valin=0
			if tx and tx.inputs then
				for i,v in ipairs(tx.inputs) do
					if v.prev_out then
						if v.prev_out.addr==addr then -- incoming value from correct address
							valin=valin+v.prev_out.value
						end
					end
				end
			end

			local valout=0
			if tx and tx.out then
				for i,v in ipairs(tx.out) do
					if v.addr==main_addr then -- check it is comming to us
						valout=valout+v.value
					end
				end
			end
			
			if valin==valout then -- confirmed spend
				t.value=valout
			end
			
			t.block=tx.block_height
		end
		
		t.dimes=math.floor(dimes*t.value/100000000) -- convert to dimes

		t.index=tx and tx.tx_index

	end
	
-- check confirms, if we need to be extra sure of transaction, for now we let it ride
--[[
	local bc=fetch.get("http://blockchain.info/latestblock")
	if bc and bc.body then
		bc=json.decode(bc.body)
	end
	if bc and bc.height then -- compare to transaction height, the bigger the difference the more valid
log(wstr.dump(bc.height))
	end
]]

log(wstr.dump(t))

	if t and t.index and t.hash and t.dimes>0 and t.value then -- got some dimes, and a transaction hash+index so hand them out
	
		local id=t.index
		local it=M.get(srv,id) -- check if transaction is already used
		if it then srv.put("*ok*") return nil end -- can only use a transaction once
		
		local it=M.set(srv,id,function(srv,e) -- create or update
			local c=e.cache
	
			c.value=t.value
			c.dimes=t.dimes
			c.hash=t.hash
			c.dumid=dluser.cache.id
			c.block=t.block
			c.addr=addr
			
			return true
		end)

		srv.put("*ok*") -- all done, stop telling me about this transaction

		return it -- return the data we just logged, nil for no data and a bad payment
	end


	return nil
end

dat.set_defs(M) -- create basic data handling funcs

dat.setup_db(M) -- make sure DB exists and is ready








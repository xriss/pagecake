-- copy all globals into locals, some locals are prefixed with a G to reduce name clashes
local coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,Gload,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require=coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,load,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require

local sys=require("wetgenes.www.any.sys")
local wet_html=require("wetgenes.html")
local replace=wet_html.replace
local url_esc=wet_html.url_esc

local html=require("base.html")


--module
local M={ modname=(...) } ; package.loaded[M.modname]=M


setmetatable(M,{__index=html}) -- use a meta table to also return html base


function M.fill_cake(srv,refined)

	refined.cake=refined.cake or html.fill_cake(srv)
	local cake=refined.cake

	cake.note={}
	cake.note.embed_width=800
	cake.note.embed_height=600
	cake.note.head_ticks=""
	cake.note.tail_ticks=""
	cake.note.ticks=[[
<div class="wetnote_ticker"><!--{-cake.note.tick_items}--></div>
]]

-- need to also fill cake.note.tick_items with the result for instance from recent_refined(srv,50)

	cake.note.tick=[[
--><div class="wetnote_tick">
{it.age} ago <a class="wetnote_profile_link" href="/profile/{it.user_id}">{it.user_name}</a> commented on <a class="wetnote_page_link" href="{it.link}">{it.title}</a>
</div><!--
]]
	cake.note.js=[[
<script language="javascript" type="text/javascript">
	var doit=function(){
		$(".wetnote_comment_text a").autoembedlink({width:{cake.note.embed_width},height:{cake.note.embed_height}});
	};
	head.js(head.fs.jquery_js,head.fs.jquery_wet_js,function(){ $(doit); });
</script>
]]


	cake.note.main=[[
<div class="wetnote_main">
	<div class="wetnote_main2">
		<div class="wetnote_comments">
			{cake.note.post}
			{cake.note.posts_link}
			{cake.note.comments}
			{cake.note.posts_link}
		</div>
	</div>
	{cake.note.head_ticks}
	{cake.note.ticks}
	{cake.note.tail_ticks}
</div>
{cake.note.js}
]]

	cake.note.post_text="Say something nice"
	cake.note.reply_text="Reply"
	cake.note.view_thread_text="View thread."
	cake.note.view_all_posts_text="View all posts."
	
	cake.note.item_login=[[{it.viewer_none_flag}
<div class="wetnote_comment_form_div">
<a class="wetnote_reply_login" href="/dumid/login/?continue={it.url}">Click here to login if you wish to comment.</a>
</div>
]]

	cake.note.posts_title=[[Posts from {cake.note.url}]]
	cake.note.posts_body=[[<a class="wetnote_view_posts_page" href="{cake.note.url}">View {cake.note.url}</a><br/><br/>]]


	cake.note.posts_link_more=""
	
	cake.note.posts_link=[[
<div class="wetnote_comment_posts_div">
<a class="wetnote_view_posts" href="/note/posts{cake.note.url}?limit=-1">{cake.note.view_all_posts_text}</a>
{cake.note.posts_link_more}
</div>
]]

	cake.note.thread_title=[[A thread from {cake.note.url}]]
	cake.note.thread_body=[[<a class="wetnote_view_posts_page" href="{cake.note.url}">View {cake.note.url}</a><br/><br/>]]

	cake.note.thread_link=[[
<div class="wetnote_comment_thread_div">
<a class="wetnote_view_thread" href="/note/thread/{it.id}?limit=-1">{cake.note.view_thread_text}</a>
</div>
]]

	cake.note.item_link=[[
<div class="wetnote_comment_form_div">
<a class="wetnote_reply_link" href="{it.url}">{cake.note.reply_text}</a>
</div>
]]

	cake.note.item_upload=[[
<div class="wetnote_comment_form_image_div" ><span> Please choose an image! </span><input  class="wetnote_comment_form_image" type="file" name="filedata" /></div>
]]

	cake.note.item_anon=[[
<div class="wetnote_comment_form_anon_dic" ><input class="wetnote_comment_form_anon_check" type="checkbox" name="anon" value="anon" {it.checked}/><span>Post anonymously?</span></div>
]]

	cake.note.item_form=[[
<div class="wetnote_comment_form_div">
<a class="wetnote_reply_link" href="#" onclick="$(this).hide(0);$('#wetnote_comment_form_{it.idhash}').show(400);return false;" style="{it.action_style}">{cake.note.reply_text}</a>
<form class="wetnote_comment_form" name="wetnote_comment_form" id="wetnote_comment_form_{it.idhash}" action="" method="post" enctype="multipart/form-data" style="{it.form_style}">
<div class="wetnote_comment_icon" ><a class="wetnote_avatar_link" href="/profile/{it.viewer_id}"><img src="{it.viewer_avatar}" width="100" height="100" /></a></div>
<div class="wetnote_comment_form_div_cont">{-it.upload}{-it.anon}
<textarea class="wetnote_comment_form_text" name="wetnote_comment_text"></textarea>
<input name="wetnote_comment_id" type="hidden" value="{it.id}"></input>
<input class="wetnote_comment_post" name="wetnote_comment_submit" type="submit" value="{it.post_text}"></input>
</div>
</form>
</div>
]]

	cake.note.item_media=[[
<a class="wetnote_media_link" href="/data/{it.media}"><img src="/thumbcache/crop/{cake.note.embed_width}/{cake.note.embed_height}/data/{it..media}" class="wetnote_comment_img" /></a>
]]

	cake.note.item_note=[[
<div class="wetnote_comment_div" id="wetnote{it.idhash}" >
<div class="wetnote_comment_icon" ><a href="/profile/{it.user_id}"><img src="{it.avatar}" width="100" height="100" /></a></div>
<div class="wetnote_comment_head" > posted by <a href="/profile/{it.user_id}">{it.user_name}</a> on {it.time} ({it.age} ago)</div>
<div class="wetnote_comment_text" >{-it.media_div}{.it.html}</div>
<div class="wetnote_comment_tail" ></div>
{-it.reply}
</div>
]]

	cake.note.item_reply_show=[[
	<a onclick="$(this).hide(0);$('.wetnote_reply_hidden_{it.grouphash}').show(400);return false;">Show hidden replies.</a>
]]
	cake.note.item_reply=[[
<div class="wetnote_reply_hidden_{it.grouphash}" style="{it.style}">{cake.note.item_note}</div>
{it.showhide}
]]

	cake.note.item_thread=[[
<div class="wetnote_thread_div">
{cake.note.item_note}
<div class="wetnote_reply_div">
{cake.note.thread_link}
{-it.replies}
{-cake.note.item_form}{-cake.note.item_login}
</div>
</div>
]]

	return cake
end


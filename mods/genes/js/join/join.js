require=(function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);throw new Error("Cannot find module '"+o+"'")}var f=n[o]={exports:{}};t[o][0].call(f.exports,function(e){var n=t[o][1][e];return s(n?n:e)},f,f.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({"onm6mO":[function(require,module,exports){

var ls=function(a) { console.log(util.inspect(a,{depth:null})); }

exports.setup=function(opts){

	var join={opts:opts};

// parse query string
	join.qs={};
	var qs=window.location.href.slice(window.location.href.indexOf('?') + 1).split('&');
	for(var i = 0; i < qs.length; i++)
	{
		var q=qs[i].split("=");
		join.qs[ q[0] ]=decodeURIComponent(q[1]);
	}
	
	join.vars={};
	join.vars.session=q.session || $.cookie("fud_session");
	join.vars.token=q.token;

//	require('./join.html.js').setup(join);

/*

handle a dumid login to an external site
first we get the user to login (possibly already logged in)
then we ask the user if they want the external site to know their info
then we redirect back to the external site

*/
	join.userapi="http://api.wetgenes.com:1408/genes/user/";
//	join.userapi="http://host.local:1408/genes/user/";

	join.template=$("<div></div>");
		
	join.fill=function(){
		opts.div.empty().append( join.template.find(".wetjoin_main").clone() );

//		console.log(join.qs);
		if(join.qs.token)
		{
			join.vars.token=join.qs.token;
			join.page("token");
			$(".wetjoin_main .wetjoin_submit").click();
		}
		else
//		if(join.qs.dumid)
		{
			join.page("session");
			$(".wetjoin_main .wetjoin_submit").click();
//			join.page("dumid");
		}
//		else
//		{
//			join.page("login");
//		}

	};

	join.page=function(pagename){
		
		$(".wetjoin").removeClass().addClass("wetjoin wetjoin_page_"+pagename);
		
		join.vars.token=  $(".wetjoin_main .wetjoin_token").val()   || join.vars.token;
		join.vars.name=   $(".wetjoin_main .wetjoin_name" ).val()   || join.vars.name;
		join.vars.email=  $(".wetjoin_main .wetjoin_email").val()   || join.vars.email;
		join.vars.pass=   $(".wetjoin_main .wetjoin_pass" ).val()   || join.vars.pass;
		join.vars.session=$(".wetjoin_main .wetjoin_session").val() || join.vars.session;

		$(".wetjoin_main .wetjoin_page").empty().append( join.template.find(".wetjoin_page_"+pagename).clone() );

		$(".wetjoin_main .wetjoin_token"   ).val(join.vars.token);
		$(".wetjoin_main .wetjoin_name"    ).val(join.vars.name);
		$(".wetjoin_main .wetjoin_email"   ).val(join.vars.email);
		$(".wetjoin_main .wetjoin_pass"    ).val(join.vars.pass);
		$(".wetjoin_main .wetjoin_session" ).val(join.vars.session);
		
		$(".wetjoin_main .span_token").text(join.vars.token);
		$(".wetjoin_main .span_name" ).text(join.vars.name);
		$(".wetjoin_main .span_email").text(join.vars.email);

		if(join.qs.dumid)
		{
			$(".wetjoin_main .span_website").text(join.qs.dumid.split("/")[2] || join.qs.dumid);
		}

		join.bind();
		return false;
	};

	join.callback=function(cmd,dat){
//		console.log(cmd,dat);
		
		if(dat.error)
		{
			$(".wetjoin_main .wetjoin_error").text( dat.error );

			if(cmd=="session"){
				join.page("login");
			}

			return;
		}
		
		var cont=function(vars){
			
			var q=""
			
			for(n in vars)
			{
				q=q+"&"+n+"="+vars[n];
			}
			
			if(join.qs["dumid"])
			{
				join.page("dumid");
			}
			else
			if(join.qs["continue"])
			{
				if(join.qs["continue"].indexOf('?') === -1) { q="?"+q; }
				window.location.href=join.qs["continue"]+q;
			}
//			else
//			{
//				window.location.href="http://forum.wetgenes.com/?"+q;
//			}
		}
			

		if(cmd=="join"){
			join.page("join2");
		}
		else
		if(cmd=="login"){
			join.vars.session=dat.session;
			join.page("login2");
			$.cookie("fud_session",join.vars.session,{ expires: 7*7, path: '/' });
			cont({S:join.vars.session});
		}
		else
		if(cmd=="forgot"){
			join.page("forgot2");
		}
		else
		if(cmd=="session"){
			join.vars.name=dat.name; // remember name
			join.page("login2");
			cont({S:join.vars.session});
		}
		else
		if(cmd=="token"){
			if(dat.command=="update")
			{
				join.vars.name=dat.name || join.vars.name; // remember name
				join.vars.email=dat.email || join.vars.email; // remember name
				join.page("login");
			}
			else
			if(dat.command=="create")
			{
				join.vars.name=dat.name || join.vars.name; // remember name
				join.vars.email=dat.email || join.vars.email; // remember name
				join.page("login");
			}
		}
	};

	join.submit=function(cmd){
//		console.log(cmd);

		$(".wetjoin_main .wetjoin_error").text("");

		var token=$(".wetjoin_main .wetjoin_token").val();
		var name= $(".wetjoin_main .wetjoin_name" ).val();
		var email=$(".wetjoin_main .wetjoin_email").val();
		var pass= $(".wetjoin_main .wetjoin_pass" ).val();

		if(cmd=="join"){
			$.post( join.userapi+"create",{
				"name":name,"email":email,"pass":pass
			},function(a,b,c){return join.callback("join",a,b,c);},"json");
			return false;
		}
		else
		if(cmd=="login"){
			$('#form').submit();
			$.post( join.userapi+"login",{
				"name":name,"pass":pass
			},function(a,b,c){return join.callback("login",a,b,c);},"json");
			return true;
		}
		else
		if(cmd=="forgot"){
			$.post( join.userapi+"update",{
				"email":email,"pass":pass
			},function(a,b,c){return join.callback("forgot",a,b,c);},"json");
			return false;
		}
		else
		if(cmd=="token"){
			$.post( join.userapi+"token",{
				"token":token
			},function(a,b,c){return join.callback("token",a,b,c);},"json");
			return false;
		}
		else
		if(cmd=="session"){
			$.post( join.userapi+"session",{
				"session":(join.vars.session || "")
			},function(a,b,c){return join.callback("session",a,b,c);},"json");
			return false;
		}
	};
	
	join.dumid_confirm=function(confirm)
	{
		if(join.qs["dumid"])
		{
			if(confirm)
			{
				if(join.qs["dumid"].indexOf('?') === -1)
				{
					window.location.href=join.qs["dumid"]+"?confirm="+join.vars.session;
				}
				else
				{
					window.location.href=join.qs["dumid"]+"&confirm="+join.vars.session;
				}
			}
			else
			{
				window.location.href=join.qs["dumid"]+"&deny=1";
			}
		}
		else
		{
			join.page("login2");
		}
		return false;
	};

	join.bind=function(){
		$(".wetjoin_main .wetjoin_header_join"   ).off("click").on("click",function(){return join.page("join");});
		$(".wetjoin_main .wetjoin_header_login"  ).off("click").on("click",function(){return join.page("login");});
		$(".wetjoin_main .wetjoin_header_forgot" ).off("click").on("click",function(){return join.page("forgot");});

		$(".wetjoin_main .wetjoin_submit_login"  ).off("click").on("click",function(){return join.submit("login");});
		$(".wetjoin_main .wetjoin_submit_join"   ).off("click").on("click",function(){return join.submit("join");});
		$(".wetjoin_main .wetjoin_submit_forgot" ).off("click").on("click",function(){return join.submit("forgot");});
		$(".wetjoin_main .wetjoin_submit_token"  ).off("click").on("click",function(){return join.submit("token");});
		$(".wetjoin_main .wetjoin_submit_session").off("click").on("click",function(){return join.submit("session");});

		$(".wetjoin_main .wetjoin_confirm").off("click").on("click",function(){return join.dumid_confirm(true);});
		$(".wetjoin_main .wetjoin_deny"   ).off("click").on("click",function(){return join.dumid_confirm(false);});

		// enter in inputs will auto force a submit
		$(".wetjoin_main input").off("keypress").on("keypress",function(e){
			if(e.which == 13)
			{
				$(this).blur();
				$(".wetjoin_main .wetjoin_submit").click();
				return false;
			}
		});
	};
	

	join.template.load("template.html",join.fill);
	
	return join;

};

},{}],"./js/join.js":[function(require,module,exports){
module.exports=require('onm6mO');
},{}]},{},[])
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJzb3VyY2VzIjpbIi9ob21lL2tyaXNzL2hnL2pzL2pvaW4vbm9kZV9tb2R1bGVzL2Jyb3dzZXJpZnkvbm9kZV9tb2R1bGVzL2Jyb3dzZXItcGFjay9fcHJlbHVkZS5qcyIsIi9ob21lL2tyaXNzL2hnL2pzL2pvaW4vanMvam9pbi5qcyJdLCJuYW1lcyI6W10sIm1hcHBpbmdzIjoiQUFBQTtBQ0FBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBIiwiZmlsZSI6ImdlbmVyYXRlZC5qcyIsInNvdXJjZVJvb3QiOiIiLCJzb3VyY2VzQ29udGVudCI6WyIoZnVuY3Rpb24gZSh0LG4scil7ZnVuY3Rpb24gcyhvLHUpe2lmKCFuW29dKXtpZighdFtvXSl7dmFyIGE9dHlwZW9mIHJlcXVpcmU9PVwiZnVuY3Rpb25cIiYmcmVxdWlyZTtpZighdSYmYSlyZXR1cm4gYShvLCEwKTtpZihpKXJldHVybiBpKG8sITApO3Rocm93IG5ldyBFcnJvcihcIkNhbm5vdCBmaW5kIG1vZHVsZSAnXCIrbytcIidcIil9dmFyIGY9bltvXT17ZXhwb3J0czp7fX07dFtvXVswXS5jYWxsKGYuZXhwb3J0cyxmdW5jdGlvbihlKXt2YXIgbj10W29dWzFdW2VdO3JldHVybiBzKG4/bjplKX0sZixmLmV4cG9ydHMsZSx0LG4scil9cmV0dXJuIG5bb10uZXhwb3J0c312YXIgaT10eXBlb2YgcmVxdWlyZT09XCJmdW5jdGlvblwiJiZyZXF1aXJlO2Zvcih2YXIgbz0wO288ci5sZW5ndGg7bysrKXMocltvXSk7cmV0dXJuIHN9KSIsIlxudmFyIGxzPWZ1bmN0aW9uKGEpIHsgY29uc29sZS5sb2codXRpbC5pbnNwZWN0KGEse2RlcHRoOm51bGx9KSk7IH1cblxuZXhwb3J0cy5zZXR1cD1mdW5jdGlvbihvcHRzKXtcblxuXHR2YXIgam9pbj17b3B0czpvcHRzfTtcblxuLy8gcGFyc2UgcXVlcnkgc3RyaW5nXG5cdGpvaW4ucXM9e307XG5cdHZhciBxcz13aW5kb3cubG9jYXRpb24uaHJlZi5zbGljZSh3aW5kb3cubG9jYXRpb24uaHJlZi5pbmRleE9mKCc/JykgKyAxKS5zcGxpdCgnJicpO1xuXHRmb3IodmFyIGkgPSAwOyBpIDwgcXMubGVuZ3RoOyBpKyspXG5cdHtcblx0XHR2YXIgcT1xc1tpXS5zcGxpdChcIj1cIik7XG5cdFx0am9pbi5xc1sgcVswXSBdPWRlY29kZVVSSUNvbXBvbmVudChxWzFdKTtcblx0fVxuXHRcblx0am9pbi52YXJzPXt9O1xuXHRqb2luLnZhcnMuc2Vzc2lvbj1xLnNlc3Npb24gfHwgJC5jb29raWUoXCJmdWRfc2Vzc2lvblwiKTtcblx0am9pbi52YXJzLnRva2VuPXEudG9rZW47XG5cbi8vXHRyZXF1aXJlKCcuL2pvaW4uaHRtbC5qcycpLnNldHVwKGpvaW4pO1xuXG4vKlxuXG5oYW5kbGUgYSBkdW1pZCBsb2dpbiB0byBhbiBleHRlcm5hbCBzaXRlXG5maXJzdCB3ZSBnZXQgdGhlIHVzZXIgdG8gbG9naW4gKHBvc3NpYmx5IGFscmVhZHkgbG9nZ2VkIGluKVxudGhlbiB3ZSBhc2sgdGhlIHVzZXIgaWYgdGhleSB3YW50IHRoZSBleHRlcm5hbCBzaXRlIHRvIGtub3cgdGhlaXIgaW5mb1xudGhlbiB3ZSByZWRpcmVjdCBiYWNrIHRvIHRoZSBleHRlcm5hbCBzaXRlXG5cbiovXG5cdGpvaW4udXNlcmFwaT1cImh0dHA6Ly9hcGkud2V0Z2VuZXMuY29tOjE0MDgvZ2VuZXMvdXNlci9cIjtcbi8vXHRqb2luLnVzZXJhcGk9XCJodHRwOi8vaG9zdC5sb2NhbDoxNDA4L2dlbmVzL3VzZXIvXCI7XG5cblx0am9pbi50ZW1wbGF0ZT0kKFwiPGRpdj48L2Rpdj5cIik7XG5cdFx0XG5cdGpvaW4uZmlsbD1mdW5jdGlvbigpe1xuXHRcdG9wdHMuZGl2LmVtcHR5KCkuYXBwZW5kKCBqb2luLnRlbXBsYXRlLmZpbmQoXCIud2V0am9pbl9tYWluXCIpLmNsb25lKCkgKTtcblxuLy9cdFx0Y29uc29sZS5sb2coam9pbi5xcyk7XG5cdFx0aWYoam9pbi5xcy50b2tlbilcblx0XHR7XG5cdFx0XHRqb2luLnZhcnMudG9rZW49am9pbi5xcy50b2tlbjtcblx0XHRcdGpvaW4ucGFnZShcInRva2VuXCIpO1xuXHRcdFx0JChcIi53ZXRqb2luX21haW4gLndldGpvaW5fc3VibWl0XCIpLmNsaWNrKCk7XG5cdFx0fVxuXHRcdGVsc2Vcbi8vXHRcdGlmKGpvaW4ucXMuZHVtaWQpXG5cdFx0e1xuXHRcdFx0am9pbi5wYWdlKFwic2Vzc2lvblwiKTtcblx0XHRcdCQoXCIud2V0am9pbl9tYWluIC53ZXRqb2luX3N1Ym1pdFwiKS5jbGljaygpO1xuLy9cdFx0XHRqb2luLnBhZ2UoXCJkdW1pZFwiKTtcblx0XHR9XG4vL1x0XHRlbHNlXG4vL1x0XHR7XG4vL1x0XHRcdGpvaW4ucGFnZShcImxvZ2luXCIpO1xuLy9cdFx0fVxuXG5cdH07XG5cblx0am9pbi5wYWdlPWZ1bmN0aW9uKHBhZ2VuYW1lKXtcblx0XHRcblx0XHQkKFwiLndldGpvaW5cIikucmVtb3ZlQ2xhc3MoKS5hZGRDbGFzcyhcIndldGpvaW4gd2V0am9pbl9wYWdlX1wiK3BhZ2VuYW1lKTtcblx0XHRcblx0XHRqb2luLnZhcnMudG9rZW49ICAkKFwiLndldGpvaW5fbWFpbiAud2V0am9pbl90b2tlblwiKS52YWwoKSAgIHx8IGpvaW4udmFycy50b2tlbjtcblx0XHRqb2luLnZhcnMubmFtZT0gICAkKFwiLndldGpvaW5fbWFpbiAud2V0am9pbl9uYW1lXCIgKS52YWwoKSAgIHx8IGpvaW4udmFycy5uYW1lO1xuXHRcdGpvaW4udmFycy5lbWFpbD0gICQoXCIud2V0am9pbl9tYWluIC53ZXRqb2luX2VtYWlsXCIpLnZhbCgpICAgfHwgam9pbi52YXJzLmVtYWlsO1xuXHRcdGpvaW4udmFycy5wYXNzPSAgICQoXCIud2V0am9pbl9tYWluIC53ZXRqb2luX3Bhc3NcIiApLnZhbCgpICAgfHwgam9pbi52YXJzLnBhc3M7XG5cdFx0am9pbi52YXJzLnNlc3Npb249JChcIi53ZXRqb2luX21haW4gLndldGpvaW5fc2Vzc2lvblwiKS52YWwoKSB8fCBqb2luLnZhcnMuc2Vzc2lvbjtcblxuXHRcdCQoXCIud2V0am9pbl9tYWluIC53ZXRqb2luX3BhZ2VcIikuZW1wdHkoKS5hcHBlbmQoIGpvaW4udGVtcGxhdGUuZmluZChcIi53ZXRqb2luX3BhZ2VfXCIrcGFnZW5hbWUpLmNsb25lKCkgKTtcblxuXHRcdCQoXCIud2V0am9pbl9tYWluIC53ZXRqb2luX3Rva2VuXCIgICApLnZhbChqb2luLnZhcnMudG9rZW4pO1xuXHRcdCQoXCIud2V0am9pbl9tYWluIC53ZXRqb2luX25hbWVcIiAgICApLnZhbChqb2luLnZhcnMubmFtZSk7XG5cdFx0JChcIi53ZXRqb2luX21haW4gLndldGpvaW5fZW1haWxcIiAgICkudmFsKGpvaW4udmFycy5lbWFpbCk7XG5cdFx0JChcIi53ZXRqb2luX21haW4gLndldGpvaW5fcGFzc1wiICAgICkudmFsKGpvaW4udmFycy5wYXNzKTtcblx0XHQkKFwiLndldGpvaW5fbWFpbiAud2V0am9pbl9zZXNzaW9uXCIgKS52YWwoam9pbi52YXJzLnNlc3Npb24pO1xuXHRcdFxuXHRcdCQoXCIud2V0am9pbl9tYWluIC5zcGFuX3Rva2VuXCIpLnRleHQoam9pbi52YXJzLnRva2VuKTtcblx0XHQkKFwiLndldGpvaW5fbWFpbiAuc3Bhbl9uYW1lXCIgKS50ZXh0KGpvaW4udmFycy5uYW1lKTtcblx0XHQkKFwiLndldGpvaW5fbWFpbiAuc3Bhbl9lbWFpbFwiKS50ZXh0KGpvaW4udmFycy5lbWFpbCk7XG5cblx0XHRpZihqb2luLnFzLmR1bWlkKVxuXHRcdHtcblx0XHRcdCQoXCIud2V0am9pbl9tYWluIC5zcGFuX3dlYnNpdGVcIikudGV4dChqb2luLnFzLmR1bWlkLnNwbGl0KFwiL1wiKVsyXSB8fCBqb2luLnFzLmR1bWlkKTtcblx0XHR9XG5cblx0XHRqb2luLmJpbmQoKTtcblx0XHRyZXR1cm4gZmFsc2U7XG5cdH07XG5cblx0am9pbi5jYWxsYmFjaz1mdW5jdGlvbihjbWQsZGF0KXtcbi8vXHRcdGNvbnNvbGUubG9nKGNtZCxkYXQpO1xuXHRcdFxuXHRcdGlmKGRhdC5lcnJvcilcblx0XHR7XG5cdFx0XHQkKFwiLndldGpvaW5fbWFpbiAud2V0am9pbl9lcnJvclwiKS50ZXh0KCBkYXQuZXJyb3IgKTtcblxuXHRcdFx0aWYoY21kPT1cInNlc3Npb25cIil7XG5cdFx0XHRcdGpvaW4ucGFnZShcImxvZ2luXCIpO1xuXHRcdFx0fVxuXG5cdFx0XHRyZXR1cm47XG5cdFx0fVxuXHRcdFxuXHRcdHZhciBjb250PWZ1bmN0aW9uKHZhcnMpe1xuXHRcdFx0XG5cdFx0XHR2YXIgcT1cIlwiXG5cdFx0XHRcblx0XHRcdGZvcihuIGluIHZhcnMpXG5cdFx0XHR7XG5cdFx0XHRcdHE9cStcIiZcIituK1wiPVwiK3ZhcnNbbl07XG5cdFx0XHR9XG5cdFx0XHRcblx0XHRcdGlmKGpvaW4ucXNbXCJkdW1pZFwiXSlcblx0XHRcdHtcblx0XHRcdFx0am9pbi5wYWdlKFwiZHVtaWRcIik7XG5cdFx0XHR9XG5cdFx0XHRlbHNlXG5cdFx0XHRpZihqb2luLnFzW1wiY29udGludWVcIl0pXG5cdFx0XHR7XG5cdFx0XHRcdGlmKGpvaW4ucXNbXCJjb250aW51ZVwiXS5pbmRleE9mKCc/JykgPT09IC0xKSB7IHE9XCI/XCIrcTsgfVxuXHRcdFx0XHR3aW5kb3cubG9jYXRpb24uaHJlZj1qb2luLnFzW1wiY29udGludWVcIl0rcTtcblx0XHRcdH1cbi8vXHRcdFx0ZWxzZVxuLy9cdFx0XHR7XG4vL1x0XHRcdFx0d2luZG93LmxvY2F0aW9uLmhyZWY9XCJodHRwOi8vZm9ydW0ud2V0Z2VuZXMuY29tLz9cIitxO1xuLy9cdFx0XHR9XG5cdFx0fVxuXHRcdFx0XG5cblx0XHRpZihjbWQ9PVwiam9pblwiKXtcblx0XHRcdGpvaW4ucGFnZShcImpvaW4yXCIpO1xuXHRcdH1cblx0XHRlbHNlXG5cdFx0aWYoY21kPT1cImxvZ2luXCIpe1xuXHRcdFx0am9pbi52YXJzLnNlc3Npb249ZGF0LnNlc3Npb247XG5cdFx0XHRqb2luLnBhZ2UoXCJsb2dpbjJcIik7XG5cdFx0XHQkLmNvb2tpZShcImZ1ZF9zZXNzaW9uXCIsam9pbi52YXJzLnNlc3Npb24seyBleHBpcmVzOiA3KjcsIHBhdGg6ICcvJyB9KTtcblx0XHRcdGNvbnQoe1M6am9pbi52YXJzLnNlc3Npb259KTtcblx0XHR9XG5cdFx0ZWxzZVxuXHRcdGlmKGNtZD09XCJmb3Jnb3RcIil7XG5cdFx0XHRqb2luLnBhZ2UoXCJmb3Jnb3QyXCIpO1xuXHRcdH1cblx0XHRlbHNlXG5cdFx0aWYoY21kPT1cInNlc3Npb25cIil7XG5cdFx0XHRqb2luLnZhcnMubmFtZT1kYXQubmFtZTsgLy8gcmVtZW1iZXIgbmFtZVxuXHRcdFx0am9pbi5wYWdlKFwibG9naW4yXCIpO1xuXHRcdFx0Y29udCh7Uzpqb2luLnZhcnMuc2Vzc2lvbn0pO1xuXHRcdH1cblx0XHRlbHNlXG5cdFx0aWYoY21kPT1cInRva2VuXCIpe1xuXHRcdFx0aWYoZGF0LmNvbW1hbmQ9PVwidXBkYXRlXCIpXG5cdFx0XHR7XG5cdFx0XHRcdGpvaW4udmFycy5uYW1lPWRhdC5uYW1lIHx8IGpvaW4udmFycy5uYW1lOyAvLyByZW1lbWJlciBuYW1lXG5cdFx0XHRcdGpvaW4udmFycy5lbWFpbD1kYXQuZW1haWwgfHwgam9pbi52YXJzLmVtYWlsOyAvLyByZW1lbWJlciBuYW1lXG5cdFx0XHRcdGpvaW4ucGFnZShcImxvZ2luXCIpO1xuXHRcdFx0fVxuXHRcdFx0ZWxzZVxuXHRcdFx0aWYoZGF0LmNvbW1hbmQ9PVwiY3JlYXRlXCIpXG5cdFx0XHR7XG5cdFx0XHRcdGpvaW4udmFycy5uYW1lPWRhdC5uYW1lIHx8IGpvaW4udmFycy5uYW1lOyAvLyByZW1lbWJlciBuYW1lXG5cdFx0XHRcdGpvaW4udmFycy5lbWFpbD1kYXQuZW1haWwgfHwgam9pbi52YXJzLmVtYWlsOyAvLyByZW1lbWJlciBuYW1lXG5cdFx0XHRcdGpvaW4ucGFnZShcImxvZ2luXCIpO1xuXHRcdFx0fVxuXHRcdH1cblx0fTtcblxuXHRqb2luLnN1Ym1pdD1mdW5jdGlvbihjbWQpe1xuLy9cdFx0Y29uc29sZS5sb2coY21kKTtcblxuXHRcdCQoXCIud2V0am9pbl9tYWluIC53ZXRqb2luX2Vycm9yXCIpLnRleHQoXCJcIik7XG5cblx0XHR2YXIgdG9rZW49JChcIi53ZXRqb2luX21haW4gLndldGpvaW5fdG9rZW5cIikudmFsKCk7XG5cdFx0dmFyIG5hbWU9ICQoXCIud2V0am9pbl9tYWluIC53ZXRqb2luX25hbWVcIiApLnZhbCgpO1xuXHRcdHZhciBlbWFpbD0kKFwiLndldGpvaW5fbWFpbiAud2V0am9pbl9lbWFpbFwiKS52YWwoKTtcblx0XHR2YXIgcGFzcz0gJChcIi53ZXRqb2luX21haW4gLndldGpvaW5fcGFzc1wiICkudmFsKCk7XG5cblx0XHRpZihjbWQ9PVwiam9pblwiKXtcblx0XHRcdCQucG9zdCggam9pbi51c2VyYXBpK1wiY3JlYXRlXCIse1xuXHRcdFx0XHRcIm5hbWVcIjpuYW1lLFwiZW1haWxcIjplbWFpbCxcInBhc3NcIjpwYXNzXG5cdFx0XHR9LGZ1bmN0aW9uKGEsYixjKXtyZXR1cm4gam9pbi5jYWxsYmFjayhcImpvaW5cIixhLGIsYyk7fSxcImpzb25cIik7XG5cdFx0XHRyZXR1cm4gZmFsc2U7XG5cdFx0fVxuXHRcdGVsc2Vcblx0XHRpZihjbWQ9PVwibG9naW5cIil7XG5cdFx0XHQkKCcjZm9ybScpLnN1Ym1pdCgpO1xuXHRcdFx0JC5wb3N0KCBqb2luLnVzZXJhcGkrXCJsb2dpblwiLHtcblx0XHRcdFx0XCJuYW1lXCI6bmFtZSxcInBhc3NcIjpwYXNzXG5cdFx0XHR9LGZ1bmN0aW9uKGEsYixjKXtyZXR1cm4gam9pbi5jYWxsYmFjayhcImxvZ2luXCIsYSxiLGMpO30sXCJqc29uXCIpO1xuXHRcdFx0cmV0dXJuIHRydWU7XG5cdFx0fVxuXHRcdGVsc2Vcblx0XHRpZihjbWQ9PVwiZm9yZ290XCIpe1xuXHRcdFx0JC5wb3N0KCBqb2luLnVzZXJhcGkrXCJ1cGRhdGVcIix7XG5cdFx0XHRcdFwiZW1haWxcIjplbWFpbCxcInBhc3NcIjpwYXNzXG5cdFx0XHR9LGZ1bmN0aW9uKGEsYixjKXtyZXR1cm4gam9pbi5jYWxsYmFjayhcImZvcmdvdFwiLGEsYixjKTt9LFwianNvblwiKTtcblx0XHRcdHJldHVybiBmYWxzZTtcblx0XHR9XG5cdFx0ZWxzZVxuXHRcdGlmKGNtZD09XCJ0b2tlblwiKXtcblx0XHRcdCQucG9zdCggam9pbi51c2VyYXBpK1widG9rZW5cIix7XG5cdFx0XHRcdFwidG9rZW5cIjp0b2tlblxuXHRcdFx0fSxmdW5jdGlvbihhLGIsYyl7cmV0dXJuIGpvaW4uY2FsbGJhY2soXCJ0b2tlblwiLGEsYixjKTt9LFwianNvblwiKTtcblx0XHRcdHJldHVybiBmYWxzZTtcblx0XHR9XG5cdFx0ZWxzZVxuXHRcdGlmKGNtZD09XCJzZXNzaW9uXCIpe1xuXHRcdFx0JC5wb3N0KCBqb2luLnVzZXJhcGkrXCJzZXNzaW9uXCIse1xuXHRcdFx0XHRcInNlc3Npb25cIjooam9pbi52YXJzLnNlc3Npb24gfHwgXCJcIilcblx0XHRcdH0sZnVuY3Rpb24oYSxiLGMpe3JldHVybiBqb2luLmNhbGxiYWNrKFwic2Vzc2lvblwiLGEsYixjKTt9LFwianNvblwiKTtcblx0XHRcdHJldHVybiBmYWxzZTtcblx0XHR9XG5cdH07XG5cdFxuXHRqb2luLmR1bWlkX2NvbmZpcm09ZnVuY3Rpb24oY29uZmlybSlcblx0e1xuXHRcdGlmKGpvaW4ucXNbXCJkdW1pZFwiXSlcblx0XHR7XG5cdFx0XHRpZihjb25maXJtKVxuXHRcdFx0e1xuXHRcdFx0XHRpZihqb2luLnFzW1wiZHVtaWRcIl0uaW5kZXhPZignPycpID09PSAtMSlcblx0XHRcdFx0e1xuXHRcdFx0XHRcdHdpbmRvdy5sb2NhdGlvbi5ocmVmPWpvaW4ucXNbXCJkdW1pZFwiXStcIj9jb25maXJtPVwiK2pvaW4udmFycy5zZXNzaW9uO1xuXHRcdFx0XHR9XG5cdFx0XHRcdGVsc2Vcblx0XHRcdFx0e1xuXHRcdFx0XHRcdHdpbmRvdy5sb2NhdGlvbi5ocmVmPWpvaW4ucXNbXCJkdW1pZFwiXStcIiZjb25maXJtPVwiK2pvaW4udmFycy5zZXNzaW9uO1xuXHRcdFx0XHR9XG5cdFx0XHR9XG5cdFx0XHRlbHNlXG5cdFx0XHR7XG5cdFx0XHRcdHdpbmRvdy5sb2NhdGlvbi5ocmVmPWpvaW4ucXNbXCJkdW1pZFwiXStcIiZkZW55PTFcIjtcblx0XHRcdH1cblx0XHR9XG5cdFx0ZWxzZVxuXHRcdHtcblx0XHRcdGpvaW4ucGFnZShcImxvZ2luMlwiKTtcblx0XHR9XG5cdFx0cmV0dXJuIGZhbHNlO1xuXHR9O1xuXG5cdGpvaW4uYmluZD1mdW5jdGlvbigpe1xuXHRcdCQoXCIud2V0am9pbl9tYWluIC53ZXRqb2luX2hlYWRlcl9qb2luXCIgICApLm9mZihcImNsaWNrXCIpLm9uKFwiY2xpY2tcIixmdW5jdGlvbigpe3JldHVybiBqb2luLnBhZ2UoXCJqb2luXCIpO30pO1xuXHRcdCQoXCIud2V0am9pbl9tYWluIC53ZXRqb2luX2hlYWRlcl9sb2dpblwiICApLm9mZihcImNsaWNrXCIpLm9uKFwiY2xpY2tcIixmdW5jdGlvbigpe3JldHVybiBqb2luLnBhZ2UoXCJsb2dpblwiKTt9KTtcblx0XHQkKFwiLndldGpvaW5fbWFpbiAud2V0am9pbl9oZWFkZXJfZm9yZ290XCIgKS5vZmYoXCJjbGlja1wiKS5vbihcImNsaWNrXCIsZnVuY3Rpb24oKXtyZXR1cm4gam9pbi5wYWdlKFwiZm9yZ290XCIpO30pO1xuXG5cdFx0JChcIi53ZXRqb2luX21haW4gLndldGpvaW5fc3VibWl0X2xvZ2luXCIgICkub2ZmKFwiY2xpY2tcIikub24oXCJjbGlja1wiLGZ1bmN0aW9uKCl7cmV0dXJuIGpvaW4uc3VibWl0KFwibG9naW5cIik7fSk7XG5cdFx0JChcIi53ZXRqb2luX21haW4gLndldGpvaW5fc3VibWl0X2pvaW5cIiAgICkub2ZmKFwiY2xpY2tcIikub24oXCJjbGlja1wiLGZ1bmN0aW9uKCl7cmV0dXJuIGpvaW4uc3VibWl0KFwiam9pblwiKTt9KTtcblx0XHQkKFwiLndldGpvaW5fbWFpbiAud2V0am9pbl9zdWJtaXRfZm9yZ290XCIgKS5vZmYoXCJjbGlja1wiKS5vbihcImNsaWNrXCIsZnVuY3Rpb24oKXtyZXR1cm4gam9pbi5zdWJtaXQoXCJmb3Jnb3RcIik7fSk7XG5cdFx0JChcIi53ZXRqb2luX21haW4gLndldGpvaW5fc3VibWl0X3Rva2VuXCIgICkub2ZmKFwiY2xpY2tcIikub24oXCJjbGlja1wiLGZ1bmN0aW9uKCl7cmV0dXJuIGpvaW4uc3VibWl0KFwidG9rZW5cIik7fSk7XG5cdFx0JChcIi53ZXRqb2luX21haW4gLndldGpvaW5fc3VibWl0X3Nlc3Npb25cIikub2ZmKFwiY2xpY2tcIikub24oXCJjbGlja1wiLGZ1bmN0aW9uKCl7cmV0dXJuIGpvaW4uc3VibWl0KFwic2Vzc2lvblwiKTt9KTtcblxuXHRcdCQoXCIud2V0am9pbl9tYWluIC53ZXRqb2luX2NvbmZpcm1cIikub2ZmKFwiY2xpY2tcIikub24oXCJjbGlja1wiLGZ1bmN0aW9uKCl7cmV0dXJuIGpvaW4uZHVtaWRfY29uZmlybSh0cnVlKTt9KTtcblx0XHQkKFwiLndldGpvaW5fbWFpbiAud2V0am9pbl9kZW55XCIgICApLm9mZihcImNsaWNrXCIpLm9uKFwiY2xpY2tcIixmdW5jdGlvbigpe3JldHVybiBqb2luLmR1bWlkX2NvbmZpcm0oZmFsc2UpO30pO1xuXG5cdFx0Ly8gZW50ZXIgaW4gaW5wdXRzIHdpbGwgYXV0byBmb3JjZSBhIHN1Ym1pdFxuXHRcdCQoXCIud2V0am9pbl9tYWluIGlucHV0XCIpLm9mZihcImtleXByZXNzXCIpLm9uKFwia2V5cHJlc3NcIixmdW5jdGlvbihlKXtcblx0XHRcdGlmKGUud2hpY2ggPT0gMTMpXG5cdFx0XHR7XG5cdFx0XHRcdCQodGhpcykuYmx1cigpO1xuXHRcdFx0XHQkKFwiLndldGpvaW5fbWFpbiAud2V0am9pbl9zdWJtaXRcIikuY2xpY2soKTtcblx0XHRcdFx0cmV0dXJuIGZhbHNlO1xuXHRcdFx0fVxuXHRcdH0pO1xuXHR9O1xuXHRcblxuXHRqb2luLnRlbXBsYXRlLmxvYWQoXCJ0ZW1wbGF0ZS5odG1sXCIsam9pbi5maWxsKTtcblx0XG5cdHJldHVybiBqb2luO1xuXG59O1xuIl19

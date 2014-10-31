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
	join.vars.session=q.session || $.cookie("wet_session");
	join.vars.token=q.token;

//	require('./join.html.js').setup(join);

/*

handle a dumid login to an external site
first we get the user to login (possibly already logged in)
then we ask the user if they want the external site to know their info
then we redirect back to the external site

*/
	join.userapi="/genes/user/";
	join.userapi="http://host.local:1408/genes/user/";

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
			$.cookie("wet_session",join.vars.session,{ expires: 7*7, path: '/' });
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
				"name":name,"email":email,"pass":pass
			},function(a,b,c){return join.callback("login",a,b,c);},"json");
			return true;
		}
		else
		if(cmd=="forgot"){
			$.post( join.userapi+"update",{
				"name":name,"email":email,"pass":pass
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
				window.location.href=join.qs["dumid"]+"&confirm="+join.vars.session;
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
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJzb3VyY2VzIjpbIi9ob21lL2tyaXNzL2hnL2pzL2pvaW4vbm9kZV9tb2R1bGVzL2Jyb3dzZXJpZnkvbm9kZV9tb2R1bGVzL2Jyb3dzZXItcGFjay9fcHJlbHVkZS5qcyIsIi9ob21lL2tyaXNzL2hnL2pzL2pvaW4vanMvam9pbi5qcyJdLCJuYW1lcyI6W10sIm1hcHBpbmdzIjoiQUFBQTtBQ0FBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQSIsImZpbGUiOiJnZW5lcmF0ZWQuanMiLCJzb3VyY2VSb290IjoiIiwic291cmNlc0NvbnRlbnQiOlsiKGZ1bmN0aW9uIGUodCxuLHIpe2Z1bmN0aW9uIHMobyx1KXtpZighbltvXSl7aWYoIXRbb10pe3ZhciBhPXR5cGVvZiByZXF1aXJlPT1cImZ1bmN0aW9uXCImJnJlcXVpcmU7aWYoIXUmJmEpcmV0dXJuIGEobywhMCk7aWYoaSlyZXR1cm4gaShvLCEwKTt0aHJvdyBuZXcgRXJyb3IoXCJDYW5ub3QgZmluZCBtb2R1bGUgJ1wiK28rXCInXCIpfXZhciBmPW5bb109e2V4cG9ydHM6e319O3Rbb11bMF0uY2FsbChmLmV4cG9ydHMsZnVuY3Rpb24oZSl7dmFyIG49dFtvXVsxXVtlXTtyZXR1cm4gcyhuP246ZSl9LGYsZi5leHBvcnRzLGUsdCxuLHIpfXJldHVybiBuW29dLmV4cG9ydHN9dmFyIGk9dHlwZW9mIHJlcXVpcmU9PVwiZnVuY3Rpb25cIiYmcmVxdWlyZTtmb3IodmFyIG89MDtvPHIubGVuZ3RoO28rKylzKHJbb10pO3JldHVybiBzfSkiLCJcbnZhciBscz1mdW5jdGlvbihhKSB7IGNvbnNvbGUubG9nKHV0aWwuaW5zcGVjdChhLHtkZXB0aDpudWxsfSkpOyB9XG5cbmV4cG9ydHMuc2V0dXA9ZnVuY3Rpb24ob3B0cyl7XG5cblx0dmFyIGpvaW49e29wdHM6b3B0c307XG5cbi8vIHBhcnNlIHF1ZXJ5IHN0cmluZ1xuXHRqb2luLnFzPXt9O1xuXHR2YXIgcXM9d2luZG93LmxvY2F0aW9uLmhyZWYuc2xpY2Uod2luZG93LmxvY2F0aW9uLmhyZWYuaW5kZXhPZignPycpICsgMSkuc3BsaXQoJyYnKTtcblx0Zm9yKHZhciBpID0gMDsgaSA8IHFzLmxlbmd0aDsgaSsrKVxuXHR7XG5cdFx0dmFyIHE9cXNbaV0uc3BsaXQoXCI9XCIpO1xuXHRcdGpvaW4ucXNbIHFbMF0gXT1kZWNvZGVVUklDb21wb25lbnQocVsxXSk7XG5cdH1cblx0XG5cdGpvaW4udmFycz17fTtcblx0am9pbi52YXJzLnNlc3Npb249cS5zZXNzaW9uIHx8ICQuY29va2llKFwid2V0X3Nlc3Npb25cIik7XG5cdGpvaW4udmFycy50b2tlbj1xLnRva2VuO1xuXG4vL1x0cmVxdWlyZSgnLi9qb2luLmh0bWwuanMnKS5zZXR1cChqb2luKTtcblxuLypcblxuaGFuZGxlIGEgZHVtaWQgbG9naW4gdG8gYW4gZXh0ZXJuYWwgc2l0ZVxuZmlyc3Qgd2UgZ2V0IHRoZSB1c2VyIHRvIGxvZ2luIChwb3NzaWJseSBhbHJlYWR5IGxvZ2dlZCBpbilcbnRoZW4gd2UgYXNrIHRoZSB1c2VyIGlmIHRoZXkgd2FudCB0aGUgZXh0ZXJuYWwgc2l0ZSB0byBrbm93IHRoZWlyIGluZm9cbnRoZW4gd2UgcmVkaXJlY3QgYmFjayB0byB0aGUgZXh0ZXJuYWwgc2l0ZVxuXG4qL1xuXHRqb2luLnVzZXJhcGk9XCIvZ2VuZXMvdXNlci9cIjtcblx0am9pbi51c2VyYXBpPVwiaHR0cDovL2hvc3QubG9jYWw6MTQwOC9nZW5lcy91c2VyL1wiO1xuXG5cdGpvaW4udGVtcGxhdGU9JChcIjxkaXY+PC9kaXY+XCIpO1xuXHRcdFxuXHRqb2luLmZpbGw9ZnVuY3Rpb24oKXtcblx0XHRvcHRzLmRpdi5lbXB0eSgpLmFwcGVuZCggam9pbi50ZW1wbGF0ZS5maW5kKFwiLndldGpvaW5fbWFpblwiKS5jbG9uZSgpICk7XG5cbi8vXHRcdGNvbnNvbGUubG9nKGpvaW4ucXMpO1xuXHRcdGlmKGpvaW4ucXMudG9rZW4pXG5cdFx0e1xuXHRcdFx0am9pbi52YXJzLnRva2VuPWpvaW4ucXMudG9rZW47XG5cdFx0XHRqb2luLnBhZ2UoXCJ0b2tlblwiKTtcblx0XHRcdCQoXCIud2V0am9pbl9tYWluIC53ZXRqb2luX3N1Ym1pdFwiKS5jbGljaygpO1xuXHRcdH1cblx0XHRlbHNlXG4vL1x0XHRpZihqb2luLnFzLmR1bWlkKVxuXHRcdHtcblx0XHRcdGpvaW4ucGFnZShcInNlc3Npb25cIik7XG5cdFx0XHQkKFwiLndldGpvaW5fbWFpbiAud2V0am9pbl9zdWJtaXRcIikuY2xpY2soKTtcbi8vXHRcdFx0am9pbi5wYWdlKFwiZHVtaWRcIik7XG5cdFx0fVxuLy9cdFx0ZWxzZVxuLy9cdFx0e1xuLy9cdFx0XHRqb2luLnBhZ2UoXCJsb2dpblwiKTtcbi8vXHRcdH1cblxuXHR9O1xuXG5cdGpvaW4ucGFnZT1mdW5jdGlvbihwYWdlbmFtZSl7XG5cdFx0XG5cdFx0JChcIi53ZXRqb2luXCIpLnJlbW92ZUNsYXNzKCkuYWRkQ2xhc3MoXCJ3ZXRqb2luIHdldGpvaW5fcGFnZV9cIitwYWdlbmFtZSk7XG5cdFx0XG5cdFx0am9pbi52YXJzLnRva2VuPSAgJChcIi53ZXRqb2luX21haW4gLndldGpvaW5fdG9rZW5cIikudmFsKCkgICB8fCBqb2luLnZhcnMudG9rZW47XG5cdFx0am9pbi52YXJzLm5hbWU9ICAgJChcIi53ZXRqb2luX21haW4gLndldGpvaW5fbmFtZVwiICkudmFsKCkgICB8fCBqb2luLnZhcnMubmFtZTtcblx0XHRqb2luLnZhcnMuZW1haWw9ICAkKFwiLndldGpvaW5fbWFpbiAud2V0am9pbl9lbWFpbFwiKS52YWwoKSAgIHx8IGpvaW4udmFycy5lbWFpbDtcblx0XHRqb2luLnZhcnMucGFzcz0gICAkKFwiLndldGpvaW5fbWFpbiAud2V0am9pbl9wYXNzXCIgKS52YWwoKSAgIHx8IGpvaW4udmFycy5wYXNzO1xuXHRcdGpvaW4udmFycy5zZXNzaW9uPSQoXCIud2V0am9pbl9tYWluIC53ZXRqb2luX3Nlc3Npb25cIikudmFsKCkgfHwgam9pbi52YXJzLnNlc3Npb247XG5cblx0XHQkKFwiLndldGpvaW5fbWFpbiAud2V0am9pbl9wYWdlXCIpLmVtcHR5KCkuYXBwZW5kKCBqb2luLnRlbXBsYXRlLmZpbmQoXCIud2V0am9pbl9wYWdlX1wiK3BhZ2VuYW1lKS5jbG9uZSgpICk7XG5cblx0XHQkKFwiLndldGpvaW5fbWFpbiAud2V0am9pbl90b2tlblwiICAgKS52YWwoam9pbi52YXJzLnRva2VuKTtcblx0XHQkKFwiLndldGpvaW5fbWFpbiAud2V0am9pbl9uYW1lXCIgICAgKS52YWwoam9pbi52YXJzLm5hbWUpO1xuXHRcdCQoXCIud2V0am9pbl9tYWluIC53ZXRqb2luX2VtYWlsXCIgICApLnZhbChqb2luLnZhcnMuZW1haWwpO1xuXHRcdCQoXCIud2V0am9pbl9tYWluIC53ZXRqb2luX3Bhc3NcIiAgICApLnZhbChqb2luLnZhcnMucGFzcyk7XG5cdFx0JChcIi53ZXRqb2luX21haW4gLndldGpvaW5fc2Vzc2lvblwiICkudmFsKGpvaW4udmFycy5zZXNzaW9uKTtcblx0XHRcblx0XHQkKFwiLndldGpvaW5fbWFpbiAuc3Bhbl90b2tlblwiKS50ZXh0KGpvaW4udmFycy50b2tlbik7XG5cdFx0JChcIi53ZXRqb2luX21haW4gLnNwYW5fbmFtZVwiICkudGV4dChqb2luLnZhcnMubmFtZSk7XG5cdFx0JChcIi53ZXRqb2luX21haW4gLnNwYW5fZW1haWxcIikudGV4dChqb2luLnZhcnMuZW1haWwpO1xuXG5cdFx0aWYoam9pbi5xcy5kdW1pZClcblx0XHR7XG5cdFx0XHQkKFwiLndldGpvaW5fbWFpbiAuc3Bhbl93ZWJzaXRlXCIpLnRleHQoam9pbi5xcy5kdW1pZC5zcGxpdChcIi9cIilbMl0gfHwgam9pbi5xcy5kdW1pZCk7XG5cdFx0fVxuXG5cdFx0am9pbi5iaW5kKCk7XG5cdFx0cmV0dXJuIGZhbHNlO1xuXHR9O1xuXG5cdGpvaW4uY2FsbGJhY2s9ZnVuY3Rpb24oY21kLGRhdCl7XG4vL1x0XHRjb25zb2xlLmxvZyhjbWQsZGF0KTtcblx0XHRcblx0XHRpZihkYXQuZXJyb3IpXG5cdFx0e1xuXHRcdFx0JChcIi53ZXRqb2luX21haW4gLndldGpvaW5fZXJyb3JcIikudGV4dCggZGF0LmVycm9yICk7XG5cblx0XHRcdGlmKGNtZD09XCJzZXNzaW9uXCIpe1xuXHRcdFx0XHRqb2luLnBhZ2UoXCJsb2dpblwiKTtcblx0XHRcdH1cblxuXHRcdFx0cmV0dXJuO1xuXHRcdH1cblx0XHRcblx0XHR2YXIgY29udD1mdW5jdGlvbih2YXJzKXtcblx0XHRcdFxuXHRcdFx0dmFyIHE9XCJcIlxuXHRcdFx0Zm9yKG4gaW4gdmFycylcblx0XHRcdHtcblx0XHRcdFx0cT1xK1wiJlwiK24rXCI9XCIrdmFyc1tuXTtcblx0XHRcdH1cblx0XHRcdFxuXHRcdFx0aWYoam9pbi5xc1tcImR1bWlkXCJdKVxuXHRcdFx0e1xuXHRcdFx0XHRqb2luLnBhZ2UoXCJkdW1pZFwiKTtcblx0XHRcdH1cblx0XHRcdGVsc2Vcblx0XHRcdGlmKGpvaW4ucXNbXCJjb250aW51ZVwiXSlcblx0XHRcdHtcblx0XHRcdFx0d2luZG93LmxvY2F0aW9uLmhyZWY9am9pbi5xc1tcImNvbnRpbnVlXCJdK3E7XG5cdFx0XHR9XG4vL1x0XHRcdGVsc2Vcbi8vXHRcdFx0e1xuLy9cdFx0XHRcdHdpbmRvdy5sb2NhdGlvbi5ocmVmPVwiaHR0cDovL2ZvcnVtLndldGdlbmVzLmNvbS8/XCIrcTtcbi8vXHRcdFx0fVxuXHRcdH1cblx0XHRcdFxuXG5cdFx0aWYoY21kPT1cImpvaW5cIil7XG5cdFx0XHRqb2luLnBhZ2UoXCJqb2luMlwiKTtcblx0XHR9XG5cdFx0ZWxzZVxuXHRcdGlmKGNtZD09XCJsb2dpblwiKXtcblx0XHRcdGpvaW4udmFycy5zZXNzaW9uPWRhdC5zZXNzaW9uO1xuXHRcdFx0am9pbi5wYWdlKFwibG9naW4yXCIpO1xuXHRcdFx0JC5jb29raWUoXCJ3ZXRfc2Vzc2lvblwiLGpvaW4udmFycy5zZXNzaW9uLHsgZXhwaXJlczogNyo3LCBwYXRoOiAnLycgfSk7XG5cdFx0XHRjb250KHtTOmpvaW4udmFycy5zZXNzaW9ufSk7XG5cdFx0fVxuXHRcdGVsc2Vcblx0XHRpZihjbWQ9PVwiZm9yZ290XCIpe1xuXHRcdFx0am9pbi5wYWdlKFwiZm9yZ290MlwiKTtcblx0XHR9XG5cdFx0ZWxzZVxuXHRcdGlmKGNtZD09XCJzZXNzaW9uXCIpe1xuXHRcdFx0am9pbi52YXJzLm5hbWU9ZGF0Lm5hbWU7IC8vIHJlbWVtYmVyIG5hbWVcblx0XHRcdGpvaW4ucGFnZShcImxvZ2luMlwiKTtcblx0XHRcdGNvbnQoe1M6am9pbi52YXJzLnNlc3Npb259KTtcblx0XHR9XG5cdH07XG5cblx0am9pbi5zdWJtaXQ9ZnVuY3Rpb24oY21kKXtcbi8vXHRcdGNvbnNvbGUubG9nKGNtZCk7XG5cblx0XHQkKFwiLndldGpvaW5fbWFpbiAud2V0am9pbl9lcnJvclwiKS50ZXh0KFwiXCIpO1xuXG5cdFx0dmFyIHRva2VuPSQoXCIud2V0am9pbl9tYWluIC53ZXRqb2luX3Rva2VuXCIpLnZhbCgpO1xuXHRcdHZhciBuYW1lPSAkKFwiLndldGpvaW5fbWFpbiAud2V0am9pbl9uYW1lXCIgKS52YWwoKTtcblx0XHR2YXIgZW1haWw9JChcIi53ZXRqb2luX21haW4gLndldGpvaW5fZW1haWxcIikudmFsKCk7XG5cdFx0dmFyIHBhc3M9ICQoXCIud2V0am9pbl9tYWluIC53ZXRqb2luX3Bhc3NcIiApLnZhbCgpO1xuXG5cdFx0aWYoY21kPT1cImpvaW5cIil7XG5cdFx0XHQkLnBvc3QoIGpvaW4udXNlcmFwaStcImNyZWF0ZVwiLHtcblx0XHRcdFx0XCJuYW1lXCI6bmFtZSxcImVtYWlsXCI6ZW1haWwsXCJwYXNzXCI6cGFzc1xuXHRcdFx0fSxmdW5jdGlvbihhLGIsYyl7cmV0dXJuIGpvaW4uY2FsbGJhY2soXCJqb2luXCIsYSxiLGMpO30sXCJqc29uXCIpO1xuXHRcdFx0cmV0dXJuIGZhbHNlO1xuXHRcdH1cblx0XHRlbHNlXG5cdFx0aWYoY21kPT1cImxvZ2luXCIpe1xuXHRcdFx0JCgnI2Zvcm0nKS5zdWJtaXQoKTtcblx0XHRcdCQucG9zdCggam9pbi51c2VyYXBpK1wibG9naW5cIix7XG5cdFx0XHRcdFwibmFtZVwiOm5hbWUsXCJlbWFpbFwiOmVtYWlsLFwicGFzc1wiOnBhc3Ncblx0XHRcdH0sZnVuY3Rpb24oYSxiLGMpe3JldHVybiBqb2luLmNhbGxiYWNrKFwibG9naW5cIixhLGIsYyk7fSxcImpzb25cIik7XG5cdFx0XHRyZXR1cm4gdHJ1ZTtcblx0XHR9XG5cdFx0ZWxzZVxuXHRcdGlmKGNtZD09XCJmb3Jnb3RcIil7XG5cdFx0XHQkLnBvc3QoIGpvaW4udXNlcmFwaStcInVwZGF0ZVwiLHtcblx0XHRcdFx0XCJuYW1lXCI6bmFtZSxcImVtYWlsXCI6ZW1haWwsXCJwYXNzXCI6cGFzc1xuXHRcdFx0fSxmdW5jdGlvbihhLGIsYyl7cmV0dXJuIGpvaW4uY2FsbGJhY2soXCJmb3Jnb3RcIixhLGIsYyk7fSxcImpzb25cIik7XG5cdFx0XHRyZXR1cm4gZmFsc2U7XG5cdFx0fVxuXHRcdGVsc2Vcblx0XHRpZihjbWQ9PVwidG9rZW5cIil7XG5cdFx0XHQkLnBvc3QoIGpvaW4udXNlcmFwaStcInRva2VuXCIse1xuXHRcdFx0XHRcInRva2VuXCI6dG9rZW5cblx0XHRcdH0sZnVuY3Rpb24oYSxiLGMpe3JldHVybiBqb2luLmNhbGxiYWNrKFwidG9rZW5cIixhLGIsYyk7fSxcImpzb25cIik7XG5cdFx0XHRyZXR1cm4gZmFsc2U7XG5cdFx0fVxuXHRcdGVsc2Vcblx0XHRpZihjbWQ9PVwic2Vzc2lvblwiKXtcblx0XHRcdCQucG9zdCggam9pbi51c2VyYXBpK1wic2Vzc2lvblwiLHtcblx0XHRcdFx0XCJzZXNzaW9uXCI6KGpvaW4udmFycy5zZXNzaW9uIHx8IFwiXCIpXG5cdFx0XHR9LGZ1bmN0aW9uKGEsYixjKXtyZXR1cm4gam9pbi5jYWxsYmFjayhcInNlc3Npb25cIixhLGIsYyk7fSxcImpzb25cIik7XG5cdFx0XHRyZXR1cm4gZmFsc2U7XG5cdFx0fVxuXHR9O1xuXHRcblx0am9pbi5kdW1pZF9jb25maXJtPWZ1bmN0aW9uKGNvbmZpcm0pXG5cdHtcblx0XHRpZihqb2luLnFzW1wiZHVtaWRcIl0pXG5cdFx0e1xuXHRcdFx0aWYoY29uZmlybSlcblx0XHRcdHtcblx0XHRcdFx0d2luZG93LmxvY2F0aW9uLmhyZWY9am9pbi5xc1tcImR1bWlkXCJdK1wiJmNvbmZpcm09XCIram9pbi52YXJzLnNlc3Npb247XG5cdFx0XHR9XG5cdFx0XHRlbHNlXG5cdFx0XHR7XG5cdFx0XHRcdHdpbmRvdy5sb2NhdGlvbi5ocmVmPWpvaW4ucXNbXCJkdW1pZFwiXStcIiZkZW55PTFcIjtcblx0XHRcdH1cblx0XHR9XG5cdFx0ZWxzZVxuXHRcdHtcblx0XHRcdGpvaW4ucGFnZShcImxvZ2luMlwiKTtcblx0XHR9XG5cdFx0cmV0dXJuIGZhbHNlO1xuXHR9O1xuXG5cdGpvaW4uYmluZD1mdW5jdGlvbigpe1xuXHRcdCQoXCIud2V0am9pbl9tYWluIC53ZXRqb2luX2hlYWRlcl9qb2luXCIgICApLm9mZihcImNsaWNrXCIpLm9uKFwiY2xpY2tcIixmdW5jdGlvbigpe3JldHVybiBqb2luLnBhZ2UoXCJqb2luXCIpO30pO1xuXHRcdCQoXCIud2V0am9pbl9tYWluIC53ZXRqb2luX2hlYWRlcl9sb2dpblwiICApLm9mZihcImNsaWNrXCIpLm9uKFwiY2xpY2tcIixmdW5jdGlvbigpe3JldHVybiBqb2luLnBhZ2UoXCJsb2dpblwiKTt9KTtcblx0XHQkKFwiLndldGpvaW5fbWFpbiAud2V0am9pbl9oZWFkZXJfZm9yZ290XCIgKS5vZmYoXCJjbGlja1wiKS5vbihcImNsaWNrXCIsZnVuY3Rpb24oKXtyZXR1cm4gam9pbi5wYWdlKFwiZm9yZ290XCIpO30pO1xuXG5cdFx0JChcIi53ZXRqb2luX21haW4gLndldGpvaW5fc3VibWl0X2xvZ2luXCIgICkub2ZmKFwiY2xpY2tcIikub24oXCJjbGlja1wiLGZ1bmN0aW9uKCl7cmV0dXJuIGpvaW4uc3VibWl0KFwibG9naW5cIik7fSk7XG5cdFx0JChcIi53ZXRqb2luX21haW4gLndldGpvaW5fc3VibWl0X2pvaW5cIiAgICkub2ZmKFwiY2xpY2tcIikub24oXCJjbGlja1wiLGZ1bmN0aW9uKCl7cmV0dXJuIGpvaW4uc3VibWl0KFwiam9pblwiKTt9KTtcblx0XHQkKFwiLndldGpvaW5fbWFpbiAud2V0am9pbl9zdWJtaXRfZm9yZ290XCIgKS5vZmYoXCJjbGlja1wiKS5vbihcImNsaWNrXCIsZnVuY3Rpb24oKXtyZXR1cm4gam9pbi5zdWJtaXQoXCJmb3Jnb3RcIik7fSk7XG5cdFx0JChcIi53ZXRqb2luX21haW4gLndldGpvaW5fc3VibWl0X3Rva2VuXCIgICkub2ZmKFwiY2xpY2tcIikub24oXCJjbGlja1wiLGZ1bmN0aW9uKCl7cmV0dXJuIGpvaW4uc3VibWl0KFwidG9rZW5cIik7fSk7XG5cdFx0JChcIi53ZXRqb2luX21haW4gLndldGpvaW5fc3VibWl0X3Nlc3Npb25cIikub2ZmKFwiY2xpY2tcIikub24oXCJjbGlja1wiLGZ1bmN0aW9uKCl7cmV0dXJuIGpvaW4uc3VibWl0KFwic2Vzc2lvblwiKTt9KTtcblxuXHRcdCQoXCIud2V0am9pbl9tYWluIC53ZXRqb2luX2NvbmZpcm1cIikub2ZmKFwiY2xpY2tcIikub24oXCJjbGlja1wiLGZ1bmN0aW9uKCl7cmV0dXJuIGpvaW4uZHVtaWRfY29uZmlybSh0cnVlKTt9KTtcblx0XHQkKFwiLndldGpvaW5fbWFpbiAud2V0am9pbl9kZW55XCIgICApLm9mZihcImNsaWNrXCIpLm9uKFwiY2xpY2tcIixmdW5jdGlvbigpe3JldHVybiBqb2luLmR1bWlkX2NvbmZpcm0oZmFsc2UpO30pO1xuXG5cdFx0Ly8gZW50ZXIgaW4gaW5wdXRzIHdpbGwgYXV0byBmb3JjZSBhIHN1Ym1pdFxuXHRcdCQoXCIud2V0am9pbl9tYWluIGlucHV0XCIpLm9mZihcImtleXByZXNzXCIpLm9uKFwia2V5cHJlc3NcIixmdW5jdGlvbihlKXtcblx0XHRcdGlmKGUud2hpY2ggPT0gMTMpXG5cdFx0XHR7XG5cdFx0XHRcdCQodGhpcykuYmx1cigpO1xuXHRcdFx0XHQkKFwiLndldGpvaW5fbWFpbiAud2V0am9pbl9zdWJtaXRcIikuY2xpY2soKTtcblx0XHRcdFx0cmV0dXJuIGZhbHNlO1xuXHRcdFx0fVxuXHRcdH0pO1xuXHR9O1xuXHRcblxuXHRqb2luLnRlbXBsYXRlLmxvYWQoXCJ0ZW1wbGF0ZS5odG1sXCIsam9pbi5maWxsKTtcblx0XG5cdHJldHVybiBqb2luO1xuXG59O1xuIl19

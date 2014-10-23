require=(function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);throw new Error("Cannot find module '"+o+"'")}var f=n[o]={exports:{}};t[o][0].call(f.exports,function(e){var n=t[o][1][e];return s(n?n:e)},f,f.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({"onm6mO":[function(require,module,exports){

var ls=function(a) { console.log(util.inspect(a,{depth:null})); }

exports.setup=function(opts){

	var join={opts:opts};
	
	join.vars={}

//	require('./join.html.js').setup(join);

	join.userapi="http://host.local:1408/genes/user/";

	join.template=$("<div></div>");
		
	join.fill=function(){
		opts.div.empty().append( join.template.find(".wetjoin_main").clone() );
		join.page("login")
	};

	join.page=function(pagename){
		join.vars.name= $(".wetjoin_main .wetjoin_name" ).val() || join.vars.name;
		join.vars.email=$(".wetjoin_main .wetjoin_email").val() || join.vars.email;
		join.vars.pass= $(".wetjoin_main .wetjoin_pass" ).val() || join.vars.pass;

		$(".wetjoin_main .wetjoin_page").empty().append( join.template.find(".wetjoin_page_"+pagename).clone() );

		$(".wetjoin_main .wetjoin_name" ).val(join.vars.name);
		$(".wetjoin_main .wetjoin_email").val(join.vars.email);
		$(".wetjoin_main .wetjoin_pass" ).val(join.vars.pass);

		join.bind();
	};

	join.callback=function(cmd,dat){
		console.log(cmd,dat);
		
		if(dat.error)
		{
			$(".wetjoin_main .wetjoin_error").text( dat.error );
			return;
		}
			

		if(cmd=="join"){
			join.page("join2");
		}
		else
		if(cmd=="login"){
			join.page("login2");
		}
		else
		if(cmd=="forgot"){
			join.page("forgot2");
		}

	};

	join.submit=function(cmd){
		console.log(cmd);

		$(".wetjoin_main .wetjoin_error").text("");

		var name= $(".wetjoin_main .wetjoin_name" ).val();
		var email=$(".wetjoin_main .wetjoin_email").val();
		var pass= $(".wetjoin_main .wetjoin_pass" ).val();

		if(cmd=="join"){
			$.post( join.userapi+"create",{
				"name":name,"email":email,"pass":pass
			},function(a,b,c){return join.callback("join",a,b,c);},"json");
		}
		else
		if(cmd=="login"){
			$.post( join.userapi+"login",{
				"name":name,"email":email,"pass":pass
			},function(a,b,c){return join.callback("login",a,b,c);},"json");
		}
		else
		if(cmd=="forgot"){
			$.post( join.userapi+"update",{
				"name":name,"email":email,"pass":pass
			},function(a,b,c){return join.callback("forgot",a,b,c);},"json");
		}
	};

	join.bind=function(){
		$(".wetjoin_main .wetjoin_header_join"  ).off("click").on("click",function(){join.page("join");});
		$(".wetjoin_main .wetjoin_header_login" ).off("click").on("click",function(){join.page("login");});
		$(".wetjoin_main .wetjoin_header_forgot").off("click").on("click",function(){join.page("forgot");});

		$(".wetjoin_main .wetjoin_submit_login" ).off("click").on("click",function(){join.submit("login");});
		$(".wetjoin_main .wetjoin_submit_join"  ).off("click").on("click",function(){join.submit("join");});
		$(".wetjoin_main .wetjoin_submit_forgot").off("click").on("click",function(){join.submit("forgot");});

		// enter in inputs will auto force a submit
		$(".wetjoin_main input").off("keypress").on("keypress",function(e){
			if(e.which == 13)
			{
				$(this).blur();
				$(".wetjoin_main .wetjoin_submit").focus().click();
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
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJzb3VyY2VzIjpbIi9ob21lL2tyaXNzL2hnL2pzL2pvaW4vbm9kZV9tb2R1bGVzL2Jyb3dzZXJpZnkvbm9kZV9tb2R1bGVzL2Jyb3dzZXItcGFjay9fcHJlbHVkZS5qcyIsIi9ob21lL2tyaXNzL2hnL2pzL2pvaW4vanMvam9pbi5qcyJdLCJuYW1lcyI6W10sIm1hcHBpbmdzIjoiQUFBQTtBQ0FBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0EiLCJmaWxlIjoiZ2VuZXJhdGVkLmpzIiwic291cmNlUm9vdCI6IiIsInNvdXJjZXNDb250ZW50IjpbIihmdW5jdGlvbiBlKHQsbixyKXtmdW5jdGlvbiBzKG8sdSl7aWYoIW5bb10pe2lmKCF0W29dKXt2YXIgYT10eXBlb2YgcmVxdWlyZT09XCJmdW5jdGlvblwiJiZyZXF1aXJlO2lmKCF1JiZhKXJldHVybiBhKG8sITApO2lmKGkpcmV0dXJuIGkobywhMCk7dGhyb3cgbmV3IEVycm9yKFwiQ2Fubm90IGZpbmQgbW9kdWxlICdcIitvK1wiJ1wiKX12YXIgZj1uW29dPXtleHBvcnRzOnt9fTt0W29dWzBdLmNhbGwoZi5leHBvcnRzLGZ1bmN0aW9uKGUpe3ZhciBuPXRbb11bMV1bZV07cmV0dXJuIHMobj9uOmUpfSxmLGYuZXhwb3J0cyxlLHQsbixyKX1yZXR1cm4gbltvXS5leHBvcnRzfXZhciBpPXR5cGVvZiByZXF1aXJlPT1cImZ1bmN0aW9uXCImJnJlcXVpcmU7Zm9yKHZhciBvPTA7bzxyLmxlbmd0aDtvKyspcyhyW29dKTtyZXR1cm4gc30pIiwiXG52YXIgbHM9ZnVuY3Rpb24oYSkgeyBjb25zb2xlLmxvZyh1dGlsLmluc3BlY3QoYSx7ZGVwdGg6bnVsbH0pKTsgfVxuXG5leHBvcnRzLnNldHVwPWZ1bmN0aW9uKG9wdHMpe1xuXG5cdHZhciBqb2luPXtvcHRzOm9wdHN9O1xuXHRcblx0am9pbi52YXJzPXt9XG5cbi8vXHRyZXF1aXJlKCcuL2pvaW4uaHRtbC5qcycpLnNldHVwKGpvaW4pO1xuXG5cdGpvaW4udXNlcmFwaT1cImh0dHA6Ly9ob3N0LmxvY2FsOjE0MDgvZ2VuZXMvdXNlci9cIjtcblxuXHRqb2luLnRlbXBsYXRlPSQoXCI8ZGl2PjwvZGl2PlwiKTtcblx0XHRcblx0am9pbi5maWxsPWZ1bmN0aW9uKCl7XG5cdFx0b3B0cy5kaXYuZW1wdHkoKS5hcHBlbmQoIGpvaW4udGVtcGxhdGUuZmluZChcIi53ZXRqb2luX21haW5cIikuY2xvbmUoKSApO1xuXHRcdGpvaW4ucGFnZShcImxvZ2luXCIpXG5cdH07XG5cblx0am9pbi5wYWdlPWZ1bmN0aW9uKHBhZ2VuYW1lKXtcblx0XHRqb2luLnZhcnMubmFtZT0gJChcIi53ZXRqb2luX21haW4gLndldGpvaW5fbmFtZVwiICkudmFsKCkgfHwgam9pbi52YXJzLm5hbWU7XG5cdFx0am9pbi52YXJzLmVtYWlsPSQoXCIud2V0am9pbl9tYWluIC53ZXRqb2luX2VtYWlsXCIpLnZhbCgpIHx8IGpvaW4udmFycy5lbWFpbDtcblx0XHRqb2luLnZhcnMucGFzcz0gJChcIi53ZXRqb2luX21haW4gLndldGpvaW5fcGFzc1wiICkudmFsKCkgfHwgam9pbi52YXJzLnBhc3M7XG5cblx0XHQkKFwiLndldGpvaW5fbWFpbiAud2V0am9pbl9wYWdlXCIpLmVtcHR5KCkuYXBwZW5kKCBqb2luLnRlbXBsYXRlLmZpbmQoXCIud2V0am9pbl9wYWdlX1wiK3BhZ2VuYW1lKS5jbG9uZSgpICk7XG5cblx0XHQkKFwiLndldGpvaW5fbWFpbiAud2V0am9pbl9uYW1lXCIgKS52YWwoam9pbi52YXJzLm5hbWUpO1xuXHRcdCQoXCIud2V0am9pbl9tYWluIC53ZXRqb2luX2VtYWlsXCIpLnZhbChqb2luLnZhcnMuZW1haWwpO1xuXHRcdCQoXCIud2V0am9pbl9tYWluIC53ZXRqb2luX3Bhc3NcIiApLnZhbChqb2luLnZhcnMucGFzcyk7XG5cblx0XHRqb2luLmJpbmQoKTtcblx0fTtcblxuXHRqb2luLmNhbGxiYWNrPWZ1bmN0aW9uKGNtZCxkYXQpe1xuXHRcdGNvbnNvbGUubG9nKGNtZCxkYXQpO1xuXHRcdFxuXHRcdGlmKGRhdC5lcnJvcilcblx0XHR7XG5cdFx0XHQkKFwiLndldGpvaW5fbWFpbiAud2V0am9pbl9lcnJvclwiKS50ZXh0KCBkYXQuZXJyb3IgKTtcblx0XHRcdHJldHVybjtcblx0XHR9XG5cdFx0XHRcblxuXHRcdGlmKGNtZD09XCJqb2luXCIpe1xuXHRcdFx0am9pbi5wYWdlKFwiam9pbjJcIik7XG5cdFx0fVxuXHRcdGVsc2Vcblx0XHRpZihjbWQ9PVwibG9naW5cIil7XG5cdFx0XHRqb2luLnBhZ2UoXCJsb2dpbjJcIik7XG5cdFx0fVxuXHRcdGVsc2Vcblx0XHRpZihjbWQ9PVwiZm9yZ290XCIpe1xuXHRcdFx0am9pbi5wYWdlKFwiZm9yZ290MlwiKTtcblx0XHR9XG5cblx0fTtcblxuXHRqb2luLnN1Ym1pdD1mdW5jdGlvbihjbWQpe1xuXHRcdGNvbnNvbGUubG9nKGNtZCk7XG5cblx0XHQkKFwiLndldGpvaW5fbWFpbiAud2V0am9pbl9lcnJvclwiKS50ZXh0KFwiXCIpO1xuXG5cdFx0dmFyIG5hbWU9ICQoXCIud2V0am9pbl9tYWluIC53ZXRqb2luX25hbWVcIiApLnZhbCgpO1xuXHRcdHZhciBlbWFpbD0kKFwiLndldGpvaW5fbWFpbiAud2V0am9pbl9lbWFpbFwiKS52YWwoKTtcblx0XHR2YXIgcGFzcz0gJChcIi53ZXRqb2luX21haW4gLndldGpvaW5fcGFzc1wiICkudmFsKCk7XG5cblx0XHRpZihjbWQ9PVwiam9pblwiKXtcblx0XHRcdCQucG9zdCggam9pbi51c2VyYXBpK1wiY3JlYXRlXCIse1xuXHRcdFx0XHRcIm5hbWVcIjpuYW1lLFwiZW1haWxcIjplbWFpbCxcInBhc3NcIjpwYXNzXG5cdFx0XHR9LGZ1bmN0aW9uKGEsYixjKXtyZXR1cm4gam9pbi5jYWxsYmFjayhcImpvaW5cIixhLGIsYyk7fSxcImpzb25cIik7XG5cdFx0fVxuXHRcdGVsc2Vcblx0XHRpZihjbWQ9PVwibG9naW5cIil7XG5cdFx0XHQkLnBvc3QoIGpvaW4udXNlcmFwaStcImxvZ2luXCIse1xuXHRcdFx0XHRcIm5hbWVcIjpuYW1lLFwiZW1haWxcIjplbWFpbCxcInBhc3NcIjpwYXNzXG5cdFx0XHR9LGZ1bmN0aW9uKGEsYixjKXtyZXR1cm4gam9pbi5jYWxsYmFjayhcImxvZ2luXCIsYSxiLGMpO30sXCJqc29uXCIpO1xuXHRcdH1cblx0XHRlbHNlXG5cdFx0aWYoY21kPT1cImZvcmdvdFwiKXtcblx0XHRcdCQucG9zdCggam9pbi51c2VyYXBpK1widXBkYXRlXCIse1xuXHRcdFx0XHRcIm5hbWVcIjpuYW1lLFwiZW1haWxcIjplbWFpbCxcInBhc3NcIjpwYXNzXG5cdFx0XHR9LGZ1bmN0aW9uKGEsYixjKXtyZXR1cm4gam9pbi5jYWxsYmFjayhcImZvcmdvdFwiLGEsYixjKTt9LFwianNvblwiKTtcblx0XHR9XG5cdH07XG5cblx0am9pbi5iaW5kPWZ1bmN0aW9uKCl7XG5cdFx0JChcIi53ZXRqb2luX21haW4gLndldGpvaW5faGVhZGVyX2pvaW5cIiAgKS5vZmYoXCJjbGlja1wiKS5vbihcImNsaWNrXCIsZnVuY3Rpb24oKXtqb2luLnBhZ2UoXCJqb2luXCIpO30pO1xuXHRcdCQoXCIud2V0am9pbl9tYWluIC53ZXRqb2luX2hlYWRlcl9sb2dpblwiICkub2ZmKFwiY2xpY2tcIikub24oXCJjbGlja1wiLGZ1bmN0aW9uKCl7am9pbi5wYWdlKFwibG9naW5cIik7fSk7XG5cdFx0JChcIi53ZXRqb2luX21haW4gLndldGpvaW5faGVhZGVyX2ZvcmdvdFwiKS5vZmYoXCJjbGlja1wiKS5vbihcImNsaWNrXCIsZnVuY3Rpb24oKXtqb2luLnBhZ2UoXCJmb3Jnb3RcIik7fSk7XG5cblx0XHQkKFwiLndldGpvaW5fbWFpbiAud2V0am9pbl9zdWJtaXRfbG9naW5cIiApLm9mZihcImNsaWNrXCIpLm9uKFwiY2xpY2tcIixmdW5jdGlvbigpe2pvaW4uc3VibWl0KFwibG9naW5cIik7fSk7XG5cdFx0JChcIi53ZXRqb2luX21haW4gLndldGpvaW5fc3VibWl0X2pvaW5cIiAgKS5vZmYoXCJjbGlja1wiKS5vbihcImNsaWNrXCIsZnVuY3Rpb24oKXtqb2luLnN1Ym1pdChcImpvaW5cIik7fSk7XG5cdFx0JChcIi53ZXRqb2luX21haW4gLndldGpvaW5fc3VibWl0X2ZvcmdvdFwiKS5vZmYoXCJjbGlja1wiKS5vbihcImNsaWNrXCIsZnVuY3Rpb24oKXtqb2luLnN1Ym1pdChcImZvcmdvdFwiKTt9KTtcblxuXHRcdC8vIGVudGVyIGluIGlucHV0cyB3aWxsIGF1dG8gZm9yY2UgYSBzdWJtaXRcblx0XHQkKFwiLndldGpvaW5fbWFpbiBpbnB1dFwiKS5vZmYoXCJrZXlwcmVzc1wiKS5vbihcImtleXByZXNzXCIsZnVuY3Rpb24oZSl7XG5cdFx0XHRpZihlLndoaWNoID09IDEzKVxuXHRcdFx0e1xuXHRcdFx0XHQkKHRoaXMpLmJsdXIoKTtcblx0XHRcdFx0JChcIi53ZXRqb2luX21haW4gLndldGpvaW5fc3VibWl0XCIpLmZvY3VzKCkuY2xpY2soKTtcblx0XHRcdFx0cmV0dXJuIGZhbHNlO1xuXHRcdFx0fVxuXHRcdH0pO1xuXHR9O1xuXHRcblxuXHRqb2luLnRlbXBsYXRlLmxvYWQoXCJ0ZW1wbGF0ZS5odG1sXCIsam9pbi5maWxsKTtcblxuXHRyZXR1cm4gam9pbjtcblxufTtcbiJdfQ==

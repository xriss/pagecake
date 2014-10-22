require=(function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);throw new Error("Cannot find module '"+o+"'")}var f=n[o]={exports:{}};t[o][0].call(f.exports,function(e){var n=t[o][1][e];return s(n?n:e)},f,f.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({"onm6mO":[function(require,module,exports){

var ls=function(a) { console.log(util.inspect(a,{depth:null})); }

exports.setup=function(opts){

	var join={opts:opts};

//	require('./join.html.js').setup(join);

	join.template=$("<div></div>");
		
	join.fill=function(){
		opts.div.empty().append( join.template.find(".wetjoin_main").clone() );
		join.page("login")
	};

	join.page=function(pagename){
		$(".wetjoin_main .wetjoin_page").empty().append( join.template.find(".wetjoin_page_"+pagename).clone() );
		join.bind();
	};

	join.bind=function(){
		$(".wetjoin_main .wetjoin_header_join").off("click").on("click",function(){join.page("join");});
		$(".wetjoin_main .wetjoin_header_login").off("click").on("click",function(){join.page("login");});
		$(".wetjoin_main .wetjoin_header_forgot").off("click").on("click",function(){join.page("forgot");});
	};
	

	join.template.load("template.html",join.fill);

	return join;

};

},{}],"./js/join.js":[function(require,module,exports){
module.exports=require('onm6mO');
},{}]},{},[])
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJzb3VyY2VzIjpbIi9ob21lL2tyaXNzL2hnL2pzL2pvaW4vbm9kZV9tb2R1bGVzL2Jyb3dzZXJpZnkvbm9kZV9tb2R1bGVzL2Jyb3dzZXItcGFjay9fcHJlbHVkZS5qcyIsIi9ob21lL2tyaXNzL2hnL2pzL2pvaW4vanMvam9pbi5qcyJdLCJuYW1lcyI6W10sIm1hcHBpbmdzIjoiQUFBQTtBQ0FBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBIiwiZmlsZSI6ImdlbmVyYXRlZC5qcyIsInNvdXJjZVJvb3QiOiIiLCJzb3VyY2VzQ29udGVudCI6WyIoZnVuY3Rpb24gZSh0LG4scil7ZnVuY3Rpb24gcyhvLHUpe2lmKCFuW29dKXtpZighdFtvXSl7dmFyIGE9dHlwZW9mIHJlcXVpcmU9PVwiZnVuY3Rpb25cIiYmcmVxdWlyZTtpZighdSYmYSlyZXR1cm4gYShvLCEwKTtpZihpKXJldHVybiBpKG8sITApO3Rocm93IG5ldyBFcnJvcihcIkNhbm5vdCBmaW5kIG1vZHVsZSAnXCIrbytcIidcIil9dmFyIGY9bltvXT17ZXhwb3J0czp7fX07dFtvXVswXS5jYWxsKGYuZXhwb3J0cyxmdW5jdGlvbihlKXt2YXIgbj10W29dWzFdW2VdO3JldHVybiBzKG4/bjplKX0sZixmLmV4cG9ydHMsZSx0LG4scil9cmV0dXJuIG5bb10uZXhwb3J0c312YXIgaT10eXBlb2YgcmVxdWlyZT09XCJmdW5jdGlvblwiJiZyZXF1aXJlO2Zvcih2YXIgbz0wO288ci5sZW5ndGg7bysrKXMocltvXSk7cmV0dXJuIHN9KSIsIlxudmFyIGxzPWZ1bmN0aW9uKGEpIHsgY29uc29sZS5sb2codXRpbC5pbnNwZWN0KGEse2RlcHRoOm51bGx9KSk7IH1cblxuZXhwb3J0cy5zZXR1cD1mdW5jdGlvbihvcHRzKXtcblxuXHR2YXIgam9pbj17b3B0czpvcHRzfTtcblxuLy9cdHJlcXVpcmUoJy4vam9pbi5odG1sLmpzJykuc2V0dXAoam9pbik7XG5cblx0am9pbi50ZW1wbGF0ZT0kKFwiPGRpdj48L2Rpdj5cIik7XG5cdFx0XG5cdGpvaW4uZmlsbD1mdW5jdGlvbigpe1xuXHRcdG9wdHMuZGl2LmVtcHR5KCkuYXBwZW5kKCBqb2luLnRlbXBsYXRlLmZpbmQoXCIud2V0am9pbl9tYWluXCIpLmNsb25lKCkgKTtcblx0XHRqb2luLnBhZ2UoXCJsb2dpblwiKVxuXHR9O1xuXG5cdGpvaW4ucGFnZT1mdW5jdGlvbihwYWdlbmFtZSl7XG5cdFx0JChcIi53ZXRqb2luX21haW4gLndldGpvaW5fcGFnZVwiKS5lbXB0eSgpLmFwcGVuZCggam9pbi50ZW1wbGF0ZS5maW5kKFwiLndldGpvaW5fcGFnZV9cIitwYWdlbmFtZSkuY2xvbmUoKSApO1xuXHRcdGpvaW4uYmluZCgpO1xuXHR9O1xuXG5cdGpvaW4uYmluZD1mdW5jdGlvbigpe1xuXHRcdCQoXCIud2V0am9pbl9tYWluIC53ZXRqb2luX2hlYWRlcl9qb2luXCIpLm9mZihcImNsaWNrXCIpLm9uKFwiY2xpY2tcIixmdW5jdGlvbigpe2pvaW4ucGFnZShcImpvaW5cIik7fSk7XG5cdFx0JChcIi53ZXRqb2luX21haW4gLndldGpvaW5faGVhZGVyX2xvZ2luXCIpLm9mZihcImNsaWNrXCIpLm9uKFwiY2xpY2tcIixmdW5jdGlvbigpe2pvaW4ucGFnZShcImxvZ2luXCIpO30pO1xuXHRcdCQoXCIud2V0am9pbl9tYWluIC53ZXRqb2luX2hlYWRlcl9mb3Jnb3RcIikub2ZmKFwiY2xpY2tcIikub24oXCJjbGlja1wiLGZ1bmN0aW9uKCl7am9pbi5wYWdlKFwiZm9yZ290XCIpO30pO1xuXHR9O1xuXHRcblxuXHRqb2luLnRlbXBsYXRlLmxvYWQoXCJ0ZW1wbGF0ZS5odG1sXCIsam9pbi5maWxsKTtcblxuXHRyZXR1cm4gam9pbjtcblxufTtcbiJdfQ==

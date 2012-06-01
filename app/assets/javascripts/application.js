// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
// WARNING: THE FIRST BLANK LINE MARKS THE END OF WHAT'S TO BE PROCESSED, ANY BLANK LINE SHOULD
// GO AFTER THE REQUIRES BELOW.
//
//= require jquery
//= require jquery_ujs
//= require twitter/bootstrap
//= require_tree .

$(function(){
	$('#nav_update').hover(
		function(){
			$('#nav_update .icon-time').addClass('icon-refresh')
		},
		function(){
			$('#nav_update .icon-time').removeClass('icon-refresh')
		}
	);
	
	
	reload_page = function(){
		$('#nav_update .icon-time').addClass('icon-refresh')
		window.location.reload();
	};
	var interval = 300
	var timeleft = interval
	
	update_countdown = function(){
		if(timeleft >= 0){
			minutes = Math.floor(timeleft/60);
			seconds = timeleft % 60;
			if (seconds < 10) {
				seconds = '0' + seconds
			}
			$('#countdown').html(minutes + ':' + seconds)
			setTimeout('update_countdown()','1000');
		}
		timeleft = timeleft - 1
	};
	
	update_countdown();
	setTimeout('reload_page()',interval*1000);
	
	
		
});

/*
* #000000book javascript
* Jamie Wilkinson <http://jamiedubs.com>
* (cc) Free Art & Technology Lab 
*/ 

$(document).ready(function(){

  // Flashes
  $('#flash-error, #flash-notice, #flash-warning').slideToggle('slow');
  setTimeout(function(){
    $('#flash-error, #flash-notice, #flash-warning').slideToggle('slow');
  }, 2500);
  
  // Zebrafy table rows
  $("tr:even").css("background-color", "#000");
  $("tr:odd").css("background-color", "#111");
  
  // Ghetto tabs
	var tabContainers = $('div.tabs > div');
	tabContainers.hide().filter(':first').show();	
	$('div.tabs ul.tab_navigation a').click(function (){
		tabContainers.hide();
		tabContainers.filter(this.hash).show();
		$('div.tabs ul.tab_navigation a').removeClass('selected');
		$(this).addClass('selected');
		return false;
	}).filter(':first').click();
	
	// Select ghettotab based on URL anchor; e.g. #vanderplayer
	// FIXME: issue right now with #vanderplayer jumping you to #vanderplayer as well as being the id... no easy way to override :\
	// relevant StackOverflow thread... http://stackoverflow.com/questions/1384500/activate-url-anchor-but-dont-scroll-to-it
	$('div.tabs ul.tab_navigation li a').each(function(){ 
	  var pattern = $(this).attr('href'); 
	  if(window.location.href.match(pattern)) { $(this).click(); }
	  scroll(0,0); // Re-center the page
	});  
  
});
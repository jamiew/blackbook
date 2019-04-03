/*
* #000000book javascript
* Jamie Wilkinson <http://jamiedubs.com>
* (cc) Free Art & Technology Lab
*/

//= require jquery
//= require jquery_ujs
//= require jquery.form

$(document).ready(function(){

  // Flashes
  $('#flash-error, #flash-notice, #flash-warning').slideToggle('slow');
  setTimeout(function(){
    $('#flash-error, #flash-notice, #flash-warning').slideToggle('slow');
  }, 2500);

  // Zebrafy table rows
  $("tr:even").css("background-color", "#000");
  $("tr:odd").css("background-color", "#111");

  // Formerly tabs - now a slider control
  var tabContainers = $('div.tabs > div');
  $('div.tabs ul.tab_navigation a').click(function (){
    $('div.tabs ul.tab_navigation a.selected').removeClass('selected');
    $(this).addClass('selected');

    var target = $(this).attr('href');
    console.log(target);
    var top = $(target).offset().top-100;
		$('html, body').animate({scrollTop:top}, 500);;
		return false;
  });

  // Select ghettotab based on URL anchor; e.g. #vanderplayer
  // This can be quirky due to the anchor name = element name
  // See: http://stackoverflow.com/questions/1384500/activate-url-anchor-but-dont-scroll-to-it
  $('div.tabs ul.tab_navigation li a').each(function(){
    var pattern = $(this).attr('href');
    if(window.location.href.match(pattern)) { $(this).click(); }
    scroll(0,0); // Re-center the page
  });

});

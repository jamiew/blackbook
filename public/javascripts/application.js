//
// Blackbook javascript
// 

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
	
	$('div.tabs ul.tab_navigation a').click(function () {
		tabContainers.hide();
		tabContainers.filter(this.hash).show();
		$('div.tabs ul.tab_navigation a').removeClass('selected');
		$(this).addClass('selected');
		return false;
	}).filter(':first').click();
  
  
});
$(function() {});

var PNB = function() {
  return {
    formFocusFirst: function(form) {
      $('#' + form + ' input:visible:enabled:first').focus();
    },

    updateSortables: function(parent) {
      var elems = $(parent + ' ul li .position'), i = 1;
      elems.each(function() {
        this.value = i++;
      });
    },

    sizeTehToolbars: function() {
      $('.textile-toolbar').each(function() {
        box_id = this.id.replace('textile-toolbar-', '');
        $(this).css('width', $('#' + box_id).css('width'));
      });
    },

    load_gat: function(code) {
      if (code) {
        var host = (("https:" == document.location.protocol) ? "https://ssl." : "http://www.");
        jQuery.getScript(host + "google-analytics.com/ga.js", function(){
          var tracker = _gat._getTracker(code);
          tracker._initData();
          tracker._trackPageview();
        });
      }
    }
  };
}();


$(document).ready(function(){

  // flashing
  $('#flash-error, #flash-notice, #flash-warning').slideToggle('slow');
  setTimeout(function(){
    $('#flash-error, #flash-notice, #flash-warning').slideToggle('slow');
  }, 2500);
  
  // table stylez
  // $("div:odd").css("background-color", "#F4F4F8");
  // $("div:even").css("background-color", "#EFF1F1");

  //for table row
  $("tr:even").css("background-color", "#000");
  $("tr:odd").css("background-color", "#111");
  
});
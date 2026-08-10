/*
* #000000book javascript
* Jamie Wilkinson <http://jamiedubs.com>
* (cc) Free Art & Technology Lab
*/

function selectTab(link) {
  document.querySelectorAll('div.tabs ul.tab_navigation a.selected').forEach(function (selected) {
    selected.classList.remove('selected');
  });
  link.classList.add('selected');

  var target = document.querySelector(link.getAttribute('href'));
  if (!target) return;
  window.scrollTo({ top: target.getBoundingClientRect().top + window.scrollY - 100, behavior: 'smooth' });
}

document.addEventListener('DOMContentLoaded', function () {
  // Flashes are display:none in CSS -- show them, then take them away again
  var flashes = document.querySelectorAll('#flash-error, #flash-notice, #flash-warning');
  flashes.forEach(function (flash) { flash.style.display = 'block'; });
  setTimeout(function () {
    flashes.forEach(function (flash) { flash.style.display = 'none'; });
  }, 2500);

  // Formerly tabs - now a slider control
  var tabLinks = document.querySelectorAll('div.tabs ul.tab_navigation a');
  tabLinks.forEach(function (link) {
    link.addEventListener('click', function (event) {
      event.preventDefault();
      selectTab(link);
    });
  });

  // Select ghettotab based on URL anchor; e.g. #vanderplayer
  var fromAnchor = Array.from(tabLinks).find(function (link) {
    return window.location.href.includes(link.getAttribute('href'));
  });
  if (fromAnchor) selectTab(fromAnchor);
});

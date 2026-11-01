/*
* #000000book javascript
* Jamie Wilkinson <http://jamiedubs.com>
* (cc) Free Art & Technology Lab
*/

// Pull a tag's GML in the first time its Source panel is opened. Inlining it
// made the markup several hundred kilobytes for something most visitors leave
// folded away.
function loadSource(details) {
  var field = details.querySelector('textarea');
  if (!details.open || details.dataset.loaded || !field) return;
  details.dataset.loaded = 'true';

  fetch(details.dataset.sourceUrl)
    .then(function (response) {
      if (!response.ok) throw new Error(response.status);
      return response.text();
    })
    .then(function (body) { field.value = body; })
    .catch(function () {
      delete details.dataset.loaded; // let opening it again retry
      field.placeholder = 'Could not load the GML. Use Download GML instead.';
    });
}

document.addEventListener('DOMContentLoaded', function () {
  document.querySelectorAll('details.source[data-source-url]').forEach(function (details) {
    details.addEventListener('toggle', function () { loadSource(details); });
  });

  // Flashes are display:none in CSS -- show them, then take them away again
  var flashes = document.querySelectorAll('#flash-error, #flash-notice, #flash-warning');
  flashes.forEach(function (flash) { flash.style.display = 'block'; });
  if (flashes.length) {
    setTimeout(function () {
      flashes.forEach(function (flash) { flash.style.display = 'none'; });
    }, 4000);
  }
});

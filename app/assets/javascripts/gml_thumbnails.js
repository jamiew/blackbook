/*
 * Live thumbnails. Every canvas[data-preview] draws its tag from the cut-down
 * payload (/data/:id.json?preview=1) once it scrolls into view. Grid cells
 * (data-autoplay) play once as they appear; filmstrip cells draw the finished
 * tag. Any cell replays on hover or focus. With reduced motion nothing moves.
 */

const base = document.querySelector('meta[name="canvasplayer"]').content;
const [{ isLandscape }, { GmlPlayer }] = await Promise.all([
  import(`${base}/gml.js`),
  import(`${base}/gml-player.js`)
]);

const reduceMotion = matchMedia('(prefers-reduced-motion: reduce)').matches;

// One fetch per tag, however many cells show it.
const loads = new Map();

function load(url) {
  if (!loads.has(url)) {
    loads.set(url, fetch(url)
      .then(response => {
        if (!response.ok) throw new Error(response.status);
        return response.json();
      })
      .then(tag => {
        tag.rotate = isLandscape({ up: tag.up }, tag.strokes);
        return tag;
      }));
  }
  return loads.get(url);
}

function mount(canvas) {
  // Every cell is a link, so hover and keyboard focus both land on it.
  const cell = canvas.closest('a');
  load(canvas.dataset.preview).then(tag => {
    if (!tag.strokes.length) return;
    const player = new GmlPlayer(canvas, tag, { loop: false, pad: 0.1, hairline: 1.25 });
    player.setMode('hairline');
    player.setLayer('drips', false);
    player.setEffect('ghost', false);

    if (reduceMotion) {
      player.seek(player.duration);
      return;
    }
    if ('autoplay' in canvas.dataset) player.play();
    else player.seek(player.duration);

    const replay = () => player.seek(0).play();
    const rest = () => player.pause().seek(player.duration);
    cell.addEventListener('mouseenter', replay);
    cell.addEventListener('focus', replay);
    cell.addEventListener('mouseleave', rest);
    cell.addEventListener('blur', rest);
  }).catch(() => { canvas.dataset.error = ''; });
}

// Mount on first sight, a little before it, and never twice.
const seen = new IntersectionObserver(entries => {
  entries.forEach(entry => {
    if (!entry.isIntersecting) return;
    seen.unobserve(entry.target);
    mount(entry.target);
  });
}, { rootMargin: '200px' });

document.querySelectorAll('canvas[data-preview]').forEach(canvas => seen.observe(canvas));

// The filmstrip opens with the current tag in view.
document.querySelector('.strip [aria-current]')?.scrollIntoView({ inline: 'center', block: 'nearest' });

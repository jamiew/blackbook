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

    // Hover replays from the start; leaving picks up where the cell was,
    // still playing if it was.
    let resumeAt = null;
    let wasPlaying = false;
    const replay = () => {
      resumeAt = player.time;
      wasPlaying = player.playing;
      player.seek(0).play();
    };
    const rest = () => {
      player.pause().seek(resumeAt ?? player.duration);
      if (wasPlaying) player.play();
    };
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

/* --- display mode: what a cell shows when the tag has a still ---------- */

// Applied on every page from what the browser remembers; the dropdown only
// exists on /data. Without JS the still shows, so the default here is set
// on purpose to the drawing.
const DISPLAY_KEY = 'blackbook.display';
const DISPLAYS = ['drawing', 'still', 'over', 'pip', 'hover'];
const display = document.querySelector('[data-display-switch]');

function setDisplay(name) {
  document.documentElement.dataset.display = name;
  if (display) display.value = name;
}

let remembered = null;
try { remembered = localStorage.getItem(DISPLAY_KEY); } catch { /* private */ }
setDisplay(DISPLAYS.includes(remembered) ? remembered : 'drawing');
display?.addEventListener('change', () => {
  setDisplay(display.value);
  try { localStorage.setItem(DISPLAY_KEY, display.value); } catch { /* private */ }
});

// The filmstrip opens with the current tag in view.
document.querySelector('.strip [aria-current]')?.scrollIntoView({ inline: 'center', block: 'nearest' });

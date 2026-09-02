/*
 * The tag page's player.
 *
 * The engine and the controls are canvasplayer's, vendored verbatim under
 * public/canvasplayer (see SOURCE there). What is blackbook's lives here:
 * mounting on [data-gml-player], the pane top right of the stage with the
 * looks and the live/still switch, what a visitor's browser remembers, and
 * the page's keys.
 *
 * Loaded as a module. The version directory comes from the layout's meta tag,
 * so a bump is one line in the helper.
 */

const base = document.querySelector('meta[name="canvasplayer"]').content;
const [{ isLandscape }, { GmlPlayer, EFFECTS, LAYERS }, { transport, switches, secs }] = await Promise.all([
  import(`${base}/gml.js`),
  import(`${base}/gml-player.js`),
  import(`${base}/gml-ui.js`)
]);

const STORE_KEY = 'blackbook.player.v2';

// Each names a look rather than a setting. Marker is the engine's own default.
const LOOKS = {
  Marker: { mode: 'marker', effects: ['ghost'], layers: ['ink', 'drips'] },
  Plotter: { mode: 'hairline', effects: [], layers: ['ink', 'points'] },
  Technical: { mode: 'skeleton', effects: [], layers: ['ink', 'points', 'vectors', 'bounds', 'graph'] },
  Wild: { mode: 'chisel', effects: ['ghost', 'bleed', 'jitter'], layers: ['ink', 'drips'] }
};

function el(name, className, text) {
  const node = document.createElement(name);
  if (className) node.className = className;
  if (text != null) node.textContent = text;
  return node;
}

function button(text, onClick) {
  const node = el('button', null, text);
  node.type = 'button';
  node.addEventListener('click', onClick);
  return node;
}

// A row in the pane, in the shape gml-ui.js builds its own, so they line up.
function row(label, buttons, segmented) {
  const wrap = el('div', 'row');
  const set = el('div', segmented ? 'set segmented' : 'set');
  set.setAttribute('role', 'group');
  set.setAttribute('aria-label', label);
  set.append(...buttons);
  wrap.append(el('span', 'label', label), set);
  return wrap;
}

// localStorage throws outright in some privacy modes, so never assume it.
function remembered() {
  try { return JSON.parse(localStorage.getItem(STORE_KEY)) || null; } catch { return null; }
}

function remember(state) {
  try { localStorage.setItem(STORE_KEY, JSON.stringify(state)); } catch { /* full, blocked or private */ }
}

function apply(player, look) {
  if (look.mode) player.setMode(look.mode);
  EFFECTS.forEach(name => player.setEffect(name, (look.effects || []).includes(name)));
  LAYERS.forEach(name => player.setLayer(name, (look.layers || []).includes(name)));
}

function currentLook(player) {
  return {
    mode: player.mode,
    effects: EFFECTS.filter(name => player.effects[name]),
    layers: LAYERS.filter(name => player.layers[name])
  };
}

const reduceMotion = matchMedia('(prefers-reduced-motion: reduce)').matches;

function mount(root) {
  const payload = root.querySelector('script[type="application/json"]');
  const canvas = root.querySelector('canvas');
  const stage = root.querySelector('.player__stage');
  if (!payload || !canvas || !stage) return;

  let data;
  try {
    data = JSON.parse(payload.textContent);
  } catch {
    root.dataset.error = 'Could not parse tag data';
    return;
  }
  if (!data.strokes?.length) {
    root.dataset.error = 'No stroke data in this tag';
    return;
  }

  // Which way was up is decided here, by the same function the reference
  // player uses, so the two can never disagree about a tag.
  data.rotate = isLandscape({ up: data.up }, data.strokes);

  const player = new GmlPlayer(canvas, data);
  const tag = player.tag;

  // The stage takes the drawing's own proportions, within reason.
  const { x0, x1, y0, y1 } = tag.bounds;
  stage.style.aspectRatio = Math.min(Math.max((x1 - x0) / (y1 - y0), 0.75), 2);

  const meta = root.querySelector('[data-player-meta]');
  if (meta) {
    const count = tag.strokes.length;
    meta.textContent = [
      `${count} ${count === 1 ? 'stroke' : 'strokes'}`,
      `${tag.pointCount} pts`,
      `${secs(tag.duration)}s`,
      tag.rotate ? 'rot 90°' : null
    ].filter(Boolean).join('  //  ');
  }

  /* --- transport and pane ---------------------------------------------- */

  const bar = root.querySelector('[data-player-controls]');
  transport(player, bar);

  const pane = el('div', 'player__pane');
  pane.hidden = true;
  stage.append(pane);

  const toggle = button('Controls', () => { showPane(pane.hidden); save(); });
  toggle.className = 'player__debug';
  toggle.setAttribute('aria-pressed', 'false');
  bar.append(toggle);

  function showPane(on) {
    pane.hidden = !on;
    toggle.setAttribute('aria-pressed', String(on));
  }

  function save() {
    remember({ ...currentLook(player), pane: !pane.hidden });
  }

  // The still the capture app uploaded, if there is one, over the canvas.
  const still = root.querySelector('.player__still');

  function showStill(on) {
    still.hidden = !on;
    if (on) player.pause();
    else if (!reduceMotion) player.play();
    build();
  }

  // gml-ui's switches read their state once, when built, so the pane is
  // rebuilt whenever something changes it from outside a switch.
  function build() {
    pane.innerHTML = '';
    if (still) {
      const live = button('Live', () => showStill(false));
      const image = button('Still', () => showStill(true));
      live.setAttribute('aria-pressed', String(still.hidden));
      image.setAttribute('aria-pressed', String(!still.hidden));
      pane.append(row('Source', [live, image], true));
    }
    pane.append(row('Look', Object.keys(LOOKS).map(name => button(name, () => {
      apply(player, LOOKS[name]);
      build();
    }))));
    switches(player, pane);
  }

  // Any button in the pane changes something worth remembering. The button's
  // own handler runs first, so this reads the state after the change.
  pane.addEventListener('click', event => {
    if (event.target.closest('button')) save();
  });

  const saved = remembered();
  if (saved) {
    apply(player, saved);
    if (saved.pane) showPane(true);
  }
  build();

  if (reduceMotion) player.seek(tag.duration);
  else player.play();

  root.player = player;
}

document.querySelectorAll('[data-gml-player]').forEach(mount);

// The page's keys. Space plays and pauses; the arrows follow whichever links
// carry them, which on a tag page is the next and previous tag. Fields, and
// buttons that space would already press, are left alone.
document.addEventListener('keydown', event => {
  if (event.altKey || event.ctrlKey || event.metaKey || event.shiftKey) return;
  if (event.target.closest('input, textarea, select, button, a, [contenteditable]')) return;

  if (event.key === ' ') {
    const player = document.querySelector('[data-gml-player]')?.player;
    if (!player) return;
    event.preventDefault();
    player.toggle();
  } else {
    // Compared here rather than spliced into a selector, which a key like
    // \ or " would make invalid.
    const link = [...document.querySelectorAll('a[data-key]')].find(a => a.dataset.key === event.key);
    if (link) link.click();
  }
});

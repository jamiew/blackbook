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
function stored(key) {
  try { return localStorage.getItem(key); } catch { return null; }
}

function store(key, value) {
  try {
    if (value === null) localStorage.removeItem(key);
    else localStorage.setItem(key, value);
  } catch { /* full, blocked or private */ }
}

function remembered() {
  try { return JSON.parse(stored(STORE_KEY)); } catch { return null; }
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

// Fit the stage to the drawing and fill the head's readout. Called on mount
// and again whenever the browse page swaps the tag.
function present(root, stage, tag) {
  // The stage takes the drawing's own proportions, within reason.
  const { x0, x1, y0, y1 } = tag.bounds;
  stage.style.aspectRatio = Math.min(Math.max((x1 - x0) / (y1 - y0), 0.75), 2);

  const meta = root.querySelector('[data-player-meta]');
  if (!meta) return;
  const count = tag.strokes.length;
  meta.textContent = [
    `${count} ${count === 1 ? 'stroke' : 'strokes'}`,
    `${tag.pointCount} pts`,
    `${secs(tag.duration)}s`,
    tag.rotate ? 'rot 90°' : null
  ].filter(Boolean).join('  //  ');
}

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
  present(root, stage, tag);

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
    store(STORE_KEY, JSON.stringify({ ...currentLook(player), pane: !pane.hidden }));
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

/* --- browse: the grid drives the player --------------------------------- */

const browse = document.querySelector('[data-browse]');
const browseRoot = browse?.querySelector('[data-gml-player]');

if (browse && browseRoot?.player) {
  const player = browseRoot.player;
  const stage = browseRoot.querySelector('.player__stage');
  const cards = () => [...browse.querySelectorAll('.tag-card')];
  const loads = new Map();
  let swapping = false;

  function fetchTag(href) {
    if (!loads.has(href)) {
      loads.set(href, fetch(`${href}.json?player=1`).then(response => {
        if (!response.ok) throw new Error(response.status);
        return response.json();
      }));
    }
    return loads.get(href);
  }

  // Play a card's tag in place. The URL follows it, so reload and back work.
  // If the fetch fails, the card's own link is where we would have gone.
  function select(card, { push = true, replace = false } = {}) {
    const href = card.getAttribute('href');
    fetchTag(href).then(data => {
      data.rotate = isLandscape({ up: data.up }, data.strokes);
      swapping = true;
      player.pause().load(data);
      swapping = false;
      present(browseRoot, stage, player.tag);

      browseRoot.querySelector('.player__id').textContent = `#${data.id}`;
      const app = card.querySelector('.tag-card__app')?.textContent.trim();
      const who = card.querySelector('.tag-card__who')?.textContent.replace(/\s+/g, ' ').trim();
      browseRoot.querySelector('.player__context').textContent = [app, who].filter(Boolean).join(' · ');
      document.querySelectorAll('[data-browse-open]').forEach(a => a.setAttribute('href', href));
      document.querySelectorAll('[data-browse-download]').forEach(a => a.setAttribute('href', `${href}.gml`));
      cards().forEach(other => other.removeAttribute('aria-current'));
      card.setAttribute('aria-current', 'true');

      if (push) {
        const url = new URL(location);
        url.searchParams.set('tag', data.id);
        history[replace ? 'replaceState' : 'pushState']({ tag: data.id }, '', url);
      }
      if (reduceMotion) player.seek(player.duration);
      else player.play();
    }).catch(() => { location.href = href; });
  }

  // In the grid-only view there is no player to load into; let the link go.
  const playerShown = () => browseRoot.offsetParent !== null;

  browse.addEventListener('click', event => {
    const card = event.target.closest('.tag-card');
    if (!card || event.metaKey || event.ctrlKey || event.shiftKey || event.button) return;
    if (!playerShown()) return;
    event.preventDefault();
    select(card);
  });

  window.addEventListener('popstate', () => {
    const id = new URL(location).searchParams.get('tag');
    const card = cards().find(c => c.getAttribute('href') === `/data/${id}`);
    if (card) select(card, { push: false });
  });

  // ← → step through the grid. Returns false when there is nothing to do, so
  // the key can fall through to the single-tag page's own arrows.
  browse.step = (direction, { wrap = false, replace = false } = {}) => {
    if (!playerShown()) return false;
    const all = cards();
    const at = all.findIndex(c => c.hasAttribute('aria-current'));
    let next = all[at + direction];
    if (!next && wrap) next = all[(at + direction + all.length) % all.length];
    if (!next) return false;
    select(next, { replace });
    next.scrollIntoView({ block: 'nearest' });
    return true;
  };

  // Previous and next on the player itself, beside Controls.
  const bar = browseRoot.querySelector('[data-player-controls]');
  const controls = bar.querySelector('.player__debug');
  [['‹', -1, 'Previous tag'], ['›', 1, 'Next tag']].forEach(([glyph, direction, label]) => {
    const step = button(glyph, () => browse.step(direction, { wrap: true }));
    step.className = 'player__step';
    step.setAttribute('aria-label', label);
    bar.insertBefore(step, controls);
  });

  // A slideshow: once a tag has played through, the next one starts. A pause
  // of your own holds it, because only the end arrives with the clock run out.
  player.opts.loop = false;
  player.on('state', state => {
    if (state.playing || swapping || reduceMotion) return;
    if (player.time < player.tag.duration) return;
    setTimeout(() => browse.step(1, { wrap: true, replace: true }), 600);
  });
}

/* --- logo: a variant picked on /logos, for this browser ----------------- */

const LOGO_KEY = 'blackbook.logo';
const logo = document.querySelector('[data-logo-default]');
// The white wordmark vanishes on the light themes; this one is black.
const LOGO_DARK = '/images/logo/clean-paper.png';

function applyLogo() {
  if (!logo) return;
  const light = ['paper', 'acid'].includes(document.documentElement.dataset.theme);
  logo.src = stored(LOGO_KEY) || (light ? LOGO_DARK : logo.dataset.original);
}

// The reset button carries an empty data-logo, which puts the original back.
document.querySelectorAll('button[data-logo]').forEach(choice => {
  choice.addEventListener('click', () => {
    const src = choice.dataset.logo;
    store(LOGO_KEY, src || null);
    applyLogo();
    document.querySelectorAll('[data-logo-variant]').forEach(v => {
      v.toggleAttribute('data-chosen', v.querySelector('button[data-logo]').dataset.logo === src);
    });
  });
});

/* --- skins: theme and chrome, from the masthead ------------------------- */

// Applied on every page from what the browser remembers. The buttons only
// exist on the browse pages.
const SKINS = { theme: ['ink', 'paper', 'acid'], chrome: ['full', 'quiet', 'bare'] };

Object.entries(SKINS).forEach(([key, names]) => {
  const host = document.querySelector(`[data-${key}-switch]`);
  const buttons = host ? [...host.querySelectorAll(`button[data-${key}]`)] : [];
  const set = name => {
    document.documentElement.dataset[key] = name;
    buttons.forEach(b => b.setAttribute('aria-pressed', String(b.dataset[key] === name)));
    applyLogo();
  };

  const saved = stored(`blackbook.${key}`);
  set(names.includes(saved) ? saved : names[0]);

  host?.addEventListener('click', event => {
    const chosen = event.target.closest(`button[data-${key}]`);
    if (!chosen) return;
    set(chosen.dataset[key]);
    store(`blackbook.${key}`, chosen.dataset[key]);
  });
});

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
  } else if (event.key === 'ArrowLeft' || event.key === 'ArrowRight') {
    if (browse?.step?.(event.key === 'ArrowRight' ? 1 : -1)) {
      event.preventDefault();
      return;
    }
    // Compared here rather than spliced into a selector, which a key like
    // \ or " would make invalid.
    const link = [...document.querySelectorAll('a[data-key]')].find(a => a.dataset.key === event.key);
    if (link) link.click();
  }
});

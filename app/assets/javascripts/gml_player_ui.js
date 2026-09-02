/*
 * Transport, readout and control panel for GmlPlayer.
 *
 * Mounts on any [data-gml-player] element, reading its tag payload from the
 * application/json script tag inside it. Keeping the numbers in HTML rather
 * than painting them onto the canvas means they stay selectable, searchable
 * and legible to a screen reader.
 *
 * Panel settings are shared across tags and remembered in localStorage, so a
 * brush you like follows you around the archive.
 */

(function () {
  'use strict';

  var STORE_KEY = 'blackbook.player.v1';

  var RATES = [0.25, 0.5, 1, 2, 4];

  var MODE_LABELS = {
    marker: 'Marker',
    hairline: 'Hairline',
    outline: 'Outline',
    dots: 'Dots',
    spray: 'Spray',
    skeleton: 'Skeleton'
  };

  var LAYER_LABELS = {
    ink: 'Ink',
    drips: 'Drips',
    vectors: 'Vectors',
    points: 'Points',
    bounds: 'Bounds',
    graph: 'Graph'
  };

  var EFFECT_LABELS = {
    glow: 'Glow',
    ghost: 'Ghost',
    chromatic: 'Chromatic',
    jitter: 'Jitter',
    fade: 'Fade'
  };

  // Sliders, named for what they do to the line rather than for the option
  // they happen to set. `group` splits them into panel columns.
  var TUNERS = [
    { key: 'maxWidth', label: 'Thickest', min: 0.008, max: 0.16, step: 0.002, digits: 3, group: 'brush' },
    { key: 'minWidth', label: 'Thinnest', min: 0.001, max: 0.08, step: 0.001, digits: 3, group: 'brush' },
    { key: 'speedBias', label: 'Speed falloff', min: 0.1, max: 1.5, step: 0.05, digits: 2, group: 'brush' },
    { key: 'smoothing', label: 'Smoothing', min: 0, max: 0.95, step: 0.01, digits: 2, group: 'brush' },
    { key: 'hairline', label: 'Line weight', min: 0.5, max: 8, step: 0.25, digits: 2, group: 'brush' },

    { key: 'dwellSpeed', label: 'Drip dwell', min: 0, max: 0.5, step: 0.005, digits: 3, group: 'ink' },
    { key: 'dripLength', label: 'Drip length', min: 0, max: 3, step: 0.05, digits: 2, group: 'ink' },
    { key: 'dotScale', label: 'Dot size', min: 0.1, max: 3, step: 0.05, digits: 2, group: 'ink' },
    { key: 'sprayDensity', label: 'Spray density', min: 1, max: 30, step: 1, digits: 0, group: 'ink' },
    { key: 'sprayScatter', label: 'Spray spread', min: 0.2, max: 4, step: 0.1, digits: 1, group: 'ink' },

    { key: 'glow', label: 'Glow', min: 0, max: 60, step: 1, digits: 0, group: 'fx' },
    { key: 'chromatic', label: 'Split', min: 0.5, max: 20, step: 0.5, digits: 1, group: 'fx' },
    { key: 'jitter', label: 'Jitter', min: 0, max: 8, step: 0.1, digits: 1, group: 'fx' },
    { key: 'fadeWindow', label: 'Fade window', min: 0.2, max: 8, step: 0.1, digits: 1, group: 'fx' },
    { key: 'ghostAlpha', label: 'Ghost', min: 0.02, max: 0.6, step: 0.01, digits: 2, group: 'fx' }
  ];

  var GROUPS = [
    { key: 'brush', label: 'Brush' },
    { key: 'ink', label: 'Ink' },
    { key: 'fx', label: 'Effects' }
  ];

  // Bundles of the above. Each names a look rather than a setting, so there is
  // somewhere to start before touching fifteen sliders.
  var PRESETS = {
    Marker: { mode: 'marker', effects: [], layers: ['ink', 'drips'], opts: {} },
    Wildstyle: {
      mode: 'marker', effects: ['glow'], layers: ['ink', 'drips'],
      opts: { maxWidth: 0.085, minWidth: 0.022, speedBias: 0.75, dwellSpeed: 0.22, dripLength: 1.8, glow: 10 }
    },
    Plotter: {
      mode: 'hairline', effects: [], layers: ['ink', 'points'],
      opts: { hairline: 1.25 }
    },
    Blueprint: {
      mode: 'outline', effects: [], layers: ['ink', 'bounds', 'graph'],
      opts: { color: '#7ec8ff', background: '#04101f' }
    },
    Xray: {
      mode: 'spray', effects: ['chromatic', 'glow'], layers: ['ink'],
      opts: { sprayDensity: 10, sprayScatter: 1.6, glow: 18, chromatic: 4 }
    },
    Comet: {
      mode: 'marker', effects: ['fade', 'glow', 'ghost'], layers: ['ink'],
      opts: { fadeWindow: 1.2, glow: 22, ghostAlpha: 0.1 }
    },
    Schematic: {
      mode: 'skeleton', effects: [], layers: ['ink', 'points', 'bounds', 'vectors', 'graph'],
      opts: {}
    }
  };

  function pad(n, width) { return String(n).padStart(width, '0'); }

  function secs(t) {
    return pad(Math.floor(t), 2) + '.' + pad(Math.round((t % 1) * 100), 2);
  }

  function el(tag, className, text) {
    var node = document.createElement(tag);
    if (className) node.className = className;
    if (text != null) node.textContent = text;
    return node;
  }

  /* localStorage throws outright in some privacy modes, so never assume it. */
  function loadSettings() {
    try {
      return JSON.parse(window.localStorage.getItem(STORE_KEY)) || null;
    } catch (err) {
      return null;
    }
  }

  function saveSettings(settings) {
    try {
      window.localStorage.setItem(STORE_KEY, JSON.stringify(settings));
    } catch (err) {
      // Full, disabled or blocked. The panel still works for this visit.
    }
  }

  function clearSettings() {
    try {
      window.localStorage.removeItem(STORE_KEY);
    } catch (err) {
      // Nothing to do.
    }
  }

  function toggleButton(label, on, onChange) {
    var button = el('button', 'player__chip', label);
    button.type = 'button';
    button.setAttribute('aria-pressed', String(!!on));
    button.addEventListener('click', function () {
      var next = button.getAttribute('aria-pressed') !== 'true';
      button.setAttribute('aria-pressed', String(next));
      onChange(next);
    });
    return button;
  }

  function fieldset(label) {
    var box = el('div', 'player__group');
    box.appendChild(el('h3', 'player__group-title', label));
    return box;
  }

  function mount(root) {
    var payload = root.querySelector('script[type="application/json"]');
    var canvas = root.querySelector('canvas');
    if (!payload || !canvas || !window.GmlPlayer) return;

    var data;
    try {
      data = JSON.parse(payload.textContent);
    } catch (err) {
      root.setAttribute('data-error', 'Could not parse tag data');
      return;
    }
    if (!data.strokes || !data.strokes.length) {
      root.setAttribute('data-error', 'No stroke data in this tag');
      return;
    }

    var player = new window.GmlPlayer(canvas, data);
    var settings = loadSettings();
    var controls = root.querySelector('[data-player-controls]');
    var stage = root.querySelector('.player__stage');

    /* --- transport ------------------------------------------------------- */

    var play = el('button', 'player__play');
    play.type = 'button';
    play.setAttribute('aria-label', 'Play');

    var scrub = document.createElement('input');
    scrub.type = 'range';
    scrub.className = 'player__scrub';
    scrub.min = 0;
    scrub.max = 1000;
    scrub.value = 0;
    scrub.setAttribute('aria-label', 'Playback position');

    var clock = el('span', 'player__clock', '00.00 / ' + secs(player.duration));

    var rate = el('button', 'player__rate', '1×');
    rate.type = 'button';
    rate.setAttribute('aria-label', 'Playback speed');

    var debug = el('button', 'player__debug', 'Controls');
    debug.type = 'button';
    debug.setAttribute('aria-pressed', 'false');

    controls.appendChild(play);
    controls.appendChild(scrub);
    controls.appendChild(clock);
    controls.appendChild(rate);
    controls.appendChild(debug);

    /* --- panel ----------------------------------------------------------- */

    var panel = el('div', 'player__panel');
    panel.hidden = true;

    var modeButtons = {};
    var layerButtons = {};
    var effectButtons = {};
    var tunerRows = {};

    // Presets first: somewhere to start before the fifteen sliders below.
    var presetBox = fieldset('Presets');
    var presetRow = el('div', 'player__chips');
    Object.keys(PRESETS).forEach(function (name) {
      var button = el('button', 'player__chip player__chip--preset', name);
      button.type = 'button';
      button.addEventListener('click', function () { applyPreset(name); });
      presetRow.appendChild(button);
    });
    presetBox.appendChild(presetRow);
    panel.appendChild(presetBox);

    var modeBox = fieldset('Drawing mode');
    var modeRow = el('div', 'player__chips');
    window.GmlPlayer.MODES.forEach(function (name) {
      var button = el('button', 'player__chip', MODE_LABELS[name]);
      button.type = 'button';
      button.setAttribute('aria-pressed', String(player.mode === name));
      button.addEventListener('click', function () { setMode(name); persist(); });
      modeRow.appendChild(button);
      modeButtons[name] = button;
    });
    modeBox.appendChild(modeRow);
    panel.appendChild(modeBox);

    var layerBox = fieldset('Layers');
    var layerRow = el('div', 'player__chips');
    window.GmlPlayer.LAYERS.forEach(function (name) {
      var button = toggleButton(LAYER_LABELS[name], player.layers[name], function (on) {
        player.setLayer(name, on);
        persist();
      });
      layerRow.appendChild(button);
      layerButtons[name] = button;
    });
    layerBox.appendChild(layerRow);
    panel.appendChild(layerBox);

    var effectBox = fieldset('Effects');
    var effectRow = el('div', 'player__chips');
    window.GmlPlayer.EFFECTS.forEach(function (name) {
      var button = toggleButton(EFFECT_LABELS[name], player.effects[name], function (on) {
        player.setEffect(name, on);
        persist();
      });
      effectRow.appendChild(button);
      effectButtons[name] = button;
    });
    effectBox.appendChild(effectRow);
    panel.appendChild(effectBox);

    var colorInputs = {};

    function colorRow(key, label) {
      var row = el('div', 'player__tuner player__tuner--color');
      var id = 'tune-' + key + '-' + data.id;

      var text = el('label', null, label);
      text.htmlFor = id;

      var input = document.createElement('input');
      input.type = 'color';
      input.id = id;
      input.className = 'player__color';
      input.value = player.opts[key];
      input.addEventListener('input', function () {
        var change = {};
        change[key] = input.value;
        player.retune(change);
        if (key === 'background' && stage) stage.style.background = input.value;
        persist();
      });

      row.appendChild(text);
      row.appendChild(input);
      row.appendChild(el('span', 'player__tuner-value', ''));
      colorInputs[key] = input;
      return row;
    }

    // Sliders, grouped, plus the two colour wells.
    var tuneGrid = el('div', 'player__panel-grid');
    GROUPS.forEach(function (group) {
      var box = fieldset(group.label);
      var list = el('div', 'player__tuners');

      TUNERS.filter(function (spec) { return spec.group === group.key; }).forEach(function (spec) {
        var row = el('div', 'player__tuner');
        var id = 'tune-' + spec.key + '-' + data.id;

        var label = el('label', null, spec.label);
        label.htmlFor = id;

        var value = el('span', 'player__tuner-value', player.opts[spec.key].toFixed(spec.digits));

        var input = document.createElement('input');
        input.type = 'range';
        input.id = id;
        input.className = 'player__scrub';
        input.min = spec.min;
        input.max = spec.max;
        input.step = spec.step;
        input.value = player.opts[spec.key];
        input.addEventListener('input', function () {
          var change = {};
          change[spec.key] = parseFloat(input.value);
          player.retune(change);
          value.textContent = parseFloat(input.value).toFixed(spec.digits);
          persist();
        });

        row.appendChild(label);
        row.appendChild(input);
        row.appendChild(value);
        list.appendChild(row);
        tunerRows[spec.key] = { input: input, value: value, spec: spec };
      });

      if (group.key === 'ink') list.appendChild(colorRow('color', 'Ink'));
      if (group.key === 'ink') list.appendChild(colorRow('background', 'Ground'));

      box.appendChild(list);
      tuneGrid.appendChild(box);
    });
    panel.appendChild(tuneGrid);

    // Readout and reset sit at the foot of the panel.
    var footer = el('div', 'player__panel-foot');
    var fields = {};
    var readoutList = el('dl', 'player__readout');
    [
      ['stroke', 'Stroke'], ['points', 'Pts'], ['speed', 'Vel'],
      ['head', 'X,Y'], ['clock', 'T'], ['timing', 'Timing']
    ].forEach(function (pair) {
      var wrap = el('div', 'player__field');
      wrap.appendChild(el('dt', null, pair[1]));
      var dd = el('dd', null, '—');
      wrap.appendChild(dd);
      readoutList.appendChild(wrap);
      fields[pair[0]] = dd;
    });
    footer.appendChild(readoutList);

    var reset = el('button', 'player__reset', 'Reset everything');
    reset.type = 'button';
    reset.addEventListener('click', function () {
      clearSettings();
      applySettings({ mode: 'marker', layers: ['ink', 'drips'], effects: [],
        opts: Object.assign(player.defaults(), { speed: player.opts.speed }) });
    });
    footer.appendChild(reset);
    panel.appendChild(footer);

    root.appendChild(panel);

    /* --- applying and remembering settings -------------------------------- */

    function setMode(name) {
      player.setMode(name);
      Object.keys(modeButtons).forEach(function (key) {
        modeButtons[key].setAttribute('aria-pressed', String(key === name));
      });
    }

    function syncTuners() {
      Object.keys(tunerRows).forEach(function (key) {
        var row = tunerRows[key];
        row.input.value = player.opts[key];
        row.value.textContent = Number(player.opts[key]).toFixed(row.spec.digits);
      });
      Object.keys(colorInputs).forEach(function (key) { colorInputs[key].value = player.opts[key]; });
      if (stage) stage.style.background = player.opts.background;
    }

    function applySettings(settings) {
      if (!settings) return;
      if (settings.opts) player.retune(settings.opts);
      if (settings.mode) setMode(settings.mode);

      window.GmlPlayer.LAYERS.forEach(function (name) {
        var on = settings.layers ? settings.layers.indexOf(name) !== -1 : player.layers[name];
        player.layers[name] = on;
        layerButtons[name].setAttribute('aria-pressed', String(on));
      });
      window.GmlPlayer.EFFECTS.forEach(function (name) {
        var on = settings.effects ? settings.effects.indexOf(name) !== -1 : player.effects[name];
        player.effects[name] = on;
        effectButtons[name].setAttribute('aria-pressed', String(on));
      });

      syncTuners();
      player.render();
    }

    function applyPreset(name) {
      var preset = PRESETS[name];
      if (!preset) return;
      // Presets set only what they care about; everything else goes back to
      // stock, so switching between them does not accumulate leftovers.
      applySettings({
        mode: preset.mode,
        layers: preset.layers,
        effects: preset.effects,
        opts: Object.assign(player.defaults(), { speed: player.opts.speed }, preset.opts)
      });
      persist();
    }

    function persist() {
      var opts = {};
      TUNERS.forEach(function (spec) { opts[spec.key] = player.opts[spec.key]; });
      opts.color = player.opts.color;
      opts.background = player.opts.background;

      saveSettings({
        mode: player.mode,
        layers: window.GmlPlayer.LAYERS.filter(function (n) { return player.layers[n]; }),
        effects: window.GmlPlayer.EFFECTS.filter(function (n) { return player.effects[n]; }),
        opts: opts,
        panelOpen: !panel.hidden
      });
    }

    /* --- wiring ----------------------------------------------------------- */

    var meta = root.querySelector('[data-player-meta]');
    if (meta) {
      meta.textContent = [
        player.strokes.length + ' STROKE' + (player.strokes.length === 1 ? '' : 'S'),
        player.pointCount + ' PTS',
        secs(player.duration) + 'S',
        data.rotate ? 'ROT 90°' : null
      ].filter(Boolean).join('  //  ');
    }

    var scrubbing = false;

    player.on('frame', function (s) {
      if (!scrubbing) scrub.value = Math.round((s.time / s.duration) * 1000);
      clock.textContent = secs(Math.min(s.time, s.duration)) + ' / ' + secs(s.duration);
      if (panel.hidden) return;
      fields.stroke.textContent = pad(s.stroke, 2) + '/' + pad(s.strokes, 2);
      fields.points.textContent = pad(s.points, 4) + '/' + pad(s.totalPoints, 4);
      fields.speed.textContent = s.speed.toFixed(3) + ' u/s';
      fields.head.textContent = s.head ? s.head[0].toFixed(4) + ',' + s.head[1].toFixed(4) : '—';
      fields.clock.textContent = secs(Math.min(s.time, s.duration)) + 's';
      fields.timing.textContent = s.timing.synthesized ? 'SYNTHESIZED'
        : (s.timing.reordered || s.timing.gapsClosed)
          ? 'REPAIRED ' + (s.timing.reordered + s.timing.gapsClosed)
          : 'CLEAN';
    });

    player.on('state', function (s) {
      root.classList.toggle('is-playing', s.playing);
      play.setAttribute('aria-label', s.playing ? 'Pause' : 'Play');
    });

    play.addEventListener('click', function () { player.toggle(); });

    scrub.addEventListener('input', function () {
      scrubbing = true;
      player.pause();
      player.seek((scrub.value / 1000) * player.duration);
    });
    scrub.addEventListener('change', function () { scrubbing = false; });

    rate.addEventListener('click', function () {
      var next = RATES[(RATES.indexOf(player.opts.speed) + 1) % RATES.length];
      player.setSpeed(next);
      rate.textContent = (next === 1 ? '1' : String(next)) + '×';
    });

    function setPanel(open) {
      panel.hidden = !open;
      debug.setAttribute('aria-pressed', String(open));
      root.classList.toggle('is-debug', open);
      if (open) player.render();
    }

    debug.addEventListener('click', function () {
      setPanel(panel.hidden);
      persist();
    });

    // Space and arrows, but only once the player has focus -- otherwise this
    // would hijack scrolling for the whole page.
    root.tabIndex = 0;
    root.addEventListener('keydown', function (event) {
      if (event.key === ' ') { event.preventDefault(); player.toggle(); }
      else if (event.key === 'ArrowLeft') { event.preventDefault(); player.pause().seek(player.time - 0.25); }
      else if (event.key === 'ArrowRight') { event.preventDefault(); player.pause().seek(player.time + 0.25); }
      else if (event.key === 'd' || event.key === 'D') debug.click();
    });

    if (settings) {
      applySettings(settings);
      if (settings.panelOpen) setPanel(true);
    } else {
      syncTuners();
    }

    if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) {
      player.seek(player.duration);
    } else {
      player.play();
    }

    root.player = player;
  }

  document.addEventListener('DOMContentLoaded', function () {
    document.querySelectorAll('[data-gml-player]').forEach(mount);
  });
}());

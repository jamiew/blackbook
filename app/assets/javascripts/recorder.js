/*
 * Draw a tag in the browser and get GML out of it.
 *
 * Pointer events become strokes of [x, y, seconds]. Both axes are divided by
 * the pad's width, so a landscape pad keeps its proportions the way the
 * EyeWriter's files do, without screenBounds arithmetic. Playback uses the
 * same engine as the rest of the site; the GML goes into the upload form's
 * field, or out as a file.
 */

const root = document.querySelector('[data-gml-recorder]');

if (root) {
  const base = document.querySelector('meta[name="canvasplayer"]').content;
  const { GmlPlayer } = await import(`${base}/gml-player.js`);

  const pad = root.querySelector('.recorder__pad');
  const stage = root.querySelector('.recorder__play');
  // The readout sits in the section head above the pad, not inside it.
  const readout = document.querySelector('[data-recorder-readout]');
  const field = root.querySelector('[data-recorder-gml]');
  const ctx = pad.getContext('2d');

  let strokes = [];
  let stroke = null;
  let started = null;
  let player = null;

  const width = () => pad.clientWidth;

  function redraw() {
    const w = width();
    ctx.fillStyle = '#000';
    ctx.fillRect(0, 0, w, pad.clientHeight);
    ctx.strokeStyle = '#fff';
    ctx.lineWidth = 3;
    ctx.lineCap = 'round';
    ctx.lineJoin = 'round';
    strokes.forEach(s => {
      ctx.beginPath();
      s.points.forEach(([x, y], i) => (i ? ctx.lineTo(x * w, y * w) : ctx.moveTo(x * w, y * w)));
      ctx.stroke();
    });
  }

  function size() {
    const dpr = Math.min(devicePixelRatio || 1, 2);
    pad.width = Math.round(pad.clientWidth * dpr);
    pad.height = Math.round(pad.clientHeight * dpr);
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    redraw();
  }

  function point(event) {
    const rect = pad.getBoundingClientRect();
    const now = performance.now();
    if (started === null) started = now;
    return [(event.clientX - rect.left) / rect.width, (event.clientY - rect.top) / rect.width, (now - started) / 1000];
  }

  const fixed = (n, places) => Number(n).toFixed(places);

  // GML 1.0, the shape every capture app writes and this site parses.
  function gml() {
    const points = s => s.points.map(([x, y, t]) =>
      `<pt><x>${fixed(x, 4)}</x><y>${fixed(y, 4)}</y><time>${fixed(t, 3)}</time></pt>`).join('');
    return '<gml spec="1.0"><tag><header>' +
      `<client><name>000000book.com</name><version>1.0</version><time>${new Date().toISOString()}</time></client>` +
      `<environment><screenBounds><x>${width()}</x><y>${pad.clientHeight}</y></screenBounds>` +
      '<up><x>0</x><y>1</y><z>0</z></up></environment></header><drawing>' +
      strokes.map(s => `<stroke>${points(s)}</stroke>`).join('') +
      '</drawing></tag></gml>';
  }

  function describe() {
    const count = strokes.reduce((n, s) => n + s.points.length, 0);
    const last = strokes.at(-1)?.points.at(-1);
    readout.textContent = strokes.length
      ? `${strokes.length} ${strokes.length === 1 ? 'stroke' : 'strokes'}  //  ${count} pts  //  ${fixed(last[2], 2)}s`
      : 'Draw here';
    root.toggleAttribute('data-empty', !strokes.length);
    if (field) field.value = strokes.length ? gml() : '';
  }

  function stopPlayback() {
    if (player) player.destroy();
    player = null;
    stage.hidden = true;
  }

  pad.addEventListener('pointerdown', event => {
    event.preventDefault();
    stopPlayback();
    pad.setPointerCapture(event.pointerId);
    stroke = { points: [point(event)] };
    strokes.push(stroke);
  });
  pad.addEventListener('pointermove', event => {
    if (!stroke) return;
    stroke.points.push(point(event));
    redraw();
  });
  const lift = () => { stroke = null; describe(); };
  pad.addEventListener('pointerup', lift);
  pad.addEventListener('pointercancel', lift);

  root.querySelector('[data-recorder-clear]').addEventListener('click', () => {
    strokes = [];
    started = null;
    stopPlayback();
    redraw();
    describe();
  });

  root.querySelector('[data-recorder-play]').addEventListener('click', () => {
    if (!strokes.length) return;
    stopPlayback();
    stage.hidden = false;
    const tag = { id: null, app: '000000book.com', rotate: false, strokes: strokes.map(s => ({ points: s.points.map(p => [...p]) })) };
    player = new GmlPlayer(stage, tag, { loop: false });
    player.play();
  });

  root.querySelector('[data-recorder-download]').addEventListener('click', () => {
    if (!strokes.length) return;
    const url = URL.createObjectURL(new Blob([gml()], { type: 'application/xml' }));
    const link = document.createElement('a');
    link.href = url;
    link.download = 'tag.gml';
    link.click();
    URL.revokeObjectURL(url);
  });

  new ResizeObserver(size).observe(pad);
  size();
  describe();
}

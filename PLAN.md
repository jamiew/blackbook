# Design refresh

The canvas is the centerpiece. One engine, canvasplayer vendored under
`public/canvasplayer/`, draws every tag: on its page, in every grid cell, on the
app cards, in the recorder.

## Done

- Chrome: instruments row gone, logo given height, `/apps` rebuilt and fixed.
- Engine: canvasplayer 6.0.0 vendored with `SOURCE`; `player.js` is the glue.
- Viewer: id in the head, filmstrip of neighbours, metadata tiles, About rebuilt
  around a hero composed from tag 10043.
- Browse: `/` and `/data` play one tag beside the grid; click or `←`/`→` loads
  it in place; four layouts from the masthead switch; combinable chips.
- Apps: `source_url`, chips, every card and page playing the app's newest tag.
- Upload: capture apps, a GML recorder, form and API. `/logos` with a toggle.
- Search and social: descriptions, canonical, cards, `sitemap.xml`, skip link.
- Cleanup: dead icons, placeholders, the ga.js partial, an unused view and a
  stale spec gone; docs rewritten short.

## Next

- [ ] `./script/rehearse-migrations.sh` for `add_source_url_to_visualizations`
      before it ships. Needs SSH to production.
- [ ] Redo the hairline, chrome and skeleton logo remixes; they wrote "co1".
- [ ] Cards and stills for tags with no attachment. `gml2img.py` in the tempt1
      worktree already ports the marker model to SVG. Backfilling production
      needs its own approval.
- [ ] Legacy forms: `tags/_form`, `tags/validator`, `users/{edit,new}`,
      `user_sessions/new`, `home/_notifications`, `favorites/index`.
- [ ] Request specs for the remaining pages; an accessibility sweep with a tool.
- [ ] Maybe: fetch `/data/:id.gml` and `parse()` on the client instead of
      inlining `player_data`. One parser, but 614KB against 70KB per page
      until the proxy gzips.

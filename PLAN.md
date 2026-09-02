# Design refresh

The canvas is the centerpiece. One engine, vendored from
[jamiew/canvasplayer](https://github.com/jamiew/canvasplayer), draws every
tag: the detail page, the grid, the filmstrip, and later the social card.

## Done

- [x] Drop the instruments row from the header. The writer profile keeps it.
- [x] Give the logo height. It is the one soft element on the page.
- [x] Fix `/apps/1` (nil website) and rebuild `visualizations/*` on the
      refreshed vocabulary. `website_link` helper shared with writer profiles.

## Next

- [ ] **Engine.** Vendor `gml.js`, `gml-player.js`, `gml-ui.js`, `gml-ui.css`
      verbatim into `public/canvasplayer/<version>/` with a `SOURCE` file (URL,
      commit, date, how to update). Blocked on an upstream commit. Blackbook
      keeps one glue module, `player.js`, loaded as `type="module"`. Rotation
      moves to the client via upstream `isLandscape`, so there is one parser.
      Delete `gml_player.js` and `gml_player_ui.js`.
- [ ] **Debug pane.** Switches overlay top-right of the stage, not below it.
      One new control: source `LIVE | STILL`, where STILL is the attachment.
- [ ] **Grid.** `Tag#preview_data` (≤300 points, ~5KB) served from
      `tags#show` as `.json?preview=1` with the existing ETag. Cells are
      canvases mounted on scroll, `hairline` mode, looped on hover.
      `prefers-reduced-motion` draws the finished tag once.
- [ ] **Filmstrip and keyboard.** `tags/_filmstrip` under the player on `/`
      and `/data/:id`. Cells are links. `←`/`→` follow prev/next, `space`
      toggles play. No pushState; every tag stays a URL.

## Backlog

- [ ] Social cards and empty thumbnails in one job: `paint()` on a Node
      canvas, one PNG per tag, used for `og:image`, the no-JS still, and tags
      with no attachment. Backfilling production needs its own approval.
- [ ] Import the wiki API docs into `docs/api/`. Routes and `DocsController`
      exist.
- [ ] `sitemap.xml`. Audit `llms.txt` and OpenGraph once cards exist.
- [ ] Normalize upload thumbnail sizes. Retroactive pass needs a read-only
      rehearsal first.
- [ ] Request specs for every page. Accessibility sweep.
- [ ] Remaining legacy views: `tags/_form`, `tags/validator`,
      `users/{edit,new}`, `user_sessions/new`, `home/_notifications`.
- [ ] Maybe: fetch `/data/:id.gml` and `parse()` on the client instead of
      inlining `player_data`. One parser, but 614KB vs 70KB per page until the
      proxy gzips.

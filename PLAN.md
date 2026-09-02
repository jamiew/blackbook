# Design refresh

The canvas is the centerpiece. One engine, vendored from
[jamiew/canvasplayer](https://github.com/jamiew/canvasplayer), draws every
tag: the detail page, the grid, the filmstrip, and later the social card.

## Done

- [x] Drop the instruments row from the header. The writer profile keeps it.
- [x] Give the logo height. It is the one soft element on the page.
- [x] Fix `/apps/1` (nil website) and rebuild `visualizations/*` on the
      refreshed vocabulary. `website_link` helper shared with writer profiles.

- [x] **Engine.** canvasplayer 6.0.0 vendored verbatim under
      `public/canvasplayer/6.0.0/` (see `SOURCE` there for the commit and how
      to update). `player.js` is the only blackbook glue. Rotation is decided
      on the client with upstream `isLandscape`, so there is one parser.
- [x] **Pane.** Looks, source `LIVE | STILL`, and gml-ui's switches overlay
      top right of the stage. Remembered per browser. `space` plays and
      pauses; `←`/`→` follow next and previous on a tag page.
- [x] `Tag#preview_data`, served from `tags#show` as `.json?preview=1`.

## Next

- [ ] **Grid.** Cells become canvases mounted on scroll from `?preview=1`,
      `hairline` mode, looped on hover. `prefers-reduced-motion` draws the
      finished tag once. `NO STILL` stays as the pre-JS state.
- [ ] **Filmstrip.** `tags/_filmstrip` under the player on `/` and
      `/data/:id`: the neighbouring tags as the same live cells, each a link,
      with a `← → browse · space play` hint. No pushState.

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

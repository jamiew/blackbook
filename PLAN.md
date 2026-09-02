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

- [x] **The viewer.** The id and context live in the player head; the
      filmstrip of live neighbours sits inside the frame; metadata is a strip
      of tiles below. `/` is the same viewer on the latest tag. Every grid
      cell on the site draws its own tag (`gml_thumbnails.js`).
- [x] **About page and graphics.** Rebuilt with a hero composed from tag
      10043's real strokes (Glif), six random live cells, and local images.
      The same render is the README header and the default OpenGraph card.

## Next

- [ ] **Browse.** `/` and `/data` become player-left, grid-right on wide
      screens. Clicking a cell or pressing `←`/`→` loads that tag into the
      player in place (`/data/:id.json?player=1`) and sets `?tag=id`, so
      reload and back work. `/` leads with `Tag::FEATURED` (canvasplayer's
      six) then newest; `/data` keeps filters and pagination.
- [ ] **Hover.** Leaving a cell resumes where it was, still playing if it was.
- [ ] **Apps.** `source_url` column (rehearsed migration) so "open source" is
      a fact; chips for language, open source, embeddable; each card animates
      one of that app's own tags; dev seeds for real apps and tags.
- [ ] **Upload page.** `/upload` in the nav: how to make a GML tag today
      (Fat Tag Deluxe and friends) and how to upload one, by form or API.
- [ ] Per-tag OpenGraph cards, and stills for tags with no attachment. The
      cheapest renderer is `gml2img.py` in the tempt1-archive worktree, which
      already ports the marker model to SVG (PNG via `rsvg-convert`).
      Backfilling production needs its own approval.

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

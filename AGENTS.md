# Working on 000000book

An archive of graffiti motion-capture data (GML) running since 2009. Rails 8.1 on
Ruby 3.4, MySQL 8.4, deployed as a container by Kamal. No JavaScript build step.

It holds real data for real people: 70,000+ tags and roughly 35 GB of GML files
and images on a block volume. Most of it cannot be regenerated. Prefer the
cautious option.

## Setup

```bash
docker compose up -d     # MySQL 8.4, pinned to the version the server runs
bundle install
bin/rails db:prepare
bin/rails db:seed        # development only: real app names on the test tags
bundle exec rspec        # needs no environment variables
bundle exec rubocop
```

Development, test and CI all use that MySQL. A version gap against production
once hid the utf8mb3 and MyISAM problems for years; keep them aligned.
`MYSQL_PORT` overrides the port. Pages 500 while MySQL is down.

## Before changing a migration

Run `./script/rehearse-migrations.sh`; it needs SSH to production. The test
database is built from `schema.rb` and has never resembled production, which is
still MyISAM and utf8mb3. See [docs/operations.md](docs/operations.md).

Migrations never run automatically on deploy. The pending set drops the
`comments` table. Run `bin/rails data:validate` first.

## Frontend

- `public/canvasplayer/<version>/` is canvasplayer, vendored byte for byte.
  `SOURCE` there records the commit and how to update. Never edit those files
  here; changes go upstream first. It sits outside the asset pipeline because
  Propshaft's fingerprints break the modules' relative imports.
- Blackbook's own JavaScript is three ES modules listed in
  `layouts/_template_header.html.haml`: `player.js` (tag page, browse, pane,
  keys, view switch, logo toggle), `gml_thumbnails.js` (every grid cell) and
  `recorder.js` (`/upload`). They find the player through
  `<meta name="canvasplayer">`, set by `ApplicationHelper#canvasplayer_path`.
- Tag payloads: the page inlines `Tag#player_data`; `.json?preview=1` is
  `Tag#preview_data` for thumbnails; `.json?player=1` is `player_data` for the
  browse page's swaps. Rotation is decided on the client with upstream
  `isLandscape` from the `up` vector each payload carries.
- Test UI changes with `agent-browser` at 1440 and 390 wide. Thumbnails only
  draw once their cells scroll into view.
- `/logos` and the masthead theme and chrome switches are design tools that
  ship. Choices live in `localStorage`: `blackbook.theme`, `blackbook.chrome`,
  `blackbook.logo`, `blackbook.player.v2`.

## Things that look wrong but are not

- **`crypted_password` and `password_salt` are still on `users`.** Accounts
  predating the Authlogic removal have only an scrypt hash, verified against the
  old scheme and rehashed to bcrypt on next login. Dropping these columns logs
  those people out permanently.
- **`*_file_name` columns are still on `tags`, `users` and `visualizations`.**
  The Active Storage backfill reads them. They go once it has run everywhere.
- **`ConvertToUtf8mb4` raises on rollback.** Converting back does not fail on
  4-byte data, it silently corrupts it.
- **`/up` is excluded from `force_ssl`.** Without that the Kamal proxy's health
  check sees a 301 and no deploy ever completes.
- **`authlogic` is still in the Gemfile,** with `require: false`, only so a spec
  can build a real scrypt hash to test legacy login against.
- **`variant_processor` is `:mini_magick`, not the Rails 8 default of `:vips`.**
  ImageMagick is what the app has always used and what both the Dockerfile and a
  plain macOS setup already have.
- **`db/seeds.rb` renames tags.** In development only, it gives the rate-limit
  test rows real app names so `/apps` has something to play. It never creates
  tags: `data/` holds orphan files at the next ids and a new row would overwrite
  one.

## Conventions

- Specs live beside what they test, `describe` named for the class or method.
- Comments explain non-obvious reasons, not behavior.
- `script/*.sh` are idempotent and safe to re-run. Keep them that way.
- Anything that touches production data must be read-only, or say loudly that it
  is not.
- Keep `PLAN.md` current: what landed, what is next.

## Don't

- Don't run migrations as a side effect of anything.
- Don't `git add -A`; other agents may be working in the same tree.
- Don't touch `volume-nyc3-01` or droplet `blackbook4-rails`. That is live
  production. Beta is `blackbook-beta` and `blackbook-beta-volume`, entirely
  separate compute and storage.
- Don't commit secrets. `.kamal/secrets` holds references only; real values live
  in the gitignored `.kamal/secrets-common` or in Rails encrypted credentials.

## More

- [docs/deployment.md](docs/deployment.md)
- [docs/operations.md](docs/operations.md)
- [docs/README.md](docs/README.md) for the API and GML documentation

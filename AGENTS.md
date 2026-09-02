# Working on 000000book

An archive of graffiti motion-capture data (GML) running since 2009. Rails 8.1 on
Ruby 3.4, MySQL, deployed as a container by Kamal.

It holds real data for real people: 70,000+ tags and roughly 35 GB of GML files
and images on a block volume. Most of it cannot be regenerated. Prefer the
cautious option.

## Setup

```bash
docker compose up -d     # MySQL 8.4, pinned to the version the server runs
bundle install
bin/rails db:prepare
bundle exec rspec        # needs no environment variables
```

Development, test and CI all use that MySQL. Development used to point at
whatever MySQL was on the laptop, which is how a version gap opened up against
production and hid the utf8mb3 and MyISAM problems for years. Keep them aligned.

`MYSQL_PORT` overrides the port if you run your own server.

## Before changing a migration

Run `./script/rehearse-migrations.sh`. The test database is built from
`schema.rb` and has never resembled production, which is still MyISAM and
utf8mb3. The rehearsal loads production's real table definitions into a
throwaway MySQL 8.4 and runs the pending set against them. See
[docs/operations.md](docs/operations.md).

Migrations never run automatically on deploy. That is deliberate: the pending set
drops the `comments` table. Run `rake data:validate` first.

## Things that look wrong but are not

- **`public/canvasplayer/` is vendored JavaScript outside the asset pipeline.**
  Propshaft fingerprints filenames, which breaks the modules' relative
  imports. `SOURCE` in that directory records the commit and how to update.
  Never edit those files here; changes go upstream first.
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
  plain macOS setup already have. `mini_magick` is declared explicitly because
  `image_processing` 2.x stopped depending on it.

## Conventions

- Specs live beside what they test, `describe` named for the class or method.
- Comments explain non-obvious reasons, not behavior.
- `script/*.sh` are idempotent and safe to re-run. Keep them that way.
- Anything that touches production data must be read-only, or say loudly that it
  is not.

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

# Operations

## Testing migrations before they touch a server

The test database is built from `schema.rb`, so it has never looked like
production, which is still MyISAM and utf8mb3. Migrations that pass the suite can
still fail or corrupt data there.

```bash
./script/rehearse-migrations.sh
```

Pulls production's table definitions (schema only, never any rows), loads them
into a throwaway MySQL 8.4, seeds the duplicate users that decide which branch
`AddMissingUniqueIndexes` takes, and runs every pending migration.

This is what caught two things reasoning alone did not:

- MyISAM's 1000-byte index limit rejects a utf8mb4 `varchar(255)` unique key,
  where [InnoDB allows 3072](https://dev.mysql.com/doc/refman/8.4/en/innodb-limits.html).
  So the charset conversion has to run *after* the InnoDB conversion.
- Converting utf8mb4 back to utf8mb3 does not fail on 4-byte data, it silently
  mangles it. A stored 🎨 (`F0 9F 8E A8`) returns as `C3 B0 C5 B8 C5 BD C2 A8`
  with no error. `ConvertToUtf8mb4` is therefore irreversible on purpose.

## Reloading beta from production

```bash
./script/resync-beta.sh
```

Streams a fresh dump and rsyncs the volume from production to beta directly, so
36 GB never travels through a laptop. Production is only ever read.

Two guards, both tested: it refuses when source and target are the same host, and
when beta's volume is not mounted, which would otherwise fill the root disk.

The dump uses `--skip-lock-tables` so it never blocks the live site. Production is
still MyISAM, so that trades a consistent snapshot for zero impact, which is the
right way round while testing. **For the final cutover, stop the app on production
first.**

## Backups and audit

```bash
script/audit-production.sh    # read-only: what is deployed, what migrations will hit
script/backup-production.sh   # verified dump, GML corpus, images, gitignored config
```

`backup-production.sh` deliberately does not copy anything off the server. It
prints the `scp` command so the transfer stays a human decision.

## Moving images into Active Storage

```bash
bin/rails active_storage:verify     # report only, writes nothing
bin/rails active_storage:backfill
```

Idempotent and resumable. Records that already have an attachment are skipped, so
an interrupted run picks up where it stopped. Paperclip's files and `*_file_name`
columns are left alone, so a bad run costs nothing.

It reports every row whose file it could not find rather than skipping quietly,
and exits non-zero if any are missing, so a script cannot move on to deleting the
originals after a partial run.

One thing worth knowing: the corpus uses two different `id_partition` widths,
around 1,900 files at 9 digits (`000/002/062`) and 879 at 15
(`000/000/000/045/135`), left by different Paperclip versions over the years.
Generating only one layout silently misses a third of the images.

Do this after growing the volume. Copying every image needs headroom the 50 GiB
volume does not have at 36 GB used.

## Passwords after the Authlogic removal

Accounts created before the move have only an scrypt hash in `crypted_password`.
scrypt cannot be converted to bcrypt, so those are verified against the old scheme
and quietly rehashed on the next successful login. Nobody is locked out and no
email is required.

`crypted_password` and `password_salt` must stay until nothing depends on them.
Dropping them early logs those accounts out permanently.

Two traps, both pinned by `spec/models/user_authenticate_legacy_scrypt_spec.rb`:

- The hashed string is the password **then** the salt. Authlogic's
  `encrypt_arguments` returns `[raw_password, salt]`. Reversed, every legacy
  login fails silently.
- `has_secure_password` defines its own `password_salt`, derived from the bcrypt
  digest, which shadows the legacy column and returns nil. The legacy path reads
  the columns directly.

## Known data issues

- 45 duplicate logins and 45 duplicate emails in production. Until these are
  cleaned up, `AddMissingUniqueIndexes` skips those two indexes rather than
  failing. The migration's own comment suspects spam accounts.

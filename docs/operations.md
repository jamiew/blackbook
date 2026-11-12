# Operations

## Testing migrations before they touch a server

The test database is built from `schema.rb`, not the legacy MyISAM/utf8mb3
schema. Passing the suite does not establish that production migrations are safe.

```bash
./script/rehearse-migrations.sh
```

This command contacts production. It copies table definitions and
`schema_migrations` versions, but no user records, into a uniquely named database
on the local Compose MySQL. It seeds duplicate users and runs pending migrations.
Coordinate the schema read with deployments and use a local Docker context.
The scratch database remains for inspection; the script prints its name and
a command to drop only that database. Never use `docker compose down -v` to
clean up a rehearsal on a volume shared with development or test databases.

A schema rehearsal is not a full-data restore or a completed cutover rehearsal.
The migration risks include:

- MyISAM's 1000-byte index limit rejects a utf8mb4 `varchar(255)` unique key,
  where [InnoDB allows 3072](https://dev.mysql.com/doc/refman/8.4/en/innodb-limits.html).
  So the charset conversion has to run *after* the InnoDB conversion.
- Converting utf8mb4 back to utf8mb3 risks corrupting 4-byte characters.
  `ConvertToUtf8mb4` is irreversible on purpose.

## Reloading beta from production

```bash
BETA_HOST=NEW_DROPLET_IP ./script/resync-beta.sh
```

Streams a database dump through the laptop and copies volume files directly
from production to beta. **It drops and recreates beta's database and deletes
beta-only volume files. Stop every beta writer first and keep a recoverable beta
backup if its contents matter.** Recreating the database prevents beta-only
tables, such as `active_storage_*`, surviving a reset of `schema_migrations`.

The script requires an explicit beta host, verified SSH host keys on the laptop
and beta, different machine IDs, mounted source and target volumes, and a
working agent-forwarded connection from beta to the same production machine.
Verify host-key fingerprints through a trusted channel before adding them to
`known_hosts`; do not disable strict checking. Forward your agent only to a
trusted beta host. Host and database names are restricted to safe characters;
volume paths must be direct mount points under `/mnt`.

`/etc/blackbook-live` blocks a resync. A failed marker check also blocks it.
**Create that marker on the new host before directing production traffic or
writers to it**, and never run a resync concurrently with cutover.

Dump, decompression and count-query failures stop the script. Any table row-count
mismatch is fatal, including while production is active; stop writers and repeat.
Matching counts do not verify row contents or snapshot consistency. A failure
after the drop can leave beta incomplete: keep it offline until a successful
reload and restore validation.

`--skip-lock-tables` avoids explicit table locks, not all blocking or server load.
MyISAM dumps can be inconsistent while writes continue. **For final cutover,
stop every production writer for the entire database and file copy.** A systemd
service's status alone does not establish that workers, cron jobs or other
clients have stopped. Migrations remain a separate, deliberate step.

## Backups and audit

```bash
script/audit-production.sh    # data reads; review reported errors
script/backup-production.sh   # database dump and private config copy
```

Both scripts contact production and require verified SSH host keys. The audit
does not modify application data, but reads can add load and it uses a temporary
credentials file. It avoids recursively walking the image tree; filesystem
usage is not an exact image-directory count or size.

The backup uses a private, unique destination and checks free space, retaining
an extra GiB above the estimated dump allowance. A file-size limit bounds the
dump; other processes can still consume disk concurrently. Invalid size results
stop the backup. The MyISAM dump locks tables and can block writes for its full
duration.

The script checks gzip integrity, a dump trailer and checksums, **not
restorability**. It does not copy the backup off the server or snapshot the
volume; it prints commands for those separate steps. Protect the local copy:
the database and config snapshot contain private data and secrets.

GML files and images are not archived to the root disk because this could
exhaust MySQL's free space. Take a separate attached-volume snapshot; a droplet
snapshot does not include attached volumes. Stop all writers and flush buffers,
keeping writes stopped across the database backup and volume snapshot for a
consistent recovery point. Restore into isolated local storage and validate
the database and files before trusting the backup.

### Local syntax checks only

These commands parse the scripts without executing them or contacting a server:

```bash
for script in audit-production backup-production rehearse-migrations resync-beta; do
  bash -n "script/$script.sh" || exit
done
```

Syntax checks do not establish operational safety or a successful production
rehearsal. Do not run the operational scripts themselves as a local smoke test.

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
volume does not have at roughly 35 GB used.

## Importing the TEMPT1 archive

```bash
bin/kamal tempt1-verify    # report only, writes nothing
bin/kamal tempt1-import
```

Or run the "Import TEMPT1 archive" workflow from the Actions tab, which does the
dry run first and only writes when you type IMPORT.

It attaches the eyetag images, repairs the two GML files MySQL truncated at
65535 bytes in 2009, and creates the tags that were never uploaded here. The 159
source files are not in this repo; they come from a pinned release tarball,
checked against a SHA256, and then each file is checked again against
`db/tempt1/manifest.tsv` as it is used.

Deliberately a rake task rather than a migration. It reaches the network, writes
Active Storage blobs, and is built to be re-run after a partial failure, which a
recorded migration version would take away.

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

- Duplicate logins and emails exist in production. `AddMissingUniqueIndexes`
  counts them first and skips those two indexes rather than failing, so the
  migration is safe to run before they are cleaned up.
  `script/rehearse-migrations.sh` prints the current counts.
- Notifications can refer to comments removed by `drop_comments_table`.
  `Notification.displayable` excludes these from `/activity` and user pages
  without deleting the notification rows.

## Rate limits

`TagsController` limits reads to 300 a minute and uploads to 30 an hour, per IP
address. Crossing either sends one email to the address in `AbuseMailer`, over
the same SES SMTP settings `exception_notification` uses. Alerts are capped at
one an hour per client and ten an hour overall, so a client hammering us cannot
turn into a mail flood.

The counters live in an in-memory store in the app process, not `Rails.cache`.
Two consequences worth knowing before reading a graph:

- **A deploy resets every counter.** A client that was being refused gets a
  clean slate the moment a new container takes over.
- **During the rollover both containers count separately**, so for a few seconds
  a client can get roughly double the allowance.

Neither matters for stopping abuse, and both avoid adding Redis or a migration.
If the limits ever need to be exact, that is the trade to revisit.

To change the numbers, edit the `rate_limit` calls in
`app/controllers/tags_controller.rb`. They were set without traffic data, so the
alert mail is the feedback loop: if a legitimate client keeps tripping, raise them.


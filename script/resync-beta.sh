#!/bin/bash
#
# Reload beta from production. This destroys beta's database and extra files.
# Stop all beta writers before running it.
#
# Moves two things:
#   the database, as a fresh mysqldump streamed into beta's MySQL
#   the volume files, rsynced prod -> beta directly so only changes travel
#
# Production data is only read, but dumping and counting can affect its load.
#
#   BETA_HOST=<new-droplet-ip> ./script/resync-beta.sh
#
# --skip-lock-tables avoids explicit table locks, not all blocking or load.
# MyISAM dumps are inconsistent while writes continue. For final cutover,
# stop every production writer for the whole database and volume copy.
#
set -euo pipefail

PROD_HOST="${PROD_HOST:-138.197.101.244}"
# No default. DigitalOcean recycles addresses, and this script drops a database
# as root on whatever host it is pointed at.
BETA_HOST="${BETA_HOST:-}"
DB_NAME="${DB_NAME:-blackbook_prod}"
VOL_SRC="${VOL_SRC:-/mnt/volume_nyc3_01}"
VOL_DEST="${VOL_DEST:-/mnt/blackbook_volume}"

step() { printf '\n\033[1m==> %s\033[0m\n' "$1"; }
die()  { echo "ERROR: $1" >&2; exit 1; }

[ -n "$BETA_HOST" ] || die "set BETA_HOST to the new droplet's IP"
for host in "$PROD_HOST" "$BETA_HOST"; do
  [[ "$host" =~ ^[a-zA-Z0-9][a-zA-Z0-9._-]*$ ]] || die "use an IPv4 address, hostname or SSH alias"
done
[[ "$DB_NAME" =~ ^[a-zA-Z0-9_]+$ ]] || die "invalid DB_NAME"
case "$DB_NAME" in mysql|sys|information_schema|performance_schema) die "refusing a system database";; esac
for path in "$VOL_SRC" "$VOL_DEST"; do
  [[ "$path" =~ ^/mnt/[a-zA-Z0-9_-]+$ ]] || die "volume paths must be direct mount points under /mnt"
done

umask 077
WORK_DIR=$(mktemp -d /tmp/blackbook-sync.XXXXXXXX)
# Keep control sockets private to this run.
SSH_OPTS=(-o BatchMode=yes -o StrictHostKeyChecking=yes -o ConnectTimeout=10
          -o ControlMaster=auto -o "ControlPath=$WORK_DIR/%C" -o ControlPersist=120)
cleanup() {
  ssh "${SSH_OPTS[@]}" -O exit "root@$PROD_HOST" >/dev/null 2>&1 || true
  ssh "${SSH_OPTS[@]}" -O exit "root@$BETA_HOST" >/dev/null 2>&1 || true
  rm -rf "$WORK_DIR"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

# PROD_HOST may be an alias from this laptop's ~/.ssh/config (.env sets it to
# one, and a dotenv shell plugin exports it). Beta pulls from production and
# has no such alias, so hand it the real address.
resolve() { ssh -G "root@$1" 2>/dev/null | awk '$1 == "hostname" { print $2 }'; }
PROD_ADDR=$(resolve "$PROD_HOST")
BETA_ADDR=$(resolve "$BETA_HOST")
[[ "$PROD_ADDR" =~ ^[a-zA-Z0-9][a-zA-Z0-9._-]*$ ]] || die "invalid resolved production address"
[[ "$BETA_ADDR" =~ ^[a-zA-Z0-9][a-zA-Z0-9._-]*$ ]] || die "invalid resolved beta address"
[ "$PROD_ADDR" != "$BETA_ADDR" ] || die "PROD_HOST and BETA_HOST are the same host"

prod() { ssh "${SSH_OPTS[@]}" "root@$PROD_HOST" "$@"; }
# Agent forwarding is what lets beta rsync from production with no key copied
# onto either server. It is on from beta's first connection because a session
# multiplexed onto a connection opened without it cannot add it later.
beta() { ssh "${SSH_OPTS[@]}" -o ForwardAgent=yes "root@$BETA_HOST" "$@"; }

step "Checks"
# ssh -G only expands SSH aliases; different DNS names can reach one machine.
prod_id=$(prod "cat /etc/machine-id") || die "cannot identify production"
beta_id=$(beta "cat /etc/machine-id") || die "cannot identify beta"
[[ "$prod_id" =~ ^[a-f0-9]{32}$ && "$beta_id" =~ ^[a-f0-9]{32}$ ]] || die "missing or invalid machine identity"
[ "$prod_id" != "$beta_id" ] || die "production and beta are the same machine"
beta "[ ! -e /etc/blackbook-live ] && [ ! -L /etc/blackbook-live ]" \
  || die "beta is marked live, or the live-marker check failed"

# rsync --delete below would happily fill beta's root disk with ~35GB of
# images if the block volume were not actually mounted. Refuse in that case.
beta "mountpoint -q '$VOL_DEST'" \
  || die "$VOL_DEST is not a mounted volume on beta. Attach and mount it first."

prod "mountpoint -q '$VOL_SRC' && [ -n \"\$(ls -A '$VOL_SRC')\" ]" \
  || die "$VOL_SRC is not a populated mounted volume on production"

# The volume step has beta pull from production. Prove that path now, before
# the database is dropped, rather than after.
pull_id=$(beta "ssh -o BatchMode=yes -o StrictHostKeyChecking=yes -o ConnectTimeout=10 root@$PROD_ADDR cat /etc/machine-id") \
  || die "beta cannot reach production with a verified host key and forwarded agent"
[ "$pull_id" = "$prod_id" ] || die "beta's production address reaches a different machine"

echo "production: $PROD_HOST  ->  beta: $BETA_HOST"
echo "Stop all beta writers now; final cutover also requires all production writers stopped."
echo "this DROPS and recreates $DB_NAME on beta, and mirrors $VOL_DEST onto it"
read -r -p "type the beta IP to continue: " confirm
[ "$confirm" = "$BETA_HOST" ] || die "not confirmed"

step "Database"
# Drop the whole database, not just the tables the dump names. Tables only beta
# has, like active_storage_*, would otherwise survive while schema_migrations
# is reset to production's, and the next migrate dies halfway on "table
# already exists". The app's grant is by database name, so it survives.
beta "[ ! -e /etc/blackbook-live ] && [ ! -L /etc/blackbook-live ] &&
  mountpoint -q '$VOL_DEST' && mysql --protocol=socket -e '
  DROP DATABASE IF EXISTS \`$DB_NAME\`;
  CREATE DATABASE \`$DB_NAME\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci'"

echo "dumping $DB_NAME from production and loading it into beta..."
# pipefail on the far side too. Without it a mysqldump that dies midway still
# exits 0 through gzip, and beta silently gets half a database.
prod "bash -o pipefail -c 'mysqldump --protocol=socket --skip-lock-tables --quick --routines --triggers $DB_NAME | gzip -1'" \
  | beta "bash -o pipefail -c 'gunzip | mysql --protocol=socket $DB_NAME'"

# Query failures must not look like matching empty output. Avoid process
# substitutions: diff does not propagate their exit statuses.
counts() {
  "$1" "DB='$DB_NAME' bash -s" <<'REMOTE'
set -euo pipefail
tables=$(mysql --protocol=socket -N -B -e "SELECT table_name FROM information_schema.tables WHERE table_schema='$DB' ORDER BY table_name")
[ -n "$tables" ] || { echo "no tables found" >&2; exit 1; }
while IFS= read -r t; do
  [[ "$t" =~ ^[a-zA-Z0-9_]+$ ]] || { echo "unsupported table name" >&2; exit 1; }
  count=$(mysql --protocol=socket -N -B "$DB" -e "SELECT COUNT(*) FROM \`$t\`")
  [[ "$count" =~ ^[0-9]+$ ]] || { echo "invalid row count" >&2; exit 1; }
  printf '%s %s\n' "$t" "$count"
done <<< "$tables"
REMOTE
}
counts prod > "$WORK_DIR/prod.counts"
counts beta > "$WORK_DIR/beta.counts"
diff "$WORK_DIR/prod.counts" "$WORK_DIR/beta.counts" \
  || die "row counts differ; stop all writers and repeat the sync before proceeding"
echo "loaded: table row counts match (not a content or snapshot consistency check)"

step "Volume files"
# rsync runs on beta pulling from production, so ~35GB never touches the laptop.
prod "mountpoint -q '$VOL_SRC'" || die "production volume is no longer mounted"
beta "[ ! -e /etc/blackbook-live ] && [ ! -L /etc/blackbook-live ] &&
  mountpoint -q '$VOL_DEST' && rsync -a --delete --exclude=/lost+found --info=stats2 \
  -e 'ssh -o BatchMode=yes -o StrictHostKeyChecking=yes -o ConnectTimeout=10' \
  'root@$PROD_ADDR:$VOL_SRC/' '$VOL_DEST/'"

step "Migrations"
# Production is still on the old schema, so the fresh dump arrives without any
# of this branch's migrations, and the app will 500 until they run. They are
# deliberately not run here: the pending set drops the comments table, and
# that should never happen as a side effect of a sync.
echo "the dump is production's schema, so the app needs migrating before it works."
echo "run the 'Migrate beta' workflow, or: bin/kamal migrate"

step "Done"
beta "mysql --protocol=socket -N '$DB_NAME' -e \"
  SELECT CONCAT(table_name, ': ', table_rows, ' rows, ', engine, ', ', table_collation)
  FROM information_schema.tables WHERE table_schema='$DB_NAME' ORDER BY table_name\""
echo
echo "Beta reload finished. Row counts alone do not prove a consistent copy."
echo "Before cutover, verify the restore with every writer stopped throughout the sync."

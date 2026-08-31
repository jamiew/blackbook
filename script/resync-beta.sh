#!/bin/bash
#
# Reload beta from live production data. Safe to run as often as you like while
# testing, and it is the same command you run one last time at cutover.
#
# Moves two things:
#   the database, as a fresh mysqldump streamed into beta's MySQL
#   the volume files, rsynced prod -> beta directly so only changes travel
#
# Production is only ever read. Nothing here writes to it.
#
#   ./script/resync-beta.sh
#
# The dump runs with --skip-lock-tables so it never blocks the live site.
# Production is still MyISAM, so that trades a consistent snapshot for zero
# impact, which is the right way round while testing. For the final cutover
# sync, stop the app on production first so nothing is mid-write.
#
set -euo pipefail

PROD_HOST="${PROD_HOST:-138.197.101.244}"
BETA_HOST="${BETA_HOST:-159.203.72.141}"
DB_NAME="${DB_NAME:-blackbook_prod}"
VOL_SRC="${VOL_SRC:-/mnt/volume_nyc3_01}"
VOL_DEST="${VOL_DEST:-/mnt/blackbook_volume}"

SSH_OPTS=(-o BatchMode=yes -o StrictHostKeyChecking=accept-new -o ConnectTimeout=10)

step() { printf '\n\033[1m==> %s\033[0m\n' "$1"; }
die()  { echo "ERROR: $1" >&2; exit 1; }

# The one mistake this script must never make.
[ "$PROD_HOST" != "$BETA_HOST" ] || die "PROD_HOST and BETA_HOST are the same host"

step "Checks"
ssh "${SSH_OPTS[@]}" "root@$PROD_HOST" true || die "cannot reach production at $PROD_HOST"
ssh "${SSH_OPTS[@]}" "root@$BETA_HOST" true || die "cannot reach beta at $BETA_HOST"

# rsync --delete below would happily fill beta's 80GB root disk with 36GB of
# images if the block volume were not actually mounted. Refuse in that case.
ssh "${SSH_OPTS[@]}" "root@$BETA_HOST" "mountpoint -q '$VOL_DEST'" \
  || die "$VOL_DEST is not a mounted volume on beta. Attach and mount it first."

ssh "${SSH_OPTS[@]}" "root@$PROD_HOST" "[ -d '$VOL_SRC' ] && [ -n \"\$(ls -A '$VOL_SRC')\" ]" \
  || die "$VOL_SRC is missing or empty on production"

echo "production: $PROD_HOST  ->  beta: $BETA_HOST"
echo "this DROPS and reloads $DB_NAME on beta, and mirrors $VOL_DEST onto it"
read -r -p "type the beta IP to continue: " confirm
[ "$confirm" = "$BETA_HOST" ] || die "not confirmed"

step "Database"
echo "dumping $DB_NAME from production and loading it into beta..."
ssh "${SSH_OPTS[@]}" "root@$PROD_HOST" \
  "mysqldump --skip-lock-tables --quick --routines --triggers '$DB_NAME' | gzip -1" \
  | ssh "${SSH_OPTS[@]}" "root@$BETA_HOST" \
    "gunzip | mysql '$DB_NAME'"
echo "loaded"

step "Volume files"
# rsync runs on beta pulling from production, so 36GB never touches the laptop.
# ssh -A forwards this laptop's agent, which is what lets beta authenticate to
# production without a key ever being copied onto either server.
ssh -A -o StrictHostKeyChecking=accept-new "root@$BETA_HOST" \
  "rsync -a --delete --info=stats2 \
     -e 'ssh -o StrictHostKeyChecking=accept-new' \
     'root@$PROD_HOST:$VOL_SRC/' '$VOL_DEST/'"

step "Migrations"
# Production is still on the old schema, so the fresh dump arrives without any
# of this branch's migrations, and the app will 500 until they run. They are
# deliberately not run here: the pending set drops a 301,076-row table, and
# that should never happen as a side effect of a sync.
echo "the dump is production's schema, so the app needs migrating before it works."
echo "run the 'Migrate beta' workflow, or: bin/kamal migrate"

step "Done"
ssh "${SSH_OPTS[@]}" "root@$BETA_HOST" "mysql -N '$DB_NAME' -e \"
  SELECT CONCAT(table_name, ': ', table_rows, ' rows, ', engine, ', ', table_collation)
  FROM information_schema.tables WHERE table_schema='$DB_NAME' ORDER BY table_name\""
echo
echo "Beta now holds a copy of production as of a moment ago."
echo "At cutover, stop production first so the dump is consistent."

#!/bin/bash
#
# Create a database dump and private config copy. A successful restore rehearsal
# and a separate volume snapshot are required before treating this as a backup.
#
# Creates on the server, under ~/blackbook-backups/<utc-timestamp>.<unique-id>/:
#   database.sql.gz       full mysqldump
#   config-snapshot/      the gitignored files a checkout would clobber
#   SHA256SUMS            checksums of both
#
# GML files and images are not archived on the root disk: their archive could
# exhaust space needed by MySQL. Snapshot the attached volume separately.
#
# It does NOT copy anything off the server or take the snapshot. It prints
# those commands for you to run, so both stay a deliberate human step.
#
# Usage:  ./script/backup-production.sh
#
set -euo pipefail

if [ -f ".env" ]; then
  while IFS= read -r line || [ -n "$line" ]; do
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    [[ -z "${line// }" ]] && continue
    [[ "$line" =~ ^[a-zA-Z_][a-zA-Z0-9_]*= ]] && export "${line?}"
  done < ".env"
fi

PROD_HOST="${PROD_HOST:-}"
PROD_USER="${PROD_USER:-}"
PROD_DB="${PROD_DB:-blackbook_production}"
PROD_APP_PATH="${PROD_APP_PATH:-}"

if [ -z "$PROD_HOST" ] || [ -z "$PROD_USER" ] || [ -z "$PROD_APP_PATH" ]; then
  echo "Set PROD_HOST, PROD_USER and PROD_APP_PATH in .env first." >&2
  exit 1
fi
[[ "$PROD_HOST" =~ ^[a-zA-Z0-9][a-zA-Z0-9._-]*$ &&
   "$PROD_USER" =~ ^[a-zA-Z0-9_][a-zA-Z0-9_-]*$ &&
   "$PROD_DB" =~ ^[a-zA-Z0-9_]+$ &&
   "$PROD_APP_PATH" =~ ^/[a-zA-Z0-9_./-]+$ ]] || {
  echo "Invalid production host, user, database or absolute app path." >&2
  exit 1
}

echo "Backing up $PROD_USER@$PROD_HOST:$PROD_APP_PATH"
echo "Run ./script/audit-production.sh first if you have not: it reports free disk."
echo

ssh -o BatchMode=yes -o StrictHostKeyChecking=yes "$PROD_USER@$PROD_HOST" "APP_PATH='$PROD_APP_PATH' DB_NAME='$PROD_DB' bash -s" <<'REMOTE'
set -euo pipefail
umask 077

cd "$APP_PATH"
STAMP=$(date -u +%Y%m%dT%H%M%SZ)
mkdir -p "$HOME/blackbook-backups"
DEST=$(mktemp -d "$HOME/blackbook-backups/$STAMP.XXXXXXXX")
STAMP=${DEST##*/}
echo "Writing to $DEST"

MYCNF=$(mktemp); chmod 600 "$MYCNF"
trap 'rm -f "$MYCNF"' EXIT

yaml_val() {
  local key="$1"
  local v
  v=$(awk '/^production:/{f=1;next} /^[^[:space:]]/{f=0} f' config/database.yml 2>/dev/null \
      | sed -n "s/^[[:space:]]*${key}:[[:space:]]*//p" | tr -d '"'"'" | head -1)
  [ -z "$v" ] && v=$(sed -n "s/^[[:space:]]*${key}:[[:space:]]*//p" config/database.yml 2>/dev/null | tr -d '"'"'" | head -1)
  echo "$v"
}

DB_FROM_YML=$(yaml_val database)
[ -n "$DB_FROM_YML" ] && DB_NAME="$DB_FROM_YML"
[[ "$DB_NAME" =~ ^[a-zA-Z0-9_]+$ ]] || { echo "Invalid database name in config." >&2; exit 1; }

cat > "$MYCNF" <<EOF
[client]
user=$(yaml_val username)
password=$(yaml_val password)
host=$(yaml_val host)
EOF

echo
echo "== 1/4 free space =="
# This is an estimate, not a guarantee. Reserve another GiB for MySQL and cap
# the dump file below the estimated allowance so it cannot consume all space.
need_kb=$(mysql --defaults-extra-file="$MYCNF" -N -B -e "
  SELECT CEIL(2 * SUM(DATA_LENGTH + INDEX_LENGTH) / 1024)
  FROM information_schema.TABLES WHERE TABLE_SCHEMA = '$DB_NAME'")
free_kb=$(df -Pk "$DEST" | awk 'NR==2 {print $4}')
[[ "$need_kb" =~ ^[0-9]+$ && "$free_kb" =~ ^[0-9]+$ && "$need_kb" -gt 0 ]] \
  || { echo "FATAL: cannot determine a positive dump size and free space." >&2; exit 1; }
echo "estimated dump allowance ${need_kb} KB plus 1048576 KB reserve; available ${free_kb} KB"
if [ "$free_kb" -lt "$((need_kb + 1048576))" ]; then
  echo "FATAL: not enough free disk for the dump and reserve."
  rmdir "$DEST"
  exit 1
fi

echo
echo "== 2/4 database dump: $DB_NAME =="
# NOT --single-transaction. That only gives a consistent snapshot on InnoDB, and
# these tables are still MyISAM until the convert_tables_to_innodb migration runs.
# --lock-tables (mysqldump's default via --opt) is what actually gives MyISAM
# consistency, at the cost of blocking writes for the duration of the dump.
# --no-tablespaces avoids needing the PROCESS privilege on MySQL 8.
(
  # Bash uses 1024-byte units normally, 512 in POSIX mode; choose the smaller
  # allowance in either mode. A larger-than-expected dump fails, not fills disk.
  ulimit -f "$((need_kb / 2))"
  mysqldump --defaults-extra-file="$MYCNF" \
    --lock-tables --no-tablespaces --routines --triggers --events \
    "$DB_NAME" | gzip -9 > "$DEST/database.sql.gz"
)

echo "== 3/4 checking dump integrity (not a restore test) =="
gzip -t "$DEST/database.sql.gz"
tables=$(gzip -dc "$DEST/database.sql.gz" | awk '/^CREATE TABLE/ {n++} END {print n+0}')
complete=$(gzip -dc "$DEST/database.sql.gz" | tail -5 | awk '/^-- Dump completed/ {n++} END {print n+0}')
echo "CREATE TABLE statements: $tables"
if [ "$complete" -lt 1 ]; then
  echo "FATAL: dump has no 'Dump completed' trailer. It is truncated. Stopping."
  exit 1
fi
echo "dump trailer present: OK"

echo
echo "== 4/4 gitignored config the checkout would clobber =="
# main tracks config/database.yml; the deployed branch ignores it. Git overwrites
# ignored files silently on checkout, so this snapshot is the only copy afterwards.
mkdir -p "$DEST/config-snapshot"; chmod 700 "$DEST/config-snapshot"
for f in config/database.yml config/master.key config/secrets.yml .env; do
  if [ -f "$f" ]; then
    cp -a "$f" "$DEST/config-snapshot/"
    echo "saved $f"
  fi
done
chmod -R go-rwx "$DEST/config-snapshot"

echo
echo "== checksums =="
cd "$DEST" && find . -type f ! -name SHA256SUMS -exec sha256sum {} + > SHA256SUMS
du -sh "$DEST"
ls -lh "$DEST"

echo
echo "Dump and config copy complete (restore not tested): $DEST"
echo "It is still only on this server. Pull it down before you migrate anything."
echo "STAMP=$STAMP"
REMOTE

echo
echo "Now copy it off the server (replace <stamp> with the STAMP printed above):"
echo "  mkdir -p ./backups && chmod 700 ./backups"
echo "  scp -r $PROD_USER@$PROD_HOST:~/blackbook-backups/<stamp> ./backups/"
echo "  (cd ./backups/<stamp> && shasum -a 256 -c SHA256SUMS)"
echo
echo "Then rehearse the restore on an isolated local MySQL, not a shared server."
echo "Use a fresh scratch database; stop if CREATE DATABASE fails. Check the"
echo "pipeline with pipefail and inspect restored tables before dropping only"
echo "that scratch database. Never use docker compose down -v on shared data."
echo
echo "For GML files and images, snapshot the block volume separately."
echo "Stop all writers and flush filesystem buffers before taking the snapshot."
echo "Keep writers stopped across the database backup and volume snapshot for"
echo "a consistent recovery point. Check current provider pricing first:"
echo "  doctl compute volume list"
echo "  doctl compute volume snapshot <volume-id> --snapshot-name blackbook-<stamp>"
echo "A droplet snapshot does not include attached volumes, so this one is separate."

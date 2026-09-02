#!/bin/bash
#
# Phase 0: take a verified, restorable backup before anything else happens.
# This is the actual insurance. Git care is not a substitute for it.
#
# Creates on the server, under ~/blackbook-backups/<utc-timestamp>/:
#   database.sql.gz       full mysqldump
#   gml-data.tar.gz       the GML files (follows the data symlink)
#   public-system.tar.gz  paperclip images
#   config-snapshot/      the gitignored files a checkout would clobber
#   SHA256SUMS            checksums of all of the above
#
# It does NOT copy anything off the server. It prints the scp command for you
# to run, so the transfer stays a deliberate human step.
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

echo "Backing up $PROD_USER@$PROD_HOST:$PROD_APP_PATH"
echo "Run ./script/audit-production.sh first if you have not: it reports free disk."
echo

ssh "$PROD_USER@$PROD_HOST" "APP_PATH='$PROD_APP_PATH' DB_NAME='$PROD_DB' bash -s" <<'REMOTE'
set -euo pipefail

cd "$APP_PATH"
STAMP=$(date -u +%Y%m%dT%H%M%SZ)
DEST=~/blackbook-backups/"$STAMP"
mkdir -p "$DEST"
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

cat > "$MYCNF" <<EOF
[client]
user=$(yaml_val username)
password=$(yaml_val password)
host=$(yaml_val host)
EOF

echo
echo "== 1/5 database dump: $DB_NAME =="
# NOT --single-transaction. That only gives a consistent snapshot on InnoDB, and
# these tables are still MyISAM until the convert_tables_to_innodb migration runs.
# --lock-tables (mysqldump's default via --opt) is what actually gives MyISAM
# consistency, at the cost of briefly blocking writes.
# --no-tablespaces avoids needing the PROCESS privilege on MySQL 8.
mysqldump --defaults-extra-file="$MYCNF" \
  --lock-tables --no-tablespaces --routines --triggers --events \
  "$DB_NAME" | gzip -9 > "$DEST/database.sql.gz"

echo "== 2/5 verifying the dump is readable and complete =="
gzip -t "$DEST/database.sql.gz"
tables=$(gzip -dc "$DEST/database.sql.gz" | grep -c '^CREATE TABLE' || true)
complete=$(gzip -dc "$DEST/database.sql.gz" | tail -5 | grep -c 'Dump completed' || true)
echo "CREATE TABLE statements: $tables"
if [ "$complete" -lt 1 ]; then
  echo "FATAL: dump has no 'Dump completed' trailer. It is truncated. Stopping."
  exit 1
fi
echo "dump trailer present: OK"

echo
echo "== 3/5 GML data =="
DATA_REAL=$(readlink -f data)
echo "data/ resolves to $DATA_REAL"
tar czf "$DEST/gml-data.tar.gz" -C "$(dirname "$DATA_REAL")" "$(basename "$DATA_REAL")"
echo "files archived: $(tar tzf "$DEST/gml-data.tar.gz" | wc -l)"

echo
echo "== 4/5 paperclip images =="
if [ -d public/system ]; then
  tar czf "$DEST/public-system.tar.gz" public/system
  echo "files archived: $(tar tzf "$DEST/public-system.tar.gz" | wc -l)"
else
  echo "public/system missing, skipping"
fi

echo
echo "== 5/5 gitignored config the checkout would clobber =="
# main tracks config/database.yml; the deployed branch ignores it. Git overwrites
# ignored files silently on checkout, so this snapshot is the only copy afterwards.
mkdir -p "$DEST/config-snapshot"; chmod 700 "$DEST/config-snapshot"
for f in config/database.yml config/master.key config/secrets.yml .env; do
  [ -f "$f" ] && cp -a "$f" "$DEST/config-snapshot/" && echo "saved $f"
done
chmod -R go-rwx "$DEST/config-snapshot"

echo
echo "== checksums =="
cd "$DEST" && find . -type f ! -name SHA256SUMS -exec sha256sum {} + > SHA256SUMS
du -sh "$DEST"
ls -lh "$DEST"

echo
echo "Backup complete: $DEST"
echo "It is still only on this server. Pull it down before you migrate anything."
echo "STAMP=$STAMP"
REMOTE

echo
echo "Now copy it off the server (replace <stamp> with the STAMP printed above):"
echo "  mkdir -p ./backups"
echo "  scp -r $PROD_USER@$PROD_HOST:~/blackbook-backups/<stamp> ./backups/"
echo "  (cd ./backups/<stamp> && sha256sum -c SHA256SUMS)"
echo
echo "Then rehearse the restore into a scratch database before trusting it:"
echo "  mysql -u root -e 'CREATE DATABASE blackbook_rehearsal'"
echo "  gzip -dc ./backups/<stamp>/database.sql.gz | mysql -u root blackbook_rehearsal"

#!/bin/bash
#
# Read-only production audit. Makes no writes: no migrations, no restarts,
# no git operations, no file changes. Safe to run any time.
#
# Answers three questions before we touch the deploy:
#   1. What code is actually running on the VPS?
#   2. Will `git reset --hard` clobber anything the server holds locally?
#   3. Will the 5 pending migrations abort partway through?
#
# Usage:  ./script/audit-production.sh              # uses .env
#         ./script/audit-production.sh > audit.txt  # keep a copy to diff later
#
set -euo pipefail

# Same .env convention as script/sync-production.sh
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
  echo "The old ./deploy script uses the ssh alias 'blackbook' and path ~/blackbook/," >&2
  echo "so PROD_APP_PATH is probably /home/rails/blackbook (confirm before running)." >&2
  exit 1
fi

echo "Auditing $PROD_USER@$PROD_HOST:$PROD_APP_PATH (read-only)"

ssh "$PROD_USER@$PROD_HOST" "APP_PATH='$PROD_APP_PATH' DB_NAME='$PROD_DB' bash -s" <<'REMOTE'
# Deliberately NOT set -e: every section must run even if an earlier one fails.
# (This is the exact bug in ./deploy, where a failed reset still reports success.)
set -uo pipefail

section() { printf '\n========== %s ==========\n' "$1"; }
have()    { command -v "$1" >/dev/null 2>&1; }

section "HOST"
hostname; uname -srm; uptime; date -u

section "CHECKOUT"
if ! cd "$APP_PATH" 2>/dev/null; then
  echo "FATAL: $APP_PATH does not exist. Find the real path with: ls -d ~/*/; exit"
  exit 1
fi
echo "path:     $(pwd -P)"
echo "branch:   $(git rev-parse --abbrev-ref HEAD 2>/dev/null)"
echo "HEAD:     $(git rev-parse HEAD 2>/dev/null)"
echo "last:     $(git log -1 --format='%ci %h %s' 2>/dev/null)"
echo
echo "-- remotes --"; git remote -v
echo
echo "-- THE DEPLOY BUG: does origin/master still resolve here? --"
if git rev-parse --verify --quiet origin/master >/dev/null; then
  echo "YES: origin/master = $(git rev-parse origin/master)"
  echo "     -> stale ref never pruned. './deploy' has been resetting to this old"
  echo "        commit on every run, silently pinning prod. Confirm with the date:"
  git log -1 --format='       %ci %h %s' origin/master
else
  echo "no: origin/master is gone"
  echo "     -> './deploy' git reset fails, script continues anyway, code never updates."
fi
echo "origin/main: $(git rev-parse --verify --quiet origin/main || echo 'NOT FETCHED')"
echo
echo "-- local drift (uncommitted/untracked, ignored files excluded) --"
drift=$(git status --porcelain 2>/dev/null | wc -l)
echo "changed paths: $drift"
git status --porcelain 2>/dev/null | head -40

section "RUNTIME"
echo ".ruby-version: $(cat .ruby-version 2>/dev/null)"
echo "ruby on PATH:  $(ruby -v 2>/dev/null || echo none)"
for rb in ~/.rbenv/shims/ruby /usr/local/bin/ruby /usr/bin/ruby; do
  [ -x "$rb" ] && echo "  $rb -> $("$rb" -v 2>/dev/null)"
done
echo "-- rbenv versions installed (need 3.4.5 for main) --"
if have rbenv; then rbenv versions; elif [ -x ~/.rbenv/bin/rbenv ]; then ~/.rbenv/bin/rbenv versions; else echo "rbenv not found"; fi
echo "bundler: $(~/.rbenv/shims/bundle -v 2>/dev/null || bundle -v 2>/dev/null || echo none)"
echo "-- Gemfile rails/ruby pins --"
grep -E "^(ruby|gem 'rails'|gem \"rails\")" Gemfile 2>/dev/null

section "CONFIG FILES PRESENT (existence and mode only, never contents)"
for f in config/database.yml config/master.key config/credentials.yml.enc config/secrets.yml .env; do
  if [ -f "$f" ]; then
    echo "present  $f  mode=$(stat -c '%a' "$f" 2>/dev/null || stat -f '%Lp' "$f" 2>/dev/null)"
  else
    echo "ABSENT   $f"
  fi
done
echo
echo "NOTE: main tracks config/database.yml but the deployed branch gitignores it."
echo "      Git silently overwrites IGNORED files on checkout, so a reset to main"
echo "      will replace the server's copy. main's production block is only:"
echo "        url: <%= ENV['DATABASE_URL'] %>"
echo "      So DATABASE_URL must exist in the service environment before cutover."
echo
echo "-- env var NAMES referenced by the systemd unit (names only, no values) --"
systemctl cat blackbook4 --no-pager 2>/dev/null | grep -E '^EnvironmentFile=' || true
systemctl cat blackbook4 --no-pager 2>/dev/null | grep -oE '^Environment=[A-Za-z_]+' | cut -d= -f2 || true

section "GML DATA"
ls -ld data 2>/dev/null || echo "no data/ entry"
echo "resolves to: $(readlink -f data 2>/dev/null || echo 'N/A')"
echo "*.gml files: $(find data/ -maxdepth 1 -name '*.gml' 2>/dev/null | wc -l)"
echo "zero-byte:   $(find data/ -maxdepth 1 -name '*.gml' -size 0 2>/dev/null | wc -l)"
echo "total size:  $(du -shL data/ 2>/dev/null | cut -f1)"
echo
echo "-- paperclip images --"
# -L follows the symlink: public/system is usually a link to the block volume,
# and plain `find` counts 0 files there while `du -L` reports the real size.
echo "public/system files: $(find -L public/system -type f 2>/dev/null | wc -l)"
echo "public/system size:  $(du -shL public/system 2>/dev/null | cut -f1)"

section "DISK (InnoDB conversion needs ~2x the largest table free)"
echo "-- app root and MySQL datadir --"
df -h .
echo
echo "-- block volume(s) holding GML data and images --"
for p in data public/system; do
  real=$(readlink -f "$p" 2>/dev/null) || continue
  [ -n "$real" ] && echo "$p -> $real" && df -h "$real"
done
echo
echo "-- inodes (76k+ small GML files make these matter) --"
df -ih .

section "MYSQL"
# Pull credentials out of the production block of database.yml into a 0600 temp
# file. Same approach as script/sync-production.sh: never puts a password on a
# command line or in the output.
MYCNF=$(mktemp); chmod 600 "$MYCNF"
trap 'rm -f "$MYCNF"' EXIT

# Look in the production: block first, then anywhere (values often live in &default)
yaml_val() {
  local key="$1"
  local v
  v=$(awk '/^production:/{f=1;next} /^[^[:space:]]/{f=0} f' config/database.yml 2>/dev/null \
      | sed -n "s/^[[:space:]]*${key}:[[:space:]]*//p" | tr -d '"'"'" | head -1)
  [ -z "$v" ] && v=$(sed -n "s/^[[:space:]]*${key}:[[:space:]]*//p" config/database.yml 2>/dev/null | tr -d '"'"'" | head -1)
  echo "$v"
}

DB_USER=$(yaml_val username)
DB_PASS=$(yaml_val password)
DB_HOST=$(yaml_val host)
DB_FROM_YML=$(yaml_val database)
[ -n "$DB_FROM_YML" ] && DB_NAME="$DB_FROM_YML"

cat > "$MYCNF" <<EOF
[client]
user=${DB_USER:-root}
password=${DB_PASS:-}
host=${DB_HOST:-127.0.0.1}
EOF

echo "database: $DB_NAME (user resolved from database.yml, password not shown)"
q() { mysql --defaults-extra-file="$MYCNF" -N -B "$DB_NAME" -e "$1" 2>&1; }

echo "server version: $(q 'SELECT VERSION();')"

echo
echo "-- tables: engine, rows, size --"
mysql --defaults-extra-file="$MYCNF" -t "$DB_NAME" -e "
  SELECT TABLE_NAME, ENGINE, TABLE_ROWS,
         ROUND(DATA_LENGTH/1024/1024) AS data_mb,
         ROUND(INDEX_LENGTH/1024/1024) AS index_mb
  FROM information_schema.TABLES
  WHERE TABLE_SCHEMA = DATABASE() ORDER BY DATA_LENGTH DESC;" 2>&1

echo
echo "-- migration state --"
echo "applied migrations: $(q 'SELECT COUNT(*) FROM schema_migrations;')"
echo "latest version:     $(q 'SELECT MAX(version) FROM schema_migrations;')"
echo "which of the 5 pending are already applied:"
q "SELECT version FROM schema_migrations WHERE version IN
   ('20250821231341','20250919154715','20250919160811','20251204000001','20251204175129');"
echo "(empty above = all 5 still pending, as expected)"

echo
echo "-- MIGRATION BLOCKERS: duplicates that abort a UNIQUE index build --"
# users.login/email mirror the migration's own check, which is what decides
# whether it skips that index. The rest exclude NULLs, because MySQL treats
# NULLs as distinct in a unique index and they cannot actually collide.
echo "dup users.login:            $(q 'SELECT COUNT(*) FROM (SELECT login FROM users GROUP BY login HAVING COUNT(*)>1) x;')  (guarded, migration skips)"
echo "dup users.email:            $(q 'SELECT COUNT(*) FROM (SELECT email FROM users GROUP BY email HAVING COUNT(*)>1) x;')  (guarded, migration skips)"
echo "dup favorites triple:       $(q 'SELECT COUNT(*) FROM (SELECT user_id,object_id,object_type FROM favorites WHERE user_id IS NOT NULL AND object_id IS NOT NULL AND object_type IS NOT NULL GROUP BY user_id,object_id,object_type HAVING COUNT(*)>1) x;')  <-- UNGUARDED, aborts migration"
echo "dup likes triple:           $(q 'SELECT COUNT(*) FROM (SELECT user_id,object_id,object_type FROM likes WHERE user_id IS NOT NULL AND object_id IS NOT NULL AND object_type IS NOT NULL GROUP BY user_id,object_id,object_type HAVING COUNT(*)>1) x;')  <-- UNGUARDED, aborts migration"
echo "dup visualizations.name:    $(q 'SELECT COUNT(*) FROM (SELECT name FROM visualizations WHERE name IS NOT NULL GROUP BY name HAVING COUNT(*)>1) x;')  <-- UNGUARDED, aborts migration"

echo
echo "-- data about to be destroyed by the pending migrations --"
echo "comments table exists: $(q "SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='comments';")"
echo "comments rows (drop_comments_table deletes ALL of these, permanently): $(q 'SELECT COUNT(*) FROM comments;')"
echo "tags.ipfs_hash non-null (remove_ipfs_from_tags drops this column): $(q 'SELECT COUNT(*) FROM tags WHERE ipfs_hash IS NOT NULL;')"

echo
echo "-- row counts --"
for t in tags users favorites likes visualizations notifications; do
  echo "$t: $(q "SELECT COUNT(*) FROM $t;")"
done

section "SERVICES"
systemctl status blackbook4 --no-pager 2>&1 | head -15
echo
echo "-- redis --"
if have redis-cli; then redis-cli ping 2>&1; else echo "redis-cli not installed"; fi
systemctl is-active redis redis-server 2>&1 | head -2
echo
echo "-- listening sockets --"
ss -lntp 2>/dev/null | head -20 || netstat -lntp 2>/dev/null | head -20

section "DONE"
echo "Nothing was modified. Review MIGRATION BLOCKERS above before any deploy."
REMOTE

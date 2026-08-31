#!/bin/bash
#
# Run the pending migrations against a throwaway copy of production's real
# schema, on the same MySQL version the server runs. Nothing else in the repo
# tests this, and it is where the expensive surprises live: production is still
# MyISAM and utf8mb3, which the test database has never been.
#
# It found two things worth the effort:
#   MyISAM's 1000-byte index limit rejects a utf8mb4 varchar(255) unique key,
#   so table engine order matters
#   rolling utf8mb4 back to utf8mb3 corrupts 4-byte characters silently
#
#   ./script/rehearse-migrations.sh
#
# Schema only. No production rows are ever copied to this machine.
#
set -euo pipefail

PROD_HOST="${PROD_HOST:-138.197.101.244}"
DB_NAME="${DB_NAME:-blackbook_prod}"
PORT="${PORT:-13306}"
WORK_DB=blackbook_rehearsal

SSH_OPTS=(-o BatchMode=yes -o StrictHostKeyChecking=accept-new -o ConnectTimeout=10)
MYSQL=(docker compose exec -T mysql mysql)

step() { printf '\n\033[1m==> %s\033[0m\n' "$1"; }
die()  { echo "ERROR: $1" >&2; exit 1; }

cd "$(dirname "$0")/.."

step "MySQL 8.4"
docker compose up -d mysql
until docker compose exec -T mysql mysqladmin ping -h127.0.0.1 --silent >/dev/null 2>&1; do
  sleep 2
done
"${MYSQL[@]}" -N -e "SELECT CONCAT('running MySQL ', VERSION())"

step "Production schema"
# --no-data is what keeps this safe to run whenever you like. Table
# definitions carry the MyISAM engine and utf8mb3 charset the migrations have
# to cope with; the rows are irrelevant to that.
ssh "${SSH_OPTS[@]}" "root@$PROD_HOST" \
  "mysqldump --no-data --skip-comments '$DB_NAME'" > /tmp/rehearsal-schema.sql \
  || die "could not read schema from production"

ssh "${SSH_OPTS[@]}" "root@$PROD_HOST" \
  "mysqldump --no-create-info --skip-comments '$DB_NAME' schema_migrations" > /tmp/rehearsal-versions.sql \
  || die "could not read schema_migrations from production"

"${MYSQL[@]}" -e "DROP DATABASE IF EXISTS $WORK_DB; CREATE DATABASE $WORK_DB"
"${MYSQL[@]}" "$WORK_DB" < /tmp/rehearsal-schema.sql
"${MYSQL[@]}" "$WORK_DB" < /tmp/rehearsal-versions.sql

echo "loaded production's schema as it stands today:"
"${MYSQL[@]}" -N "$WORK_DB" -e "
  SELECT CONCAT('  ', table_name, ': ', engine, ', ', table_collation)
  FROM information_schema.tables WHERE table_schema='$WORK_DB' ORDER BY table_name"

step "Duplicate rows that change what the migrations do"
# AddMissingUniqueIndexes skips the users indexes when duplicates exist, so
# whether that branch runs is a property of production data, not of the code.
ssh "${SSH_OPTS[@]}" "root@$PROD_HOST" "mysql -N '$DB_NAME' -e '
  SELECT CONCAT(\"  duplicate logins: \", COUNT(*)) FROM (SELECT 1 FROM users GROUP BY login HAVING COUNT(*)>1) a;
  SELECT CONCAT(\"  duplicate emails: \", COUNT(*)) FROM (SELECT 1 FROM users GROUP BY email HAVING COUNT(*)>1) b;'"

# Seed one duplicate pair so the skip branch is actually exercised here. With
# an empty users table the migration takes the other path and proves nothing.
"${MYSQL[@]}" "$WORK_DB" -e "
  INSERT INTO users (login,email,crypted_password,password_salt,persistence_token,perishable_token,login_count)
  VALUES ('dup','dup@example.com','x','x','t1','p1',0),('dup','dup@example.com','x','x','t2','p2',0)"

step "Migrating"
RAILS_ENV=production \
SECRET_KEY_BASE=rehearsal-only-not-a-real-key \
DATABASE_URL="mysql2://root@127.0.0.1:$PORT/$WORK_DB" \
  bundle exec rails db:migrate

step "Result"
"${MYSQL[@]}" -N "$WORK_DB" -e "
  SELECT CONCAT('  ', table_name, ': ', engine, ', ', table_collation)
  FROM information_schema.tables WHERE table_schema='$WORK_DB' ORDER BY table_name"

# The point of the utf8mb4 migration, asserted rather than assumed. The emoji
# goes in as a hex literal because neither the shell nor MySQL would read a
# \xF0 escape as the byte it looks like.
"${MYSQL[@]}" "$WORK_DB" -e \
  "INSERT INTO tags (title, slug) VALUES (CONCAT('emoji ', _utf8mb4 0xF09F8EA8), 'rehearsal-emoji')" >/dev/null

read -r bytes chars <<<"$("${MYSQL[@]}" -N "$WORK_DB" -e \
  "SELECT LENGTH(title), CHAR_LENGTH(title) FROM tags WHERE slug='rehearsal-emoji'")"

# 7 characters in 10 bytes is the whole point: the emoji is one character
# occupying four bytes, which utf8mb3 could never have stored.
[ "$bytes" = "10" ] && [ "$chars" = "7" ] \
  || die "4-byte characters did not survive: $bytes bytes / $chars chars, wanted 10 / 7"
echo "  4-byte characters store correctly ($bytes bytes, $chars characters)"

echo
echo "Rehearsal passed. Drop the database with: docker compose down -v"

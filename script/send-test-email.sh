#!/usr/bin/env bash
#
# Send one real email through the production mail settings, so you find out
# whether SES accepts our sender here rather than from a silent bounce.
#
#   ./script/send-test-email.sh                   # to jamie@jamiedubs.com
#   ./script/send-test-email.sh you@example.com
#
# Runs with RAILS_ENV=production because that is the only environment wired to
# SES, but points DATABASE_URL at the local MySQL from compose.yaml. It reads no
# production data and writes nothing anywhere. Safe to re-run.
#
# Needs the credentials key, either as config/master.key or RAILS_MASTER_KEY.
# In a git worktree config/master.key is absent, since it is gitignored and
# lives only in the main checkout.
#
# Note that a new SES account is sandboxed and can only send to addresses you
# have verified in the SES console. A rejection naming the recipient means the
# sender is fine and the recipient is not verified.

set -euo pipefail

TO="${1:-jamie@jamiedubs.com}"
cd "$(dirname "$0")/.."

if [ ! -f config/master.key ] && [ -z "${RAILS_MASTER_KEY:-}" ]; then
  echo "No credentials key. Either run this from the main checkout, or:" >&2
  echo "  RAILS_MASTER_KEY=\$(cat /path/to/blackbook/config/master.key) $0 $TO" >&2
  exit 1
fi

export RAILS_ENV=production
# Local MySQL from compose.yaml, never production.
export DATABASE_URL="${DATABASE_URL:-mysql2://root@127.0.0.1:${MYSQL_PORT:-13306}/blackbook_dev}"
# The production config only reads this to decide whether to serve static files.
export RAILS_SERVE_STATIC_FILES=false

exec bin/rails runner - "$TO" <<'RUBY'
to = ARGV.first

ses = Rails.application.credentials.ses
if ses.blank?
  abort "No `ses` key in credentials, so ActionMailer would fall back to sendmail " \
        "and this would prove nothing. Add it with: bin/rails credentials:edit"
end

from = ActionMailer::Base.default_params[:from]
puts "delivery_method: #{ActionMailer::Base.delivery_method}"
puts "smtp host:       #{ActionMailer::Base.smtp_settings[:address]}:#{ActionMailer::Base.smtp_settings[:port]}"
puts "from:            #{from}"
puts "to:              #{to}"
puts

mail = ActionMailer::Base.mail(
  to: to,
  subject: "[blackbook] SES test #{Time.zone.now.iso8601}",
  body: <<~BODY
    Sent by script/send-test-email.sh to check that SES accepts our sender.

    from: #{from}
    host: #{Socket.gethostname}
    time: #{Time.zone.now}

    If you are reading this, the sender address is verified and rate limit
    alerts from AbuseMailer will arrive too.
  BODY
)

mail.deliver_now
puts "Sent. raise_delivery_errors is on, so no exception means SES accepted it."
RUBY

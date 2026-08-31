#!/bin/bash
#
# Provision a fresh Ubuntu droplet to run blackbook. Run it ON the droplet, as
# root, on first boot. Safe to re-run: every step checks before it acts.
#
#   scp script/provision-droplet.sh root@<new-droplet-ip>:
#   ssh root@<new-droplet-ip> 'APP_DOMAIN=beta.000000book.com bash provision-droplet.sh'
#
# It does NOT touch the block volume's contents, restore the database, or deploy
# the app. Those are deliberate steps you run afterwards, listed at the end.
#
set -euo pipefail

APP_DOMAIN="${APP_DOMAIN:?set APP_DOMAIN, e.g. beta.000000book.com}"
HOSTNAME_SHORT="${HOSTNAME_SHORT:-blackbook-${APP_DOMAIN%%.*}}"
APP_USER="${APP_USER:-rails}"
APP_DIR="${APP_DIR:-/home/$APP_USER/blackbook}"
RUBY_VERSION="${RUBY_VERSION:-3.4.5}"
DB_NAME="${DB_NAME:-blackbook_prod}"
DB_USER="${DB_USER:-blackbook}"
AUTH_USER="${AUTH_USER:-blackbook}"
# Deliberately no default: this repo is public. Pass AUTH_PASS=... or take the
# random one the script prints on first run.
AUTH_PASS="${AUTH_PASS:-}"
ENV_FILE=/etc/blackbook.env

[ "$(id -u)" -eq 0 ] || { echo "Run as root"; exit 1; }

step() { printf '\n\033[1m==> %s\033[0m\n' "$1"; }

step "Hostname"
# Distinct from the laptop, and matched by script/setup-server-shell.sh so the
# prompt and tmux bar say the same thing.
hostnamectl set-hostname "$HOSTNAME_SHORT"
grep -q "$HOSTNAME_SHORT" /etc/hosts || echo "127.0.1.1 $HOSTNAME_SHORT" >> /etc/hosts
echo "$HOSTNAME_SHORT"

step "System packages"
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get upgrade -y -qq
# libyaml-dev is not optional: psych fails to build without it on Ruby 3.4.
apt-get install -y -qq \
  build-essential autoconf bison patch rustc \
  libssl-dev libyaml-dev libreadline-dev zlib1g-dev libncurses-dev libffi-dev libgdbm-dev \
  libmysqlclient-dev libvips42 imagemagick \
  git curl ufw nginx mysql-server certbot python3-certbot-nginx \
  apache2-utils unattended-upgrades tmux
timedatectl set-timezone Etc/UTC
dpkg-reconfigure -f noninteractive unattended-upgrades

step "Firewall"
ufw allow OpenSSH >/dev/null
ufw allow 'Nginx Full' >/dev/null
ufw --force enable >/dev/null
ufw status

step "App user: $APP_USER"
if ! id -u "$APP_USER" >/dev/null 2>&1; then
  adduser --disabled-password --gecos "" "$APP_USER"
  usermod -aG sudo "$APP_USER"
  install -d -m 700 -o "$APP_USER" -g "$APP_USER" "/home/$APP_USER/.ssh"
  # Reuse the key you logged in with, so you can ssh straight in as $APP_USER
  if [ -f /root/.ssh/authorized_keys ]; then
    install -m 600 -o "$APP_USER" -g "$APP_USER" \
      /root/.ssh/authorized_keys "/home/$APP_USER/.ssh/authorized_keys"
  fi
fi
echo "$APP_USER ready"

step "rbenv and Ruby $RUBY_VERSION"
sudo -u "$APP_USER" bash <<RBENV
set -euo pipefail
# Start in the app user's home. sudo keeps root's cwd of /root, which
# $APP_USER cannot read, and ruby-build's popd back to it fails after a
# successful make install, rolling the whole build back.
cd "\$HOME"
# Ubuntu 26.04 mounts /tmp as a tmpfs at half of RAM, so 2GB on this box.
# ruby-build defaults there and dies linking libruby-static.a with "Disk quota
# exceeded", and because tmpfs is RAM it also steals memory from the compile.
# 24.04 left /tmp on disk, which is why this only appears on 26.04.
export TMPDIR="\$HOME/.rbenv-build-tmp"
mkdir -p "\$TMPDIR"
export RBENV_ROOT="\$HOME/.rbenv"
[ -d "\$RBENV_ROOT" ] || git clone -q https://github.com/rbenv/rbenv.git "\$RBENV_ROOT"
[ -d "\$RBENV_ROOT/plugins/ruby-build" ] || \
  git clone -q https://github.com/rbenv/ruby-build.git "\$RBENV_ROOT/plugins/ruby-build"
git -C "\$RBENV_ROOT/plugins/ruby-build" pull -q
export PATH="\$RBENV_ROOT/bin:\$RBENV_ROOT/shims:\$PATH"
if ! rbenv versions --bare | grep -qx "$RUBY_VERSION"; then
  echo "Building Ruby $RUBY_VERSION, this takes a few minutes..."
  rbenv install "$RUBY_VERSION"
fi
rbenv global "$RUBY_VERSION"
gem install bundler --no-document --silent

# The systemd unit calls the shim by absolute path, so the service runs without
# this. Humans do not: every manual step below, and script/resync-beta.sh, run
# as $APP_USER and would otherwise get "bundle: command not found".
if ! grep -q RBENV_ROOT "\$HOME/.profile" 2>/dev/null; then
  cat >> "\$HOME/.profile" <<'PROFILE'

export RBENV_ROOT="\$HOME/.rbenv"
export PATH="\$RBENV_ROOT/bin:\$RBENV_ROOT/shims:\$PATH"
PROFILE
fi
ruby -v && bundle -v
RBENV

step "MySQL"
mysql -e "SELECT 1" >/dev/null
if ! mysql -e "USE $DB_NAME" 2>/dev/null; then
  # utf8mb4 for the database, but the restored tables keep their own utf8mb3
  # charset from the dump. Do not "fix" that during the migration.
  mysql -e "CREATE DATABASE $DB_NAME CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci"
  echo "created database $DB_NAME"
fi

if [ ! -f "$ENV_FILE" ]; then
  # Generated here and never printed. The systemd unit is the only reader.
  DB_PASS=$(openssl rand -base64 30 | tr -d '/+=' | head -c 32)
  mysql -e "CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS'"
  mysql -e "ALTER USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS'"
  mysql -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost'"
  mysql -e "FLUSH PRIVILEGES"

  touch "$ENV_FILE"; chmod 600 "$ENV_FILE"; chown root:root "$ENV_FILE"
  cat > "$ENV_FILE" <<ENV
RAILS_ENV=production
DATABASE_URL=mysql2://$DB_USER:$DB_PASS@127.0.0.1/$DB_NAME
RAILS_SERVE_STATIC_FILES=
RAILS_LOG_TO_STDOUT=1
ENV
  echo "wrote $ENV_FILE (mode 600, password not shown)"
else
  echo "$ENV_FILE already exists, leaving it alone"
fi

step "Block volume"
# DigitalOcean attaches volumes under /dev/disk/by-id/scsi-0DO_Volume_<name>.
# Nothing is formatted here: this volume came from a snapshot of live data and
# must be mounted as-is.
VOL=$(ls /dev/disk/by-id/scsi-0DO_Volume_* 2>/dev/null | head -1 || true)
if [ -z "$VOL" ]; then
  echo "NO VOLUME ATTACHED. Attach it in the DO panel, then re-run this script."
else
  mkdir -p /mnt/blackbook_volume
  if ! mountpoint -q /mnt/blackbook_volume; then
    mount -o defaults,nofail,discard,noatime "$VOL" /mnt/blackbook_volume
  fi
  grep -q blackbook_volume /etc/fstab || \
    echo "$VOL /mnt/blackbook_volume ext4 defaults,nofail,discard,noatime 0 2" >> /etc/fstab
  echo "mounted $VOL"
  df -h /mnt/blackbook_volume
  echo
  echo "Volume contents (symlink the app at these AFTER checking them):"
  ls -la /mnt/blackbook_volume/
fi

step "Basic auth gate"
if [ -f /etc/nginx/.htpasswd ]; then
  echo "/etc/nginx/.htpasswd already exists, left alone"
else
  if [ -z "$AUTH_PASS" ]; then
    AUTH_PASS=$(openssl rand -base64 12)
    echo "No AUTH_PASS given, generated one. Write this down now:"
  fi
  htpasswd -bcB /etc/nginx/.htpasswd "$AUTH_USER" "$AUTH_PASS" >/dev/null
  chown root:www-data /etc/nginx/.htpasswd
  chmod 640 /etc/nginx/.htpasswd
  echo "  user: $AUTH_USER"
  echo "  pass: $AUTH_PASS"
fi

step "nginx for $APP_DOMAIN"
# X-Forwarded-Proto is load-bearing: main sets config.force_ssl = true, and
# without this header Rails redirects to https forever.
cat > /etc/nginx/sites-available/blackbook <<NGINX
upstream blackbook { server 127.0.0.1:3000 fail_timeout=0; }

server {
  listen 80;
  server_name $APP_DOMAIN;
  root $APP_DIR/public;
  client_max_body_size 20M;

  # Beta is gated. auth_basic sits on each location rather than on the server,
  # so certbot's own /.well-known/acme-challenge/ block inherits nothing and
  # can still answer unauthenticated. Delete these three pairs to go public.
  location ^~ /assets/ {
    auth_basic "blackbook beta";
    auth_basic_user_file /etc/nginx/.htpasswd;
    expires max; add_header Cache-Control public;
  }
  location ^~ /system/ {
    auth_basic "blackbook beta";
    auth_basic_user_file /etc/nginx/.htpasswd;
    expires max; add_header Cache-Control public;
  }

  location / {
    auth_basic "blackbook beta";
    auth_basic_user_file /etc/nginx/.htpasswd;
    try_files \$uri @app;
  }

  location @app {
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
    proxy_set_header Host \$http_host;
    proxy_redirect off;
    proxy_pass http://blackbook;
  }
}
NGINX
ln -sf /etc/nginx/sites-available/blackbook /etc/nginx/sites-enabled/blackbook
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl reload nginx

step "systemd unit"
cat > /etc/systemd/system/blackbook.service <<UNIT
[Unit]
Description=blackbook (puma)
After=network.target mysql.service
Requires=mysql.service

[Service]
Type=simple
User=$APP_USER
WorkingDirectory=$APP_DIR
EnvironmentFile=$ENV_FILE
ExecStart=/home/$APP_USER/.rbenv/shims/bundle exec puma -C config/puma.rb
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
UNIT
systemctl daemon-reload
systemctl enable blackbook >/dev/null
echo "unit installed (not started: the app is not deployed yet)"

step "Done"
cat <<NEXT

Provisioned. The app is NOT deployed and the service is NOT running yet.

Remaining steps, in order:

1. Point DNS at this droplet, then get a certificate:
     certbot --nginx -d $APP_DOMAIN

2. Clone the app as $APP_USER:
     sudo -u $APP_USER git clone https://github.com/jamiew/blackbook $APP_DIR

3. Symlink data and images at the volume. Check the listing above first,
   then point them at the real directories:
     sudo -u $APP_USER ln -s /mnt/blackbook_volume/<gml-dir>    $APP_DIR/data
     sudo -u $APP_USER ln -s /mnt/blackbook_volume/<images-dir> $APP_DIR/public/system

4. Copy config/master.key from your laptop (it is gitignored, and Rails 8
   will not boot without it):
     scp config/master.key $APP_USER@$APP_DOMAIN:$APP_DIR/config/

5. Restore the database dump:
     gzip -dc database.sql.gz | mysql $DB_NAME

6. Check what the pending migrations will do BEFORE running them:
     cd $APP_DIR && RAILS_ENV=production bundle exec rake data:validate

7. Then start it:
     systemctl start blackbook && systemctl status blackbook

NEXT

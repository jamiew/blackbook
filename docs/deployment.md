# Deployment

The app is deployed as a Docker container by [Kamal](https://kamal-deploy.org).
MySQL is deliberately **not** containerized: it stays a host package so the block
volume, backups and unattended-upgrades keep working as they already do.

## Layout

| | |
|---|---|
| Beta | `beta.000000book.com`, droplet `blackbook-beta`, nyc3 |
| Storage | block volume mounted at `/mnt/blackbook_volume`, holding GML files and images |
| Database | MySQL 8.4 on the host, reached over its Unix socket |
| Registry | `ghcr.io/jamiew/blackbook` |

## Commands

```bash
kamal setup            # first time on a new server
kamal deploy           # build, push, roll over with no downtime
kamal rollback         # back to the previous image
kamal logs             # follow
kamal console          # rails console
kamal migrate          # run migrations, deliberately a separate step
```

Migrations never run automatically. `bin/docker-entrypoint` omits the `db:prepare`
that Rails generates, because the pending set drops the `comments` table and that
must not happen because a container restarted or a deploy rolled back.

## Secrets

Kamal reads `.kamal/secrets-common` first, then `.kamal/secrets`, and **later
values win**. A key present in both takes the value from `.kamal/secrets`, even
if that resolves to an empty string because the shell variable it references is
unset. That failure is silent.

- `.kamal/secrets` is committed and contains only references, never values.
- `.kamal/secrets-common` is gitignored and holds `KAMAL_REGISTRY_PASSWORD` (a
  GitHub token with the `write:packages` scope) and `DATABASE_URL`. Neither may
  be named in `.kamal/secrets`, or the empty shell value would win.

Application secrets go in Rails encrypted credentials rather than the
environment. The encrypted file is safe to commit in a public repo, and
`RAILS_MASTER_KEY` already reaches the container.

```bash
bin/rails credentials:edit
```

## Host MySQL

The container reaches the database over MySQL's Unix socket, bind-mounted
read-only by `config/deploy.yml`. Nothing listens on a port, so there is no
bind address, firewall rule or certificate to keep working. TCP was tried
first and every route timed out at connect.

Two one-time things on the server:

1. A grant for the socket, which MySQL sees as localhost:

   ```sql
   CREATE USER 'blackbook'@'localhost' IDENTIFIED BY '<password>';
   GRANT ALL PRIVILEGES ON blackbook_prod.* TO 'blackbook'@'localhost';
   ```

2. `DATABASE_URL` naming `localhost`, so the client picks the socket:

   ```
   mysql2://blackbook:<password>@localhost/blackbook_prod
   ```

[DigitalOcean Managed MySQL](https://www.digitalocean.com/products/managed-databases-mysql)
removes this section, and the patching with it.

## Email

Production sends through Amazon SES over SMTP, configured from encrypted
credentials under the `ses` key. It falls back to `:sendmail` when those are
absent, which is what the old server used.

SES SMTP credentials are **not** AWS access keys; generate a separate pair in the
[SES console](https://console.aws.amazon.com/ses/home#/smtp). New accounts are
[sandboxed](https://docs.aws.amazon.com/ses/latest/dg/request-production-access.html)
and can only send to verified addresses until you request production access.

## A new host

`kamal setup` does everything above the operating system. Four things it does
not do, so a fresh droplet needs them first:

```bash
# 1. Attach the block volume and mount it at /mnt/blackbook_volume, then
#    create the three directories config/deploy.yml bind-mounts:
mkdir -p /mnt/blackbook_volume/{blackbook-data,active-storage}
mkdir -p /mnt/blackbook_volume/blackbook-backup/public/system

# 2. MySQL, matching the version in compose.yaml
apt-get install -y mysql-server
mysql -e "CREATE DATABASE blackbook_prod
          CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"

# 3. The grant and DATABASE_URL from "Host MySQL" above.

# 4. Only 80 and 443 need to be open; nothing listens on 3306.
ufw allow 80,443/tcp
```

Nothing may hold port 80 when `kamal setup` runs: kamal-proxy binds it, and a
partly-created proxy container is hard to recover from. In particular, do not
install nginx.

`./deploy` still ships the old production server, and retires with it.

# Deployment

`config/deploy.yml` targets **beta**, using a Docker container managed by
[Kamal](https://kamal-deploy.org). Production still uses the legacy `./deploy`
script. MySQL runs on the host; GML and images live on a persistent block volume.

## Layout

| | |
|---|---|
| Beta | `beta.000000book.com`, droplet `blackbook-beta`, nyc3 |
| Storage | block volume mounted at `/mnt/blackbook_volume`, holding GML files and images |
| Database | MySQL 8.4 on the host, reached over its Unix socket |
| Registry | `ghcr.io/jamiew/blackbook` |

## Beta commands

```bash
kamal setup            # first time on a new server
kamal deploy           # build, push, roll over with no downtime
kamal rollback <version> # roll back to a retained image version
kamal logs             # follow
kamal console          # rails console
kamal migrate          # run migrations, deliberately a separate step
```

Migrations never run automatically: `bin/docker-entrypoint` does not run
`db:prepare`. Before `kamal migrate`, check migration status, take a backup and
follow the [migration rehearsal procedure](operations.md). The repository
includes a migration that drops `comments`; do not assume it is pending on every
target.

## Secrets

Kamal loads `.kamal/secrets-common` before `.kamal/secrets`; later values win.
Keep literal credentials in the gitignored file or the calling environment.
The committed file must contain references only. Avoid duplicate definitions:
an unset environment reference can overwrite a value from the common file.

Deployment needs `KAMAL_REGISTRY_PASSWORD`, `DATABASE_URL` and `RAILS_MASTER_KEY`.
For local registry pushes, use a GitHub token with `write:packages`.
Application mail settings live in Rails encrypted credentials. Never commit
the master key or unencrypted credentials.

```bash
bin/rails credentials:edit
```

## Host MySQL

The container uses `/var/run/mysqld/mysqld.sock`, with the host socket directory
mounted read-only by `config/deploy.yml`. This does not disable MySQL TCP on the
host: configure its listener and firewall separately, and do not expose 3306
publicly.

Configure the database account and connection:

1. A grant for the socket, which MySQL sees as localhost:

   ```sql
   CREATE USER 'blackbook'@'localhost' IDENTIFIED BY '<password>';
   GRANT ALL PRIVILEGES ON blackbook_prod.* TO 'blackbook'@'localhost';
   ```

2. `DATABASE_URL` naming `localhost`, so the client picks the socket:

   ```
   mysql2://blackbook:<password>@localhost/blackbook_prod
   ```


## Email

Production-mode Rails sends through Amazon SES when the encrypted `ses`
credentials are present. Otherwise it falls back to `:sendmail`; the container
does not install a sendmail service, so configure SES before relying on mail.

SES SMTP credentials are **not** AWS access keys; generate a separate pair in the
[SES console](https://console.aws.amazon.com/ses/home#/smtp). New accounts are
[sandboxed](https://docs.aws.amazon.com/ses/latest/dg/request-production-access.html)
and can only send to verified addresses until you request production access.

Set `ses.smtp_address`, `ses.smtp_username`, `ses.smtp_password` and `ses.from`;
`ses.port` defaults to 587. The verified sender is applied through
`config.action_mailer.default_options`. A mailer-level `default from:` would
override it. Development and test use the fallback in `config/application.rb`.

To send a real test message:

```bash
./script/send-test-email.sh you@example.com
```

This uses production mail settings and requires the credentials key. The script
defaults to local MySQL, but honors an existing `DATABASE_URL`; check your
environment before running it. SES accepting the message does not guarantee
inbox delivery.

## A new host

Provision the host before `kamal setup`:

1. Attach the intended block volume at `/mnt/blackbook_volume`. Create
   `blackbook-data`, `active-storage` and `blackbook-backup/public/system` within
   it. These bind mounts must be writable by container UID/GID `1000:1000`;
   ownership set in the image does not change a mounted host directory.
2. Install MySQL **8.4** from an appropriate package source. The distribution's
   default `mysql-server` package may be a different version. Create
   `blackbook_prod` with `utf8mb4` and `utf8mb4_unicode_ci`, then configure the
   account and `DATABASE_URL` above.
3. Configure SSH access and allow HTTP/HTTPS traffic on ports 80 and 443.
   Keep the database private. `kamal-proxy` needs those web ports; do not install
   a competing web server.
4. Set the target host, proxy hostname and secrets before deploying. The checked-in
   config targets beta; changing `BETA_HOST` alone does not change its hostname.

These are provisioning instructions, not permission to modify the live production
volume. See [operations](operations.md) for the separate beta and production
storage and backup procedures.

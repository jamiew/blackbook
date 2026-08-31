# Deployment

The app is deployed as a Docker container by [Kamal](https://kamal-deploy.org).
MySQL is deliberately **not** containerized: it stays a host package so the block
volume, backups and unattended-upgrades keep working as they already do.

## Layout

| | |
|---|---|
| Beta | `beta.000000book.com`, droplet `blackbook-beta`, nyc3 |
| Storage | block volume mounted at `/mnt/blackbook_volume`, holding GML files and images |
| Database | MySQL 8.4 on the host, reached over the Docker bridge |
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
that Rails generates, because the pending set drops a 301,076-row table and that
must not happen because a container restarted or a deploy rolled back.

## Secrets

Kamal reads `.kamal/secrets-common` first, then `.kamal/secrets`, and **later
values win**. A key present in both takes the value from `.kamal/secrets`, even
if that resolves to an empty string because the shell variable it references is
unset. That failure is silent.

- `.kamal/secrets` is committed and contains only references, never values.
- `.kamal/secrets-common` is gitignored and holds `KAMAL_REGISTRY_PASSWORD`, a
  GitHub token with the `write:packages` scope.

Application secrets go in Rails encrypted credentials rather than the
environment. The encrypted file is safe to commit in a public repo, and
`RAILS_MASTER_KEY` already reaches the container.

```bash
bin/rails credentials:edit
```

## Host MySQL

The container reaches the database over the Docker bridge. Two one-time changes
on the server, neither of which exposes MySQL publicly, since ufw still blocks
3306 from outside:

1. Listen on loopback and the bridge, in `/etc/mysql/mysql.conf.d/mysqld.cnf`:

   ```
   bind-address = 127.0.0.1,172.17.0.1
   ```

2. Let the app user connect from the bridge network:

   ```sql
   CREATE USER 'blackbook'@'172.17.%' IDENTIFIED BY '<password>';
   GRANT ALL PRIVILEGES ON blackbook_prod.* TO 'blackbook'@'172.17.%';
   ```

`DATABASE_URL` then points at `host.docker.internal`.
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

## The older path

`script/provision-droplet.sh` builds a server the pre-container way: rbenv, Ruby
from source, Puma under systemd, nginx in front. It is kept until Kamal is
serving beta, then both it and `./deploy` should go.

Two things it works around, both specific to Ubuntu 26.04:

- `sudo` keeps root's cwd of `/root`, which the app user cannot read, so
  ruby-build's `popd` fails *after* a successful `make install` and rolls the
  whole build back.
- 26.04 mounts `/tmp` as a tmpfs at half of RAM. The Ruby build overruns it and,
  because tmpfs is RAM, also competes with the compile for memory.

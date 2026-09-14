# Inception Developer Documentation

This document describes how to set up, build, run, and maintain the Inception
WordPress stack during development.

## Project architecture
The stack contains three Docker Compose services on the `inception` bridge
network:

- `nginx`: Debian 12, Nginx, and OpenSSL. It exposes HTTPS on host port 443.
- `wordpress`: Debian 12, PHP 8.2-FPM, the PHP MySQL extension, MariaDB
	client, and WP-CLI. It listens on port 9000 inside the Docker network.
- `mariadb`: Debian 12 and MariaDB. It stores the WordPress database and is
	reachable by the other containers as `mariadb`.

The request path is:
```text
Browser -> nginx:443 -> wordpress:9000 -> mariadb:3306
```

## Prerequisites
Install the following on the host:

- Linux
- Docker Engine
Confirm the Docker installation before starting:

```sh
docker --version
docker compose version
make --version
```

The current configuration uses the domain `abchaman.42.fr`. Add it to
`/etc/hosts` for local development:

```text
127.0.0.1 abchaman.42.fr
```

If the domain changes, update all of these locations consistently:

- `srcs/.env` (`DOMAIN_NAME`)
- `srcs/requirements/nginx/conf/nginx.conf` (`server_name`)
- `srcs/requirements/nginx/Dockerfile` (the certificate subject)

## Configuration and secrets

The Compose file loads environment variables from `srcs/.env`. Create that
file before starting the stack:

```dotenv
DOMAIN_NAME=abchaman.42.fr
MYSQL_DATABASE=wp_db
MYSQL_USER=wp_user
MYSQL_PASSWORD=change-me
MYSQL_ROOT_PASSWORD=change-me-too
WP_ADMIN_USER=admin
WP_ADMIN_PASSWORD=change-me
WP_ADMIN_EMAIL=admin@example.com
WP_USER=author
WP_PASSWORD=change-me
WP_EMAIL=author@example.com
```

Use strong local or deployment-specific passwords and keep `.env` out of
version control. These values are used by the MariaDB and WordPress
entrypoints during first initialization. Existing database and WordPress
accounts are not automatically changed when the file is edited later.

The initial WordPress setup performs these operations when `wp-config.php`
does not exist:

1. Downloads WordPress with WP-CLI.
2. Creates `wp-config.php` using the MariaDB service hostname.
3. Installs the site using the `DOMAIN_NAME` and administrator variables.
4. Creates the additional author account.

## Build and launch

Run all commands from the repository root.

The main development command is:

```sh
make
```

The `all` target creates the host data directories and runs:

```sh
cd srcs && docker compose up --build -d
```

To run the equivalent Compose command manually:

```sh
mkdir -p /home/inception/data/mariadb /home/inception/data/wordpress
docker compose -f srcs/docker-compose.yml up --build -d
```

The first build installs Debian packages, generates the Nginx self-signed
certificate, and downloads WordPress during the first WordPress container
startup.

## Container management

Make targets:

| Command | Effect |
| --- | --- |
| `make` or `make all` | Create data directories, build images, and start containers |
| `make down` | Stop and remove containers, preserving host data |
| `make clean` | Stop containers and remove Compose volumes and project images |
| `make fclean` | Run `clean`, prune Docker resources, and delete project data |
| `make re` | Run `fclean`, then build and start from scratch |

Equivalent direct Compose commands:

```sh
docker compose -f srcs/docker-compose.yml ps
docker compose -f srcs/docker-compose.yml logs -f nginx
docker compose -f srcs/docker-compose.yml logs -f wordpress
docker compose -f srcs/docker-compose.yml logs -f mariadb
docker compose -f srcs/docker-compose.yml stop
docker compose -f srcs/docker-compose.yml start
docker compose -f srcs/docker-compose.yml down
```

Inspect the resolved Compose configuration before troubleshooting build or
volume changes:

```sh
docker compose -f srcs/docker-compose.yml config
```

Useful container commands include:

```sh
docker exec -it wordpress wp user list --allow-root
docker exec -it wordpress sh
docker exec -it mariadb mariadb -u root -p
```

The MariaDB command prompts for `MYSQL_ROOT_PASSWORD` from `srcs/.env`.

## Data and persistence

The Compose volumes are named `db-volume` and `wp-volume`, but they are local
bind mounts with these host locations:

| Compose volume | Host path | Container path | Contents |
| --- | --- | --- | --- |
| `db-volume` | `/home/inception/data/mariadb` | `/var/lib/mysql` | MariaDB database files |
| `wp-volume` | `/home/inception/data/wordpress` | `/var/www/html` | WordPress files and `wp-config.php` |

The WordPress volume is mounted by both the WordPress and Nginx containers.
This lets PHP-FPM execute the application while Nginx serves static files from
the same directory.

Stopping containers with `make down` preserves both host directories. Removing
Compose volumes with `make clean` does not remove the bind-mounted files, so
the data can still be reused. The `fclean` target explicitly deletes the
contents of both host directories and therefore causes a full reinitialization
on the next `make`.

Back up both directories while the stack is stopped if the site must be
restored elsewhere. Do not manually edit database files or WordPress files
while their containers are running.

## Rebuilding after code changes

Changes to a Dockerfile, entrypoint, or Nginx configuration require an image
rebuild:

```sh
docker compose -f srcs/docker-compose.yml up --build -d
```

Changes to `srcs/.env` affect initialization-dependent settings. If the
database and WordPress files already exist, remove the persistent data only
when a clean initialization is intended:

```sh
make fclean
make
```

This destroys the current site and database, so back up the data first.

# Inception User Documentation

This document explains how to use and administer the Inception WordPress stack.

## Services

The project provides three services:

- **Nginx** receives HTTPS requests on port 443 and serves the website.
- **WordPress** runs the website through PHP-FPM and stores its files in the
  WordPress data directory.
- **MariaDB** stores the WordPress database.

The services communicate through the private Docker network named `inception`.
Only Nginx is exposed to the host.

## Prerequisites

Install and start Docker Engine, Docker Compose v2, and GNU Make. The host
must also resolve the project domain to the local machine. Add this line to
`/etc/hosts` if necessary:

```text
127.0.0.1 abchaman.42.fr
```

The domain must match `DOMAIN_NAME` in `srcs/.env` and `server_name` in the
Nginx configuration.

## Start the project

From the project root, run:

```sh
make
```

This creates the persistent data directories, builds the three images, and
starts the containers in the background. The first startup can take longer
because the images and WordPress files must be downloaded.

To stop the project without deleting its data:

```sh
make down
```

To start it again, run `make`. Existing WordPress and MariaDB data will be
reused.

### Cleanup commands

```sh
make clean
```

Stops the stack and removes its Docker volumes and images.

```sh
make fclean
```

Also removes unused Docker resources and permanently deletes the project data
under `/home/inception/data`.

Use `make fclean` only when a complete reset is intended. To reset and rebuild
the project in one command, run:

```sh
make re
```

## Access the website

Once the containers are running, open:

```text
https://abchaman.42.fr
```

Nginx uses a self-signed certificate, so the browser will show a certificate
warning the first time. Accept the certificate exception for local use.

The WordPress administration panel is available at:

```text
https://abchaman.42.fr/wp-admin
```

Sign in with the WordPress administrator account configured in `srcs/.env`.

## Credentials

All initial credentials are kept in:

```text
srcs/.env
```

The relevant variables are:

| Variable | Purpose |
| --- | --- |
| `MYSQL_ROOT_PASSWORD` | MariaDB root password |
| `MYSQL_USER` | WordPress database user name |
| `MYSQL_PASSWORD` | WordPress database user password |
| `WP_ADMIN_USER` | WordPress administrator user name |
| `WP_ADMIN_PASSWORD` | WordPress administrator password |
| `WP_ADMIN_EMAIL` | WordPress administrator email |
| `WP_USER` | Additional WordPress author user name |
| `WP_PASSWORD` | Additional WordPress author password |
| `WP_EMAIL` | Additional WordPress author email |

Keep `srcs/.env` private and do not publish it. Replace the example or
training passwords before using the project outside a local environment.

The entrypoint scripts use these values during the first initialization only.
After WordPress and MariaDB data already exist, changing `.env` does not
automatically change existing WordPress accounts or database passwords.
Manage existing WordPress users from the administration panel, or with WP-CLI
inside the WordPress container. For example:

```sh
docker exec -it wordpress wp user list --allow-root
docker exec -it wordpress wp user update <user> --user_pass='<new-password>' --allow-root
```

To apply a completely new initial configuration, stop the project and use
`make fclean`, then update `srcs/.env` and run `make`. This deletes all existing
site and database data.

## Check service status

From the project root, check that all three containers are running:

```sh
docker compose -f srcs/docker-compose.yml ps
```

The expected containers are:

- `nginx`
- `wordpress`
- `mariadb`

View logs for one service with:

```sh
docker compose -f srcs/docker-compose.yml logs nginx
docker compose -f srcs/docker-compose.yml logs wordpress
docker compose -f srcs/docker-compose.yml logs mariadb
```

Follow logs while troubleshooting by adding `-f`, for example:

```sh
docker compose -f srcs/docker-compose.yml logs -f wordpress
```

A basic website check can be performed with:

```sh
curl -k -I https://abchaman.42.fr
```

An HTTP response such as `200`, `301`, or `302` confirms that Nginx is
answering. If the site cannot be reached, first check `docker compose ps`,
then inspect the Nginx and WordPress logs.

## Persistent data

The stack stores data on the host at:

- `/home/inception/data/wordpress`: WordPress files
- `/home/inception/data/mariadb`: MariaDB database files

Do not edit these directories while the services are running. Back them up
when the project is stopped if the website data must be preserved.

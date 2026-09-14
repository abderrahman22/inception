# Inception

This project builds a small WordPress website with Docker Compose. It is split
into three services connected through a private Docker bridge network:

- **Nginx**: HTTPS reverse proxy and static file server.
- **WordPress**: PHP-FPM application server. WordPress is downloaded and
	configured automatically with WP-CLI on the first start.
- **MariaDB**: WordPress database server.

## Architecture

```text
Browser
	 |
	 | HTTPS :443
	 v
 Nginx  --->  WordPress/PHP-FPM :9000  --->  MariaDB :3306
	 |                 |                         |
	 +-----------------+-------------------------+
			 Docker network: inception
```

Nginx uses a self-signed certificate and serves the domain configured in
`srcs/requirements/nginx/conf/nginx.conf`. The WordPress and MariaDB data are
stored in bind-mounted host directories:

- `/home/inception/data/wordpress`
- `/home/inception/data/mariadb`

## Requirements

- Linux with Docker Engine and Docker Compose v2
- GNU Make
- `sudo` access for the `fclean` target
- A hosts-file entry pointing the configured domain to the local machine, for
	example:

	```text
	127.0.0.1 abchaman.42.fr
	```

## Configuration

Create or update `srcs/.env` with the values used by the containers:

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

The file contains credentials and should not be committed to a public
repository. The domain in `.env` must match the `server_name` and certificate
subject configured for Nginx if those values are changed.

## Usage

Build the images, create the data directories, and start the stack in the
background:

```sh
make
```

Open the site at `https://abchaman.42.fr`. Because the certificate is
self-signed, the browser will display a certificate warning on first access.

Available Make targets:

| Command | Description |
| --- | --- |
| `make` or `make all` | Build images and start all services |
| `make down` | Stop and remove the containers |
| `make clean` | Stop containers, remove volumes, and remove images |
| `make fclean` | Clean Docker resources and delete persistent project data |
| `make re` | Run `fclean`, then rebuild and start the project |

Use `make fclean` with care: it permanently deletes the WordPress and MariaDB
data stored under `/home/inception/data`.

## Project layout

```text
.
├── Makefile
├── srcs
│   ├── .env
│   ├── docker-compose.yml
│   └── requirements
│       ├── mariadb
│       │   ├── Dockerfile
│       │   └── tools/entrypoint.sh
│       ├── nginx
│       │   ├── Dockerfile
│       │   └── conf/nginx.conf
│       └── wordpress
│           ├── Dockerfile
│           └── tools/entrypoint.sh
```

## Service details

### MariaDB

The MariaDB image is based on Debian 12. Its entrypoint initializes the
database, creates the WordPress user, grants that user access to the WordPress
database, and sets the root password on the first run. Subsequent starts reuse
the existing database files.

### WordPress

The WordPress image is based on Debian 12 and installs PHP 8.2-FPM, the MySQL
PHP extension, the MariaDB client, and WP-CLI. On first start it downloads
WordPress, creates `wp-config.php`, installs the site, and creates a second
author account. PHP-FPM listens on port 9000 inside the Docker network.

### Nginx

The Nginx image is based on Debian 12 and installs Nginx and OpenSSL. It serves
HTTPS on port 443, forwards PHP requests to `wordpress:9000`, and shares the
WordPress volume so it can serve the site files.
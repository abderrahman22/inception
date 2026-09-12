#!/bin/bash
set -e

DATADIR=/var/lib/mysql

# First-run: initialize the data directory if the volume is empty
if [ ! -d "${DATADIR}/mysql" ]; then
    echo "No existing database found, initializing..."
    mariadb-install-db --user=mysql --datadir=${DATADIR} > /dev/null

    # Start MariaDB temporarily (no networking) to run setup
    mysqld_safe --datadir=${DATADIR} --skip-networking &

    # Wait until it's actually ready instead of a fixed sleep
    until mysqladmin ping --silent 2>/dev/null; do
        sleep 1
    done

    mariadb -u root <<-EOSQL
        CREATE DATABASE IF NOT EXISTS ${SQL_DATABASE};
        CREATE USER IF NOT EXISTS '${SQL_USER}'@'%' IDENTIFIED BY '${SQL_PASSWORD}';
        GRANT ALL PRIVILEGES ON ${SQL_DATABASE}.* TO '${SQL_USER}'@'%';
        ALTER USER 'root'@'localhost' IDENTIFIED BY '${SQL_ROOT_PASSWORD}';
        FLUSH PRIVILEGES;
EOSQL

    mysqladmin -u root -p"${SQL_ROOT_PASSWORD}" shutdown
    echo "Initialization complete."
else
    echo "Existing database found, skipping initialization."
fi

exec mysqld_safe --datadir=${DATADIR}
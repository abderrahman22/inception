#!/bin/bash
set -e

mkdir -p /var/www/wordpress
cd /var/www/wordpress

if [ ! -f /usr/local/bin/wp ]; then
    wget -q https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
    chmod +x wp-cli.phar
    mv wp-cli.phar /usr/local/bin/wp
fi

# Wait until MariaDB actually accepts connections, not just "container started"
echo "Waiting for MariaDB..."
until php -r "new mysqli('mariadb', '${SQL_USER}', '${SQL_PASSWORD}', '${SQL_DATABASE}');" 2>/dev/null; do
    sleep 2
done
echo "MariaDB is up."

if [ ! -f wp-config.php ]; then
    wp core download --allow-root

    wp config create \
        --dbname=${SQL_DATABASE} \
        --dbuser=${SQL_USER} \
        --dbpass=${SQL_PASSWORD} \
        --dbhost=mariadb \
        --allow-root

    wp core install \
        --url=localhost \
        --title="Inception Abdo" \
        --admin_user=${WP_ADMIN} \
        --admin_password=${WP_ADMIN_PASSWORD} \
        --admin_email=admin@abdo.com \
        --allow-root

    wp user create ${WP_USER} user@abdo.com \
        --user_pass=${WP_USER_PASSWORD} \
        --role=author \
        --allow-root
fi

exec php-fpm8.2 -F
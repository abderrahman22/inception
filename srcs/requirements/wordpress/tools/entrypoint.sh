#!/bin/bash

if [ ! -f "wp-config.php" ]; then
    echo "Downloading WordPress..."
    wp core download --allow-root

    echo "Configuring database connection..."
    wp config create --dbname=$MYSQL_DATABASE \
                     --dbuser=$MYSQL_USER \
                     --dbpass=$MYSQL_PASSWORD \
                     --dbhost=mariadb \
                     --allow-root

    echo "Installing WordPress..."
    wp core install --url=$DOMAIN_NAME \
                    --title="Inception WP" \
                    --admin_user=$WP_ADMIN_USER \
                    --admin_password=$WP_ADMIN_PASSWORD \
                    --admin_email=$WP_ADMIN_EMAIL \
                    --allow-root

    echo "Creating a second user..."
    wp user create $WP_USER $WP_EMAIL --role=author --user_pass=$WP_PASSWORD --allow-root
fi

exec /usr/sbin/php-fpm8.2 -F
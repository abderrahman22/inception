FROM debian:12

RUN apt-get update && apt-get install -y nginx openssl && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /etc/nginx/ssl

RUN openssl req -x509 -nodes -out /etc/nginx/ssl/inception.crt -keyout /etc/nginx/ssl/inception.key -subj "/C=MA/ST=Rabat-Sale-Kenitra/L=Sale/O=42/OU=1337/CN=abchaman.42.fr/UID=abchaman"

COPY conf/nginx.conf /etc/nginx/nginx.conf

RUN mkdir -p /var/www/html && chown -R www-data:www-data /var/www/html

CMD ["nginx", "-g", "daemon off;"]
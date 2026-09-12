FROM debian:trixie

RUN apt-get update && apt-get install -y mariadb-server mariadb-client

COPY ./conf/50-server.cnf /etc/mysql/mariadb.conf.d/50-server.cnf 
COPY ./tools/entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

CMD ["/entrypoint.sh"]
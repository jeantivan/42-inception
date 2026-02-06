ARG ALPINE_VERSION=${ALPINE_VERSION:-3.22}
FROM alpine:${ALPINE_VERSION}

RUN apk update && apk add --no-cache \
	mariadb \
	mariadb-client \
	&& mkdir -p /run/mysqld \
	&& chown -R mysql:mysql /run/mysqld /var/lib/mysql

COPY tools/my.cnf /etc/my.cnf.d/mariadb-server.cnf
COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh

RUN chmod +x /usr/local/bin/entrypoint.sh

ENV DATADIR="/var/lib/mysql"

RUN chown -R mysql:mysql "$DATADIR"

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

USER mysql

CMD ["mariadbd"]

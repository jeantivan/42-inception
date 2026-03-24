ARG ALPINE_VERSION=${ALPINE_VERSION:-3.22}
FROM alpine:${ALPINE_VERSION}

RUN apk add --no-cache \
    curl \
    ca-certificates \
    php83 php83-ctype php83-curl php83-dom php83-json php83-mbstring \
    php83-mysqli php83-openssl php83-pdo php83-pdo_mysql php83-pdo_pgsql \
    php83-session php83-simplexml php83-xml php83-xmlreader php83-xmlwriter

ARG ADMINER_VERSION=5.4.2

RUN mkdir -p /var/www/html && \
    curl -L https://github.com/vrana/adminer/releases/download/v${ADMINER_VERSION}/adminer-${ADMINER_VERSION}.php -o /var/www/html/index.php && \
    chown -R nobody:nobody /var/www/html

WORKDIR /var/www/html

COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh


USER nobody
EXPOSE 8080

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

CMD ["php83",  "-S", "0.0.0.0:8080", "-t", "/var/www/html"]


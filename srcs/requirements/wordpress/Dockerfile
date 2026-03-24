ARG ALPINE_VERSION=${ALPINE_VERSION:-3.22}
FROM alpine:${ALPINE_VERSION}

# Install PHP and extensions
RUN apk add --no-cache \
	curl \
    php83 php83-fpm php83-phar php83-bcmath php83-common php83-ctype \
    php83-curl php83-dom php83-exif php83-fileinfo php83-gd php83-iconv \
    php83-intl php83-json php83-mbstring php83-mysqli php83-opcache \
    php83-openssl php83-pdo php83-pdo_mysql php83-pecl-redis \
    php83-session php83-simplexml php83-tokenizer php83-xml \
    php83-xmlreader php83-xmlwriter php83-zip

WORKDIR /tmp

# Download WP-CLI
RUN curl -L https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -o /usr/local/bin/wp && \
    chmod +x /usr/local/bin/wp

# Memory limit for PHP
RUN echo "memory_limit = 256M" > /etc/php83/conf.d/memory.ini && \
    addgroup -S nobody 2>/dev/null || true && \
    adduser -S nobody -D -H -G nobody 2>/dev/null || true && \
    mkdir -p /run/php /var/www/html && \
    chown -R nobody:nobody /run/php /var/www/html

WORKDIR /var/www/html

COPY tools/php-fpm.conf /etc/php83/php-fpm.conf
COPY tools/www.conf /etc/php83/php-fpm.d/www.conf
COPY tools/php.ini /etc/php83/conf.d/wordpress.ini
COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh

RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 9000

ENTRYPOINT [ "/usr/local/bin/entrypoint.sh" ]

# Run PHP-FPM in the foreground
CMD [ "php-fpm83", "--nodaemonize", "--fpm-config", "/etc/php83/php-fpm.conf" ]

ARG ALPINE_VERSION=${ALPINE_VERSION:-3.22}
FROM alpine:${ALPINE_VERSION}

# Install PHP and extensions
RUN apk add --no-cache \
	curl \
	php83 \
	php83-fpm \
	php83-mysqli \
	php83-curl \
	php83-gd \
	php83-xml \
	php83-mbstring \
	php83-zip \
	php83-bcmath

WORKDIR /var/www/html

# Configure PHP-FPM to listen on port 9000
RUN sed -i 's/listen = 127.0.0.1:9000/listen = 9000/' /etc/php83/php-fpm.d/www.conf

# Copy entrypoint script
COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Create necessary directories and set permissions
RUN mkdir -p /var/www/html
RUN chown -R nobody:nobody /var/www/html

# Run entrypoint script
ENTRYPOINT [ "/usr/local/bin/entrypoint.sh" ]

# Run PHP-FPM in the foreground
CMD [ "php-fpm83", "-F" ]

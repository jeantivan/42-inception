#!/bin/sh

set -e

# Environment variables
WORDPRESS_DIR="/var/www/html"
WORDPRESS_DB_USER=${WORDPRESS_DB_USER}
WORDPRESS_DB_HOST=${WORDPRESS_DB_HOST}
WORDPRESS_DB_NAME=${WORDPRESS_DB_NAME}
WORDPRESS_DB_PASSWORD=$(cat /run/secrets/db_password)

echo "[Entrypoint] Starting entrypoint script..."

if [ -z "$(ls -A $WORDPRESS_DIR)" ]; then
	echo "[Entrypoint] No files found in $WORDPRESS_DIR, starting Wordpress setup..."]

	echo "[Entrypoint] Downloading latest Wordpress and extracting files to $WORDPRESS_DIR..."
	curl -fSL https://wordpress.org/latest.tar.gz -o latest.tar.gz && tar -xzf latest.tar.gz -C $WORDPRESS_DIR --strip-components=1 && \
	rm latest.tar.gz
else
	echo "[Entrypoint] Files found in $WORDPRESS_DIR, skipping Wordpress download..."
fi

if [ ! -f "$WORDPRESS_DIR/wp-config.php" ]; then
	echo "[Entrypoint] No wp-config.php found, creating configuration file..."
	cp $WORDPRESS_DIR/wp-config-sample.php $WORDPRESS_DIR/wp-config.php

	# Update wp-config.php with environment variables
	sed -i "s/database_name_here/${WORDPRESS_DB_NAME}/" $WORDPRESS_DIR/wp-config.php
	sed -i "s/username_here/${WORDPRESS_DB_USER}/" $WORDPRESS_DIR/wp-config.php
	sed -i "s/password_here/${WORDPRESS_DB_PASSWORD}/" $WORDPRESS_DIR/wp-config.php
	sed -i "s/localhost/${WORDPRESS_DB_HOST}/" $WORDPRESS_DIR/wp-config.php

	# Add SSL configuration to wp-config.php
	cat <<EOL >> wp-config.php
// Force SSL for admin area
define('FORCE_SSL_ADMIN', true);

if ( strpos(\$_SERVER['HTTP_X_FORWARDED_PROTO'], 'https') !== false ) {
	\$_SERVER['HTTPS'] = 'on';
}
EOL

	echo "[Entrypoint] wp-config.php created and configured successfully."
else
	echo "[Entrypoint] wp-config.php already exists, skipping configuration..."
fi

echo "[Entrypoint] Starting PHP-FPM..."

exec "$@"

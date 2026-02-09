#!/bin/sh

set -e

# Environment variables
WORDPRESS_DIR="/var/www/html"
WORDPRESS_DB_USER=${WORDPRESS_DB_USER}
WORDPRESS_DB_HOST=${WORDPRESS_DB_HOST}
WORDPRESS_DB_NAME=${WORDPRESS_DB_NAME}
WORDPRESS_DB_PASSWORD=$(cat /run/secrets/db_password)
WORDPRESS_GUESS_USER=${WORDPRESS_GUESS_USER}
WORDPRESS_GUESS_PASSWORD=$(cat /run/secrets/wordpress_guess_password)


echo "[Entrypoint] Starting WordPress entrypoint script..."

download_wordpress() {
	if [ -z "$(ls -A $WORDPRESS_DIR)" ]; then
		echo "[Entrypoint] No files found in $WORDPRESS_DIR, starting WordPress setup..."

		echo "[Entrypoint] Downloading latest WordPress and extracting files to $WORDPRESS_DIR..."
		wp core download --path=$WORDPRESS_DIR --allow-root
	else
		echo "[Entrypoint] Files found in $WORDPRESS_DIR, skipping WordPress download..."
	fi
}

install_wordpress() {
	config_wordpress

	echo "[Entrypoint] Running WordPress installation..."
	wp core install --url=$DOMAIN_NAME \
					--title="$WORDPRESS_SITE_TITLE" \
					--admin_user=$WORDPRESS_ADMIN_USER \
					--admin_password=$(cat /run/secrets/wordpress_admin_password) \
					--admin_email=$WORDPRESS_ADMIN_EMAIL \
					--path=$WORDPRESS_DIR --allow-root
}

config_wordpress() {
	if [ ! -f "$WORDPRESS_DIR/wp-config.php" ]; then
		echo "[Entrypoint] Creating WordPress configuration..."
		wp config create --dbname=$WORDPRESS_DB_NAME \
						--dbuser=$WORDPRESS_DB_USER \
						--dbpass=$WORDPRESS_DB_PASSWORD \
						--dbhost=$WORDPRESS_DB_HOST \
						--path=$WORDPRESS_DIR --allow-root
		# Add SSL configuration to wp-config.php
		cat <<EOL >> wp-config.php
		define('FORCE_SSL_ADMIN', true);

	if ( isset(\$_SERVER['HTTP_X_FORWARDED_PROTO']) && strpos(\$_SERVER['HTTP_X_FORWARDED_PROTO'], 'https') !== false ) {
			\$_SERVER['HTTPS'] = 'on';
		}
EOL
		echo "[Entrypoint] WordPress configuration created and configured successfully."
	else
		echo "[Entrypoint] wp-config.php already exists, skipping configuration..."
	fi
}

create_guess_user() {
	if ! wp user get $WORDPRESS_GUESS_USER --path=$WORDPRESS_DIR --allow-root > /dev/null 2>&1; then
		echo "[Entrypoint] Creating guess user '$WORDPRESS_GUESS_USER'..."
		echo "DEBUG: WORDPRESS_GUESS_USER='$WORDPRESS_GUESS_USER', WORDPRESS_GUESS_EMAIL='$WORDPRESS_GUESS_EMAIL', WORDPRESS_GUESS_PASSWORD='$WORDPRESS_GUESS_PASSWORD'"
		wp user create $WORDPRESS_GUESS_USER $WORDPRESS_GUESS_EMAIL \
			--user_pass=$WORDPRESS_GUESS_PASSWORD \
			--role=subscriber \
			--path=$WORDPRESS_DIR --allow-root
	else
		echo "[Entrypoint] Guess user '$WORDPRESS_GUESS_USER' already exists, skipping creation..."
	fi
}

main () {
	download_wordpress
	install_wordpress
	create_guess_user

	echo "[Entrypoint] WordPress setup completed successfully. Starting the server..."
	exec "$@"
}

main "$@"


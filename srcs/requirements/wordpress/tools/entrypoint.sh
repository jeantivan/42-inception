#!/bin/sh

set -e

# Check for secrets
if [ ! -f /run/secrets/db_password ]; then
    echo "Error: db_password secret is missing."
    exit 1
fi

if [ ! -f /run/secrets/wordpress_admin_password ] || [ ! -f /run/secrets/wordpress_guest_password ]; then
    echo "Error: WordPress password secrets are missing."
    exit 1
fi

# Environment variables
WORDPRESS_DIR="/var/www/html"
WORDPRESS_DB_PASSWORD=$(cat /run/secrets/db_password)
WORDPRESS_ADMIN_PASSWORD=$(cat /run/secrets/wordpress_admin_password)
WORDPRESS_GUEST_PASSWORD=$(cat /run/secrets/wordpress_guest_password)


echo "[Entrypoint] Starting WordPress initialization..."

# ==========================================
# Function: Download WordPress
# ==========================================
download_wordpress() {
	if [ ! -f "$WORDPRESS_DIR/wp-includes/version.php"]; then
		echo "[Entrypoint] Downloading Wordpress core files..."
		wp core download --path="$WORDPRESS_DIR" --allow-root --quiet
	else
		echo "[Entrypoint] WordPress core files already present."
	fi
}

# ==========================================
# Function: Create wp-config.php
# ==========================================
config_wordpress() {
	if [ ! -f "$WORDPRESS_DIR/wp-config.php" ]; then
		echo "[Entrypoint] Generating wp-config.php..."
		wp config create --dbname="$WORDPRESS_DB_NAME" \
						--dbuser="$WORDPRESS_DB_USER" \
						--dbpass="$WORDPRESS_DB_PASSWORD" \
						--dbhost="$WORDPRESS_DB_HOST" \
						--path="$WORDPRESS_DIR" --allow-root --quiet
		# Add SSL configuration to wp-config.php
		echo "[Entrypoint] Injecting SSL configuration for NGINX proxy..."
        sed -i "s/^\/\* That's all, stop editing!.*/define('FORCE_SSL_ADMIN', true);\n\nif (isset(\$_SERVER['HTTP_X_FORWARDED_PROTO']) \&\& strpos(\$_SERVER['HTTP_X_FORWARDED_PROTO'], 'https') !== false) {\n    \$_SERVER['HTTPS'] = 'on';\n}\n\n\/* That's all, stop editing! \/*/" "$WORDPRESS_DIR/wp-config.php"
		echo "[Entrypoint] WordPress configuration created and configured successfully."
	else
		echo "[Entrypoint] wp-config.php already exists, skipping configuration..."
	fi
}

# ==========================================
# Function: Install DDBB
# ==========================================
install_wordpress() {
	if ! wp core is-installed --path="$WORDPRESS_DIR" --allow-root 2>/dev/null; then
		echo "[Entrypoint] Running WordPress DDBB installation..."
		wp core install \
			--url="$DOMAIN_NAME" \
			--title="$WORDPRESS_SITE_TITLE" \
			--admin_user="$WORDPRESS_ADMIN_USER" \
			--admin_password="$WORDPRESS_ADMIN_PASSWORD" \
			--admin_email="$WORDPRESS_ADMIN_EMAIL" \
			--path="$WORDPRESS_DIR" --allow-root --quiet
	else
		echo "[Entrypoint] WordPress database already installed."
	fi
}


# ==========================================
# Function: Create guest user
# ==========================================
create_guest_user() {
	if ! wp user get "$WORDPRESS_GUEST_USER" --path="$WORDPRESS_DIR" --allow-root > /dev/null 2>&1; then
		echo "[Entrypoint] Creating regular user '$WORDPRESS_GUEST_USER'..."
		wp user create "$WORDPRESS_GUEST_USER" "$WORDPRESS_GUEST_EMAIL" \
			--user_pass="$WORDPRESS_GUEST_PASSWORD" \
			--role=subscriber \
			--path="$WORDPRESS_DIR" \
			--allow-root --quiet
	else
		echo "[Entrypoint] Regular user '$WORDPRESS_GUEST_USER' already exists."
	fi
}

# ==========================================
# Function: Redis configuration
# ==========================================
setup_redis() {

	if wp core is-installed --path="$WORDPRESS_DIR" --allow-root 2>/dev/null; then
		echo "[Entrypoint] Configuring Redis..."
		if ! grep -q "WP_REDIS_HOST" "$WORDPRESS_DIR/wp-config.php"; then
			echo "[Entrypoint] Setting Redis environment variables..."
			wp config set WP_REDIS_HOST redis --path="$WORDPRESS_DIR" --allow-root --quiet
			wp config set WP_REDIS_PORT 6379 --raw --path="$WORDPRESS_DIR" --allow-root --quiet
		fi

		if ! wp plugin is-installed redis-cache --path="$WORDPRESS_DIR" --allow-root > /dev/null 2>&1; then
			echo "[Entrypoint] Installing Redis Cache plugin..."
			wp plugin install redis-cache --activate --path="$WORDPRESS_DIR" --allow-root --quiet
		fi

		echo "[Entrypoint] Enabling Redis object cache connection..."
		wp redis enable --path="$WORDPRESS_DIR" --allow-root > /dev/null 2>&1 || true
	fi
	echo "[Entrypoint] Redis configured successfully."
}

# ==========================================
# Function: Wait active (Active Polling) for MariaDB
# ==========================================
wait_db() {
	echo "[Entrypoint] Waiting for MariaDB to be fully ready and accepting connections..."

	max_retries=15
	retries=0
	while ! php -r "
		\$conn = @mysqli_connect('$WORDPRESS_DB_HOST', '$WORDPRESS_DB_USER', '$WORDPRESS_DB_PASSWORD');
		exit(\$conn ? 0 : 1);
	" > /dev/null 2>&1; do
		retries=$((retries + 1))
		if [ "$retries" -ge "$max_retries" ]; then
			echo "[Entrypoint] ❌ Timeout: MariaDB is not responding after 30 seconds. Exiting."
			exit 1
		fi
		echo "   ⏳ Database not ready yet... retrying in 2 seconds ($retries/$max_retries)"
		sleep 2
	done

	echo "[Entrypoint] ✅ MariaDB is fully ready and connected!"
}

main () {
	download_wordpress
	config_wordpress
	wait_db
	install_wordpress
	create_guest_user
	setup_redis

	chown -R nobody:nobody "$WORDPRESS_DIR"

	echo "[Entrypoint] WordPress setup completed successfully. Starting the server..."
	exec "$@"
}

main "$@"


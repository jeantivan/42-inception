#!/bin/sh

set -e

echo "[Entrypoint] Starting vsftpd..."

FTP_PASSWORD=$(cat /run/secrets/ftp_password)

if [ -z "$FTP_USER" ] || [ -z "$FTP_PASSWORD" ]; then
	echo "Error: FTP_USER and FTP_PASSWORD environment variables must be set."
	exit 1
fi

if ! id "$FTP_USER" > /dev/null 2>&1; then
	echo "[Entrypoint] Creating user $FTP_USER..."

	# Create USER
	# -D: Don't create a home directory
	# -h: Home directory
	# -s /bin/false: Set the shell to /bin/false to prevent shell access
	adduser -D -h /var/www -s /bin/false "$FTP_USER"

	# Set user password
	echo "$FTP_USER:$FTP_PASSWORD" | chpasswd

	if getent group www-data > /dev/null 2>&1; then
		echo "[Entrypoint] Adding $FTP_USER to www-data group..."
		adduser "$FTP_USER" www-data
	else
		addgroup -g 82 www-data
		adduser "$FTP_USER" www-data
	fi
fi


mkdir -p /var/www
chown -R "$FTP_USER":www-data /var/www/html
chmod -R 775 /var/www/html

echo "[Entrypoint] Config finished, starting vsftpd..."

exec "$@"

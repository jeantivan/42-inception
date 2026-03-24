#!/bin/sh

set -e

echo "[Entrypoint] Starting vsftpd service setup..."

if [ ! -f /run/secrets/ftp_password ]; then
	echo "[Entrypoint] ERROR: ftp_password is missing"
	exit 1;
fi


FTP_PASSWORD=$(cat /run/secrets/ftp_password)

if [ -z "$FTP_USER" ]; then
	echo "[Entrypoint] ERROR: FTP_USER environment variables must be set."
	exit 1
fi

if ! id "$FTP_USER" > /dev/null 2>&1; then
	echo "[Entrypoint] Creating user '$FTP_USER'..."

	# -D: No defaults / -h: Directory home is the web / -s: No shell access
	adduser -D -h /var/www/html -s /bin/false "$FTP_USER"

	# Set user password
	echo "$FTP_USER:$FTP_PASSWORD" | chpasswd

	addgroup "FTP_USER" nobody 2>/dev/null || true
fi

mkdir -p /var/www/html
chown -R "$FTP_USER":nobody /var/www/html
chmod -R 775 /var/www/html

echo "[Entrypoint] FTP cconfig finished, starting vsftpd..."

exec "$@"

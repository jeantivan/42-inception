#!/bin/sh

set -e

# Check for required secrets
if [ ! -f /run/secrets/db_root_password ] || [ ! -s /run/secrets/db_root_password ]; then
	echo "Error: db_root_password secret is missing or empty"
	exit 1
fi

if [ ! -f /run/secrets/db_password ] || [ ! -s /run/secrets/db_password ]; then
	echo "Error: db_password secret is missing or empty"
	exit 1
fi

MARIADB_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)
MARIADB_PASSWORD=$(cat /run/secrets/db_password)
MARIADB_USER=${MARIADB_USER:-mysqldefaultuser}
MARIADB_DATABASE=${MARIADB_DATABASE:-mysqldefaultdb}


if [ "$1" = "mariadbd" ]; then
	if [ ! -d "$DATADIR/mysql" ]; then
		echo "[Entrypoint] Initializing MariaDB..."

		mariadb-install-db --user=mysql --datadir="$DATADIR" --log-error=/dev/stderr --skip-test-db > /dev/null

		mariadbd --user=mysql --datadir="$DATADIR" --skip-networking > /dev/null 2>&1 & pid="$!"

		until mariadb-admin --socket=/run/mysqld/mysqld.sock ping >> /dev/null 2>&1; do
			echo "Waiting for database server to start..."
			sleep 1
		done

		echo "[Entrypoint] Database server started"

		echo "[Entrypoint] Setting up users and database..."
		mariadb > /dev/null 2>&1 <<-EOSQL
			ALTER USER 'root'@'localhost' IDENTIFIED BY '${MARIADB_ROOT_PASSWORD}';
			DELETE FROM mysql.user WHERE User='';
			DROP DATABASE IF EXISTS test;
			CREATE USER IF NOT EXISTS '${MARIADB_USER}'@'%' IDENTIFIED BY '${MARIADB_PASSWORD}';
			CREATE USER IF NOT EXISTS '${MARIADB_USER}'@'localhost' IDENTIFIED BY '${MARIADB_PASSWORD}';
			CREATE DATABASE IF NOT EXISTS \`${MARIADB_DATABASE}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
			GRANT ALL PRIVILEGES ON \`${MARIADB_DATABASE}\`.* TO '${MARIADB_USER}'@'%';
			GRANT ALL PRIVILEGES ON \`${MARIADB_DATABASE}\`.* TO '${MARIADB_USER}'@'localhost';
			FLUSH PRIVILEGES;
EOSQL

		echo "[Entrypoint] Shutting down temporary database server..."
		mariadb-admin shutdown -u root -p"${MARIADB_ROOT_PASSWORD}" > /dev/null 2>&1

		wait "$pid"

		echo "[Entrypoint] MariaDB initialization complete"
	else
		echo "[Entrypoint] MariaDB already initialized, skipping setup"
	fi
fi

exec "$@"

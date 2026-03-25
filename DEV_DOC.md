*This project has been created as part of the 42 curriculum by jtivan-r.*

# Inception - Developer Documentation

This document provides technical guidelines for developers and evaluators on how to set up, build, manage, and understand the underlying architecture of the Inception infrastructure.

## 1. Prerequisites & Setup

Before launching the project, the environment must be properly configured with the necessary tools, configuration files, and security secrets.

### Prerequisites
* **Docker & Docker Compose**: Ensure you have the latest versions installed on your host machine or Virtual Machine.
* **Make**: Required to run the automation scripts provided in the repository.
* **Host Configuration (sudo)**: The project uses a local domain (`<your-login>.42.fr`). The `Makefile` requires `sudo` privileges to automatically map `127.0.0.1` to your domain in the `/etc/hosts` file.

### Setup: Configuration Files & Secrets
To maintain strict security standards, configuration and sensitive data are decoupled:
* **Environment Variables (`.env`)**: General configurations (domain name, DB names, users) are stored in `./srcs/.env`. If missing, the `Makefile` will halt the build.
* **Secrets Management**: Passwords are **never** stored in the `.env` file or hardcoded. They must be created as plain text files inside the `./secrets/` directory. The `Makefile` strictly checks for:
  * `db_root_password.txt`
  * `db_password.txt`
  * `wordpress_admin_password.txt`
  * `wordpress_guest_password.txt`
  * `ftp_password.txt`

## 2. Compose Commands & Lifecycle Management

The project uses a `Makefile` to wrap standard Docker Compose commands (`docker compose -f ./srcs/docker-compose.yml`), providing a clear, C-style lifecycle management.

* **`make` / `make all`**: Initializes the infrastructure. It checks prerequisites, prepares host directories, builds images from scratch (`docker compose up -d --build`), and starts the containers in the background.
* **`make stop`**: Gracefully pauses the infrastructure (`docker compose stop`). Containers and networks remain intact.
* **`make clean`**: Removes the containers and networks (`docker compose down --remove-orphans`). Similar to removing `.o` files in C, the persistent data remains safe.
* **`make fclean`**: Performs a deep system wipe. It executes `docker compose down -v --rmi all`, runs a `docker system prune -a -f`, and recursively deletes the local data directories. Use this for a complete factory reset.
* **Debugging Commands**:
  * `docker ps -a` (Check container health status)
  * `docker compose -f srcs/docker-compose.yml logs -f <service>` (Tail logs)
  * `docker exec -it <container_name> sh` (Access container shell)

## 3. Data Persistence

To ensure that data survives container restarts or `make clean` executions, the project utilizes **Docker Named Volumes** mapped to specific directories on the host machine.

* **Host Location**: Persistent data is physically stored on the host at `/home/<your-login>/data`.
* **Volumes Used**:
  1. `mariadb_data`: Stores the MariaDB SQL files. Ensures all WordPress posts, users, and DB configurations persist.
  2. `wordpress_data`: Stores the downloaded WordPress core files, themes, and user uploads. It is shared between the `wordpress`, `nginx`, and `ftp` containers.
* **Persistence Mechanism**: Data remains intact through standard stops and restarts. The data is **only** wiped if you explicitly remove the volumes via `make fclean`.

## 4. Architecture & Development Notes

This section details specific architectural decisions and optimizations implemented in the Dockerfiles and Entrypoints.

### Core Services
* **NGINX**: Configured exclusively for TLSv1.3. Worker processes are correctly dropped to the `nginx` user. Cache directories are explicitly `chown`-ed to prevent 500 Internal Server Errors during heavy proxying.
* **MariaDB**: Initialization scripts are silenced (`> /dev/null 2>&1`) to keep Docker logs clean. The container runs entirely under the `mysql` user.
* **WordPress**: The entrypoint uses **Active Polling** (a PHP `mysqli_connect` loop) instead of a hardcoded `sleep` to wait for MariaDB. This prevents race conditions during the initial DB setup.

### Bonus Services
* **FTP Server (`ftp`)**: The `vsftpd` user is added to the `nobody` group. This critical step ensures that files uploaded via FTP can be seamlessly read/executed by PHP-FPM without triggering 403 Forbidden errors.
* **Redis Cache (`redis`)**: Configured as a volatile object cache. Disk persistence (`save ""`) is disabled to eliminate unnecessary I/O overhead. Health is verified via `redis-cli ping`.
* **Adminer (`adminer`)**: Implemented as a highly lightweight, stateless container. It relies on PHP's built-in web server and deliberately does *not* wait for MariaDB to start, ensuring loose coupling.
* **Static Site (`static_site`)**: Built using Astro/Node.js. The `Dockerfile` uses a highly optimized **multi-stage build** to discard dev-dependencies. It is strictly isolated and only accessible via NGINX reverse proxy (`/docs/`).

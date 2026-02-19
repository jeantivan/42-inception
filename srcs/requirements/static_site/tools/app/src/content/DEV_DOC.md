# Developer Documentation

This document is intended for developers who need to understand the technical architecture, set up the environment from scratch, build and manage the containers, and work with the project's data persistence layer.

---

## Architecture Overview

The Inception project implements a three-tier web infrastructure using Docker containers orchestrated with Docker Compose. Each service runs in an isolated container with a single responsibility:

```
┌─────────────────────────────────────────────────────────────┐
│                         Host Machine                         │
│  ┌────────────────────────────────────────────────────────┐ │
│  │              Docker Network (Bridge)                    │ │
│  │                                                          │ │
│  │   ┌──────────┐      ┌──────────┐      ┌──────────┐    │ │
│  │   │  NGINX   │ 9000 │WordPress │ 3306 │ MariaDB  │    │ │
│  │   │ (TLS)    │◄────►│ +php-fpm │◄────►│          │    │ │
│  │   └────┬─────┘      └────┬─────┘      └────┬─────┘    │ │
│  │        │ :443            │                  │           │ │
│  └────────┼─────────────────┼──────────────────┼──────────┘ │
│           │                 │                  │             │
│        ┌──▼──┐           ┌──▼──────────┐   ┌──▼──────────┐ │
│        │ :443│           │  wp_data    │   │  db_data    │ │
│        │Port │           │  (volume)   │   │  (volume)   │ │
│        └─────┘           └─────────────┘   └─────────────┘ │
│                                                              │
│         /home/<login>/data/wordpress   /home/<login>/data/db│
└─────────────────────────────────────────────────────────────┘
```

### Service Communication

- **NGINX** listens on port 443 (HTTPS) and forwards requests to WordPress on port 9000 using FastCGI
- **WordPress+PHP-FPM** processes PHP scripts and queries MariaDB on port 3306
- **MariaDB** stores all persistent data and only accepts connections from the WordPress container
- All inter-container communication happens over a private Docker bridge network

### Data Persistence

Two named Docker volumes provide persistent storage:
- `wp_data` — WordPress files (themes, plugins, uploads, core files)
- `db_data` — MariaDB database files

These volumes are backed by directories on the host at `/home/<login>/data/` but are managed entirely by Docker's volume driver.

---

## Setting Up the Environment from Scratch

### Prerequisites

Ensure the following are installed on your system:

```bash
# Check Docker
docker --version          # Should show Docker 20.x or higher
docker compose version    # Should show Compose v2.x or higher

# Check Make
make --version           # Should show GNU Make 4.x or higher
```

If any are missing:

```bash
# Install Docker (Debian/Ubuntu)
sudo apt-get update
sudo apt-get install docker.io docker-compose-plugin

# Install Make
sudo apt-get install build-essential

# Add your user to docker group to avoid needing sudo
sudo usermod -aG docker $USER
# Log out and back in for this to take effect
```

### Clone and Navigate

```bash
git clone <your-repo-url> inception
cd inception
```

### Configure Environment Variables

Copy the example file and edit it:

```bash
cp srcs/.env.example srcs/.env
vim srcs/.env  # or nano, emacs, etc.
```

Required variables in `srcs/.env`:

```bash
# Domain Configuration
DOMAIN_NAME=<your-login>.42.fr

# MariaDB Configuration
MYSQL_DATABASE=wordpress_db
MYSQL_USER=wp_user
MYSQL_ROOT_PASSWORD_FILE=/run/secrets/db_root_password
MYSQL_PASSWORD_FILE=/run/secrets/db_password

# WordPress Configuration
WP_ADMIN_USER=admin_user
WP_ADMIN_PASSWORD_FILE=/run/secrets/wp_admin_password
WP_ADMIN_EMAIL=admin@example.com
WP_USER=regular_user
WP_USER_PASSWORD_FILE=/run/secrets/wp_user_password
WP_USER_EMAIL=user@example.com

# Host Paths for Volumes
DB_DATA_PATH=/home/<your-login>/data/db
WP_DATA_PATH=/home/<your-login>/data/wordpress

# Secret Paths (relative to project root)
DB_ROOT_PASSWORD_PATH=./secrets/db_root_password.txt
DB_PASSWORD_PATH=./secrets/db_password.txt
WP_ADMIN_PASSWORD_PATH=./secrets/wp_admin_password.txt
WP_USER_PASSWORD_PATH=./secrets/wp_user_password.txt
```

### Create Docker Secrets

Create the secrets directory and generate passwords:

```bash
mkdir -p secrets

# Generate strong random passwords
openssl rand -base64 32 | tr -d '\n' > secrets/db_root_password.txt
openssl rand -base64 32 | tr -d '\n' > secrets/db_password.txt
openssl rand -base64 32 | tr -d '\n' > secrets/wp_admin_password.txt
openssl rand -base64 32 | tr -d '\n' > secrets/wp_user_password.txt

# Or set your own passwords
echo -n "your_secure_password" > secrets/db_password.txt

# Verify (should show no newlines, just the password)
cat secrets/db_password.txt && echo
```

Set appropriate permissions:

```bash
chmod 600 secrets/*.txt
```

### Update `/etc/hosts`

Add your domain to the hosts file:

```bash
sudo bash -c 'echo "127.0.0.1 <your-login>.42.fr" >> /etc/hosts'
```

Or let the Makefile handle it (if configured to do so).

---

## Building and Launching the Project

### Using the Makefile

The Makefile provides convenient targets for managing the entire lifecycle:

```bash
# Build images and start containers
make

# Same as 'make', but more explicit
make all

# Build images without starting containers
make build

# Start containers (assumes images already built)
make up

# Stop containers (keep volumes and images)
make down

# Stop and remove containers, volumes, networks, and images
make fclean

# Full rebuild from scratch
make re
```

### Using Docker Compose Directly

For more granular control:

```bash
cd srcs

# Build all services
docker compose build

# Build a specific service
docker compose build nginx
docker compose build wordpress
docker compose build mariadb

# Start services in detached mode
docker compose up -d

# View logs in real-time
docker compose logs -f

# Stop services
docker compose down

# Stop and remove volumes (WARNING: deletes data)
docker compose down -v
```

### Build Order and Dependencies

Docker Compose automatically handles the build order based on the `depends_on` directives in `docker-compose.yml`:

1. **MariaDB** — Built first, has no dependencies
2. **WordPress** — Waits for MariaDB to be healthy
3. **NGINX** — Waits for WordPress to be ready

---

## Managing Containers and Volumes

### Container Management

```bash
# List running containers
docker ps

# List all containers (including stopped)
docker ps -a

# View logs for a specific container
docker logs inception_nginx_1
docker logs -f inception_wordpress_1  # Follow mode

# Execute commands inside a running container
docker exec -it inception_mariadb_1 bash
docker exec -it inception_wordpress_1 sh

# Restart a single container
docker restart inception_nginx_1

# Stop a single container
docker stop inception_wordpress_1

# Remove a stopped container
docker rm inception_mariadb_1

# View resource usage
docker stats
```

### Volume Management

```bash
# List all volumes
docker volume ls

# Inspect a volume (shows mount point and metadata)
docker volume inspect wp_data
docker volume inspect db_data

# Check volume contents (from host)
sudo ls -lah /home/<login>/data/wordpress
sudo ls -lah /home/<login>/data/db

# Backup a volume
docker run --rm -v wp_data:/data -v $(pwd):/backup \
  alpine tar czf /backup/wp_data_backup.tar.gz /data

# Restore a volume
docker run --rm -v wp_data:/data -v $(pwd):/backup \
  alpine tar xzf /backup/wp_data_backup.tar.gz -C /

# Remove a volume (WARNING: deletes data)
docker volume rm wp_data
```

### Network Management

```bash
# List networks
docker network ls

# Inspect the project network
docker network inspect inception_network

# See which containers are connected
docker network inspect inception_network | grep -A 5 "Containers"

# Test connectivity between containers
docker exec inception_wordpress_1 ping mariadb
docker exec inception_wordpress_1 nc -zv mariadb 3306
```

---

## Project Data Storage and Persistence

### Volume Configuration

Volumes are defined in `srcs/docker-compose.yml`:

```yaml
volumes:
  db_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/<login>/data/db

  wp_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/<login>/data/wordpress
```

This configuration creates **named volumes** backed by specific host directories. Docker manages the volumes, but the data is stored at predictable locations.

### Data Location on Host

All persistent data lives at:

```
/home/<login>/data/
├── db/                    # MariaDB data directory
│   ├── mysql/             # System tables
│   ├── wordpress_db/      # Your WordPress database
│   └── ib_logfile*        # InnoDB logs
│
└── wordpress/             # WordPress installation
    ├── wp-content/
    │   ├── themes/        # WordPress themes
    │   ├── plugins/       # WordPress plugins
    │   └── uploads/       # User uploads
    ├── wp-config.php      # WordPress config
    └── ...
```

### Data Persistence Behavior

- **Survives `make down`** — Stopping containers does not affect volumes
- **Survives `docker compose down`** — Same as above
- **Survives container removal** — Volumes are independent of container lifecycle
- **Does NOT survive `make fclean`** — Explicitly removes volumes
- **Does NOT survive `docker compose down -v`** — The `-v` flag removes volumes

### Accessing Data

#### From the Host

```bash
# Read WordPress config
cat /home/<login>/data/wordpress/wp-config.php

# Check database files
sudo ls -lh /home/<login>/data/db/wordpress_db/

# View uploaded images
ls -lh /home/<login>/data/wordpress/wp-content/uploads/
```

#### From Inside Containers

```bash
# WordPress container
docker exec -it inception_wordpress_1 sh
ls -la /var/www/html/

# MariaDB container
docker exec -it inception_mariadb_1 bash
mysql -u root -p$(cat /run/secrets/db_root_password)
```

---

## Working with Dockerfiles

Each service has its own Dockerfile in `srcs/requirements/<service>/`:

```
srcs/requirements/
├── mariadb/
│   ├── Dockerfile
│   ├── .dockerignore
│   ├── conf/              # MariaDB configuration files
│   └── tools/             # Initialization scripts
│
├── wordpress/
│   ├── Dockerfile
│   ├── .dockerignore
│   ├── conf/              # PHP-FPM and WordPress config
│   └── tools/             # Setup scripts (WP-CLI)
│
└── nginx/
    ├── Dockerfile
    ├── .dockerignore
    ├── conf/              # NGINX config, SSL certs
    └── tools/             # Certificate generation scripts
```

### Dockerfile Best Practices (Used in This Project)

1. **Use specific base image tags** — Never use `latest`
   ```dockerfile
   FROM debian:bullseye
   # NOT: FROM debian:latest
   ```

2. **Minimize layers** — Combine RUN commands
   ```dockerfile
   RUN apt-get update && apt-get install -y \
       nginx \
       openssl \
    && rm -rf /var/lib/apt/lists/*
   ```

3. **Use .dockerignore** — Exclude unnecessary files from build context

4. **No passwords in Dockerfiles** — Use Docker secrets or build args
   ```dockerfile
   # WRONG
   ENV DB_PASSWORD=secret123

   # CORRECT
   RUN --mount=type=secret,id=db_password \
       cat /run/secrets/db_password > /tmp/pass
   ```

5. **Run as non-root when possible** — But MariaDB/MySQL require root during init

6. **Single process per container** — Use `exec` form of ENTRYPOINT
   ```dockerfile
   ENTRYPOINT ["nginx", "-g", "daemon off;"]
   ```

### Rebuilding After Dockerfile Changes

```bash
# Rebuild a single service
docker compose build --no-cache nginx

# Rebuild everything
make fclean && make

# Rebuild and start
docker compose up -d --build
```

---

## Debugging and Troubleshooting

### Check Container Health

```bash
# View container status
docker ps

# Detailed inspection
docker inspect inception_nginx_1 | jq '.[0].State'
```

### View Logs

```bash
# Last 100 lines
docker logs --tail 100 inception_mariadb_1

# Follow logs in real-time
docker logs -f inception_wordpress_1

# Show timestamps
docker logs -t inception_nginx_1

# All services at once
docker compose logs -f
```

### Test Network Connectivity

```bash
# From WordPress to MariaDB
docker exec inception_wordpress_1 ping -c 3 mariadb
docker exec inception_wordpress_1 nc -zv mariadb 3306

# From NGINX to WordPress
docker exec inception_nginx_1 nc -zv wordpress 9000

# DNS resolution
docker exec inception_wordpress_1 nslookup mariadb
```

### Inspect Container Filesystem

```bash
# Get a shell inside the container
docker exec -it inception_wordpress_1 sh

# Run a one-off command
docker exec inception_nginx_1 ls -la /etc/nginx/

# Copy files from container to host
docker cp inception_wordpress_1:/var/www/html/wp-config.php .
```

### Test MariaDB Connection

```bash
# From host (if port is exposed)
mysql -h 127.0.0.1 -u wp_user -p

# From inside MariaDB container
docker exec -it inception_mariadb_1 mysql -u root -p
```

### Verify WordPress Installation

```bash
# Using WP-CLI
docker exec inception_wordpress_1 wp core version
docker exec inception_wordpress_1 wp user list
docker exec inception_wordpress_1 wp plugin list

# Check PHP-FPM status
docker exec inception_wordpress_1 ps aux | grep php-fpm
```

### Common Issues and Solutions

#### Container exits immediately after start

**Check:** Container logs and Dockerfile CMD/ENTRYPOINT

```bash
docker logs inception_mariadb_1
```

**Common causes:**
- Process runs in background (use `daemon off` for nginx, `mysqld` for MariaDB)
- Script exits with error
- Missing required files or secrets

#### "Connection refused" between containers

**Check:** Network configuration and service names

```bash
docker network inspect inception_network
docker exec inception_wordpress_1 ping mariadb
```

**Solution:** Use service names defined in `docker-compose.yml`, not container names or IPs

#### Permission denied on volumes

**Check:** Volume mount points and ownership

```bash
ls -la /home/<login>/data/
docker exec inception_wordpress_1 ls -la /var/www/html/
```

**Solution:** Adjust ownership on host or in Dockerfile

```bash
sudo chown -R www-data:www-data /home/<login>/data/wordpress
```

#### Secrets not found

**Check:** Secrets paths in `.env` and `docker-compose.yml`

```bash
docker exec inception_mariadb_1 ls -la /run/secrets/
```

**Solution:** Verify secret files exist and paths in `docker-compose.yml` are correct

---

## Testing and Validation

### Manual Testing Checklist

- [ ] All containers start successfully: `docker ps` shows 3+ running containers
- [ ] NGINX serves HTTPS on port 443: `curl -k https://localhost`
- [ ] WordPress homepage loads: Visit `https://<login>.42.fr` in browser
- [ ] WordPress admin accessible: `https://<login>.42.fr/wp-admin`
- [ ] Can create a post and it persists after `make down && make`
- [ ] Database contains expected data: `docker exec inception_mariadb_1 mysql ...`
- [ ] Logs show no critical errors: `docker compose logs | grep -i error`

### Automated Health Checks

Docker Compose can define health checks:

```yaml
services:
  mariadb:
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      interval: 10s
      timeout: 5s
      retries: 5
```

Check health status:
```bash
docker inspect inception_mariadb_1 | jq '.[0].State.Health'
```

---

## Development Workflow

### Making Changes to Services

1. **Modify configuration files** in `srcs/requirements/<service>/conf/`
2. **Rebuild the affected service:**
   ```bash
   docker compose build nginx
   ```
3. **Restart the service:**
   ```bash
   docker compose up -d nginx
   ```
4. **Verify changes:**
   ```bash
   docker logs nginx
   curl -k https://localhost
   ```

### Adding a New Service (Bonus)

1. Create service directory:
   ```bash
   mkdir -p srcs/requirements/bonus/redis
   ```

2. Write Dockerfile:
   ```bash
   vim srcs/requirements/bonus/redis/Dockerfile
   ```

3. Add service to `docker-compose.yml`:
   ```yaml
   redis:
     build: ./requirements/bonus/redis
     networks:
       - inception_network
     restart: unless-stopped
   ```

4. Update WordPress to use Redis (if applicable)
5. Build and test:
   ```bash
   docker compose build redis
   docker compose up -d redis
   docker logs redis
   ```

### Version Control Best Practices

**Always commit:**
- Dockerfiles
- Configuration files
- Scripts
- `docker-compose.yml`
- `.env.example` (template)
- Documentation

**Never commit:**
- `.env` (actual values)
- `secrets/` directory
- Compiled binaries
- Temporary files

---

## Additional Resources

- [Docker Compose File Reference](https://docs.docker.com/compose/compose-file/)
- [Dockerfile Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [Docker Networking Deep Dive](https://docs.docker.com/network/)
- [Docker Volume Management](https://docs.docker.com/storage/volumes/)
- [WP-CLI Commands](https://developer.wordpress.org/cli/commands/)
- [NGINX FastCGI Configuration](https://nginx.org/en/docs/http/ngx_http_fastcgi_module.html)
- [MariaDB Docker Documentation](https://hub.docker.com/_/mariadb)

# User Documentation

This document explains how to use the Inception infrastructure from an end-user or administrator perspective. You don't need to understand Docker internals to follow this guide — just the basics of starting, stopping, and accessing the services.

---

## What Services Are Provided

The Inception stack provides a complete WordPress website running over HTTPS. The infrastructure consists of three interconnected services:

1. **NGINX Web Server** — The front door to your infrastructure. All traffic enters through NGINX on port 443 using encrypted HTTPS (TLSv1.2/TLSv1.3). NGINX handles SSL/TLS termination and forwards requests to WordPress.

2. **WordPress + PHP-FPM** — Your content management system. WordPress runs with PHP-FPM to handle dynamic content generation, theme rendering, and plugin execution. You can create posts, pages, manage users, and customize your site through the WordPress admin panel.

3. **MariaDB Database** — The persistent storage backend. All WordPress content (posts, pages, users, settings) is stored in a MariaDB database. This data persists across container restarts and rebuilds.

Additionally, the stack may include optional bonus services such as:
- **Redis Cache** — Speeds up WordPress by caching frequently accessed data
- **FTP Server** — Allows file uploads directly to the WordPress volume
- **Adminer** — Web-based database management tool
- **Static Website** — A separate site served alongside WordPress

---

## Starting the Project

From the project root directory, run:

```bash
make
```

This command will:
- Create the necessary host directories for persistent data storage
- Build Docker images for each service (if not already built)
- Start all containers in the correct order
- Wait for services to become healthy

The first startup may take 2-5 minutes as Docker downloads base images and builds custom images from the Dockerfiles. Subsequent starts are much faster (usually under 30 seconds).

**Expected output:**
```
Creating network "inception_network" ...
Creating volume "db_data" ...
Creating volume "wp_data" ...
Building mariadb...
Building wordpress...
Building nginx...
Starting inception_mariadb_1 ... done
Starting inception_wordpress_1 ... done
Starting inception_nginx_1 ... done
```

Once you see all containers marked as "done" or "healthy", the stack is ready.

---

## Stopping the Project

To stop all services while preserving your data (recommended for normal shutdowns):

```bash
make down
```

This stops and removes the containers but leaves the Docker volumes intact — your WordPress site and database remain safe.

To perform a **full cleanup** (removes containers, volumes, networks, and images):

```bash
make fclean
```

⚠️ **Warning:** `make fclean` will **permanently delete** all WordPress content and database records. Only use this if you want to start completely fresh.

---

## Accessing the Website

Once the stack is running, open your browser and navigate to:

```
https://<your-login>.42.fr
```

Replace `<your-login>` with your actual 42 login. For example, if your login is `jdoe`, visit:

```
https://jdoe.42.fr
```

### Self-Signed Certificate Warning

Because the TLS certificate is self-signed (not issued by a trusted Certificate Authority), your browser will display a security warning:

- **Chrome/Edge:** "Your connection is not private"
- **Firefox:** "Warning: Potential Security Risk Ahead"
- **Safari:** "This Connection Is Not Private"

This is **expected and safe** in a development/learning environment. Click "Advanced" → "Proceed to site" (wording varies by browser) to continue.

---

## Accessing the Administration Panel

WordPress provides a web-based admin panel for managing your site. Access it at:

```
https://<your-login>.42.fr/wp-admin
```

### Admin Credentials

Your administrator username and password are defined in the `.env` file:

- **Username:** Check the `WP_ADMIN_USER` variable
- **Password:** Stored in the file referenced by `WP_ADMIN_PASSWORD_FILE` (typically `secrets/wp_admin_password.txt`)

Example login:
```
Username: admin_user
Password: (contents of secrets/wp_admin_password.txt)
```

### Regular User Credentials

A second, non-admin user is also created during setup:

- **Username:** Check the `WP_USER` variable
- **Password:** Stored in the file referenced by `WP_USER_PASSWORD_FILE` (typically `secrets/wp_user_password.txt`)

This user has editor or author privileges but cannot change critical site settings.

---

## Locating and Managing Credentials

All sensitive credentials are stored in **two places**:

### 1. The `.env` File (Non-Sensitive Config)

Located at `srcs/.env`, this file contains non-sensitive configuration like:
- Domain name
- Database name
- Usernames
- Paths to secret files

You can edit this file with any text editor, but **never commit it to Git**.

### 2. The `secrets/` Directory (Passwords)

Located at `secrets/` in the project root, this directory contains plain-text files with passwords:

```
secrets/
├── db_root_password.txt       # MariaDB root password
├── db_password.txt            # MariaDB WordPress user password
├── ftp_password.txt           # FTP server password (if FTP bonus is enabled)
├── wp_admin_password.txt      # WordPress admin password
└── wp_user_password.txt       # WordPress regular user password
```

**To view a password:**
```bash
cat secrets/wp_admin_password.txt
```

**To change a password:**
1. Edit the corresponding file in `secrets/`
2. Run `make fclean` to remove the old containers
3. Run `make` to rebuild with the new password

⚠️ **Important:** The `secrets/` directory is in `.gitignore` and must never be committed to version control.

---

## Checking That Services Are Running Correctly

### Method 1: Check Container Status

Run:
```bash
docker ps
```

You should see three running containers (plus any bonus services):
```
CONTAINER ID   IMAGE                  STATUS          PORTS                   NAMES
a1b2c3d4e5f6   inception_nginx        Up 2 minutes    0.0.0.0:443->443/tcp    inception_nginx_1
b2c3d4e5f6a7   inception_wordpress    Up 2 minutes    9000/tcp                inception_wordpress_1
c3d4e5f6a7b8   inception_mariadb      Up 2 minutes    3306/tcp                inception_mariadb_1
```

All containers should show `Up` status. If any show `Restarting` or `Exited`, there's a problem.

### Method 2: Check Container Logs

To see what a specific service is doing:
```bash
docker logs inception_nginx_1
docker logs inception_wordpress_1
docker logs inception_mariadb_1
```

Look for errors (lines starting with `ERROR`, `FATAL`, or `CRITICAL`). Successful startup logs typically end with messages like:
- NGINX: `"nginx: [notice] started"`
- WordPress: `"NOTICE: ready to handle connections"`
- MariaDB: `"mysqld: ready for connections"`

### Method 3: Test the Website

Simply visit `https://<your-login>.42.fr` in your browser. If the WordPress homepage loads, the stack is working correctly.

### Method 4: Check Data Persistence

1. Log in to WordPress admin and create a test post
2. Run `make down` to stop the containers
3. Run `make` to restart
4. Verify your test post is still there

If the post survives the restart, your volumes are correctly configured.

---

## Troubleshooting Common Issues

### "Connection refused" or "Site can't be reached"

**Cause:** NGINX container isn't running or port 443 is blocked.

**Solution:**
1. Check if NGINX is running: `docker ps | grep nginx`
2. Make sure port 443 isn't used by another service: `sudo lsof -i :443`
3. Check NGINX logs: `docker logs inception_nginx_1`

### "Database connection error"

**Cause:** MariaDB isn't ready or WordPress has wrong credentials.

**Solution:**
1. Wait 30 seconds — MariaDB can take time to initialize on first startup
2. Check MariaDB logs: `docker logs inception_mariadb_1`
3. Verify credentials in `srcs/.env` match those in `secrets/db_password.txt`

### "502 Bad Gateway"

**Cause:** WordPress+PHP-FPM container isn't running or isn't reachable.

**Solution:**
1. Check if WordPress is running: `docker ps | grep wordpress`
2. Check WordPress logs: `docker logs inception_wordpress_1`
3. Restart the stack: `make down && make`

### Site loads but shows "Error establishing database connection"

**Cause:** WordPress can't communicate with MariaDB container.

**Solution:**
1. Verify both containers are on the same Docker network: `docker network inspect inception_network`
2. Check that the database name in `.env` matches the database created in MariaDB
3. Rebuild from scratch: `make fclean && make`

---

## Where to Find Help

- Check container logs: `docker logs <container_name>`
- Inspect running containers: `docker ps -a`
- View Docker networks: `docker network ls`
- View Docker volumes: `docker volume ls`
- Consult the [Developer Documentation](DEV_DOC.md) for technical details
- Refer to the [README](README.md) for project overview and setup instructions

*This project has been created as part of the 42 curriculum by jtivan-r.*

# Inception

## Table of Content

  * [Description](#description)
  * [Virtual Machines vs Docker](#virtual-machines-vs-docker)
  * [Secrets vs Environment Variables](#secrets-vs-environment-variables)
  * [Docker Network vs Host Network](#docker-network-vs-host-network)
  * [Docker Volumes vs Bind Mounts](#docker-volumes-vs-bind-mounts)
  * [Instructions](#instructions)
    - [Prerequisites](#prerequisites)
    - [Step 1: Configure Environment Variables](#step-1-configure-environment-variables)
    - [Step 2: Create secrets](#step-2-create-the-secrets)
    - [Step 3: Build and run](#step-3-build-and-run)
    - [Step 4: Access the site](#step-4-access-the-site)
  * [Bonus Services](#bonus-services)
  * [Resources](#resources)
    - [Official Documentation](#official-documentation)
    - [Tutorial & Articles](#tutorials--articles)
  * [AI Usage Disclosure](#ai-usage-disclosure)


---
## Description

Inception is a system administration project that deepens your understanding of Docker and containerization by building a small but complete web infrastructure from scratch. Rather than pulling pre-built images, you write your own Dockerfiles for each service and orchestrate them with Docker Compose — all running inside a personal virtual machine.

The stack is composed of three core services, each isolated in its own container:

- **NGINX** — the sole entry point into the infrastructure, serving traffic exclusively over HTTPS (TLSv1.2/TLSv1.3) on port 443.
- **WordPress + php-fpm** — the application layer, communicating with NGINX over port 9000.
- **MariaDB** — the database backend, storing all WordPress data persistently.

Two named Docker volumes provide persistent storage: one for the WordPress database and one for the WordPress website files. All containers are connected through a dedicated Docker network and are configured to restart automatically on failure.

---

### Virtual Machines vs Docker

A **Virtual Machine (VM)** emulates an entire physical computer, including its own OS kernel, hardware drivers, and system libraries. This makes VMs very isolated and flexible but also heavy — each VM can consume several gigabytes of RAM and take minutes to boot.

**Docker containers**, on the other hand, share the host's OS kernel and isolate only the application and its dependencies in user space. This makes containers lightweight (often just megabytes), nearly instant to start, and much more efficient with system resources. The trade-off is a slightly thinner isolation boundary compared to a full VM.

In this project, Docker is run *inside* a VM to combine both approaches: the VM provides a clean, reproducible environment, while Docker manages the service-level isolation and orchestration within it.

---

### Secrets vs Environment Variables

**Environment variables** are the standard way to pass configuration values (database names, usernames, etc.) into containers. They are convenient and natively supported by Docker and Docker Compose via `.env` files. However, their values can be visible in process listings (`ps aux`), image layers, and `docker inspect` output, which makes them unsuitable for sensitive data.

**Docker secrets** are the recommended way to handle confidential information such as passwords and API keys. Secrets are stored encrypted on disk, mounted into containers as in-memory files (under `/run/secrets/`), and never exposed in environment variables or image history. In this project, sensitive credentials are stored in a `secrets/` directory and referenced via Docker secrets, while non-sensitive configuration lives in the `.env` file.

---

### Docker Network vs Host Network

With **host network** mode (`network: host`), the container shares the host machine's network stack directly. There is no network isolation — the container sees the same interfaces and IP addresses as the host. This can improve raw performance but eliminates isolation and is **forbidden** in this project.

A **Docker network** (bridge mode) creates a private virtual network shared only among the containers you explicitly connect to it. Each container gets its own virtual IP address and communicates with others by service name (DNS resolution handled by Docker). External traffic can only reach the infrastructure through explicitly published ports — in this project, solely port 443 on the NGINX container. This is the correct approach for a secure, well-isolated infrastructure.

---

### Docker Volumes vs Bind Mounts

**Bind mounts** map a specific path on the host machine directly into the container. They are simple but tightly couple the container to the host's filesystem layout, making the setup less portable and harder to manage.

**Docker named volumes** are managed entirely by Docker. Docker creates and maintains the storage area, and containers reference volumes by name rather than by host path. Named volumes are more portable, easier to back up, and better suited for production-style data persistence. In this project, named volumes are mandatory for the WordPress database and website files, and their data is stored at `/home/<login>/data` on the host — but accessed through Docker's volume management layer, not as raw bind mounts.

---

## Instructions

### Prerequisites

Before running the project, make sure the following are available on your system:

- **Docker** (with Docker Compose support)
- **GNU Make**
- **sudo privileges** (required by the Makefile to manage host directories and `/etc/hosts`)
- **Internet connection** (needed during the first build to download base images and packages)
- **Port 443 free** — NGINX is the sole entry point and binds exclusively to port 443. If something else is already listening on that port, the stack will fail to start. Running the project inside a dedicated VM is strongly recommended to avoid conflicts.


### Step 1: Configure environment variables

Copy the provided example file and fill in your values:

```bash
cp srcs/.env.example srcs/.env
```

Open `srcs/.env` and set every variable. The file is self-documented — each variable has a comment describing its purpose. Key variables include your domain name, database name, usernames, and the paths to your secret files (see Step 2).

> ⚠️ Never commit `.env` to your repository. It is listed in `.gitignore` by default.


### Step 2: Create the secrets

Sensitive credentials are never stored in environment variables or Dockerfiles. Instead, they are read from plain-text files at runtime via Docker secrets.

Create a `secrets/` directory at the root of the project and add one file per secret, each containing **only the password string** with no extra whitespace or newline:

```
secrets/
├── db_root_password.txt       # MariaDB root password
├── db_password.txt            # MariaDB password for the WordPress user
├── ftp_password.txt           # FTP server password
├── wp_admin_password.txt      # WordPress administrator password
└── wp_user_password.txt       # WordPress regular user password
```

Example — creating a secret file:
```bash
echo -n "mySuperSecretPassword" > secrets/db_password.txt
```

Once the files are created, update the corresponding path variables in your `srcs/.env` file to point to each one (the variable names are listed in `.env.example`).

> ⚠️ The `secrets/` directory must be added to `.gitignore`. Committing passwords to a repository will result in immediate project failure.


### Step 3: Build and run

Once the environment file and secrets are in place, launch the entire infrastructure with a single command from the project root:

```bash
make
```

The Makefile will create the required host directories, build all Docker images from their respective Dockerfiles, and bring the stack up with Docker Compose. The first build may take a few minutes depending on your internet connection.

To stop and remove the containers while preserving your data volumes:

```bash
make down
```

To perform a full teardown (containers, volumes, and built images):

```bash
make fclean
```


### Step 4: Access the site

Once the stack is running, open your browser and navigate to:

```
https://<your-login>.42.fr
```

> Because the TLS certificate is self-signed, your browser will show a security warning — this is expected. Accept the exception to proceed to the WordPress site.

The WordPress admin panel is available at:

```
https://<your-login>.42.fr/wp-admin
```

---
---

## Bonus Services

In addition to the mandatory requirements, this project implements several bonus features to enhance performance, usability, and the development workflow. These services are fully integrated into the existing `inception_network`.

- **Redis Cache (`redis`)** An in-memory data structure store configured as an object cache for WordPress. It significantly improves database query performance and page load times. The WordPress container is configured with a strict dependency and will only start once the Redis healthcheck (`redis-cli ping`) is successful.

- **FTP Server (`ftp`)** A File Transfer Protocol server connected directly to the `wordpress_data` volume. It allows administrators to remotely upload, download, and manage the website's core files, themes, and plugins via port 21 (control) and ports 30000-30009 (passive data connections), using the secure credentials defined in your `secrets/` directory.

- **Adminer (`adminer`)** A lightweight, full-featured database management tool contained in a single PHP file. It provides a clean Graphical User Interface (GUI) to easily inspect and manage the MariaDB database without needing to use the command line.
  > **Access:** `http://<your-login>.42.fr/adminer`

- **Static Website (`static_site`)** A standalone static webpage served as a production-ready Node.js application. It is built using a highly optimized multi-stage Dockerfile that compiles the assets and runs only the lightweight runtime environment. Following the strict network isolation rules, it is not exposed directly to the host; instead, NGINX acts as a reverse proxy to serve it securely over HTTPS.
  > **Access:** `https://<your-login>.42.fr/docs/`

---

## Resources

### Official Documentation

- **Docker**
  - [Docker Documentation](https://docs.docker.com/) — Official Docker docs covering images, containers, Dockerfiles, and best practices
  - [Docker Compose Documentation](https://docs.docker.com/compose/) — Guide to multi-container orchestration with Compose
  - [Dockerfile Reference](https://docs.docker.com/engine/reference/builder/) — Complete syntax reference for writing Dockerfiles
  - [Docker Secrets](https://docs.docker.com/engine/swarm/secrets/) — Managing sensitive data in Docker

- **NGINX**
  - [NGINX Documentation](https://nginx.org/en/docs/) — Official NGINX documentation
  - [NGINX SSL/TLS Configuration](https://nginx.org/en/docs/http/configuring_https_servers.html) — Setting up HTTPS with TLS
  - [NGINX and FastCGI](https://nginx.org/en/docs/http/ngx_http_fastcgi_module.html) — Connecting NGINX to PHP-FPM

- **MariaDB**
  - [MariaDB Documentation](https://mariadb.com/kb/en/documentation/) — Official MariaDB knowledge base
  - [MariaDB Server System Variables](https://mariadb.com/kb/en/server-system-variables/) — Configuration reference
  - [MariaDB in Docker](https://hub.docker.com/_/mariadb) — Official Docker image documentation

- **WordPress**
  - [WordPress Documentation](https://wordpress.org/documentation/) — Official WordPress docs
  - [WP-CLI](https://wp-cli.org/) — Command-line interface for WordPress (used for automated setup)

### Tutorials & Articles

- [Docker Best Practices for Writing Dockerfiles](https://docs.docker.com/develop/dev-best-practices/)
- [Understanding Docker Networking](https://docs.docker.com/network/)
- [Managing Persistent Data with Docker Volumes](https://docs.docker.com/storage/volumes/)

---

### AI Usage Disclosure

AI tools were used throughout this project to accelerate development and improve productivity. Specifically:

- **Planning & Architecture** — Used AI to explore design patterns, compare approaches (e.g., secrets vs environment variables), and clarify Docker best practices.
- **Development & Debugging** — GitHub Copilot assisted with boilerplate code generation, configuration syntax, and suggesting solutions for build and runtime errors.
- **Documentation** — AI was used to draft, structure, and refine this README and related documentation files, ensuring clarity and completeness.

> All AI-generated content was carefully reviewed, tested, and adapted to the specific requirements of the project.

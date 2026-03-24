*This project has been created as part of the 42 curriculum by \<login\>.*

# Inception - Developer Documentation

This document provides technical guidelines for developers on how to set up, build, manage, and understand the underlying architecture of the Inception infrastructure.

## 1. Setting Up the Environment from Scratch

[cite_start]Before launching the project, the environment must be properly configured with the necessary prerequisites, configuration files, and secrets[cite: 519].

### Prerequisites
* **Docker & Docker Compose**: Ensure you have the latest versions installed on your host machine or Virtual Machine.
* **Make**: Required to run the automation scripts provided in the repository.
* **Host Configuration**: The project uses a local domain (`jtivan-r.42.fr`). The `Makefile` includes a `check_host` rule that automatically appends `127.0.0.1 jtivan-r.42.fr` to your `/etc/hosts` file.

### Configuration Files
* **Environment Variables**: General environment configurations are stored in an `.env` file located at `./srcs/.env`. If it does not exist, the `Makefile` will prompt an error. You must create it and define variables such as `DOMAIN_NAME` and other non-sensitive setup parameters.

### Secrets Management
For security reasons, passwords are not stored in the `.env` file or hardcoded into Dockerfiles. They must be created as plain text files inside the `./secrets/` directory. The `Makefile` will strictly check for the existence of the following files before building:
* `db_root_password.txt`
* `db_password.txt`
* `wordpress_admin_password.txt`
* `wordpress_guest_password.txt`
* `ftp_password.txt` (Required for the bonus part)

## 2. Building and Launching the Project

[cite_start]The project relies on a `Makefile` to orchestrate the build process using Docker Compose[cite: 520]. The compose file is located at `./srcs/docker-compose.yml`.

* **Initialization**: Run `make` or `make up`. This command executes a sequence of checks (`check_files`, `check_host`, `prepare_dirs`), builds the Docker images from scratch (`--no-cache`), and brings up the containers in detached mode (`-d`).
* **Under the Hood**: The `Makefile` ensures that the data directories are created on the host before Docker attempts to bind them, preventing permission issues.

## 3. Managing Containers and Volumes

[cite_start]You can manage the lifecycle of the infrastructure using the following `Makefile` rules and Docker commands[cite: 521]:

* **`make clean`**: Gracefully stops all running containers defined in the compose file without destroying them.
* **`make down`**: Stops and removes all containers, networks, and named volumes associated with the project (`docker compose down -v`). Use this for a complete reset.
* **Manual Debugging**:
  * Use `docker ps` to verify the state of the containers.
  * Use `docker logs <container_name>` to inspect the output of a specific service (e.g., NGINX, WordPress, MariaDB).
  * Use `docker exec -it <container_name> sh` to open a shell inside a running container for direct troubleshooting.

## 4. Data Storage and Persistence

[cite_start]To ensure that data survives container restarts or removals, the project utilizes Docker named volumes[cite: 522].

* **Host Location**: According to the `Makefile`, the persistent data is physically stored on the host machine at `/home/${USER}/data`.
* **Volumes Used**:
  1. **Database Volume**: Stores the MariaDB data files, ensuring all WordPress posts, users, and configurations persist.
  2. **Web Files Volume**: Stores the downloaded WordPress core files and user uploads, shared between the WordPress and NGINX (if needed) or FTP containers.
* **Persistence Mechanism**: Even if you run `make clean`, the data remains intact in the `VOLUME_DIR`. The data is only wiped if you explicitly remove the volumes (e.g., via `make down` which uses the `-v` flag, or `make fclean`).

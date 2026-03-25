*This project has been created as part of the 42 curriculum by jtivan-r.*

# Inception - User Documentation

This document explains in clear and simple terms how an end user or administrator can interact with the Inception infrastructure.

## 1. Services Provided by the Stack

This infrastructure sets up a complete web environment using isolated containers to provide the following core and bonus services:

* **NGINX (Core)**: Acts as the sole web server and entry point to the infrastructure. It ensures secure connections by serving traffic exclusively over HTTPS (TLSv1.3) on port 443.
* **WordPress (Core)**: The content management system (CMS) and application layer. It runs alongside `php-fpm` to generate and serve the website content.
* **MariaDB (Core)**: The database management system securely storing all the information, posts, and configurations for the WordPress site.
* **Bonus Services**: The stack also includes **Redis** (for object caching), an **FTP Server** (for file management), **Adminer** (for database administration), and a **Static Website** (showcase page). See Section 6 for more details.

## 2. Starting and Stopping the Project

You can easily manage the lifecycle of the project using the provided `Makefile` at the root of the repository:

* **To start the project**: Run `make` (or `make all`). This command will prepare the necessary directories, verify your secrets, build the Docker images, and start the containers in the background.
* **To pause the project**: Run `make stop`. This halts the running containers and pauses the processes, but keeps the containers intact and ready to resume.
* **To clean the infrastructure**: Run `make clean`. This stops and safely removes the containers and networks. Your persistent data (database and website files) remains perfectly safe in the volumes.
* **To completely wipe the project**: Run `make fclean`.
	> **Warning:** This is a deep clean. It will remove all containers, networks, built images, and permanently delete all persistent data volumes and local host directories.
* **To restart from scratch**: Run `make re`. This executes a full clean (`fclean`) followed by a fresh build (`all`).

## 3. Accessing the Website and Administration Panel

Once the stack is successfully running, you can access the web interfaces via your preferred web browser:

* **Public Website**: Navigate to `https://<your-login>.42.fr` (e.g., `https://jtivan-r.42.fr`).
* **Administration Panel**: Navigate to `https://<your-login>.42.fr/wp-admin` to log in and manage the site content.

> **Note:** Because the TLS certificate used for HTTPS is self-signed for local development, your browser will likely display a security warning. You can safely accept the exception/risk to proceed to the site.

## 4. Locating and Managing Credentials

To ensure maximum security, sensitive information is not hardcoded into the project files. Administrators can locate and manage credentials as follows:

* **Secrets**: All passwords (MariaDB root, MariaDB user, WordPress admin, WordPress guest, FTP password, etc.) are stored as plain text files inside the `secrets/` directory at the root of the project.
* **Environment Variables**: General configuration data (like domain names and database names) is located in the `.env` file inside the `srcs/` directory.
* **Managing Credentials**: To update a password or configuration, simply edit the corresponding file in the `secrets/` directory or the `.env` file **before** building and starting the project with `make`.

## 5. Checking that Services are Running Correctly

Administrators can verify that the infrastructure is healthy and running smoothly using the following methods:

* **Container Status**: Run `docker ps` in your terminal. You should see all your containers (NGINX, WordPress, MariaDB, and the bonus services) listed with a status of "Up" and "(healthy)".
* **Service Logs**: Run `docker compose -f srcs/docker-compose.yml logs -f` to output the consolidated logs of all your running containers. This is the best way to troubleshoot issues, monitor incoming web requests, and verify that the database and web server initialized without errors.

## 6. Bonus Services and Features

In addition to the core infrastructure, this project includes several extended functionalities that enhance usability and performance.

* **Adminer (Database GUI)**: You can manage the MariaDB database through a user-friendly graphical interface. Because NGINX is the only entry point, access it securely by navigating to `https://<your-login>.42.fr/adminer` (or via its mapped port, depending on your NGINX routing configuration).
* **Static Website**: A standalone showcase website running in a highly optimized production environment. You can securely visit it by navigating to `https://<your-login>.42.fr/docs/`.
* **FTP Server**: Administrators can transfer and manage WordPress website files remotely via FTP. The server is accessible on port `21` (with passive ports 30000-30009). You will need the specific FTP credentials defined in your `secrets/` to log in.
* **Redis Cache**: The infrastructure includes an in-memory caching system designed to significantly speed up the WordPress website. This service runs completely transparently in the background and requires no user interaction.

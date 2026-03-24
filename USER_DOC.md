*This project has been created as part of the 42 curriculum by \<login\>.*

# Inception - User Documentation

This document explains in clear and simple terms how an end user or administrator can interact with the Inception infrastructure.

## 1. Services Provided by the Stack

[cite_start]This infrastructure sets up a complete web environment using isolated containers to provide the following core services[cite: 511]:

* **NGINX**: Acts as the sole web server and entry point to the infrastructure. It ensures secure connections by serving traffic exclusively over HTTPS (TLSv1.2 or TLSv1.3) on port 443.
* **WordPress**: The content management system (CMS) and application layer. It runs alongside `php-fpm` to generate and serve the website content.
* **MariaDB**: The database management system securely storing all the information, posts, and configurations for the WordPress site.

## 2. Starting and Stopping the Project

[cite_start]You can easily manage the lifecycle of the project using the provided `Makefile` at the root of the repository[cite: 512]:

* **To start the project**: Run `make` or `make up`. [cite_start]This command will prepare the necessary directories, verify your secrets, build the Docker images, and start the containers in the background[cite: 556].
* **To stop the project**: Run `make clean`. [cite_start]This halts the running containers but keeps them intact[cite: 556].
* **To shut down the project**: Run `make down`. [cite_start]This stops and removes the containers and networks, but your data (database and website files) remains perfectly safe in the persistent volumes[cite: 556].
* **To completely wipe the project**: Run `make fclean`. [cite_start]**Warning:** This will safely remove all containers, networks, and permanently delete all persistent data volumes[cite: 556].

## 3. Accessing the Website and Administration Panel

[cite_start]Once the stack is successfully running, you can access the web interfaces via your preferred web browser[cite: 513]:

* **Public Website**: Navigate to `https://<your-login>.42.fr` (e.g., `https://jtivan-r.42.fr`).
* **Administration Panel**: Navigate to `https://<your-login>.42.fr/wp-admin` to log in and manage the site content.

> **Note:** Because the TLS certificate used for HTTPS is self-signed for local development, your browser will likely display a security warning. You can safely accept the exception/risk to proceed to the site.

## 4. Locating and Managing Credentials

To ensure maximum security, sensitive information is not hardcoded into the project files. [cite_start]Administrators can locate and manage credentials as follows[cite: 514]:

* [cite_start]**Secrets**: All passwords (MariaDB root, MariaDB user, WordPress admin, WordPress user, etc.) are stored as plain text files inside the `secrets/` directory at the root of the project[cite: 556].
* [cite_start]**Environment Variables**: General configuration data (like domain names and database names) is located in the `.env` file inside the `srcs/` directory[cite: 556].
* **Managing Credentials**: To update a password or configuration, simply edit the corresponding file in the `secrets/` directory or the `.env` file **before** building and starting the project with `make`.

## 5. Checking that Services are Running Correctly

[cite_start]Administrators can verify that the infrastructure is healthy and running smoothly using the following methods[cite: 515]:

* **Container Status**: Run `docker ps` in your terminal. You should see three containers (NGINX, WordPress, and MariaDB) listed with a status of "Up".
* [cite_start]**Service Logs**: Run `make logs` to output the consolidated logs of all your running containers[cite: 556]. This is the best way to troubleshoot issues, monitor incoming web requests, and verify that the database and web server initialized without errors.

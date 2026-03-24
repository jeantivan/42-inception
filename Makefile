COMPOSE_FILE = ./srcs/docker-compose.yml
ENV_FILE = ./srcs/.env

# Check if the .env file exists
ifeq (,$(wildcard $(ENV_FILE)))
$(error "$(ENV_FILE) not found. Please create the $(ENV_FILE) file with the necessary environment variables.")
endif

# ==============================================================================
# ⚠️ IMPORTANT CONFIGURATION WARNING ⚠️
# The following variables (VOLUME_DIR, DOMAIN, and the secret files) MUST exactly
# match the values you have defined in your ./srcs/.env file.
# If they differ, the Makefile checks will pass/fail incorrectly and the host
# routing or volume mounting will not work as expected.
# ==============================================================================


VOLUME_DIR = /home/${USER}/data
DOMAIN=jtivan-r.42.fr

SECRET_DIR= ./secrets/

# Necessaries secrets files
# Ensure these filenames match the paths in your .env file
REQUIRED_SECRETS = $(SECRET_DIR)db_root_password.txt \
				   $(SECRET_DIR)db_password.txt \
				   $(SECRET_DIR)wordpress_admin_password.txt \
				   $(SECRET_DIR)wordpress_guest_password.txt \
				   $(SECRET_DIR)ftp_password.txt

# Colors
BOLD_PURPLE = \033[1;35m
BOLD_CYAN = \033[1;36m
BOLD_YELLOW = \033[1;33m
NO_COLOR = \033[0m
DEF_COLOR = \033[0;39m
GRAY = \033[0;90m
RED = \033[0;91m
GREEN = \033[0;92m
YELLOW = \033[0;93m
BLUE = \033[0;94m
MAGENTA = \033[0;95m
CYAN = \033[0;96m
WHITE = \033[0;97m
BG_GREEN = \033[42;37m


all: up

prepare_dirs:
	@echo "${BOLD_CYAN}Preparing volume directories on $(VOLUME_DIR)${NO_COLOR}"
	@mkdir -p $(VOLUME_DIR)
	@echo "${GRAY}\t mkdir -p $(VOLUME_DIR)${NO_COLOR}"
	@mkdir -p $(VOLUME_DIR)/mariadb
	@echo "${GRAY}\t mkdir -p $(VOLUME_DIR)/mariadb${NO_COLOR}"
	@mkdir -p $(VOLUME_DIR)/wordpress
	@echo "${GRAY}\t mkdir -p $(VOLUME_DIR)/wordpress${NO_COLOR}"
	@echo "${CYAN}Created $(VOLUME_DIR)/mariadb and $(VOLUME_DIR)/wordpress directories.${NO_COLOR}"

check_files:
	@echo "${BOLD_PURPLE}Checking for required secrets...${NO_COLOR}"
	@for file in $(REQUIRED_SECRETS); do \
		echo "${GRAY}\t Checking for $$file ...${NO_COLOR}"; \
		if [ ! -f "$$file" ]; then \
			echo "${RED}Error: Required secret file '$$file' is missing.${NO_COLOR}"; \
			exit 1; \
		fi; \
	done
	@echo "${GREEN}All required secret files are present.${NO_COLOR}"

check_host:
	@echo "Checking if $(DOMAIN) exists in /etc/hosts"
	@if grep -wq "$(DOMAIN)" "/etc/hosts"; then \
	    echo "✔ $(DOMAIN) already exists in hosts file"; \
	else \
	    echo "Adding entry..."; \
	    echo "127.0.0.1\t$(DOMAIN)" | sudo tee -a "/etc/hosts" > /dev/null; \
	    echo "Done."; \
	fi

up: check_files check_host prepare_dirs
	docker compose -f $(COMPOSE_FILE) build --no-cache
	docker compose -f $(COMPOSE_FILE) up -d --remove-orphans

clean:
	@echo "${BOLD_YELLOW}Stopping containers...${NO_COLOR}"
	@docker compose -f $(COMPOSE_FILE) stop
	@echo "${GREEN}All containers stopped.${NO_COLOR}"

down: clean
	@echo "${BOLD_YELLOW}Stopping and removing containers, networks, and volumes...${NO_COLOR}"
	@docker compose -f $(COMPOSE_FILE) down -v --remove-orphans
	@echo "${GREEN}All containers, networks, and volumes have been removed.${NO_COLOR}"

fclean: down
	@echo "${BOLD_YELLOW}Removing all volumes...${NO_COLOR}"
	@docker volume prune -f
	@sudo rm -rf $(VOLUME_DIR)
	@echo "${GREEN}All volumes have been removed.${NO_COLOR}"

re: fclean up

logs:
	docker compose -f $(COMPOSE_FILE) logs $(ARGS)

.PHONY: all up clean down fclean re prepare_dirs logs

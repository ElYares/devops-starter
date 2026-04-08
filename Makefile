SHELL := /bin/bash

COMPOSE_BASE := docker compose --env-file .env -f infra/compose/docker-compose.yml
COMPOSE_DEV := $(COMPOSE_BASE) -f infra/compose/docker-compose.dev.yml
COMPOSE_ADMIN := $(COMPOSE_DEV) -f infra/compose/docker-compose.admin.yml
COMPOSE_PROD := $(COMPOSE_BASE) -f infra/compose/docker-compose.prod.yml
COMPOSE_PROD_ADMIN := $(COMPOSE_PROD) -f infra/compose/docker-compose.prod.admin.yml
API_VENV := apps/api/.venv
API_PYTHON := $(API_VENV)/bin/python
TRAEFIK_ADMIN_USERS_FILE := infra/proxy/traefik/admin-users
TRAEFIK_ADMIN_SECRET_FILE := infra/secrets/traefik_admin_users
TRAEFIK_PROD_DYNAMIC_TEMPLATE := infra/proxy/traefik/dynamic.prod.tpl.yml
TRAEFIK_PROD_DYNAMIC_FILE := infra/proxy/traefik/generated/dynamic.prod.yml
TRAEFIK_PROD_ADMIN_DYNAMIC_TEMPLATE := infra/proxy/traefik/dynamic.prod.admin.tpl.yml
TRAEFIK_PROD_ADMIN_DYNAMIC_FILE := infra/proxy/traefik/generated/dynamic.prod.admin.yml

.PHONY: setup install install-api install-web up down logs ps build pull config validate-secrets-dev validate-secrets-prod validate-prod-tls render-traefik-prod render-traefik-prod-admin traefik-admin-users check-prod-admin-secret up-admin down-admin logs-admin ps-admin config-admin up-prod-admin down-prod-admin logs-prod-admin ps-prod-admin config-prod-admin bootstrap deploy backup restore up-prod down-prod logs-prod ps-prod config-prod lint lint-fix test

setup:
	cp -n .env.example .env || true

install: install-api install-web

install-api:
	python3 -m venv $(API_VENV)
	$(API_PYTHON) -m pip install --upgrade pip
	$(API_PYTHON) -m pip install -r apps/api/requirements.txt

install-web:
	cd apps/web && npm install

bootstrap:
	chmod +x infra/scripts/*.sh
	./infra/scripts/bootstrap.sh

up:
	$(MAKE) validate-secrets-dev
	$(COMPOSE_DEV) up -d --build

down:
	$(COMPOSE_DEV) down

logs:
	$(COMPOSE_DEV) logs -f

ps:
	$(COMPOSE_DEV) ps

build:
	$(COMPOSE_DEV) build

pull:
	$(COMPOSE_DEV) pull

config:
	$(MAKE) validate-secrets-dev
	$(COMPOSE_DEV) config

validate-secrets-dev:
	@bash -lc 'set -a; source .env; set +a; \
	for var in POSTGRES_PASSWORD REDIS_PASSWORD GRAFANA_ADMIN_PASSWORD; do \
		value="$${!var:-}"; \
		if [ -z "$$value" ]; then \
			echo "$$var is required in .env"; \
			exit 1; \
		fi; \
		case "$$value" in \
			admin|change-me|starter_password) \
				echo "$$var must not use the insecure default value '\''$$value'\''"; \
				exit 1; \
				;; \
		esac; \
	done'

validate-secrets-prod:
	@$(MAKE) validate-secrets-dev

validate-prod-tls:
	@bash -lc 'set -a; source .env; set +a; \
	test -n "$${PUBLIC_BASE_DOMAIN:-}" || (echo "PUBLIC_BASE_DOMAIN is required in .env for production TLS" && exit 1); \
	test -n "$${TRAEFIK_ACME_EMAIL:-}" || (echo "TRAEFIK_ACME_EMAIL is required in .env for production TLS" && exit 1); \
	test "$${PUBLIC_BASE_DOMAIN}" != "localhost" || (echo "PUBLIC_BASE_DOMAIN must not be localhost for production TLS" && exit 1)'

render-traefik-prod:
	$(MAKE) validate-prod-tls
	mkdir -p infra/proxy/traefik/generated
	@bash -lc 'set -a; source .env; set +a; envsubst '\''$${PUBLIC_BASE_DOMAIN}'\'' < $(TRAEFIK_PROD_DYNAMIC_TEMPLATE) > $(TRAEFIK_PROD_DYNAMIC_FILE)'

render-traefik-prod-admin:
	$(MAKE) validate-prod-tls
	mkdir -p infra/proxy/traefik/generated
	@bash -lc 'set -a; source .env; set +a; envsubst '\''$${PUBLIC_BASE_DOMAIN}'\'' < $(TRAEFIK_PROD_ADMIN_DYNAMIC_TEMPLATE) > $(TRAEFIK_PROD_ADMIN_DYNAMIC_FILE)'

traefik-admin-users:
	@bash -lc 'set -a; source .env; set +a; \
	test -n "$${TRAEFIK_ADMIN_USER:-}" || (echo "TRAEFIK_ADMIN_USER is required in .env" && exit 1); \
	test -n "$${TRAEFIK_ADMIN_PASSWORD:-}" || (echo "TRAEFIK_ADMIN_PASSWORD is required in .env" && exit 1); \
	test "$${TRAEFIK_ADMIN_PASSWORD}" != "admin" || (echo "TRAEFIK_ADMIN_PASSWORD must not use the insecure default value '\''admin'\''" && exit 1); \
	test "$${TRAEFIK_ADMIN_PASSWORD}" != "change-me" || (echo "TRAEFIK_ADMIN_PASSWORD must not use the insecure default value '\''change-me'\''" && exit 1); \
	test "$${TRAEFIK_ADMIN_PASSWORD}" != "starter_password" || (echo "TRAEFIK_ADMIN_PASSWORD must not use the insecure default value '\''starter_password'\''" && exit 1); \
	test "$${TRAEFIK_ADMIN_PASSWORD}" != "change-me-admin" || (echo "TRAEFIK_ADMIN_PASSWORD must be changed from the default value" && exit 1); \
	htpasswd -nbB "$${TRAEFIK_ADMIN_USER}" "$${TRAEFIK_ADMIN_PASSWORD}" > $(TRAEFIK_ADMIN_USERS_FILE)'

check-prod-admin-secret:
	test -f "$(TRAEFIK_ADMIN_SECRET_FILE)" || (echo "$(TRAEFIK_ADMIN_SECRET_FILE) is required for prod admin access" && exit 1)

up-admin:
	$(MAKE) validate-secrets-dev
	$(MAKE) traefik-admin-users
	$(COMPOSE_ADMIN) up -d --build

down-admin:
	$(COMPOSE_ADMIN) down

logs-admin:
	$(COMPOSE_ADMIN) logs -f

ps-admin:
	$(COMPOSE_ADMIN) ps

config-admin:
	$(MAKE) validate-secrets-dev
	$(MAKE) traefik-admin-users
	$(COMPOSE_ADMIN) config

up-prod:
	$(MAKE) validate-secrets-prod
	$(MAKE) render-traefik-prod
	$(COMPOSE_PROD) up -d --build

down-prod:
	$(COMPOSE_PROD) down

logs-prod:
	$(COMPOSE_PROD) logs -f

ps-prod:
	$(COMPOSE_PROD) ps

config-prod:
	$(MAKE) validate-secrets-prod
	$(MAKE) render-traefik-prod
	$(COMPOSE_PROD) config

up-prod-admin:
	$(MAKE) validate-secrets-prod
	$(MAKE) render-traefik-prod-admin
	$(MAKE) check-prod-admin-secret
	$(COMPOSE_PROD_ADMIN) up -d --build

down-prod-admin:
	$(COMPOSE_PROD_ADMIN) down

logs-prod-admin:
	$(COMPOSE_PROD_ADMIN) logs -f

ps-prod-admin:
	$(COMPOSE_PROD_ADMIN) ps

config-prod-admin:
	$(MAKE) validate-secrets-prod
	$(MAKE) render-traefik-prod-admin
	$(MAKE) check-prod-admin-secret
	$(COMPOSE_PROD_ADMIN) config

lint:
	test -x $(API_PYTHON) || (echo "API virtualenv missing. Run 'make install-api' first." && exit 1)
	cd apps/api && .venv/bin/python -m ruff check .
	cd apps/web && npm run lint

lint-fix:
	test -x $(API_PYTHON) || (echo "API virtualenv missing. Run 'make install-api' first." && exit 1)
	cd apps/api && .venv/bin/python -m ruff check --fix .
	cd apps/web && npm run lint

test:
	test -x $(API_PYTHON) || (echo "API virtualenv missing. Run 'make install-api' first." && exit 1)
	$(API_PYTHON) -m pytest apps/api
	cd apps/web && npm run test

deploy:
	chmod +x infra/scripts/*.sh
	./infra/scripts/deploy.sh

backup:
	chmod +x infra/scripts/*.sh
	./infra/scripts/backup.sh

restore:
	chmod +x infra/scripts/*.sh
	test -n "$(BACKUP_FILE)" || (echo "BACKUP_FILE is required. Use 'make restore BACKUP_FILE=path/to/file.sql.gz.enc'" && exit 1)
	./infra/scripts/restore.sh "$(BACKUP_FILE)"

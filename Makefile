SHELL := /bin/bash

ifneq (,$(wildcard .env))
include .env
export
endif

COMPOSE_BASE := docker compose --env-file .env -f infra/compose/docker-compose.yml
COMPOSE_DEV := $(COMPOSE_BASE) -f infra/compose/docker-compose.dev.yml
COMPOSE_PROD := $(COMPOSE_BASE) -f infra/compose/docker-compose.prod.yml
API_VENV := apps/api/.venv
API_PYTHON := $(API_VENV)/bin/python

.PHONY: setup install install-api install-web up down logs ps build pull config bootstrap deploy backup restore up-prod down-prod logs-prod ps-prod config-prod lint lint-fix test

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
	$(COMPOSE_DEV) config

up-prod:
	$(COMPOSE_PROD) up -d --build

down-prod:
	$(COMPOSE_PROD) down

logs-prod:
	$(COMPOSE_PROD) logs -f

ps-prod:
	$(COMPOSE_PROD) ps

config-prod:
	$(COMPOSE_PROD) config

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
	./infra/scripts/restore.sh

SHELL := /bin/bash

ifneq (,$(wildcard .env))
include .env
export
endif

COMPOSE := docker compose --env-file .env -f infra/compose/docker-compose.yml

.PHONY: setup up down logs ps build pull config bootstrap deploy backup restore

setup:
	cp -n .env.example .env || true

bootstrap:
	chmod +x infra/scripts/*.sh
	./infra/scripts/bootstrap.sh

up:
	$(COMPOSE) up -d --build

down:
	$(COMPOSE) down

logs:
	$(COMPOSE) logs -f

ps:
	$(COMPOSE) ps

build:
	$(COMPOSE) build

pull:
	$(COMPOSE) pull

config:
	$(COMPOSE) config

deploy:
	chmod +x infra/scripts/*.sh
	./infra/scripts/deploy.sh

backup:
	chmod +x infra/scripts/*.sh
	./infra/scripts/backup.sh

restore:
	chmod +x infra/scripts/*.sh
	./infra/scripts/restore.sh

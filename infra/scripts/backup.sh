#!/usr/bin/env bash

set -euo pipefail

if [[ -f .env ]]; then
  set -a
  source .env
  set +a
fi

mkdir -p infra/backups
timestamp="$(date +%Y%m%d-%H%M%S)"
target="infra/backups/postgres-${timestamp}.sql"

echo "Creating PostgreSQL backup at ${target}"
docker compose --env-file .env -f infra/compose/docker-compose.yml exec -T postgres \
  pg_dump -U "${POSTGRES_USER:-starter}" "${POSTGRES_DB:-starter}" > "${target}"

echo "Backup completed"

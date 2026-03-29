#!/usr/bin/env bash

set -euo pipefail

if [[ -f .env ]]; then
  set -a
  source .env
  set +a
fi

if [[ $# -lt 1 ]]; then
  echo "Usage: ./infra/scripts/restore.sh <backup-file>"
  exit 1
fi

backup_file="$1"

if [[ ! -f "${backup_file}" ]]; then
  echo "Backup file not found: ${backup_file}"
  exit 1
fi

echo "Restoring PostgreSQL backup from ${backup_file}"
docker compose --env-file .env -f infra/compose/docker-compose.yml exec -T postgres \
  psql -U "${POSTGRES_USER:-starter}" "${POSTGRES_DB:-starter}" < "${backup_file}"

echo "Restore completed"

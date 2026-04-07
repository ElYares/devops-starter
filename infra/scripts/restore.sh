#!/usr/bin/env bash

set -euo pipefail

umask 077

if [[ -f .env ]]; then
  set -a
  source .env
  set +a
fi

if [[ -z "${BACKUP_ENCRYPTION_PASSPHRASE:-}" ]]; then
  echo "BACKUP_ENCRYPTION_PASSPHRASE is required in .env"
  exit 1
fi

if [[ "${BACKUP_ENCRYPTION_PASSPHRASE}" == "change-this-backup-passphrase" ]]; then
  echo "BACKUP_ENCRYPTION_PASSPHRASE must be changed from the default value"
  exit 1
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
openssl enc -d -aes-256-cbc -pbkdf2 -pass env:BACKUP_ENCRYPTION_PASSPHRASE -in "${backup_file}" \
  | gunzip -c \
  | docker compose --env-file .env -f infra/compose/docker-compose.yml exec -T postgres \
    psql -U "${POSTGRES_USER:-starter}" "${POSTGRES_DB:-starter}"

echo "Restore completed"

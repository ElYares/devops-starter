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

backup_dir="${BACKUP_DIR:-infra/backups}"
retention_days="${BACKUP_RETENTION_DAYS:-7}"

mkdir -p "${backup_dir}"
timestamp="$(date +%Y%m%d-%H%M%S)"
target="${backup_dir}/postgres-${timestamp}.sql.gz.enc"

echo "Creating PostgreSQL backup at ${target}"
docker compose --env-file .env -f infra/compose/docker-compose.yml exec -T postgres \
  pg_dump -U "${POSTGRES_USER:-starter}" "${POSTGRES_DB:-starter}" \
  | gzip -c \
  | openssl enc -aes-256-cbc -pbkdf2 -salt -pass env:BACKUP_ENCRYPTION_PASSPHRASE -out "${target}"

find "${backup_dir}" -type f -name 'postgres-*.sql.gz.enc' -mtime +"${retention_days}" -delete

echo "Backup completed"

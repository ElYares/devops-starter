#!/usr/bin/env bash

# Prepares the local environment file and blocks obviously insecure defaults
# before the user tries to boot the stack.
set -euo pipefail

if [[ ! -f .env ]]; then
  cp .env.example .env
  echo ".env created from .env.example"
else
  echo ".env already exists"
fi

set -a
source .env
set +a

required_secrets=(
  "POSTGRES_PASSWORD"
  "REDIS_PASSWORD"
  "GRAFANA_ADMIN_PASSWORD"
)

# Fail fast on empty or placeholder credentials because the starter is meant to
# model safe defaults from day one.
for key in "${required_secrets[@]}"; do
  value="${!key:-}"
  if [[ -z "${value}" ]]; then
    echo "${key} is required in .env"
    exit 1
  fi

  case "${value}" in
    admin|change-me|starter_password)
      echo "${key} must not use the insecure default value '${value}'"
      exit 1
      ;;
  esac
done

echo "Bootstrap complete."
echo "Run 'make install' to install local quality-tool dependencies."
echo "Run 'make up' to start the stack."

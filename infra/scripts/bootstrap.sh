#!/usr/bin/env bash

set -euo pipefail

if [[ -f .env ]]; then
  set -a
  source .env
  set +a
fi

if [[ ! -f .env ]]; then
  cp .env.example .env
  echo ".env created from .env.example"
else
  echo ".env already exists"
fi

echo "Bootstrap complete. Run 'make up' to start the stack."

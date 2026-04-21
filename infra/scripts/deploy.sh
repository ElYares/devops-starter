#!/usr/bin/env bash

# Placeholder entrypoint for future deployment automation. It already loads the
# shared `.env` file so the implementation can reuse the same configuration
# contract as the Make targets and compose commands.
set -euo pipefail

if [[ -f .env ]]; then
  set -a
  source .env
  set +a
fi

echo "Placeholder deploy script."
echo "Next iteration should add registry auth, image tags and remote rollout."

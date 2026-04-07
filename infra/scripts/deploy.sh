#!/usr/bin/env bash

set -euo pipefail

if [[ -f .env ]]; then
  set -a
  source .env
  set +a
fi

echo "Placeholder deploy script."
echo "Next iteration should add registry auth, image tags and remote rollout."

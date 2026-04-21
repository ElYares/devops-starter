#!/usr/bin/env bash

# Pulls versioned images from the registry and updates the running stack without
# rebuilding containers on the target host.
set -euo pipefail

if [[ -f .env ]]; then
  set -a
  source .env
  set +a
fi

deploy_env="${DEPLOY_ENV:-production}"
enable_admin="${DEPLOY_ADMIN:-false}"

case "${deploy_env}" in
  staging|production)
    ;;
  *)
    echo "DEPLOY_ENV must be 'staging' or 'production'"
    exit 1
    ;;
esac

required_env=(
  "API_IMAGE"
  "WEB_IMAGE"
  "IMAGE_TAG"
  "POSTGRES_PASSWORD"
  "REDIS_PASSWORD"
  "GRAFANA_ADMIN_PASSWORD"
  "PUBLIC_BASE_DOMAIN"
  "TRAEFIK_ACME_EMAIL"
)

for key in "${required_env[@]}"; do
  if [[ -z "${!key:-}" ]]; then
    echo "${key} is required for deploy"
    exit 1
  fi
done

compose_args=(
  --env-file .env
  -f infra/compose/docker-compose.yml
  -f infra/compose/docker-compose.prod.yml
)

if [[ "${enable_admin}" == "true" ]]; then
  compose_args+=(-f infra/compose/docker-compose.prod.admin.yml)
fi

echo "Deploy environment: ${deploy_env}"
echo "API image: ${API_IMAGE}:${IMAGE_TAG}"
echo "Web image: ${WEB_IMAGE}:${IMAGE_TAG}"

if [[ "${enable_admin}" == "true" ]]; then
  make render-traefik-prod-admin
  make check-prod-admin-secret
else
  make render-traefik-prod
fi

docker compose "${compose_args[@]}" pull api web
docker compose "${compose_args[@]}" up -d

base_domain="${PUBLIC_BASE_DOMAIN}"
web_url="https://web.${base_domain}"
api_url="https://api.${base_domain}"

echo "Waiting for web health at ${web_url}"
curl --fail --silent --show-error --location "${web_url}/api/health" >/dev/null

echo "Waiting for API liveness at ${api_url}"
curl --fail --silent --show-error --location "${api_url}/health" >/dev/null

echo "Waiting for API readiness at ${api_url}"
curl --fail --silent --show-error --location "${api_url}/ready" >/dev/null

echo "Deploy completed"

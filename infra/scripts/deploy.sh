#!/usr/bin/env bash

# Pulls versioned images from the registry and updates the running stack without
# rebuilding containers on the target host. CD can pass immutable digest refs,
# and the script keeps a rollback target from the currently running services.
set -euo pipefail

if [[ -f .env ]]; then
  set -a
  source .env
  set +a
fi

deploy_env="${DEPLOY_ENV:-production}"
enable_admin="${DEPLOY_ADMIN:-false}"
health_retries="${DEPLOY_HEALTH_RETRIES:-30}"
health_sleep_seconds="${DEPLOY_HEALTH_SLEEP_SECONDS:-5}"

resolved_api_image_ref="${API_IMAGE_REF:-}"
resolved_web_image_ref="${WEB_IMAGE_REF:-}"

if [[ -z "${resolved_api_image_ref}" ]]; then
  if [[ -z "${API_IMAGE:-}" ]]; then
    echo "API_IMAGE is required when API_IMAGE_REF is not provided"
    exit 1
  fi

  resolved_api_image_ref="${API_IMAGE}:${IMAGE_TAG:-latest}"
fi

if [[ -z "${resolved_web_image_ref}" ]]; then
  if [[ -z "${WEB_IMAGE:-}" ]]; then
    echo "WEB_IMAGE is required when WEB_IMAGE_REF is not provided"
    exit 1
  fi

  resolved_web_image_ref="${WEB_IMAGE}:${IMAGE_TAG:-latest}"
fi

case "${deploy_env}" in
  staging|production)
    ;;
  *)
    echo "DEPLOY_ENV must be 'staging' or 'production'"
    exit 1
    ;;
esac

required_env=(
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

compose_cmd() {
  API_IMAGE_REF="${API_IMAGE_REF:-$resolved_api_image_ref}" \
  WEB_IMAGE_REF="${WEB_IMAGE_REF:-$resolved_web_image_ref}" \
  docker compose "${compose_args[@]}" "$@"
}

current_image_ref() {
  local service="$1"
  local container_id image_id

  container_id="$(compose_cmd ps -q "$service" 2>/dev/null || true)"
  if [[ -z "${container_id}" ]]; then
    return 0
  fi

  image_id="$(docker inspect --format '{{.Image}}' "${container_id}" 2>/dev/null || true)"
  if [[ -z "${image_id}" ]]; then
    return 0
  fi

  docker image inspect \
    --format '{{if .RepoDigests}}{{index .RepoDigests 0}}{{else}}{{index .RepoTags 0}}{{end}}' \
    "${image_id}" 2>/dev/null || true
}

wait_for_url() {
  local label="$1"
  local url="$2"
  local attempt

  for ((attempt = 1; attempt <= health_retries; attempt++)); do
    if curl --fail --silent --show-error --location "${url}" >/dev/null; then
      echo "${label} is healthy"
      return 0
    fi

    echo "Waiting for ${label} (${attempt}/${health_retries})"
    sleep "${health_sleep_seconds}"
  done

  return 1
}

rollback() {
  if [[ -z "${previous_api_image_ref:-}" || -z "${previous_web_image_ref:-}" ]]; then
    echo "Rollback skipped because a previous image reference is not available."
    return 1
  fi

  echo "Rolling back to previous image digests"
  API_IMAGE_REF="${previous_api_image_ref}" \
  WEB_IMAGE_REF="${previous_web_image_ref}" \
  docker compose "${compose_args[@]}" pull api web

  API_IMAGE_REF="${previous_api_image_ref}" \
  WEB_IMAGE_REF="${previous_web_image_ref}" \
  docker compose "${compose_args[@]}" up -d
}

echo "Deploy environment: ${deploy_env}"
echo "API image: ${resolved_api_image_ref}"
echo "Web image: ${resolved_web_image_ref}"

previous_api_image_ref="$(current_image_ref api)"
previous_web_image_ref="$(current_image_ref web)"

if [[ "${enable_admin}" == "true" ]]; then
  make render-traefik-prod-admin
  make check-prod-admin-secret
else
  make render-traefik-prod
fi

compose_cmd pull api web
compose_cmd up -d

base_domain="${PUBLIC_BASE_DOMAIN}"
web_url="https://web.${base_domain}"
api_url="https://api.${base_domain}"

if ! wait_for_url "web health" "${web_url}/api/health" \
  || ! wait_for_url "api liveness" "${api_url}/health" \
  || ! wait_for_url "api readiness" "${api_url}/ready"; then
  echo "Deployment health checks failed"

  if rollback; then
    echo "Rollback completed"
  else
    echo "Rollback could not complete automatically"
  fi

  exit 1
fi

echo "Deploy completed"

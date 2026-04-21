# DevOps Starter

Starter reutilizable para desplegar aplicaciones modernas con buenas practicas DevOps desde el inicio.

## Stack inicial

- FastAPI para API demo
- Next.js para frontend demo
- Traefik como reverse proxy
- PostgreSQL
- Redis
- Prometheus
- Grafana
- Docker Compose
- GitHub Actions

## Estructura

```text
devops-starter/
├── apps/
│   ├── api/
│   └── web/
├── infra/
│   ├── compose/
│   ├── monitoring/
│   └── proxy/
├── docs/
├── .github/workflows/
├── .env.example
├── Makefile
└── README.md
```

Documentacion por capa:

- `infra/README.md`: orquestacion, redes, overlays y scripts operativos
- `apps/api/README.md`: contrato de la API, probes y metricas
- `apps/web/README.md`: flujo del frontend, variables de entorno y healthcheck

## Quickstart

```bash
make setup
make install
make up
```

Servicios esperados:

- App web: `http://web.localhost:${TRAEFIK_PORT}`
- API: `http://api.localhost:${TRAEFIK_PORT}`

Dashboard de Traefik:

- no se expone en `make up`
- se habilita de forma protegida con `make up-admin`
- en produccion solo se habilita con `make up-prod-admin` usando `infra/secrets/traefik_admin_users`

Observabilidad:

- Prometheus, Grafana y `api.localhost/metrics` no se exponen en `make up`
- se habilitan de forma protegida con `make up-admin`

Produccion:

- `make up-prod` habilita HTTPS en Traefik con Let's Encrypt
- requiere `PUBLIC_BASE_DOMAIN` y `TRAEFIK_ACME_EMAIL` en `.env`

Seguridad HTTP:

- Next.js y Traefik agregan headers base de seguridad
- en produccion Traefik agrega HSTS sobre HTTPS

## Objetivo de esta primera version

- scaffold funcional y ordenado
- servicios dockerizados por separado
- compose unico para desarrollo local
- healthchecks
- monitoreo base
- pipeline CI inicial
- documentacion inicial

## Modos de compose

- `infra/compose/docker-compose.yml`: base comun del stack
- `infra/compose/docker-compose.dev.yml`: overlay para desarrollo local
- `infra/compose/docker-compose.prod.yml`: overlay para entorno server

Comandos principales:

```bash
make install
make install-api
make install-web
make up
make down
make config
make up-prod
make config-prod
make lint
make test
```

Antes de levantar el stack, cambia los secretos de `.env`. Los comandos de arranque fallan si detectan valores inseguros como `admin`, `change-me` o `starter_password`.

Backups:

- `make backup` genera backups cifrados de PostgreSQL
- `make restore` restaura un backup cifrado

`make install` prepara las dependencias locales para lint y tests:

- crea `apps/api/.venv`
- instala dependencias Python de la API
- instala dependencias Node del frontend

## Siguientes pasos

1. Probar `make up` en una maquina con Docker y Docker Compose.
2. Anadir migraciones reales para la API.
3. Agregar backup y restore.
4. Separar `compose.dev` y `compose.prod`.
5. Endurecer seguridad y despliegue.

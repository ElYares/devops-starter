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

## Quickstart

```bash
make setup
make install
make up
```

Servicios esperados:

- App web: `http://web.localhost:${TRAEFIK_PORT}`
- API: `http://api.localhost:${TRAEFIK_PORT}`
- Prometheus: `http://prometheus.localhost:${TRAEFIK_PORT}`
- Grafana: `http://grafana.localhost:${TRAEFIK_PORT}`

Dashboard de Traefik:

- no se expone en `make up`
- se habilita de forma protegida con `make up-admin`
- en produccion solo se habilita con `make up-prod-admin` usando `infra/secrets/traefik_admin_users`

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

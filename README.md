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
cp .env.example .env
make up
```

Servicios esperados:

- App web: `http://web.localhost`
- API: `http://api.localhost`
- Traefik dashboard: `http://traefik.localhost`
- Prometheus: `http://prometheus.localhost`
- Grafana: `http://grafana.localhost`

## Objetivo de esta primera version

- scaffold funcional y ordenado
- servicios dockerizados por separado
- compose unico para desarrollo local
- healthchecks
- monitoreo base
- pipeline CI inicial
- documentacion inicial

## Siguientes pasos

1. Probar `make up` en una maquina con Docker y Docker Compose.
2. Anadir migraciones reales para la API.
3. Agregar backup y restore.
4. Separar `compose.dev` y `compose.prod`.
5. Endurecer seguridad y despliegue.

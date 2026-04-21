# Infra

La carpeta `infra/` concentra la definicion operativa del starter: compose,
proxy, monitoreo y scripts de soporte.

## Responsabilidades

- Orquestar contenedores y overlays por entorno.
- Definir networking interno entre proxy, apps y observabilidad.
- Configurar Traefik, Prometheus y Grafana.
- Proveer scripts de bootstrap, backup, restore y despliegue.

## Estructura

```text
infra/
├── compose/                 # Base compose y overlays dev/prod/admin
├── monitoring/              # Configuracion de Prometheus y provisioning de Grafana
├── proxy/traefik/           # Rutas y middlewares del reverse proxy
├── scripts/                 # Operaciones locales y de despliegue
└── backups/                 # Backups cifrados de PostgreSQL
```

## Redes de Compose

- `edge`: trafico que toca proxy, frontend y endpoints expuestos.
- `backend`: comunicacion privada entre API, Postgres y Redis.
- `observability`: scrapeo de metricas y acceso a dashboards.

Esta separacion evita mezclar trafico de usuario, trafico de datos y trafico de monitoreo.

## Capas de configuracion

- `compose/docker-compose.yml`: base comun del stack.
- `compose/docker-compose.dev.yml`: ajustes para desarrollo local.
- `compose/docker-compose.admin.yml`: expone paneles protegidos para diagnostico local.
- `compose/docker-compose.prod.yml`: activa piezas de produccion como TLS.
- `compose/docker-compose.prod.admin.yml`: version de admin pensada para produccion.

## Scripts

- `scripts/bootstrap.sh`: prepara `.env` y valida secretos minimos.
- `scripts/deploy.sh`: placeholder para automatizar despliegue remoto.
- `scripts/backup.sh`: genera backup cifrado de PostgreSQL.
- `scripts/restore.sh`: restaura un backup cifrado existente.

## Extension sugerida

- Mover el placeholder de deploy a una estrategia concreta de registry y rollout.
- Versionar dashboards y reglas de alerta junto al provisioning de Grafana.
- Agregar secretos administrados fuera de `.env` si el starter pasa a entornos compartidos.

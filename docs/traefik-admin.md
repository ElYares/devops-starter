# Traefik Admin

## Objetivo

Este proyecto no expone el dashboard de Traefik por defecto. Solo se habilita en modos explicitos y protegidos.

## Modos disponibles

### Local / desarrollo

Usa `.env` para generar automaticamente el archivo `htpasswd` que Traefik necesita.

Variables requeridas en `.env`:

```bash
TRAEFIK_ADMIN_USER=admin
TRAEFIK_ADMIN_PASSWORD=un-password-fuerte
```

Comandos:

```bash
make config-admin
make up-admin
make ps-admin
```

URL:

```text
http://traefik-admin.localhost:${TRAEFIK_PORT}
```

Comportamiento esperado:

- el navegador debe pedir usuario y password
- si las credenciales son correctas, muestra el dashboard
- si `TRAEFIK_ADMIN_PASSWORD` sigue en `change-me-admin`, `make up-admin` falla

### Produccion

Produccion no usa `.env` para las credenciales del dashboard. Usa un secret local de Compose.

Crear el secret:

```bash
mkdir -p infra/secrets
htpasswd -nbB admin 'un-password-fuerte' > infra/secrets/traefik_admin_users
```

Validar y levantar:

```bash
make config-prod-admin
make up-prod-admin
make ps-prod-admin
```

URL:

```text
http://traefik-admin.localhost:${TRAEFIK_PORT}
```

Comportamiento esperado:

- si `infra/secrets/traefik_admin_users` no existe, `make up-prod-admin` falla
- el dashboard exige autenticacion basica

## Modo normal sin dashboard

Para levantar el stack sin dashboard:

```bash
make up
```

Eso deja disponibles:

- `http://web.localhost:${TRAEFIK_PORT}`
- `http://api.localhost:${TRAEFIK_PORT}`

Y no debe exponer:

- `http://traefik.localhost:${TRAEFIK_PORT}`
- `http://localhost:8080`
- `http://prometheus.localhost:${TRAEFIK_PORT}`
- `http://grafana.localhost:${TRAEFIK_PORT}`
- `http://api.localhost:${TRAEFIK_PORT}/metrics`

## Endpoints protegidos en modo admin

Cuando usas `make up-admin` o `make up-prod-admin`, estos endpoints quedan protegidos con autenticacion basica e IP allowlist:

- `http://traefik-admin.localhost:${TRAEFIK_PORT}`
- `http://prometheus.localhost:${TRAEFIK_PORT}`
- `http://grafana.localhost:${TRAEFIK_PORT}`
- `http://api.localhost:${TRAEFIK_PORT}/metrics`

## Troubleshooting

### El dashboard no pide password

Revisa que hayas levantado `make up-admin` o `make up-prod-admin`, no `make up`.

### `make up-admin` falla por password default

Cambia `TRAEFIK_ADMIN_PASSWORD` en `.env`. El valor `change-me-admin` esta bloqueado intencionalmente.

### `make up-prod-admin` falla por secret faltante

Crea `infra/secrets/traefik_admin_users` con `htpasswd`.

### Quiero apagar el dashboard admin

Usa:

```bash
make down-admin
make down-prod-admin
```

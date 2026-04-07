# Deployment

## Flujo inicial

1. Copiar `.env.example` a `.env`.
2. Ejecutar `make up` para entorno local.
3. Validar healthchecks con `make ps`.
4. Revisar logs con `make logs`.

## Entornos

- `make up`: compose base + overlay dev
- `make up-admin`: compose base + overlay dev + overlay admin protegido
- `make up-prod`: compose base + overlay prod
- `make up-prod-admin`: compose prod + overlay admin protegido con secret
- `make config`: valida configuracion dev
- `make config-admin`: valida configuracion dev con dashboard protegido
- `make config-prod`: valida configuracion prod
- `make config-prod-admin`: valida produccion con dashboard protegido por secret

## Seguridad antes de exponer el stack

Antes de usar `make up-prod` fuera de un entorno local, revisa [docs/security.md](/home/elyarestark/develop/devops-starter/docs/security.md).
Para el uso operativo del dashboard protegido, revisa [docs/traefik-admin.md](/home/elyarestark/develop/devops-starter/docs/traefik-admin.md).

Minimo requerido:

- rotar todas las credenciales por defecto
- desactivar o proteger Traefik dashboard
- no exponer Prometheus, Grafana ni `/metrics` sin autenticacion
- habilitar TLS
- endurecer contenedores y politicas del proxy
- usar passwords reales para PostgreSQL, Redis y Grafana antes de `make up` o `make up-prod`

## TLS en produccion

`make up-prod` y `make up-prod-admin` ahora generan una configuracion de Traefik para HTTPS con Let's Encrypt.

Variables requeridas en `.env`:

- `PUBLIC_BASE_DOMAIN`
- `TRAEFIK_ACME_EMAIL`
- `TRAEFIK_PORT`
- `TRAEFIK_TLS_PORT`

Ejemplo:

```bash
PUBLIC_BASE_DOMAIN=example.com
TRAEFIK_ACME_EMAIL=ops@example.com
TRAEFIK_PORT=80
TRAEFIK_TLS_PORT=443
```

Hosts esperados en produccion:

- `https://web.${PUBLIC_BASE_DOMAIN}`
- `https://api.${PUBLIC_BASE_DOMAIN}`

Modo admin en produccion:

- `https://traefik-admin.${PUBLIC_BASE_DOMAIN}`
- `https://prometheus.${PUBLIC_BASE_DOMAIN}`
- `https://grafana.${PUBLIC_BASE_DOMAIN}`
- `https://api.${PUBLIC_BASE_DOMAIN}/metrics`

Notas:

- Traefik redirige HTTP a HTTPS automaticamente en produccion
- los certificados se solicitan por ACME HTTP challenge
- el almacenamiento ACME queda en un volumen Docker persistente
- Traefik agrega headers de seguridad en el borde y HSTS en produccion
- FastAPI deshabilita `/docs`, `/redoc` y `/openapi.json` cuando `APP_ENV=production`
- el compose base aplica hardening de contenedores con `read_only`, `no-new-privileges`, `tmpfs` y limites por servicio cuando es viable

## Acceso local

Con el `.env` actual, Traefik publica el stack por `:${TRAEFIK_PORT}`.

- frontend: `http://web.localhost:${TRAEFIK_PORT}`
- api: `http://api.localhost:${TRAEFIK_PORT}`

El dashboard de Traefik no se publica en `make up`. Solo existe en `make up-admin` y requiere autenticacion:

- traefik admin: `http://traefik-admin.localhost:${TRAEFIK_PORT}`

Prometheus, Grafana y `api.localhost/metrics` tampoco se publican en `make up`. Solo quedan disponibles en `make up-admin` y `make up-prod-admin`, siempre detras de autenticacion basica e IP allowlist.

Antes de usar `make up-admin`, define en `.env`:

- `TRAEFIK_ADMIN_USER`
- `TRAEFIK_ADMIN_PASSWORD`

Para `make up-prod-admin`, no uses `.env` para las credenciales del dashboard. Crea el secret:

```bash
mkdir -p infra/secrets
htpasswd -nbB admin 'un-password-fuerte' > infra/secrets/traefik_admin_users
```

## Validacion de secretos

Los comandos de arranque y validacion fallan si detectan secretos inseguros en `.env`.

Valores bloqueados:

- `admin`
- `change-me`
- `starter_password`

Esto aplica al menos a:

- `POSTGRES_PASSWORD`
- `REDIS_PASSWORD`
- `GRAFANA_ADMIN_PASSWORD`

## Backups cifrados

Los scripts `make backup` y `make restore` ahora usan archivos cifrados por passphrase.

Variables relevantes en `.env`:

- `BACKUP_DIR`
- `BACKUP_RETENTION_DAYS`
- `BACKUP_ENCRYPTION_PASSPHRASE`

## Proximo objetivo

- parametrizar imagenes para registry
- anadir script de deploy controlado
- definir estrategia de release por ramas o tags

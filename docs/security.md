# Seguridad

## Estado actual

Este starter tiene una base funcional para desarrollo local, pero no debe exponerse a Internet sin endurecimiento adicional. La mayor parte del riesgo actual esta en infraestructura, observabilidad y configuraciones por defecto, no en la logica de negocio de la app demo.

## Hallazgos principales

### Criticos / altos

- Traefik expone el dashboard con `--api.insecure=true` en el compose base.
- El router de Traefik publica el servicio `api@internal` sin autenticacion adicional.
- Existen credenciales por defecto previsibles para PostgreSQL, Redis y Grafana.
- Redis solo exige password en el overlay de produccion; en el compose base no hay autenticacion.
- La API publica `/metrics` sin autenticacion.
- Prometheus y Grafana quedan publicables detras del proxy sin controles de acceso.

### Medios

- No hay TLS configurado en Traefik.
- No hay middlewares visibles de `basicAuth`, `ipAllowList`, `rateLimit` ni headers de seguridad en el proxy.
- FastAPI mantiene expuestos los endpoints automaticos `/docs`, `/redoc` y `/openapi.json`.
- Next.js no define headers base como CSP, `X-Frame-Options`, `Referrer-Policy` o `X-Content-Type-Options`.
- Los contenedores corren como usuario no root, pero no tienen hardening adicional como `read_only`, `cap_drop` o `no-new-privileges`.

### Bajos

- Los backups se guardan como SQL plano en `infra/backups/` sin cifrado ni politica de retencion.
- No hay `.dockerignore`, por lo que el contexto de build puede crecer y filtrar archivos innecesarios a futuro.

## Riesgos por area

### Proxy y borde

- Exposicion del dashboard de Traefik y de servicios de observabilidad.
- Trafico HTTP sin cifrado.
- Ausencia de controles de acceso y limitacion de peticiones.

### Secretos y credenciales

- Variables de ejemplo con valores reutilizables en entornos reales.
- Riesgo de despliegue con passwords por defecto si no se valida el bootstrap.

### Observabilidad

- `/metrics`, Prometheus y Grafana pueden revelar topologia, nombres de servicios, estados internos y fallos de dependencias.

### Datos

- Dumps de base de datos en texto plano.
- Redis sin auth en el compose base.

## Recomendaciones prioritarias

1. Desactivar por completo el dashboard inseguro de Traefik y no publicar `api@internal` sin proteccion.
2. Exigir secretos no default en bootstrap y en produccion. El stack debe fallar si detecta `admin`, `change-me` o `starter_password`.
3. Requerir password de Redis en todos los entornos y hacer que la API lo use.
4. No publicar Prometheus, Grafana ni `/metrics` al borde publico sin auth e IP allowlist.
5. Configurar TLS en Traefik para cualquier despliegue fuera de local.
6. Agregar headers de seguridad en el frontend y/o proxy.
7. Deshabilitar docs de FastAPI en produccion o protegerlas.
8. Endurecer contenedores con `read_only`, `cap_drop: [ALL]`, `security_opt: ["no-new-privileges:true"]`, `tmpfs` y limites de recursos.
9. Cifrar backups o moverlos a almacenamiento controlado con permisos explicitos y retencion.
10. Agregar `.dockerignore` para reducir contexto de build y evitar inclusiones accidentales.

## Implementacion actual del dashboard de Traefik

El compose base y el overlay de desarrollo normal ya no exponen el dashboard de Traefik.

- `make up`: levanta el stack sin dashboard publico
- `make up-admin`: levanta el stack con dashboard habilitado solo bajo autenticacion basica
- `make up-prod`: levanta produccion sin dashboard publico
- `make up-prod-admin`: levanta produccion con dashboard habilitado usando un secret de Compose

El dashboard protegido se publica en:

- `http://traefik-admin.localhost:${TRAEFIK_PORT}`

Para habilitar `make up-admin`, define estas variables en `.env`:

- `TRAEFIK_ADMIN_USER`
- `TRAEFIK_ADMIN_PASSWORD`

`make up-admin` genera automaticamente `infra/proxy/traefik/admin-users` con `htpasswd`.

Ejemplo en `.env`:

```bash
TRAEFIK_ADMIN_USER=admin
TRAEFIK_ADMIN_PASSWORD=un-password-fuerte
```

El archivo generado queda ignorado por Git y Traefik lo monta como `usersFile` para el middleware de `basicAuth`.

En produccion, el dashboard admin no usa `.env`. Requiere un secret local en:

- `infra/secrets/traefik_admin_users`

Ese archivo debe contener una entrada `htpasswd`, por ejemplo:

```bash
htpasswd -nbB admin 'un-password-fuerte' > infra/secrets/traefik_admin_users
```

Luego puedes validar o levantar el modo admin de produccion con:

```bash
make config-prod-admin
make up-prod-admin
```

## Politica actual de secretos

El proyecto ahora falla temprano si detecta valores inseguros en secretos base durante `bootstrap`, `make up`, `make config`, `make up-prod` y variantes admin.

Valores bloqueados:

- `admin`
- `change-me`
- `starter_password`

Variables validadas:

- `POSTGRES_PASSWORD`
- `REDIS_PASSWORD`
- `GRAFANA_ADMIN_PASSWORD`

Ademas, `TRAEFIK_ADMIN_PASSWORD` se valida cuando usas `make up-admin` o `make config-admin`.

## Redis

Redis ahora exige password en todos los entornos desde el compose base y la API consume `REDIS_PASSWORD` para sus checks y endpoints demo.

## Observabilidad en el borde

Prometheus, Grafana y `/metrics` ya no se publican en el baseline.

- `make up`: no expone `prometheus.localhost`, `grafana.localhost` ni `api.localhost/metrics`
- `make up-admin`: expone esos endpoints solo con `basicAuth` e `ipAllowList`
- `make up-prod-admin`: hace lo mismo en produccion usando el secret `infra/secrets/traefik_admin_users`

La allowlist actual permite solo rangos privados y loopback:

- `127.0.0.1/32`
- `10.0.0.0/8`
- `172.16.0.0/12`
- `192.168.0.0/16`

## TLS en produccion

Produccion ya no depende de HTTP plano como ruta principal. Traefik queda configurado para:

- escuchar en `:80` y `:443`
- redirigir `HTTP -> HTTPS`
- emitir certificados con Let's Encrypt por `httpChallenge`
- servir `web` y `api` bajo `websecure`

La configuracion dinamica de produccion se genera desde plantillas usando `PUBLIC_BASE_DOMAIN`, para evitar hardcodear dominios reales en el repositorio.

## Headers de seguridad

El proyecto ahora aplica headers de seguridad en dos capas:

- Next.js para las respuestas del frontend
- Traefik para las rutas publicadas en el borde

Headers aplicados:

- `X-Frame-Options: DENY`
- `X-Content-Type-Options: nosniff`
- `Referrer-Policy: strict-origin-when-cross-origin`
- `Permissions-Policy: camera=(), microphone=(), geolocation=()`
- `Cross-Origin-Opener-Policy: same-origin`

Ademas, en produccion bajo TLS Traefik agrega `Strict-Transport-Security`.

## FastAPI docs

La API ahora deshabilita `/docs`, `/redoc` y `/openapi.json` cuando `APP_ENV=production`.

- desarrollo: docs habilitadas
- produccion: docs y esquema OpenAPI no publicados

## Hardening de contenedores

El compose base ahora aplica endurecimiento por defecto a los servicios del stack.

Servicios con root filesystem de solo lectura:

- `traefik`
- `api`
- `web`
- `prometheus`
- `grafana`

Controles aplicados donde son viables:

- `read_only: true`
- `cap_drop: [ALL]`
- `security_opt: ["no-new-privileges:true"]`
- `tmpfs: [/tmp]`
- limites de memoria, CPU y `pids_limit`

Excepciones controladas:

- `postgres`
- `redis`

Esos dos servicios no usan `read_only: true` porque requieren escritura de datos. En ellos se aplican `no-new-privileges`, `tmpfs` y limites de recursos.

## Backups

Los backups de PostgreSQL ya no se guardan en texto plano.

El flujo actual:

- genera dump por stream
- comprime con `gzip`
- cifra con `openssl` usando `BACKUP_ENCRYPTION_PASSPHRASE`
- guarda archivos `*.sql.gz.enc`
- aplica retencion por dias con `BACKUP_RETENTION_DAYS`

Variables relevantes:

- `BACKUP_DIR`
- `BACKUP_RETENTION_DAYS`
- `BACKUP_ENCRYPTION_PASSPHRASE`

El script falla si `BACKUP_ENCRYPTION_PASSPHRASE` no existe o sigue en el valor placeholder.

## Checklist minima antes de produccion

- `Traefik dashboard` deshabilitado o protegido
- `Grafana` con credenciales rotadas
- `PostgreSQL` con password fuerte
- `Redis` con autenticacion activa
- `Prometheus` no expuesto publicamente
- `API /metrics` protegida o interna
- `TLS` habilitado
- `HTTP security headers` habilitados
- `FastAPI docs` deshabilitadas o protegidas
- `Backups` cifrados y con retencion
- `Containers` con hardening adicional

## Nota

Esta revision fue estatica sobre el repositorio. No incluye escaneo dinamico, pentest, analisis SBOM ni validacion de CVEs en dependencias o imagenes.

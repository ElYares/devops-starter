# Raspberry Pi LAN Testing

## Objetivo

Documentar como probar este starter en una Raspberry Pi dentro de una red local,
sin dominio publico, sin DNS publico y sin Let's Encrypt.

## Cuando usar esta guia

Usa esta guia si:

- la Raspberry solo sera accesible dentro de tu LAN
- no tienes todavia un dominio publico apuntando a la IP publica
- quieres validar el stack, networking, imagenes y Traefik antes de exponer nada a Internet

No uses esta guia como referencia para el flujo final de produccion con TLS
publico. Para ese caso revisa [docs/deployment.md](/home/elyarestark/develop/devops-starter/docs/deployment.md)
y [docs/raspberry-pi-testing.md](/home/elyarestark/develop/devops-starter/docs/raspberry-pi-testing.md).

## Importante

Mientras todo sea solo interno en la red local:

- no uses `make up-prod`
- no uses `make up-prod-admin`
- no uses `make config-prod`
- no uses `infra/scripts/deploy.sh` en modo productivo

La razon es que el overlay `prod` asume:

- `PUBLIC_BASE_DOMAIN`
- certificados Let's Encrypt
- puertos publicos `80/443`
- DNS real apuntando al host

Sin eso, el flujo correcto es el overlay de desarrollo/local.

## Flujo recomendado en LAN

1. Clonar el repo en la Raspberry Pi.
2. Preparar un `.env` para entorno interno.
3. Levantar el stack con `make up` o `make up-admin`.
4. Probar desde otra maquina de la misma red local.
5. Solo despues de validar la LAN, pasar a staging publico o CD remoto.

## `.env` recomendado para pruebas internas

Ejemplo minimo:

```env
COMPOSE_PROJECT_NAME=devops-starter-staging

API_IMAGE=ghcr.io/tu-owner/tu-repo/api
WEB_IMAGE=ghcr.io/tu-owner/tu-repo/web
IMAGE_TAG=latest
API_IMAGE_REF=
WEB_IMAGE_REF=

TRAEFIK_PORT=80

POSTGRES_DB=starter
POSTGRES_USER=starter
POSTGRES_PASSWORD=TU_PASSWORD_DB

REDIS_PORT=6379
REDIS_PASSWORD=TU_PASSWORD_REDIS

NEXT_PUBLIC_API_BASE_URL=http://api.localhost

GRAFANA_ADMIN_USER=admin
GRAFANA_ADMIN_PASSWORD=TU_PASSWORD_GRAFANA

BACKUP_DIR=infra/backups
BACKUP_RETENTION_DAYS=7
BACKUP_ENCRYPTION_PASSPHRASE=TU_PASSPHRASE_BACKUP
```

## Variables que puedes ignorar por ahora

Mientras no uses `prod`, estas variables no son relevantes para la prueba LAN:

- `PUBLIC_BASE_DOMAIN`
- `TRAEFIK_ACME_EMAIL`
- `TRAEFIK_TLS_PORT`

## Cosas que si debes cambiar

No dejes placeholders en:

- `API_IMAGE`
- `WEB_IMAGE`
- `POSTGRES_PASSWORD`
- `REDIS_PASSWORD`
- `GRAFANA_ADMIN_PASSWORD`
- `BACKUP_ENCRYPTION_PASSPHRASE`

`API_IMAGE_REF` y `WEB_IMAGE_REF` pueden quedarse vacios durante la prueba
manual en LAN.

## Levantar el stack en la Raspberry

Para stack base:

```bash
make config
make up
```

Para stack con paneles admin protegidos:

```bash
make config-admin
make up-admin
```

## Que esperar al levantar

El routing de Traefik en modo local/dev usa estos hosts:

- `web.localhost`
- `api.localhost`
- `grafana.localhost`
- `prometheus.localhost`
- `traefik-admin.localhost`

Eso funciona bien cuando accedes desde la misma maquina. Desde otra PC de la
LAN, usar la IP sola no basta porque Traefik enruta por header `Host`.

## Probar desde otra maquina en la LAN

Supongamos que la Raspberry tiene IP local `192.168.1.82`.

### Opcion A: prueba rapida con `curl`

Puedes forzar el `Host` manualmente:

```bash
curl -H 'Host: web.localhost' http://192.168.1.82/
curl -H 'Host: api.localhost' http://192.168.1.82/health
```

Si levantaste `make up-admin`, tambien puedes probar:

```bash
curl -H 'Host: traefik-admin.localhost' http://192.168.1.82/
curl -H 'Host: grafana.localhost' http://192.168.1.82/
curl -H 'Host: prometheus.localhost' http://192.168.1.82/
```

### Opcion B: prueba desde navegador

Puedes agregar entradas al archivo `hosts` de tu maquina cliente apuntando a la
IP local de la Raspberry.

Ejemplo:

```text
192.168.1.82 web.localhost
192.168.1.82 api.localhost
192.168.1.82 grafana.localhost
192.168.1.82 prometheus.localhost
192.168.1.82 traefik-admin.localhost
```

## Nota sobre `localhost`

Algunos sistemas tratan `*.localhost` de forma especial. Si tu navegador o tu
OS no resuelven bien esos hosts remotos, la opcion mas estable es ajustar el
starter para usar nombres internos tipo:

- `web.home.arpa`
- `api.home.arpa`
- `grafana.home.arpa`

Eso puede hacerse en una iteracion posterior si quieres un modo LAN mas limpio.

## Validacion recomendada

Antes de pasar a un deploy remoto o a un entorno publico, valida esto:

1. La Raspberry puede hacer `docker pull` de las imagenes publicadas.
2. `make up` levanta correctamente todos los servicios.
3. Traefik enruta a `web` y `api`.
4. `api` responde `/health` y `/ready`.
5. Si usas `make up-admin`, Grafana, Prometheus y Traefik admin quedan protegidos.

## Flujo sugerido de maduracion

### Etapa 1: LAN

- levantar con `make up`
- probar por IP local y `Host` headers
- validar networking, contenedores y observabilidad

### Etapa 2: LAN con hostnames internos

- ajustar Traefik a nombres mas amigables para red local
- agregar entradas en `hosts` o DNS interno

### Etapa 3: staging publico

- configurar dominio real
- abrir puertos `80/443`
- usar `make up-prod` o CD remoto
- activar digests, smoke checks y rollback desde GitHub Actions

## Recomendacion

No intentes forzar el flujo productivo demasiado pronto. Primero confirma que
la Raspberry puede levantar bien el stack en LAN. Una vez que eso este estable,
la transicion a staging publico y luego a CD remoto es mucho mas directa.

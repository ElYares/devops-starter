# Raspberry Pi Test Environment

Esta guia describe como montar un entorno de pruebas en una Raspberry Pi para
validar el flujo de despliegue de este proyecto, incluyendo el `cd.yml`, las
imagenes publicadas en GHCR y el despliegue remoto con Docker Compose.

## Objetivo

Usar una Raspberry Pi como servidor de staging ligero para validar:

- publicacion de imagenes `api` y `web` desde GitHub Actions
- despliegue remoto por SSH
- resolucion de Traefik y TLS
- healthchecks de `web` y `api`
- comportamiento del stack en arquitectura ARM64

## Requisitos

- Raspberry Pi 4, 5 o equivalente con al menos 4 GB de RAM
- Raspberry Pi OS 64-bit o Ubuntu Server 64-bit para ARM
- acceso SSH a la Raspberry Pi
- dominio o subdominio apuntando a la IP publica de la Raspberry Pi
- puertos `80` y `443` abiertos en el router o firewall
- Docker Engine y Docker Compose plugin instalados

## Importante sobre arquitectura

La Raspberry Pi usa arquitectura ARM64. Para que este proyecto funcione en ese
host, las imagenes publicadas en GHCR deben incluir `linux/arm64`.

El workflow `cd.yml` de este repo ya construye imagenes multi-arquitectura para:

- `linux/amd64`
- `linux/arm64`

Sin esto, la Raspberry Pi no podria hacer `docker pull` de las imagenes
publicadas por el pipeline.

## Preparar la Raspberry Pi

Actualizar el sistema:

```bash
sudo apt update
sudo apt upgrade -y
```

Instalar Docker:

```bash
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker "$USER"
newgrp docker
```

Verificar versiones:

```bash
docker version
docker compose version
```

Crear ruta del proyecto:

```bash
mkdir -p ~/apps/devops-starter
cd ~/apps/devops-starter
git clone <tu-repo> .
```

## Preparar `.env`

Partir de [`.env.example`](/home/elyarestark/develop/devops-starter/.env.example:1):

```bash
cp .env.example .env
```

Configurar al menos estas variables:

```bash
COMPOSE_PROJECT_NAME=devops-starter-staging

API_IMAGE=ghcr.io/<owner>/<repo>/api
WEB_IMAGE=ghcr.io/<owner>/<repo>/web
IMAGE_TAG=latest

PUBLIC_BASE_DOMAIN=staging.example.com
TRAEFIK_ACME_EMAIL=ops@example.com

POSTGRES_PASSWORD=<password-fuerte>
REDIS_PASSWORD=<password-fuerte>
GRAFANA_ADMIN_PASSWORD=<password-fuerte>

TRAEFIK_PORT=80
TRAEFIK_TLS_PORT=443
```

Notas:

- `IMAGE_TAG` sera sobrescrito por `cd.yml` durante el deploy remoto.
- `PUBLIC_BASE_DOMAIN` debe ser un dominio real resolviendo hacia la Raspberry Pi.
- Usa valores unicos para staging; no reutilices secretos de produccion.

## Acceso a GHCR

Si el repositorio o las imagenes son privadas, autentica Docker:

```bash
echo "<ghcr-token>" | docker login ghcr.io -u "<github-user>" --password-stdin
```

El token debe tener al menos permiso de lectura de paquetes.

## Validacion manual previa

Antes de conectar GitHub Actions, valida que la Raspberry Pi pueda resolver la
configuracion productiva:

```bash
make config-prod
```

Si quieres probar el overlay admin tambien:

```bash
mkdir -p infra/secrets
htpasswd -nbB admin '<password-fuerte>' > infra/secrets/traefik_admin_users
make config-prod-admin
```

## Prueba manual del deploy

Puedes probar el script antes de activar el CD:

```bash
export DEPLOY_ENV=staging
export IMAGE_TAG=latest
./infra/scripts/deploy.sh
```

Esto debe:

- renderizar la config productiva de Traefik
- hacer `docker compose pull` de `api` y `web`
- levantar el stack
- validar:
  - `https://web.<dominio>/api/health`
  - `https://api.<dominio>/health`
  - `https://api.<dominio>/ready`

## Integracion con GitHub Actions

En GitHub crea el environment `staging` y configura:

Secrets:

- `DEPLOY_HOST`: IP o hostname de la Raspberry Pi
- `DEPLOY_USER`: usuario SSH
- `DEPLOY_PATH`: ruta del repo en la Raspberry Pi
- `DEPLOY_SSH_KEY`: llave privada usada por Actions

Variables:

- `CD_STAGING_ENABLED=true`

El workflow [`.github/workflows/cd.yml`](/home/elyarestark/develop/devops-starter/.github/workflows/cd.yml:1)
hara esto:

1. construira y publicara imagenes `api` y `web` en GHCR
2. generara un `IMAGE_TAG` basado en commit o tag
3. entrara por SSH a la Raspberry Pi
4. ejecutara `./infra/scripts/deploy.sh`

## DNS recomendado para pruebas

Puedes usar un subdominio dedicado, por ejemplo:

- `web.staging.example.com`
- `api.staging.example.com`

En ese caso, configura:

```bash
PUBLIC_BASE_DOMAIN=staging.example.com
```

El proyecto espera:

- `web.${PUBLIC_BASE_DOMAIN}`
- `api.${PUBLIC_BASE_DOMAIN}`

## Validaciones despues del deploy

Verifica desde tu maquina:

```bash
curl -I https://web.staging.example.com/api/health
curl https://api.staging.example.com/health
curl https://api.staging.example.com/ready
```

Verifica en la Raspberry Pi:

```bash
docker compose --env-file .env -f infra/compose/docker-compose.yml -f infra/compose/docker-compose.prod.yml ps
docker compose --env-file .env -f infra/compose/docker-compose.yml -f infra/compose/docker-compose.prod.yml logs --tail=100
```

## Pruebas recomendadas

- push a `main` y confirmar que se publican imagenes en GHCR
- confirmar que `deploy-staging` corre en GitHub Actions
- validar que Traefik obtiene certificados TLS
- validar que `api` y `web` usan la version correcta del `IMAGE_TAG`
- reiniciar la Raspberry Pi y comprobar que el stack vuelve a levantar
- correr `make backup` para confirmar que el flujo operativo base funciona

## Limitaciones practicas

- PostgreSQL, Grafana y builds de Next.js pueden consumir bastante RAM en una Pi de 4 GB
- si el host es muy justo, evita activar `prod-admin` al mismo tiempo
- para pruebas continuas, una Pi 5 o un SSD externo mejora mucho la estabilidad
- este entorno es util para staging y validacion, no para produccion seria con trafico real

## Siguiente paso sugerido

Una vez validado staging en Raspberry Pi:

- activar aprobacion manual para `production`
- separar secretos entre staging y production
- agregar rollback por tag anterior

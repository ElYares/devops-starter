# CI/CD Assessment

## Objetivo

Documentar el estado actual del proyecto y definir una ruta pragmatica para
llevar el pipeline de CI/CD a un nivel mas confiable y operable.

## Estado Actual

El repo ya tiene una base util:

- monorepo separado en `apps/web`, `apps/api` e `infra`
- GitHub Actions para CI y CD
- build y push de imagenes Docker multi-arquitectura a GHCR
- despliegue remoto por SSH con Docker Compose
- healthchecks, observabilidad y overlays por entorno

Validaciones ejecutadas sobre el repo:

- `docker compose ... config` para overlays dev y prod: OK
- `apps/api/.venv/bin/python -m ruff check apps/api`: OK
- `apps/api/.venv/bin/python -m pytest apps/api`: OK
- `cd apps/web && npm run test`: OK
- `cd apps/web && npm run build`: OK

## Hallazgos Principales

### 1. El CD no esta encadenado a CI

Los workflows de CI y CD existen por separado:

- `.github/workflows/ci.yml`
- `.github/workflows/cd.yml`

Hoy el flujo de CD publica y despliega en `push` a `main` o tags sin depender
formalmente de una senal de CI aprobada. Eso deja una ventana donde puedes
desplegar algo aunque el control de calidad no este gobernando el merge o la
promocion.

### 2. No hay promocion estricta de artefactos

El workflow de CD reconstruye imagenes al publicar. Eso es funcional, pero no
es el patron mas solido para entornos serios. Lo ideal es:

- construir una vez
- validar esa imagen
- promover exactamente ese digest a staging
- promover el mismo digest a produccion

### 3. El deploy actual no tiene rollback real

`infra/scripts/deploy.sh` hace `pull`, `up -d` y luego curls de health. Si el
healthcheck falla:

- no se conserva un estado previo listo para revertir
- no hay rollback automatico
- no hay espera robusta con retries y timeout controlado

### 4. Reproducibilidad mejorable en Node

El proyecto tiene `apps/web/package-lock.json`, pero hoy usa `npm install` en:

- `.github/workflows/ci.yml`
- `apps/web/Dockerfile`
- `Makefile`

Para CI y build de imagen, `npm ci` es mejor porque instala exactamente el
lockfile y reduce drift entre entornos.

### 5. Falta un punto canonico de calidad

Ya existe `Makefile` con `lint` y `test`, pero no hay un contrato claro para
los jobs de CI por dominio, por ejemplo:

- `make ci-api`
- `make ci-web`
- `make ci-compose`

Eso complica mantener paridad entre lo que corre localmente y lo que corre en
GitHub Actions.

### 6. Higiene de artefactos operativos

Existe un backup cifrado versionado en Git:

- `infra/backups/postgres-20260407-175616.sql.gz.enc`

Aunque este cifrado, un backup real no deberia estar en el repo. Ademas,
`.gitignore` hoy no ignora `infra/backups/`.

### 7. Seguridad del pipeline aun basica

Todavia faltan piezas tipicas de una base DevSecOps:

- escaneo de imagenes
- escaneo de dependencias
- SBOM
- firma de imagenes
- pinning confiable del host SSH en lugar de `ssh-keyscan` al vuelo

## Recomendacion De Arquitectura Operativa

Para este starter, mantener `GitHub Actions + GHCR + Docker Compose + SSH` es
razonable. No moveria el proyecto a Kubernetes todavia.

El siguiente salto correcto no es complejidad, sino confiabilidad:

1. endurecer CI
2. gobernar merges a `main`
3. promover artefactos por digest
4. endurecer deploy y rollback
5. agregar seguridad al supply chain

## Plan Macro

### Fase 1. Cerrar la base

- habilitar branch protection para que `main` requiera CI verde
- eliminar backups del repo e ignorar `infra/backups/`
- unificar calidad en comandos canonicos del `Makefile`
- cambiar `npm install` por `npm ci` en CI y en el Dockerfile web

### Fase 2. Endurecer CI

- convertir CI en la puerta obligatoria de merge
- agregar cache de dependencias para Python y Node
- separar jobs por area y opcionalmente por paths
- publicar reportes y artifacts utiles

### Fase 3. Endurecer CD

- desplegar solo despues de CI exitoso
- promover imagenes por digest, no por rebuild
- agregar smoke checks con retries y timeouts claros
- implementar rollback simple al digest previo

### Fase 4. DevSecOps minimo

- Trivy o equivalente para imagenes
- escaneo de dependencias
- SBOM
- firma de imagenes
- control de host SSH confiable

## Plan De Accion Enfocado: Cerrar La Base

### Objetivo

Dejar el repositorio en un estado donde `main` este protegido, el pipeline sea
reproducible y el flujo local/CI use los mismos comandos.

### Entregables

- `main` protegida en GitHub
- backup removido del repo
- `infra/backups/` ignorado por Git
- nuevos targets `make ci-api`, `make ci-web`, `make ci-compose`
- CI usando esos targets
- `npm ci` en workflow y Dockerfile del frontend

### Secuencia Recomendada

1. Limpiar artefactos operativos del repo.
2. Estandarizar comandos de calidad en `Makefile`.
3. Cambiar installs de Node a `npm ci`.
4. Ajustar `ci.yml` para consumir los nuevos targets canonicos.
5. Configurar branch protection en GitHub.

### Detalle Por Tarea

#### A. Branch protection

Esto no vive en el repo; se configura en GitHub.

Config recomendada para `main`:

- require pull request before merging
- require status checks to pass before merging
- checks requeridos:
  - `validate-compose`
  - `api-quality`
  - `web-quality`
  - `image-build`
- dismiss stale approvals when new commits are pushed
- block direct pushes a `main`

Si luego renombramos jobs o consolidamos CI, la lista de checks debe seguir ese
nombre final.

#### B. Eliminar backup versionado e ignorar `infra/backups/`

Cambios:

- borrar `infra/backups/postgres-20260407-175616.sql.gz.enc` del tracking Git
- agregar `infra/backups/` a `.gitignore`

Razon:

- evita versionar datos operativos
- baja ruido en PRs
- reduce riesgo de fuga de informacion

#### C. Unificar calidad en `Makefile`

Agregar targets canonicos:

- `ci-api`: install/lint/test de API con flujo reproducible
- `ci-web`: install/lint/test/build de web
- `ci-compose`: validacion de compose dev/prod

Objetivo:

- que local y GitHub Actions ejecuten exactamente el mismo contrato
- reducir duplicacion de shell en workflows
- hacer mas simple el mantenimiento futuro

#### D. Cambiar `npm install` por `npm ci`

Aplicar en:

- `.github/workflows/ci.yml`
- `apps/web/Dockerfile`
- `Makefile` en targets de CI o instalacion donde convenga reproducibilidad

Criterio:

- en CI y builds deterministas: `npm ci`
- en desarrollo local tambien puede usarse `npm ci` si el proyecto depende del
  lockfile como fuente de verdad

#### E. Ajustar CI al nuevo contrato

Actualizar `.github/workflows/ci.yml` para que use:

- `make ci-compose`
- `make ci-api`
- `make ci-web`

Beneficio:

- el workflow deja de codificar pasos duplicados
- el repo expresa claramente su contrato de calidad

## Riesgos Y Consideraciones

- branch protection requiere acceso administrativo al repo
- si se cambia a `npm ci`, el lockfile debe estar sano y actualizado
- si `ci-api` depende de `.venv`, hay que decidir si CI crea esa venv o si usa
  install directo con Python del runner; lo importante es que el contrato quede
  consistente

## Siguiente Paso Recomendado

Implementar primero la Fase 1 completa y solo despues tocar CD. Si `main` no
esta gobernada por CI reproducible, endurecer despliegue todavia no ataca el
problema principal.

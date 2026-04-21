# API

Esta carpeta contiene una API demo en FastAPI pensada para validar que el stack
base de infraestructura, monitoreo y networking esta funcionando.

## Responsabilidades

- Exponer probes de `health` y `ready` para Docker Compose y el proxy.
- Comprobar conectividad a PostgreSQL y Redis.
- Publicar metricas Prometheus desde el mismo proceso.
- Entregar un endpoint demo consumido por el frontend.

## Estructura

```text
apps/api/
├── app/main.py          # Punto de entrada HTTP y probes operativos
├── tests/test_main.py   # Contrato base de endpoints y configuracion
├── Dockerfile           # Imagen de runtime para el servicio API
├── requirements.txt     # Dependencias Python
└── ruff.toml            # Reglas de lint
```

## Variables de entorno

- `APP_ENV`: controla si FastAPI expone `/docs`, `/redoc` y `/openapi.json`.
- `POSTGRES_DB`, `POSTGRES_USER`, `POSTGRES_PASSWORD`: credenciales de Postgres.
- `POSTGRES_HOST`, `POSTGRES_PORT`: ubicacion del contenedor de base de datos.
- `POSTGRES_CONNECT_TIMEOUT_SECONDS`: timeout corto para probes y arranque.
- `REDIS_HOST`, `REDIS_PORT`, `REDIS_PASSWORD`: configuracion de Redis.
- `REDIS_CONNECT_TIMEOUT_SECONDS`: timeout corto para probes y cliente demo.

## Endpoints

- `GET /`: smoke test minimo de la API.
- `GET /health`: liveness probe; solo confirma que el proceso responde.
- `GET /ready`: readiness probe; verifica Postgres y Redis.
- `GET /demo`: usa Redis para incrementar un contador y regresar estado de dependencias.
- `GET /metrics`: salida Prometheus para el stack de observabilidad.

## Flujo operativo

1. Docker Compose levanta Postgres y Redis.
2. El `lifespan` inicial de FastAPI ejecuta probes para poblar metricas.
3. El frontend consulta `GET /demo` para mostrar estado vivo del stack.
4. Prometheus scrapea `GET /metrics` para dashboards y alertas futuras.

## Extension sugerida

- Separar rutas por dominio cuando la API deje de ser solo demo.
- Mover checks de infraestructura a un modulo `services/health.py` si crecen.
- Reemplazar el contador `api_demo_visits` por casos de uso reales o seed data.

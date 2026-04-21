"""FastAPI demo app for the starter stack.

This module centralizes the operational contract of the API:
- liveness and readiness probes used by Docker Compose
- connectivity checks for Postgres and Redis
- a small demo endpoint consumed by the frontend
- Prometheus metrics scraped by the monitoring layer
"""

import os
from contextlib import asynccontextmanager

from fastapi import FastAPI
from prometheus_client import CONTENT_TYPE_LATEST, Counter, Gauge, generate_latest
from psycopg import connect
from redis import Redis
from starlette.responses import Response

# Global metrics keep the starter observable from the first iteration.
REQUEST_COUNTER = Counter("api_requests_total", "Total API requests")
POSTGRES_UP = Gauge("api_postgres_up", "Postgres connectivity status")
REDIS_UP = Gauge("api_redis_up", "Redis connectivity status")


def app_env() -> str:
    """Return the normalized runtime environment."""
    return os.getenv("APP_ENV", "development").lower()


def db_dsn() -> str:
    """Build the Postgres DSN from Compose-provided environment variables."""
    return (
        f"dbname={os.getenv('POSTGRES_DB', 'starter')} "
        f"user={os.getenv('POSTGRES_USER', 'starter')} "
        f"password={os.getenv('POSTGRES_PASSWORD', 'starter_password')} "
        f"host={os.getenv('POSTGRES_HOST', 'postgres')} "
        f"port={os.getenv('POSTGRES_PORT', '5432')} "
        f"connect_timeout={os.getenv('POSTGRES_CONNECT_TIMEOUT_SECONDS', '1')}"
    )


def redis_client() -> Redis:
    """Create a Redis client from environment configuration."""
    return Redis(
        host=os.getenv("REDIS_HOST", "redis"),
        port=int(os.getenv("REDIS_PORT", "6379")),
        password=os.getenv("REDIS_PASSWORD"),
        socket_connect_timeout=float(
            os.getenv("REDIS_CONNECT_TIMEOUT_SECONDS", "1")
        ),
        socket_timeout=float(os.getenv("REDIS_CONNECT_TIMEOUT_SECONDS", "1")),
        decode_responses=True,
    )


def postgres_check() -> bool:
    """Probe Postgres and update the exported gauge."""
    try:
        with connect(db_dsn()) as conn:
            with conn.cursor() as cur:
                cur.execute("select 1;")
                cur.fetchone()
        POSTGRES_UP.set(1)
        return True
    except Exception:
        POSTGRES_UP.set(0)
        return False


def redis_check() -> bool:
    """Probe Redis and update the exported gauge."""
    try:
        redis_client().ping()
        REDIS_UP.set(1)
        return True
    except Exception:
        REDIS_UP.set(0)
        return False


@asynccontextmanager
async def lifespan(_: FastAPI):
    """Warm dependency gauges during startup for dashboards and alerts."""
    postgres_check()
    redis_check()
    yield


def create_app() -> FastAPI:
    """Create the FastAPI app and hide interactive docs in production."""
    is_production = app_env() == "production"

    return FastAPI(
        title="DevOps Starter API",
        lifespan=lifespan,
        docs_url=None if is_production else "/docs",
        redoc_url=None if is_production else "/redoc",
        openapi_url=None if is_production else "/openapi.json",
    )


app = create_app()


def readiness_payload() -> dict[str, bool | str]:
    """Aggregate dependency checks for readiness-oriented responses."""
    postgres_ok = postgres_check()
    redis_ok = redis_check()
    return {
        "status": "ready" if postgres_ok and redis_ok else "degraded",
        "postgres": postgres_ok,
        "redis": redis_ok,
    }


@app.get("/")
def root() -> dict[str, str]:
    """Expose a minimal smoke-test endpoint for the API service."""
    REQUEST_COUNTER.inc()
    return {
        "service": "api",
        "status": "ok",
        "message": "DevOps Starter API",
    }


@app.get("/health")
def health() -> dict[str, str]:
    """Expose liveness without blocking on downstream dependencies."""
    REQUEST_COUNTER.inc()
    return {"status": "ok"}


@app.get("/ready")
def ready() -> dict[str, bool | str]:
    """Expose readiness based on Postgres and Redis reachability."""
    REQUEST_COUNTER.inc()
    return readiness_payload()


@app.get("/demo")
def demo() -> dict[str, object]:
    """Exercise Redis and return dependency status for the frontend demo."""
    REQUEST_COUNTER.inc()
    cache = redis_client()
    visits = cache.incr("api_demo_visits")
    status = readiness_payload()
    return {
        "service": "api",
        "visits": visits,
        "postgres": status["postgres"],
        "redis": status["redis"],
    }


@app.get("/metrics")
def metrics() -> Response:
    """Expose Prometheus metrics for scraping."""
    return Response(generate_latest(), media_type=CONTENT_TYPE_LATEST)

import os
from contextlib import asynccontextmanager

from fastapi import FastAPI
from prometheus_client import CONTENT_TYPE_LATEST, Counter, Gauge, generate_latest
from psycopg import connect
from redis import Redis
from starlette.responses import Response


REQUEST_COUNTER = Counter("api_requests_total", "Total API requests")
POSTGRES_UP = Gauge("api_postgres_up", "Postgres connectivity status")
REDIS_UP = Gauge("api_redis_up", "Redis connectivity status")


def db_dsn() -> str:
    return (
        f"dbname={os.getenv('POSTGRES_DB', 'starter')} "
        f"user={os.getenv('POSTGRES_USER', 'starter')} "
        f"password={os.getenv('POSTGRES_PASSWORD', 'starter_password')} "
        f"host={os.getenv('POSTGRES_HOST', 'postgres')} "
        f"port={os.getenv('POSTGRES_PORT', '5432')}"
    )


def redis_client() -> Redis:
    return Redis(
        host=os.getenv("REDIS_HOST", "redis"),
        port=int(os.getenv("REDIS_PORT", "6379")),
        decode_responses=True,
    )


def postgres_check() -> bool:
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
    try:
        redis_client().ping()
        REDIS_UP.set(1)
        return True
    except Exception:
        REDIS_UP.set(0)
        return False


@asynccontextmanager
async def lifespan(_: FastAPI):
    postgres_check()
    redis_check()
    yield


app = FastAPI(title="DevOps Starter API", lifespan=lifespan)


@app.get("/")
def root():
    REQUEST_COUNTER.inc()
    return {
        "service": "api",
        "status": "ok",
        "message": "DevOps Starter API",
    }


@app.get("/health")
def health():
    REQUEST_COUNTER.inc()
    return {"status": "ok"}


@app.get("/ready")
def ready():
    REQUEST_COUNTER.inc()
    postgres_ok = postgres_check()
    redis_ok = redis_check()
    return {
        "status": "ready" if postgres_ok and redis_ok else "degraded",
        "postgres": postgres_ok,
        "redis": redis_ok,
    }


@app.get("/demo")
def demo():
    REQUEST_COUNTER.inc()
    cache = redis_client()
    visits = cache.incr("api_demo_visits")
    return {
        "service": "api",
        "visits": visits,
        "postgres": postgres_check(),
        "redis": redis_check(),
    }


@app.get("/metrics")
def metrics():
    return Response(generate_latest(), media_type=CONTENT_TYPE_LATEST)

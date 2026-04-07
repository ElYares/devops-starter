from fastapi.testclient import TestClient

from app.main import app, redis_client

client = TestClient(app)


def test_health_endpoint():
    response = client.get("/health")

    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_ready_endpoint_degraded_when_dependencies_fail(monkeypatch):
    monkeypatch.setattr("app.main.postgres_check", lambda: False)
    monkeypatch.setattr("app.main.redis_check", lambda: False)

    response = client.get("/ready")

    assert response.status_code == 200
    assert response.json() == {
        "status": "degraded",
        "postgres": False,
        "redis": False,
    }


def test_redis_client_uses_password_from_env(monkeypatch):
    monkeypatch.setenv("REDIS_PASSWORD", "super-secret")

    client = redis_client()

    assert client.connection_pool.connection_kwargs["password"] == "super-secret"

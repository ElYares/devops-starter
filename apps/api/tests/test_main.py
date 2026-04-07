from fastapi.testclient import TestClient

from app.main import app

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

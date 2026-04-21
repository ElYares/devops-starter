from app.main import create_app, db_dsn, health, ready, redis_client


def test_health_endpoint():
    assert health() == {"status": "ok"}


def test_ready_endpoint_degraded_when_dependencies_fail(monkeypatch):
    monkeypatch.setattr("app.main.postgres_check", lambda: False)
    monkeypatch.setattr("app.main.redis_check", lambda: False)

    assert ready() == {
        "status": "degraded",
        "postgres": False,
        "redis": False,
    }


def test_redis_client_uses_password_from_env(monkeypatch):
    monkeypatch.setenv("REDIS_PASSWORD", "super-secret")
    monkeypatch.setenv("REDIS_CONNECT_TIMEOUT_SECONDS", "2.5")

    client = redis_client()

    assert client.connection_pool.connection_kwargs["password"] == "super-secret"
    assert client.connection_pool.connection_kwargs["socket_connect_timeout"] == 2.5
    assert client.connection_pool.connection_kwargs["socket_timeout"] == 2.5


def test_db_dsn_includes_short_connect_timeout(monkeypatch):
    monkeypatch.setenv("POSTGRES_CONNECT_TIMEOUT_SECONDS", "2")

    assert "connect_timeout=2" in db_dsn()


def test_docs_enabled_outside_production(monkeypatch):
    monkeypatch.setenv("APP_ENV", "development")
    app = create_app()

    assert app.docs_url == "/docs"
    assert app.redoc_url == "/redoc"
    assert app.openapi_url == "/openapi.json"


def test_docs_disabled_in_production(monkeypatch):
    monkeypatch.setenv("APP_ENV", "production")
    app = create_app()

    assert app.docs_url is None
    assert app.redoc_url is None
    assert app.openapi_url is None

# Deployment

## Flujo inicial

1. Copiar `.env.example` a `.env`.
2. Ejecutar `make up`.
3. Validar healthchecks con `make ps`.
4. Revisar logs con `make logs`.

## Proximo objetivo

- separar entorno local y server
- parametrizar imagenes para registry
- anadir script de deploy controlado

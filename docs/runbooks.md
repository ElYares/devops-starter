# Runbooks

## Stack no levanta

1. Verifica que Docker y Docker Compose esten instalados.
2. Ejecuta `make config` para validar variables y compose.
3. Usa `make logs` para detectar el servicio fallando.

## API no responde

1. Confirma que `postgres` y `redis` esten healthy.
2. Revisa `http://api.localhost/ready`.
3. Verifica variables en `.env`.

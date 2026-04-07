# Runbooks

## Stack no levanta

1. Verifica que Docker y Docker Compose esten instalados.
2. Ejecuta `make config` para validar variables y compose.
3. Usa `make logs` para detectar el servicio fallando.

## API no responde

1. Confirma que `postgres` y `redis` esten healthy.
2. Revisa `http://api.localhost/ready`.
3. Verifica variables en `.env`.

## Backup y restore

Antes de usar backups, define en `.env`:

- `BACKUP_ENCRYPTION_PASSPHRASE`
- opcionalmente `BACKUP_DIR`
- opcionalmente `BACKUP_RETENTION_DAYS`

Crear backup:

```bash
make backup
```

El archivo resultante queda cifrado con extension `.sql.gz.enc`.

Restaurar backup:

```bash
make restore BACKUP_FILE=infra/backups/postgres-YYYYMMDD-HHMMSS.sql.gz.enc
```

O directamente:

```bash
./infra/scripts/restore.sh infra/backups/postgres-YYYYMMDD-HHMMSS.sql.gz.enc
```

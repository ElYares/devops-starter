# Arquitectura

## Objetivo

Crear un starter DevOps reutilizable para aplicaciones modernas con una base operable desde el primer commit.

## Componentes

- `web`: frontend demo en Next.js
- `api`: backend demo en FastAPI
- `postgres`: persistencia principal
- `redis`: cache / estado efimero
- `traefik`: reverse proxy y entrypoint unico
- `prometheus`: scraping de metricas
- `grafana`: visualizacion inicial

## Redes

- `edge`: trafico expuesto al proxy y servicios publicables
- `backend`: trafico interno entre API, Postgres y Redis
- `observability`: trafico interno de monitoreo

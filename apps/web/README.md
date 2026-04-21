# Web

Esta carpeta contiene el frontend demo en Next.js. Su objetivo no es cubrir
producto real, sino mostrar el flujo entre proxy, frontend y API dentro del
starter.

## Responsabilidades

- Renderizar una pagina inicial que explique el stack.
- Consultar la API desde el servidor usando la red interna de Docker.
- Exponer un endpoint local de `health` para healthchecks del contenedor.
- Aplicar headers HTTP base de seguridad desde Next.js.

## Estructura

```text
apps/web/
├── app/page.tsx             # Home server-rendered y consumo del endpoint /demo
├── app/layout.tsx           # Metadata y shell raiz
├── app/api/health/route.ts  # Healthcheck del contenedor web
├── next.config.ts           # Standalone output y headers de seguridad
├── tests/env.test.mjs       # Validacion minima de variables publicas
├── Dockerfile               # Build multi-stage para runtime liviano
└── package.json             # Scripts y dependencias del frontend
```

## Variables de entorno

- `API_INTERNAL_BASE_URL`: URL preferida desde el contenedor web hacia la API.
- `NEXT_PUBLIC_API_BASE_URL`: URL publica para exponer la API fuera del cluster local.

La pagina usa primero `API_INTERNAL_BASE_URL` para evitar salir por el proxy
cuando la llamada ocurre server-side dentro de Docker Compose.

## Flujo de datos

1. `app/page.tsx` se renderiza en el servidor.
2. `getApiStatus()` consulta `GET /demo` de la API.
3. Si la API no responde, el frontend muestra un fallback controlado.
4. Traefik publica la app bajo `web.localhost` y enruta segun la configuracion de infra.

## Extension sugerida

- Mover la capa de llamadas HTTP a `lib/api.ts` cuando aparezcan mas endpoints.
- Agregar componentes reutilizables si la UI crece mas alla de una sola pagina.
- Mantener `app/api/health/route.ts` liviano para que siga siendo un probe confiable.

# Troubleshooting

## Hosts locales

Este starter usa dominios `*.localhost`, por lo que no requiere editar `/etc/hosts` en la mayoria de sistemas modernos.

## Puertos en uso

Si `80`, `8080` o `3001` ya estan en uso, ajusta `.env` y vuelve a levantar el stack.

## Dependencias de build

La primera ejecucion descargara imagenes y dependencias de Node/Python, por lo que puede tardar mas.

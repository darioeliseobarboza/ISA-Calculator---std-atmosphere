# Orquestación Docker — Atmosphere

Orquestación a nivel monorepo de los dos servicios de aplicación de Atmosphere:

- **`atmosphere-api`** — binario Go (stdlib `net/http`), imagen distroless non-root.
- **`atmosphere-web`** — build de Flutter web servido por `nginx:1.27-alpine`.

> Los targets **desktop** (Windows/Linux) de la app **NO se contenerizan** (ADR-004):
> se distribuyen como binarios nativos (`flutter build windows` / `flutter build linux`).
> Este `docker/` orquesta únicamente la API y la web.

Sistema **stateless** (ADR-003): no hay base de datos ni volúmenes de persistencia.

## Patrón base + overrides

Sigue el patrón **base + overrides** de Docker Compose v2 (ADR-004):

| Archivo | Rol |
|---|---|
| `docker-compose.yml` | **Base** — única fuente de verdad de lo común (servicios, env vars compartidas por nombre, red de aplicación). No define `build`/`image`/`ports`/red de entorno. |
| `docker-compose.dev.yml` | **Override dev** — `build:` desde el path local + puertos en localhost + valores de env de dev. |
| `docker-compose.prod.yml` | **Override prod** — `image:` del registry + red externa `ingress-network` + vars del proxy, **sin** puertos al host. |

La config común vive **una sola vez** en el base; cada override carga **solo** sus diferencias (`build` vs `image`, red y exposición de puertos). Esto garantiza la paridad estructural dev/prod y evita drift.

## Comandos

Los comandos combinan **siempre** base + override (`-f` base primero, override después):

### Desarrollo (local)

```bash
docker compose -f docker/docker-compose.yml -f docker/docker-compose.dev.yml up
```

- Buildea ambas imágenes localmente desde `services/atmosphere-api` y `services/atmosphere-app`.
- Expone en el host: **API → `http://localhost:8080`**, **web → `http://localhost:8081`**.
- Verificación rápida:

  ```bash
  curl -i http://localhost:8080/health      # 200 {"status":"ok","timestamp":"<RFC3339>"}
  curl -i http://localhost:8081/            # 200 text/html (index del build Flutter)
  ```

Bajar el entorno:

```bash
docker compose -f docker/docker-compose.yml -f docker/docker-compose.dev.yml down
```

### Producción

```bash
docker compose -f docker/docker-compose.yml -f docker/docker-compose.prod.yml up -d
```

- Usa **imágenes del registry** (no buildea). **No expone puertos al host**: el tráfico entra por el proxy.
- Renderizar/inspeccionar la config sin levantar:

  ```bash
  docker compose -f docker/docker-compose.yml -f docker/docker-compose.prod.yml config
  ```

## Prerequisitos de producción

1. **Red externa `ingress-network`.** El compose de prod la referencia como `external: true` (NO la crea). Debe existir en el host antes de levantar:

   ```bash
   docker network create ingress-network   # solo si aún no existe
   ```

2. **Proxy en `ingress-network`.** En esa red debe estar corriendo **nginx-proxy + acme-companion**, que:
   - Descubre los contenedores por las env vars `VIRTUAL_HOST`, `VIRTUAL_PORT` y `LETSENCRYPT_HOST`.
   - Enruta por dominio y **termina TLS** (los contenedores NO exponen puertos al host).

3. **Imágenes publicadas en el registry.** Los servicios usan `image:` versionada. Las referencias se parametrizan por variables (ver tabla). En particular:

   > **`atmosphere-web` hornea `API_BASE_URL` en BUILD-TIME.** El `API_BASE_URL` no es env de runtime: se inyecta como build-arg cuando se construye la imagen (Flutter lo bundlea vía `flutter_dotenv`). Por eso la **imagen de prod debe haberse construido con el dominio productivo de la API** ya horneado. El compose de prod no puede cambiarlo en runtime.

## Variables de entorno por ambiente

### `atmosphere-api`

| Variable | Dev | Prod | Notas |
|---|---|---|---|
| `ENV` | `development` | `production` | En `production` la API hace **fail-fast** si `CORS_ALLOWED_ORIGINS` está vacío. |
| `HTTP_ADDR` | `:8080` | `:8080` | **Nombre real de la variable** (NO `PORT`). Dirección `host:port` de escucha. |
| `CORS_ALLOWED_ORIGINS` | `http://localhost:8081` | dominio(s) del frontend, **no vacío** | Lista separada por comas, sin wildcard. Obligatoria en producción. |
| `VIRTUAL_HOST` | — | dominio público de la API | Solo prod. Descubrimiento por el proxy. |
| `VIRTUAL_PORT` | — | `8080` | Solo prod. Puerto **interno** del contenedor. |
| `LETSENCRYPT_HOST` | — | = `VIRTUAL_HOST` | Solo prod. Dispara emisión/renovación TLS. |

> **`HTTP_ADDR`, no `PORT`.** ADR-004 y `docs/prd/architecture.md` mencionan la variable como `PORT`, pero la implementación real (S-001, `cmd/atmosphere-api/config.go`) lee **`HTTP_ADDR`** (default `:8080`). Los compose declaran `HTTP_ADDR`.

> **Healthcheck de la API: omitido.** La imagen de `atmosphere-api` es distroless (sin shell ni `curl`/`wget`) y el binario no expone subcomando de healthcheck, por lo que un `healthcheck` de Compose basado en shell no funciona. `GET /health` sigue disponible para chequeo externo (proxy / verificación manual / la web).

### `atmosphere-web`

| Variable / Arg | Dev | Prod | Notas |
|---|---|---|---|
| `API_BASE_URL` | `http://localhost:8080` (build-arg) | dominio prod de la API (build-arg, **horneado al publicar la imagen**) | **Build-time, no runtime.** En dev va bajo `build.args`; en prod ya viene en la imagen del registry. |
| `VIRTUAL_HOST` | — | dominio público del frontend | Solo prod. |
| `VIRTUAL_PORT` | — | `80` | Solo prod. Puerto **interno** de nginx. |
| `LETSENCRYPT_HOST` | — | = `VIRTUAL_HOST` | Solo prod. |

### Variables del compose de prod (referencias parametrizables)

El override de prod usa interpolación con defaults de ejemplo. Definí estas variables (p. ej. en un `.env` junto a los compose, o en el entorno del deploy) antes de levantar prod:

| Variable | Para qué | Ejemplo |
|---|---|---|
| `API_IMAGE` | Imagen:tag de la API en el registry | `registry.example.com/atmosphere-api:1.0.0` |
| `WEB_IMAGE` | Imagen:tag de la web en el registry | `registry.example.com/atmosphere-web:1.0.0` |
| `API_DOMAIN` | Dominio público de la API | `api.atmosphere.example.com` |
| `WEB_DOMAIN` | Dominio público del frontend | `app.atmosphere.example.com` |
| `API_CORS_ORIGINS` | `CORS_ALLOWED_ORIGINS` de la API (no vacío) | `https://app.atmosphere.example.com` |

## Puertos

| Ambiente | API | Web |
|---|---|---|
| **dev** | `localhost:8080` → contenedor `8080` | `localhost:8081` → contenedor `80` |
| **prod** | sin puerto al host (entra por el proxy, interno `8080`) | sin puerto al host (entra por el proxy, interno `80`) |

## CORS (sistema vivo end-to-end)

La web (origen `http://localhost:8081` en dev) y la API (`http://localhost:8080`) son orígenes distintos, por lo que la API tiene **CORS habilitado** (S-001). En dev, `CORS_ALLOWED_ORIGINS=http://localhost:8081` autoriza el origen de la web. Comportamiento:

- `GET /health` con `Origin` permitido → `200` + `Access-Control-Allow-Origin: <origin>` + `Vary: Origin`.
- Preflight `OPTIONS` desde origen permitido → `204` con `Access-Control-Allow-Methods: GET, POST, OPTIONS` y `Access-Control-Allow-Headers: Content-Type`.
- Origen no permitido → `GET` responde `200` **sin** `Access-Control-Allow-Origin` (el browser bloquea la lectura cross-origin); preflight → `403`.

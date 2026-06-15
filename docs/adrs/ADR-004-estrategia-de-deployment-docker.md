# ADR-004: Estrategia de deployment (monorepo + Docker dev/prod + ingress-network)

**Status:** Accepted
**Date:** 2026-06-12
**Deciders:** Darío (dueño del producto), Technical Leader
**Tags:** deployment, docker, monorepo, proxy, tls, cors

## Context

Hay que definir estructura de repo, empaquetado y despliegue (diferidos en el discovery).
Son dos servicios (API Go + frontend Flutter) de un producto personal, con un entorno
**local** para desarrollo/prueba manual y un entorno **productivo** detrás de un proxy con
TLS.

## Decision

- **Monorepo** con `services/atmosphere-api`, `services/atmosphere-app` y `docker/`.
- Compose con **patrón base + overrides** en `docker/`:
  - `docker-compose.yml`: **base común** (única fuente de verdad de lo compartido).
  - `docker-compose.dev.yml` (override): **build desde el path del proyecto**, servicios expuestos en **localhost** (también sirve para prueba manual).
  - `docker-compose.prod.yml` (override): **imágenes desde el registry oficial**, conectados a la red externa **`ingress-network`** (proxy + certificados TLS), sin puertos al host.
- Contenedores: `atmosphere-api` (binario Go) y `atmosphere-web` (build de Flutter web servido por nginx). Targets **desktop** = binarios nativos (sin Docker).
- Web y API son orígenes distintos → **CORS** habilitado.
- El proxy es **nginx-proxy + acme-companion**: enruta por `VIRTUAL_HOST`/`VIRTUAL_PORT` y emite TLS por `LETSENCRYPT_HOST`.

## Implementation Rules

- Estructura monorepo MUST ser: `services/atmosphere-api/`, `services/atmosphere-app/`, `docker/docker-compose.yml` (base), `docker/docker-compose.dev.yml` (override dev), `docker/docker-compose.prod.yml` (override prod).
- `docker-compose.yml` (base) MUST contener la definición común de los servicios (nombres, env vars comunes, healthcheck, alias de red) — única fuente de verdad de lo compartido. NO define `build`/`image`/`ports`/red de entorno (eso va en los overrides).
- El override **dev** MUST agregar `build:` desde el path del proyecto y exponer puertos en localhost (p. ej. API `8080`, web `8081`).
- El override **prod** MUST agregar `image:` desde el registry oficial (tags versionados), conectar los servicios a la red externa **`ingress-network`** y NO exponer `ports` al host.
- En prod, cada servicio expuesto MUST definir: `VIRTUAL_HOST` (dominio), `VIRTUAL_PORT` (puerto interno del contenedor) y `LETSENCRYPT_HOST` (= `VIRTUAL_HOST`).
- Los comandos MUST combinar base + override: dev → `docker compose -f docker/docker-compose.yml -f docker/docker-compose.dev.yml up`; prod → `docker compose -f docker/docker-compose.yml -f docker/docker-compose.prod.yml up -d`.
- **Paridad:** lo común MUST vivir una sola vez en el base (paridad estructural); cada override carga SOLO sus diferencias (`build` vs `image`, red, puertos). NO duplicar la config común en los overrides.
- `atmosphere-web` MUST ser un contenedor nginx que sirve el build de Flutter web; los targets desktop (Windows/Linux) MUST ser binarios nativos (`flutter build windows`/`linux`), NO contenerizados.
- CORS MUST estar habilitado en `atmosphere-api` con orígenes permitidos vía `CORS_ALLOWED_ORIGINS` por ambiente.
- Variables de entorno: `atmosphere-api` → `PORT`, `CORS_ALLOWED_ORIGINS`; `atmosphere-web` → `API_BASE_URL`; en prod además `VIRTUAL_HOST`, `VIRTUAL_PORT`, `LETSENCRYPT_HOST` por servicio + registry/tags.

## Consequences

### Positive
- Dev y prod con **paridad estructural**: lo común vive una sola vez en el base; lo que se prueba local es lo que corre en prod (salvo build/image, red y puertos).
- TLS y enrutamiento automáticos vía nginx-proxy + acme-companion (cero config manual de certificados).
- Monorepo simplifica cambios atómicos al contrato.

### Negative
- El patrón base+override requiere pasar dos `-f` en cada comando (menor).
- Depende de que `ingress-network` y el proxy existan en el servidor de producción.

### Risks
- **Riesgo:** drift entre dev y prod. **Mitigación:** la config común vive SOLO en el base (paridad estructural); los overrides solo llevan diferencias.
- **Riesgo:** `ingress-network` no creada en el host. **Mitigación:** documentar el prerequisito (red externa + proxy) en el README de `docker/`.

## Alternatives Considered

### Alternative 1: nginx propio sirviendo estático + reverse-proxy a la API (mismo origen)
**Pros:** sin CORS en producción.
**Cons:** no usa el proxy/ingress existente del servidor; el usuario prefiere contenedores separados detrás de `ingress-network`.
**Why rejected:** decisión del usuario (contenedores separados + CORS, detrás del proxy con `ingress-network`).

### Alternative 2: Cloud gestionado (PaaS)
**Pros:** menos administración.
**Cons:** costo/infra innecesarios para uso personal; el usuario ya tiene proxy + ingress propios.
**Why rejected:** se prioriza self-hosted con el proxy existente.

## References

- [docs/discovery/analisis-tecnico.md](../discovery/analisis-tecnico.md) (Arq-7; "Decisiones Operativas Fuera de Alcance" promovidas aquí)
- [docs/prd/architecture.md](../prd/architecture.md) (Estrategia de Deployment)

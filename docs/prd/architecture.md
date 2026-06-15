---
created: 2026-06-12
last_updated: 2026-06-12
status: "Draft"
---

# Arquitectura del Producto — Calculadora ISA (Atmósfera Estándar)

> Derivado del discovery: [análisis técnico](../discovery/analisis-tecnico.md)

## Servicios

| Servicio | Tecnología | Responsabilidades | Entidades que posee | Base de Datos | APIs Externas |
|---|---|---|---|---|---|
| **atmosphere-api** | Go 1.26.4 + stdlib `net/http` + `encoding/json` + `math`/`float64` | Motor ISA: cálculo analítico + interpolación + comparación + conversión de unidades; validación de entrada. Stateless. | CalculationRequest, AtmosphericLayer, PhysicalConstants, AtmosphericResult, TableNode, ISATable, Comparison, MagnitudeDifference | — | — |
| **atmosphere-app** | Flutter (Dart) + Riverpod + `http` + `intl` | Frontend (Windows/Linux/Web): entrada, selección de unidad de altitud, presentación SI+imperial, sección de fórmulas de conversión. No calcula. | — | — | — |

## Bases de Datos

Ninguna. `atmosphere-api` es **stateless** (no persiste consultas ni resultados; sin historial en v1).

## Interacciones entre Servicios

### Comunicaciones Internas

- **atmosphere-app → atmosphere-api** (HTTP/REST JSON, **síncrono**)
  - Única llamada por cálculo: `POST /v1/calculate` (+ `GET /health`). La API devuelve ambos métodos + comparación + metadata de la tabla en una sola respuesta.
  - **Orígenes distintos** (web y API son contenedores separados) → **CORS** habilitado en la API.

### Integraciones Externas

Ninguna. (En producción, el **proxy** de `ingress-network` hace de entrada y termina TLS, pero es infraestructura, no una API externa de negocio.)

## Requerimientos Técnicos

### Infraestructura

**Deployment:**
- **Monorepo**; servicios en `services/atmosphere-api` y `services/atmosphere-app`. Compose en la carpeta `docker/` (ver Estrategia de Deployment).

**Ambientes:**
- **dev (local):** `docker/docker-compose.dev.yml` — **build desde el path del proyecto**, servicios expuestos en **localhost**.
- **production:** `docker/docker-compose.prod.yml` — **imágenes desde el registry oficial**, conectados a la red externa **`ingress-network`** (proxy + certificados TLS); sin exponer puertos al host.

**CI/CD:** fuera de alcance de esta iteración (se define más adelante).

### Concerns Transversales

**Logging:**
- Logs básicos a stdout en `atmosphere-api` (formato y nivel a afinar; observabilidad detallada diferida).

**Monitoring:**
- Health check `GET /health` en `atmosphere-api`.

**Error Tracking:**
- Fuera de alcance de esta iteración.

### Seguridad

**Autenticación:** ninguna en v1 (herramienta personal, sin datos sensibles).

**CORS:** habilitado en `atmosphere-api`, con **orígenes permitidos configurables por ambiente** (dev: `http://localhost:<puerto-web>`; prod: dominio del frontend).

**TLS:** en producción lo termina el **proxy** de `ingress-network` (los certificados viven ahí), no la API.

**Secrets / Configuración:** vía **variables de entorno** por ambiente (sin secretos sensibles en v1; ver Deployment).

### Performance

**Cálculo:** en memoria, stateless; sin cache (el cálculo y la generación de tabla son instantáneos). Cómputo en **float64** con las constantes exactas ISA 1976 (R, ρ₀, a₀, μ₀ y el exponente derivados en runtime; sin redondeo interno).

**Rate limiting:** no aplica en v1 (sin auth, uso personal).

**CDN:** no aplica.

## Estrategia de Deployment

**Estructura (monorepo):**

```
/ (raíz)
├── docs/                          # documentación (ya existe)
├── services/
│   ├── atmosphere-api/            # Go (Dockerfile)
│   └── atmosphere-app/            # Flutter (Dockerfile web → nginx)
└── docker/
    ├── docker-compose.yml         # base (común)
    ├── docker-compose.dev.yml     # override local
    └── docker-compose.prod.yml    # override producción
```

**Contenedores:**
- `atmosphere-api` — binario Go.
- `atmosphere-web` — build de Flutter **web** servido por nginx (artefacto del target web de `atmosphere-app`).
- Targets **desktop** (Windows/Linux) = **binarios nativos** (`flutter build windows`/`linux`), **no** se contenerizan; apuntan a la API por URL configurable.

**Compose (patrón base + overrides):**

- **`docker/docker-compose.yml` (base):** definición común de `atmosphere-api` y `atmosphere-web` — nombres de servicios, env vars comunes, healthcheck, alias de red. Es la **única fuente de verdad** de lo compartido (no define `build`/`image`/`ports`/red de entorno).
- **`docker/docker-compose.dev.yml` (override local):** agrega `build:` desde el path del proyecto (`../services/atmosphere-api`, `../services/atmosphere-app`); servicios expuestos en **localhost** (p. ej. API `:8080`, web `:8081`); CORS permite el origen local.
- **`docker/docker-compose.prod.yml` (override producción):** agrega `image:` desde el **registry oficial** (tags versionados); servicios en la red externa **`ingress-network`** (proxy + certificados TLS), **sin** `ports` al host; vars del proxy por servicio (`VIRTUAL_HOST`, `VIRTUAL_PORT`, `LETSENCRYPT_HOST`); CORS permite el dominio del frontend. El proxy (**nginx-proxy + acme-companion**) enruta por `VIRTUAL_HOST`/`VIRTUAL_PORT` y emite/renueva TLS por `LETSENCRYPT_HOST`.

**Se levantan combinando base + override:**
- dev: `docker compose -f docker/docker-compose.yml -f docker/docker-compose.dev.yml up`
- prod: `docker compose -f docker/docker-compose.yml -f docker/docker-compose.prod.yml up -d`

**Paridad:** lo común vive **una sola vez** en `docker-compose.yml` (paridad **estructural**: no puede divergir). Cada override carga **solo sus diferencias** — `build` (dev) vs `image` (prod), red (`localhost`/default vs `ingress-network`) y exposición de puertos (dev expone, prod no).

**Variables de entorno** — los **nombres** comunes se declaran en el base; los **valores** por ambiente van en cada override (las que apliquen):
- `atmosphere-api`: `PORT`, `CORS_ALLOWED_ORIGINS`.
- `atmosphere-web` (build): `API_BASE_URL` (dev: `http://localhost:8080`; prod: dominio de la API).
- **prod — variables del proxy** (nginx-proxy + acme-companion en `ingress-network`), por cada servicio expuesto:
  - `atmosphere-web`: `VIRTUAL_HOST` (dominio del frontend), `VIRTUAL_PORT` (puerto interno de nginx, p. ej. `80`), `LETSENCRYPT_HOST` (= `VIRTUAL_HOST`).
  - `atmosphere-api`: `VIRTUAL_HOST` (dominio de la API), `VIRTUAL_PORT` (p. ej. `8080`), `LETSENCRYPT_HOST` (= `VIRTUAL_HOST`).
- `prod`: además, registry/tags de imagen.

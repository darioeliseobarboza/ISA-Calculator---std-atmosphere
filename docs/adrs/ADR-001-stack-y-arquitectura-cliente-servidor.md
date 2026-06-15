# ADR-001: Stack y arquitectura cliente-servidor

**Status:** Accepted
**Date:** 2026-06-12
**Deciders:** Darío (dueño del producto), Technical Leader
**Tags:** stack, arquitectura, go, flutter, http

## Context

La Calculadora ISA es un producto **cliente-servidor**: el cálculo lo realiza una API
(backend) y un frontend solo presenta los resultados obtenidos por petición. El frontend
debe distribuirse para **Windows, Linux y Web**. Es una herramienta personal (un solo
desarrollador), sin cuentas ni datos sensibles. Las decisiones de stack ya fueron tomadas
en el discovery (preferencia explícita del usuario: API en Go, frontend en Flutter).

## Decision

- **atmosphere-api**: Go 1.26.4 con router del estándar `net/http`, `encoding/json` y `math`/`float64`. Servicio HTTP stateless.
- **atmosphere-app**: Flutter (Dart) con Riverpod (estado), `http` (cliente) e `intl` (formato/i18n). Targets `windows`, `linux`, `web`.
- **Comunicación**: HTTP/REST JSON, **síncrona** request/response. Un único `POST /v1/calculate` (+ `GET /health`). Sin bus ni colas.
- **Sin autenticación** en v1; CORS habilitado (web y API son orígenes distintos).

## Implementation Rules

- La API MUST usar **Go 1.26.4** y router **stdlib `net/http`** (ServeMux con patrones método+path). NO usar Gin, Echo, Fiber ni chi.
- Serialización MUST ser `encoding/json` (stdlib).
- Las rutas MUST llevar prefijo de versión **`/v1/`**.
- El frontend MUST ser Flutter (Dart) con **Riverpod** (estado), **`http`** (cliente) e **`intl`** (formato). El frontend NO calcula: solo presenta lo que devuelve la API.
- La comunicación MUST ser HTTP/REST JSON síncrona; no hay procesos async ni mensajería.
- Respuestas HTTP: `200` éxito; `400` validación con cuerpo `{ "error": { "code": string, "message": string } }`, con `code` ∈ `outOfRange` | `invalidInput` | `invalidStep`.
- Los identificadores JSON MUST ir en **inglés** (tipos `PascalCase`, campos/enums `camelCase`), idénticos a las entidades del dominio (`geopotentialAltitude`, `dynamicViscosity`, `relativeErrorPct`, …).

## Consequences

### Positive
- Binario único Go, liviano e ideal para un servicio stateless; dependencias mínimas (solo stdlib).
- Flutter cubre los tres targets desde una sola base de código.
- Comunicación simple (un endpoint), fácil de testear con `curl`/Postman.

### Negative
- Dos lenguajes/toolchains (Go + Dart) en el monorepo.
- El contrato JSON se mantiene a mano en ambos lados (no hay tipos compartidos).

### Risks
- **Riesgo:** divergencia del contrato API↔frontend. **Mitigación:** monorepo (cambios atómicos) + contrato documentado en la spec OpenAPI como fuente de verdad.

## Alternatives Considered

### Alternative 1: Framework web en Go (Gin/Echo/Fiber)
**Pros:** ergonomía, middleware listo.
**Cons:** dependencia mayor, innecesaria para 1–2 endpoints.
**Why rejected:** el stdlib `net/http` (Go ≥1.22) alcanza y mantiene cero dependencias.

### Alternative 2: Otro frontend (React web + Tauri/Electron desktop)
**Pros:** ecosistema web amplio.
**Cons:** múltiples toolchains para cubrir desktop+web; el usuario prefiere Flutter.
**Why rejected:** Flutter cubre Win/Linux/Web con una sola base; decisión del usuario.

## References

- [docs/discovery/analisis-tecnico.md](../discovery/analisis-tecnico.md) (Arq-1, Arq-2, Arq-3, Arq-4, Arq-6)

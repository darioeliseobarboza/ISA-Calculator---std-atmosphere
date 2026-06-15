# Conventions Catalog

Development conventions by language. Each convention defines how to solve one concrete concern (logging, validation, auth, etc.): which package to use, how to configure it, how to use it, and which rules to follow.

## How they are used

1. A service declares which conventions it uses in `docs/architectures/{service}/manifest.yaml`.
2. Skills (`service-planify-story`, `service-implement-story`) read the declared conventions from this catalog.
3. The `_base.md` of each language is **always included** when a service uses that language.
4. Conventions with `required_by` are auto-included when any of the listed conventions is active.

## Frontmatter of each convention

```yaml
---
id: {convention-id}                                 # internal id, kebab-case
display_name: {short human-readable name}           # shown to the user in skills (Spanish)
language: {language}
description: {one-line description}                 # used by skills for tooltips
applies_to: [api, worker, cli, library, frontend]   # service types where it applies
required_by: []                                     # auto-included if any of these is active
package: {recommended-package}                      # recommended package (may change)
---
```

**`display_name`** is what skills show to end users. It is in Spanish (consumer language) and includes the package between parens when relevant (e.g., "Logging estructurado (Pino)"). The `id` is for internal cross-references only.

## When to add or modify

- **New convention**: when a recurring concern appears that is not yet covered.
- **Modify existing convention**: when the recommended package changes, a practice improves, or a better pattern is detected.
- **Changes propagate** to all services via `update-tools`.

---

## Node

Conventions for services written in Node.js (TypeScript).

| id | Display name | Applies to | Description |
|---|---|---|---|
| [_base](./node/_base.md) | Convenciones generales | always | Naming, dates, minimal structure, strict TypeScript |
| [auth-jwt](./node/auth-jwt.md) | Autenticación JWT (jose) | api | JWT creation and verification, access + refresh token pattern |
| [cache](./node/cache.md) | Caché (ioredis) | api, worker | Redis caching with cache-aside pattern |
| [ci-gitlab](./node/ci-gitlab.md) | CI/CD (GitLab) | api, worker, cli | GitLab CI pipeline — build, test, release with Docker |
| [dockerfile](./node/dockerfile.md) | Dockerfile (Node) | api, worker, cli | Multi-stage Dockerfile — test, builder, production stages |
| [env-config](./node/env-config.md) | Configuración de entorno (@t3-oss/env-core) | api, worker, cli | Type-safe env variable validation at startup |
| [error-handling](./node/error-handling.md) | Manejo de errores | api, worker | Error modeling and propagation, canonical error shape |
| [http-server](./node/http-server.md) | Servidor HTTP (Fastify) | api | HTTP server, routing, middlewares |
| [logging](./node/logging.md) | Logging estructurado (Pino) | api, worker, cli | Structured logging |
| [observability](./node/observability.md) | Observabilidad (OpenTelemetry) | api, worker | Distributed tracing and log correlation |
| [orm](./node/orm.md) | ORM / Acceso a base de datos (Prisma) | api, worker, cli | Database access layer with repository pattern |
| [queue](./node/queue.md) | Cola de trabajos (BullMQ) | api, worker | Background job queues backed by Redis |
| [security](./node/security.md) | Seguridad HTTP (helmet + rate-limit) | api | HTTP security headers, rate limiting, CORS |
| [testing](./node/testing.md) | Testing (Vitest + Testcontainers, contenedor compartido) | api, worker, cli, library | Unit + integration; one shared container per suite (globalSetup), sequential, seed-state reset |
| [validation](./node/validation.md) | Validacion de inputs (Zod) | api, worker | Input validation (body, params, query) |

> More conventions to add: `http-client`.

## Next.js

Conventions for web applications with Next.js (App Router). Aligned with the official Next.js 15+ recommendations.

| id | Display name | Applies to | Description |
|---|---|---|---|
| [_base](./nextjs/_base.md) | Convenciones generales | always | App Router, TypeScript strict, project structure, Server Components by default |
| [api-routes](./nextjs/api-routes.md) | API Routes (Route Handlers) | frontend | Route Handlers for external clients, when to use vs Server Actions |
| [auth](./nextjs/auth.md) | Autenticación (Auth.js) | frontend | Auth.js v5, DAL pattern, middleware protection, OIDC + Credentials |
| [ci-gitlab](./nextjs/ci-gitlab.md) | CI/CD (GitLab) | frontend | GitLab CI pipeline — build, lint, typecheck, test, release |
| [data-fetching](./nextjs/data-fetching.md) | Obtencion de datos (Server Components + fetch) | frontend | Native `fetch` in Server Components, explicit caching, Suspense streaming |
| [dockerfile](./nextjs/dockerfile.md) | Dockerfile (Next.js) | frontend | Multi-stage Dockerfile with standalone output |
| [error-handling](./nextjs/error-handling.md) | Manejo de errores | frontend | `error.tsx` boundaries, expected vs unexpected errors, contract with backend |
| [forms](./nextjs/forms.md) | Formularios (Server Actions + useActionState + Zod) | frontend | Server Actions + `useActionState` + Zod, no react-hook-form |
| [mutations](./nextjs/mutations.md) | Mutaciones (Server Actions) | frontend | Server Actions as the default write pattern, `revalidatePath`/`revalidateTag` |
| [state-management](./nextjs/state-management.md) | Estado client-side (Zustand + nuqs) | frontend | Decision tree: URL state (nuqs), global (Zustand), local (useState) |
| [styling](./nextjs/styling.md) | Estilado (Tailwind CSS) | frontend | Tailwind + `cn()` helper, design system tokens, `cva` for variants |
| [testing-e2e](./nextjs/testing-e2e.md) | Testing E2E (Playwright) | frontend | Critical flows, auth with storageState, CI configuration |
| [testing-unit](./nextjs/testing-unit.md) | Testing unitario (Vitest + Testing Library) | frontend | Client Components, hooks, Server Actions as functions |

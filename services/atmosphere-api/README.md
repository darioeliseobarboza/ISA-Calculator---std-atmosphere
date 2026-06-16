# atmosphere-api

HTTP backend for the ISA (International Standard Atmosphere) calculator. Go
service built on the standard library `net/http` — no web framework (ADR-001).
Stateless: no database, no session, no disk persistence (ADR-003).

This skeleton (story S-001) exposes a single liveness endpoint and the HTTP
plumbing (config, structured logging, middleware chain). The calculation
endpoint (`POST /v1/calculate`) arrives with FG-2/3.

## Endpoints

### `GET /health`

Liveness check. No auth, no `/v1/` prefix (it is not a domain resource).

```
$ curl -i localhost:8080/health
HTTP/1.1 200 OK
Content-Type: application/json

{"status":"ok","timestamp":"2026-06-12T16:00:00Z"}
```

- `status`: always `"ok"`.
- `timestamp`: RFC3339, UTC.

## Configuration

All configuration comes from environment variables (12-factor). See
[`.env.dist`](./.env.dist) for a template; copy it to `.env` for local dev
(`.env` is git-ignored).

| Variable | Default | Required | Description |
|----------|---------|----------|-------------|
| `ENV` | `development` | no | Runtime environment: `development` \| `production`. |
| `HTTP_ADDR` | `:8080` | no | Address the HTTP server listens on. |
| `LOG_DIR` | `./logs` | no | Directory for structured (slogx) log files. |
| `LOG_DEBUG` | `false` | no | Enable debug-level logging (`true` \| `false`). |
| `CORS_ALLOWED_ORIGINS` | _(empty)_ | **yes in production** | Comma-separated list of allowed CORS origins (no wildcard). |

The service is **fail-fast**: in `production`, an empty `CORS_ALLOWED_ORIGINS`
aborts startup with a non-zero exit code.

## Run locally

```bash
# from services/atmosphere-api
cp .env.dist .env            # optional; defaults work for dev
go run ./cmd/atmosphere-api
# -> server started addr=:8080 env=development
```

With explicit env vars:

```bash
ENV=development \
HTTP_ADDR=:8080 \
CORS_ALLOWED_ORIGINS=http://localhost:8081 \
go run ./cmd/atmosphere-api
```

The process shuts down gracefully on `SIGINT` / `SIGTERM`.

## Test

```bash
go test ./...            # full suite (includes in-process HTTP integration)
go test -short ./...     # unit only (skips integration)
go test -race ./...      # race detector (used in CI)
```

## Build the Docker image

Multi-stage build: a pinned `golang:1.26.4-alpine3.24` builder produces a
static, stripped binary that ships in a non-root `distroless/static` runtime.

```bash
# from services/atmosphere-api
docker build -t atmosphere-api:dev .

docker run --rm -p 8080:8080 \
  -e CORS_ALLOWED_ORIGINS=http://localhost:8081 \
  atmosphere-api:dev

curl -i localhost:8080/health
```

> Compose orchestration (dev/prod overrides, nginx-proxy) lives in `docker/`
> and is delivered by story S-003 — this service only ships its `Dockerfile`.

## Layout

```
cmd/atmosphere-api/   entry point: config load, wiring, run, signal handling
internal/http/        server, route mounting, hand-written middleware chain
internal/shared/      cross-cutting infra (logging)
```

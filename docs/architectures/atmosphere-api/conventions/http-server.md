---
id: http-server
display_name: Servidor HTTP (stdlib net/http)
language: golang
description: HTTP server, routing, middleware for REST APIs using the standard library
applies_to: [api]
required_by: []
package: net/http (stdlib)
---

# HTTP Server (Go, net/http)

HTTP server for services exposing a REST API, built on the standard library
[`net/http`](https://pkg.go.dev/net/http) with the Go 1.22+ `ServeMux` (method+path
routing). Service-local replacement of the catalog default (chi): atmosphere-api keeps
zero web-framework dependencies (ADR-001), so routing uses `ServeMux` and middleware is
composed by hand.

## When to use

- Services of type `api` (atmosphere-api exposes `POST /v1/calculate` and `GET /health`).
- Workers that only consume messages do not use this (they may expose a minimal `/health`).

## Package

```
net/http        # stdlib: server, ServeMux (method+path routing), handlers
encoding/json   # stdlib: request/response (de)serialization
```

No third-party router or middleware library.

## Structure

```
internal/
├── http/
│   ├── server.go              # builds the *http.Server + ServeMux + middleware chain
│   ├── middleware.go          # requestID, recoverer, cors (hand-written)
│   └── routes.go              # mounts each module's routes onto the mux
└── {module}/
    ├── handler.go             # HTTP handlers (parse, call service, write response)
    ├── service.go             # business logic (the ISA engine)
    └── {module}.go            # domain types
```

Each module exposes its routes; `internal/http/routes.go` mounts them onto the shared `*http.ServeMux`.

## Base configuration

```go
// internal/http/server.go
package http

import (
	"net/http"
	"time"
)

// NewServer builds the *http.Server: a ServeMux with /health, the mounted module
// routes, and the hand-written middleware chain.
func NewServer(addr string, allowedOrigins []string, mount func(mux *http.ServeMux)) *http.Server {
	mux := http.NewServeMux()

	mux.HandleFunc("GET /health", func(w http.ResponseWriter, _ *http.Request) {
		writeJSON(w, http.StatusOK, map[string]any{
			"status":    "ok",
			"timestamp": time.Now().UTC().Format(time.RFC3339),
		})
	})

	mount(mux)

	// Middleware composed by hand (net/http has none): outermost first.
	handler := chain(mux,
		requestID,                // inject requestId + child logger into ctx
		recoverer,                // panic -> 500 (canonical error shape)
		cors(allowedOrigins),     // CORS for the Web target (configurable origins)
	)

	return &http.Server{
		Addr:              addr,
		Handler:           handler,
		ReadHeaderTimeout: 5 * time.Second,
		ReadTimeout:       15 * time.Second,
		WriteTimeout:      30 * time.Second,
		IdleTimeout:       60 * time.Second,
	}
}
```

Middleware is plain `func(http.Handler) http.Handler`, applied with a small `chain` helper:

```go
// internal/http/middleware.go
type middleware func(http.Handler) http.Handler

func chain(h http.Handler, mws ...middleware) http.Handler {
	for i := len(mws) - 1; i >= 0; i-- {
		h = mws[i](h)
	}
	return h
}
```

## Routing

One `Routes` method per module, mounted centrally. `ServeMux` patterns carry the method and path params (Go 1.22+):

```go
// internal/calculation/handler.go
func (h *Handler) Routes(mux *http.ServeMux) {
	mux.HandleFunc("POST /v1/calculate", h.calculate)
}

// internal/http/routes.go
func Mount(calc *calculation.Handler) func(*http.ServeMux) {
	return func(mux *http.ServeMux) {
		calc.Routes(mux)
	}
}
```

Path params are read with `r.PathValue("id")` when a route declares them (e.g. `GET /v1/things/{id}`).

## Handlers

A handler only **decodes input, calls the service, writes the response**. No business logic, no direct DB access (atmosphere-api has no DB; the "service" is the ISA engine).

```go
// internal/calculation/handler.go
func (h *Handler) calculate(w http.ResponseWriter, r *http.Request) {
	var in CalculationRequest
	if err := json.NewDecoder(r.Body).Decode(&in); err != nil {
		writeError(w, r, errs.NewValidation("invalid body", nil))
		return
	}

	res, err := h.svc.Calculate(r.Context(), in)
	if err != nil {
		writeError(w, r, err) // mapped per error-handling convention
		return
	}

	writeJSON(w, http.StatusOK, res)
}
```

`writeError` translates a domain error to the canonical shape and status (see `error-handling`); `writeJSON` is a small shared helper that sets `Content-Type: application/json` and encodes the value.

## REST conventions

| Operation | Method | Path | Success |
|---|---|---|---|
| List | GET | `/things` | 200 |
| Get | GET | `/things/{id}` | 200 |
| Create | POST | `/things` | 201 |
| Partial update | PATCH | `/things/{id}` | 200 |
| Replace | PUT | `/things/{id}` | 200 |
| Delete | DELETE | `/things/{id}` | 204 |

- Resources in **plural, kebab-case**. No verbs in paths; exceptional actions as sub-resources (`POST /things/{id}/cancel`). `POST /v1/calculate` is the calc action endpoint of this service.
- Path versioning `/v1/...`.
- Query params in `camelCase`: `?pageSize=20&sortBy=createdAt`.

## Request context

A `requestID` middleware injects a request-scoped child logger carrying `requestId` into the context. Handlers and services log through that context logger (see `logging`), never a global logger, so every line keeps the `requestId`.

## Rules

- One route maps to one handler method. No nested logic in the router.
- Handlers do not access the DB or external APIs directly; they call the module's service.
- Every endpoint that receives external input **validates it with the standard library** (parse + range checks; e.g. altitude within `0–36089 ft`). No validation library is used in this service.
- Status codes per the table. Never `200` with an `{"error": ...}` body — errors carry their own status.
- The resource is returned directly (no `{"data": ...}` envelope). Errors use the `{"error": ...}` envelope from `error-handling`.
- Always set server timeouts (`ReadHeaderTimeout` at minimum). Never run an unbounded handler.
- `GET /health` is unauthenticated and cheap (liveness); returns `{"status":"ok","timestamp":...}`.
- Middleware (requestID, recoverer, CORS) is **hand-written** as `func(http.Handler) http.Handler`; CORS allowed origins come from config (env) per ADR-001/ADR-004.

## Framework variants

This service uses the **standard library `net/http` + `ServeMux`** variant on purpose (ADR-001: zero web-framework dependency). Heavier routers/frameworks (chi, Echo, Gin, Fiber) are NOT used here. The cost is writing middleware by hand; the rules above (routing, status, validation, error shape, timeouts) still apply.

## Integration with other conventions

- **validation**: N/A — inputs are validated with the standard library (no validator package in this service), but the "validate every external input" rule still holds.
- **error-handling**: `writeError` maps domain errors to the canonical `{"error":{...}}` response and status.
- **logging**: the `requestID` middleware creates the request-scoped child logger (via `slogx`) used by handlers.
- **config**: server `addr` and CORS allowed origins are read from configuration (env) at startup.

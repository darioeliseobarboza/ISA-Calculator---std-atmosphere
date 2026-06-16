# Reusable Code - Middlewares - atmosphere-api

## Overview

Hand-written HTTP middlewares and their composer. The standard library
`net/http` ships no middleware, so behavior is composed via `Chain`. All live
in `internal/http/middleware.go`.

## Chain

**Location:** `internal/http/middleware.go`
**Description:** Composes a list of middlewares around a handler, applying the outermost (first) middleware first.

**Signature:**
```go
func Chain(h http.Handler, mws ...Middleware) http.Handler
```

**Usage:**
```go
handler := Chain(mux, RequestID, Recoverer, CORS(allowedOrigins))
```

---

## RequestID

**Location:** `internal/http/middleware.go`
**Description:** Injects a request correlation id into the request context under a private key. Honors an incoming `X-Request-Id` header; otherwise generates a random 128-bit hex id. Retrieve it for logging with `RequestArgs`.

**Signature:**
```go
func RequestID(next http.Handler) http.Handler
```

**Usage:**
```go
handler := Chain(mux, RequestID)
// inside a downstream handler:
logger.Info("handled", RequestArgs(r.Context())...)
```

---

## Recoverer

**Location:** `internal/http/middleware.go`
**Description:** Recovers from a panic in any downstream handler and responds `500` with the canonical error envelope `{ "error": { "code": "INTERNAL_ERROR", "message": ... } }`. The process keeps serving subsequent requests.

**Signature:**
```go
func Recoverer(next http.Handler) http.Handler
```

**Usage:**
```go
handler := Chain(mux, Recoverer)
```

---

## CORS

**Location:** `internal/http/middleware.go`
**Description:** Returns a middleware that authorizes cross-origin requests whose `Origin` is in `allowedOrigins`. Allowed origins get `Access-Control-Allow-Origin/-Methods/-Headers` (+ `Vary: Origin`); an allowed preflight (`OPTIONS` + `Access-Control-Request-Method`) short-circuits with `204`. Disallowed origins are still served but receive no allow header (the browser blocks the read).

**Signature:**
```go
func CORS(allowedOrigins []string) Middleware
```

**Usage:**
```go
handler := Chain(mux, CORS([]string{"https://app.example.com"}))
```

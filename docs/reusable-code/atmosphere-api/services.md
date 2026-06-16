# Reusable Code - Services - atmosphere-api

## Overview

Service-construction helpers: the HTTP server builder and the logger
constructor. Both are wired manually in `cmd/atmosphere-api/main.go`.

## NewServer

**Location:** `internal/http/server.go`
**Description:** Builds the `*http.Server` for the service. Registers the liveness route `GET /health`, exposes a `mount` seam for domain routes, wraps the mux in the middleware chain (`RequestID` → `Recoverer` → `CORS`) and sets bounded server timeouts.

**Signature:**
```go
func NewServer(addr string, allowedOrigins []string, mount func(mux *http.ServeMux)) *http.Server
```

**Usage:**
```go
srv := apihttp.NewServer(cfg.HTTPAddr, cfg.CORSAllowedOrigins, apihttp.Mount)
_ = srv.ListenAndServe()
```

---

## logging.New

**Location:** `internal/shared/logging/logging.go`
**Description:** Constructs the single per-service structured logger over slogx. info/warn/error are always enabled; debug is gated by the flag. Caller owns the logger and must `Close` it (typically deferred in `main`).

**Signature:**
```go
func New(dir string, debug bool) (*slogx.Logger, error)
```

**Usage:**
```go
logger, err := logging.New(cfg.LogDir, cfg.LogDebug)
if err != nil { /* ... */ }
defer func() { _ = logger.Close() }()
```

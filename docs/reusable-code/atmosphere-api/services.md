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
calcHandler := calculation.NewHandler(calculation.NewService())
srv := apihttp.NewServer(cfg.HTTPAddr, cfg.CORSAllowedOrigins, apihttp.Mount(calcHandler))
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

---

## calculation.Service / NewService

**Location:** `internal/calculation/service.go`
**Description:** Application layer of the ISA calculation (story S-004). `Calculate` applies the `altitudeUnit` default (`ft`), normalizes the altitude to feet, validates the `0–36089 ft` range (authoritative; returns `*errs.Error` `outOfRange`/`invalidInput`), runs the analytical engine and assembles each absolute magnitude as `{si, imperial}` plus the relatives and the `{m, ft}` echo. Stateless and pure (ADR-003).

**Signature:**
```go
func NewService() *Service
func (s *Service) Calculate(ctx context.Context, in CalculationRequest) (CalculationResponse, error)
```

**Usage:**
```go
svc := calculation.NewService()
res, err := svc.Calculate(ctx, calculation.CalculationRequest{
    GeopotentialAltitude: &alt, AltitudeUnit: "ft",
})
```

---

## calculation.Handler / NewHandler

**Location:** `internal/calculation/handler.go`
**Description:** HTTP transport for the calculation module. Decodes the body (malformed/non-numeric → `invalidInput`), delegates to the `Service`, and writes the canonical response/error via `respond`. `Routes(mux)` registers `POST /v1/calculate`; mounted through `apihttp.Mount`.

**Signature:**
```go
func NewHandler(svc *Service) *Handler
func (h *Handler) Routes(mux *http.ServeMux)
```

**Usage:**
```go
h := calculation.NewHandler(calculation.NewService())
srv := apihttp.NewServer(addr, origins, apihttp.Mount(h))
```

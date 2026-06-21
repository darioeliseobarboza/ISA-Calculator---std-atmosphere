# Reusable Code - Types/Interfaces - atmosphere-api

## Overview

Commonly used types of the service skeleton.

## Config

**Location:** `cmd/atmosphere-api/config.go`
**Description:** Typed runtime configuration. The single source of configuration — nothing else in the service reads the environment directly. Built by `loadConfig` (fail-fast in production).

**Definition:**
```go
type Config struct {
    Env                string   // "development" | "production"
    HTTPAddr           string   // e.g. ":8080"
    LogDir             string   // structured-log directory
    LogDebug           bool     // enable debug level
    CORSAllowedOrigins []string // CORS allow-list
}
```

**Usage:**
```go
cfg, err := loadConfig()
if err != nil { /* fail fast */ }
srv := apihttp.NewServer(cfg.HTTPAddr, cfg.CORSAllowedOrigins, apihttp.Mount)
```

---

## Middleware

**Location:** `internal/http/middleware.go`
**Description:** Function type for an HTTP middleware; the unit composed by `Chain`.

**Definition:**
```go
type Middleware func(http.Handler) http.Handler
```

**Usage:**
```go
var mw Middleware = CORS([]string{"https://app.example.com"})
handler := Chain(mux, mw)
```

---

## errs.Error

**Location:** `internal/shared/errs/errs.go`
**Description:** Typed domain error (story S-004). Carries the public `Code` (camelCase per ADR-001: `outOfRange`, `invalidInput`; `invalidStep` reserved for FG-3), a `Message`, and an optional wrapped cause (`Wrap` / `Unwrap`). `Status()` maps the code to its HTTP status (the two FG-2 codes → 400). The boundary uses `errors.As` to recover it from a wrapped chain.

**Definition:**
```go
type Error struct {
    Code    string // public contract code (camelCase)
    Message string
    // cause error (unexported; via Wrap/Unwrap)
}
func NewOutOfRange(msg string) *Error
func NewInvalidInput(msg string) *Error
func (e *Error) Wrap(cause error) *Error
func (e *Error) Status() int
```

**Usage:**
```go
return errs.NewOutOfRange("geopotentialAltitude out of range (0–36089 ft)")
// at the boundary:
respond.ErrorFrom(w, err) // reads Code + Status()
```

---

## calculation DTOs

**Location:** `internal/calculation/dto.go`
**Description:** Request/response shapes for `POST /v1/calculate` (story S-004), JSON identifiers in English camelCase (ADR-001). `MagnitudeValue {si, imperial}` is an absolute magnitude in both unit systems; `AltitudeValue {m, ft}` echoes the input altitude; `AtmosphericResult` groups the six absolutes plus the five relative ratios and `method`. FG-2 omits `input.tableStep`, `results.interpolation`, `comparison`, `table` (additive evolution to FG-3 without breaking change).

**Definition:**
```go
type MagnitudeValue struct { SI, Imperial float64 } // json: si, imperial
type AltitudeValue  struct { M, Ft float64 }        // json: m, ft
type CalculationRequest struct {
    GeopotentialAltitude *float64 // pointer: nil distinguishes "missing" from 0
    AltitudeUnit         string   // "m" | "ft" (default "ft")
    TableStep            *float64 // accepted but ignored in FG-2
}
type AtmosphericResult struct {
    Method string
    Temperature, Pressure, Density, DynamicViscosity,
    KinematicViscosity, SpeedOfSound MagnitudeValue
    Theta, Delta, Sigma, SpeedOfSoundRatio, ViscosityRatio float64
}
type CalculationResponse struct { Input CalculationInput; Results CalculationResults }
```

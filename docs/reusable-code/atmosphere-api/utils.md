# Reusable Code - Utils/Helpers - atmosphere-api

## Overview

Small, generic helpers used across the HTTP layer and config loading.

## WriteJSON

**Location:** `internal/http/middleware.go`
**Description:** Serializes any value as a JSON response, setting `Content-Type: application/json` and the given status. The canonical way to write a response body in this service. Since S-004 it delegates to `respond.JSON` so the wire format is identical everywhere.

**Signature:**
```go
func WriteJSON(w http.ResponseWriter, status int, v any)
```

**Usage:**
```go
WriteJSON(w, http.StatusOK, map[string]any{"status": "ok"})
```

---

## WriteError

**Location:** `internal/http/middleware.go`
**Description:** Translates a domain error into the canonical `{ "error": { code, message } }` envelope at the HTTP boundary (story S-004). A `*errs.Error` (even wrapped) yields its public code and status; any other error becomes 500 `INTERNAL_ERROR` with a generic message. Delegates to `respond.ErrorFrom`. The request is accepted so callers have it in scope for correlated logging (log once, at the boundary).

**Signature:**
```go
func WriteError(r *http.Request, w http.ResponseWriter, err error)
```

**Usage:**
```go
if err != nil {
    apihttp.WriteError(r, w, err) // outOfRange/invalidInput -> 400; else 500
    return
}
```

---

## RequestArgs

**Location:** `internal/http/middleware.go`
**Description:** Extracts the request correlation id (set by `RequestID`) from a context and returns it as slog key-value args, ready to spread into a logger call. Returns nil when no id is present (slogx has no per-context child logger).

**Signature:**
```go
func RequestArgs(ctx context.Context) []any
```

**Usage:**
```go
logger.Info("request handled", RequestArgs(r.Context())...)
```

---

## splitCSV

**Location:** `cmd/atmosphere-api/config.go`
**Description:** Splits a comma-separated string into a slice, trimming surrounding whitespace from each element and dropping empty segments. Empty or whitespace-only input yields nil. Used to parse `CORS_ALLOWED_ORIGINS`.

**Signature:**
```go
func splitCSV(s string) []string
```

**Usage:**
```go
origins := splitCSV("https://a.com, https://b.com") // []string{"https://a.com", "https://b.com"}
```

---

## units conversions (package `internal/units`)

**Location:** `internal/units/units.go`
**Description:** Pure, stateless conversions (story S-004) isolating every factor in one place (ADR-002/ADR-005). Altitude m↔ft is exact (`1 ft = 0.3048 m`); each absolute magnitude has an SI→imperial converter. All compute in `float64` with no rounding (rounding is a presentation concern owned by the frontend).

**Signatures:**
```go
func FeetFromMeters(m float64) float64            // m -> ft
func MetersFromFeet(ft float64) float64           // ft -> m
func RankineFromKelvin(k float64) float64          // K -> °R  (×1.8)
func PSFFromPascal(pa float64) float64             // Pa -> lbf/ft²
func SlugPerFt3FromKgPerM3(kgPerM3 float64) float64 // kg/m³ -> slug/ft³
func SlugPerFtSecFromPascalSec(paSec float64) float64 // Pa·s -> slug/(ft·s)
func Ft2PerSecFromM2PerSec(m2PerSec float64) float64  // m²/s -> ft²/s
func FtPerSecFromMPerSec(mPerSec float64) float64     // m/s -> ft/s
```

**Usage:**
```go
ftAltitude := units.FeetFromMeters(5000)           // 16404.199...
imperialTemp := units.RankineFromKelvin(288.15)    // 518.67
```

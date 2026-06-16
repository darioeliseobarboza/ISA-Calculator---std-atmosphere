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

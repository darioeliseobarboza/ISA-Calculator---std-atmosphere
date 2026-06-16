# Reusable Code - Utils/Helpers - atmosphere-api

## Overview

Small, generic helpers used across the HTTP layer and config loading.

## WriteJSON

**Location:** `internal/http/middleware.go`
**Description:** Serializes any value as a JSON response, setting `Content-Type: application/json` and the given status. The canonical way to write a response body in this service.

**Signature:**
```go
func WriteJSON(w http.ResponseWriter, status int, v any)
```

**Usage:**
```go
WriteJSON(w, http.StatusOK, map[string]any{"status": "ok"})
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

# Reusable Code - Response Writers - atmosphere-api

## Overview

Package `internal/shared/respond` (story S-004) centralizes how the service
writes JSON responses and the canonical error envelope. It is a neutral package
so both the transport layer (`internal/http`) and the domain handlers
(`internal/calculation`) can use it without an import cycle — `internal/http`
mounts `calculation.Handler`, so the shared writers cannot live in
`internal/http`.

## respond.JSON

**Location:** `internal/shared/respond/respond.go`
**Description:** Serializes any value as JSON with the given status and the `application/json` Content-Type. The canonical success writer.

**Signature:**
```go
func JSON(w http.ResponseWriter, status int, v any)
```

**Usage:**
```go
respond.JSON(w, http.StatusOK, res)
```

---

## respond.Error

**Location:** `internal/shared/respond/respond.go`
**Description:** Emits the canonical `{ "error": { code, message } }` envelope with an explicit status and code. Use when the code/status are already known (e.g. the recoverer's fixed 500).

**Signature:**
```go
func Error(w http.ResponseWriter, status int, code, message string)
```

**Usage:**
```go
respond.Error(w, http.StatusInternalServerError, "INTERNAL_ERROR", "internal server error")
```

---

## respond.ErrorFrom

**Location:** `internal/shared/respond/respond.go`
**Description:** Translates any error into the canonical envelope at the boundary. A `*errs.Error` (possibly wrapped — recovered via `errors.As`) yields its public `Code` and `Status()`; any other error becomes 500 `INTERNAL_ERROR` with a generic message so internal details never leak. Logging of the cause is the caller's responsibility.

**Signature:**
```go
func ErrorFrom(w http.ResponseWriter, err error)
```

**Usage:**
```go
res, err := svc.Calculate(r.Context(), in)
if err != nil {
    respond.ErrorFrom(w, err) // outOfRange/invalidInput -> 400; else -> 500
    return
}
respond.JSON(w, http.StatusOK, res)
```

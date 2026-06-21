// Package respond centralizes how atmosphere-api writes JSON responses and the
// canonical error envelope to the wire.
//
// It lives under internal/shared so both the transport layer (internal/http)
// and the domain handlers (internal/calculation) can write responses without
// creating an import cycle: internal/http mounts calculation.Handler, so the
// shared writers cannot live in internal/http (calculation would then import
// http, and http imports calculation). Both import respond instead.
package respond

import (
	"encoding/json"
	"errors"
	"net/http"

	"github.com/darioeliseobarboza/atmosphere-api/internal/shared/errs"
)

// codeInternal is the public code for an unexpected (untyped) failure.
const codeInternal = "INTERNAL_ERROR"

// JSON serializes v as JSON with the given status and the application/json
// Content-Type. It is the canonical way to emit a success body.
func JSON(w http.ResponseWriter, status int, v any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(v)
}

// Error emits the canonical error envelope { "error": { code, message } } with
// the given status. Use it when the code/status are already known (e.g. the
// recoverer's fixed 500).
func Error(w http.ResponseWriter, status int, code, message string) {
	JSON(w, status, map[string]any{
		"error": map[string]any{
			"code":    code,
			"message": message,
		},
	})
}

// ErrorFrom translates an error into the canonical envelope at the boundary.
// A *errs.Error (possibly wrapped) yields its public Code and Status(); any
// other error becomes 500 INTERNAL_ERROR with a generic message so internal
// details never leak to the client.
//
// Logging of the underlying cause is the caller's responsibility — ErrorFrom
// only writes the wire response.
func ErrorFrom(w http.ResponseWriter, err error) {
	var de *errs.Error
	if errors.As(err, &de) {
		Error(w, de.Status(), de.Code, de.Message)
		return
	}
	Error(w, http.StatusInternalServerError, codeInternal, "internal server error")
}

// Package http hosts the HTTP transport layer for atmosphere-api: the server
// construction, route mounting and the hand-written middleware chain. The
// standard library net/http ships no middleware, so it is composed by hand
// here (see Chain).
package http

import (
	"context"
	"crypto/rand"
	"encoding/hex"
	"net/http"
	"slices"

	"github.com/darioeliseobarboza/atmosphere-api/internal/shared/respond"
)

// Middleware decorates an http.Handler with cross-cutting behavior.
type Middleware func(http.Handler) http.Handler

// Chain composes middlewares around h, applying the outermost one first: the
// first middleware in mws is the outermost wrapper and runs before the rest.
func Chain(h http.Handler, mws ...Middleware) http.Handler {
	for i := len(mws) - 1; i >= 0; i-- {
		h = mws[i](h)
	}
	return h
}

// ctxKey is a private context key type so callers cannot collide with it.
type ctxKey struct{ name string }

var reqIDKey = ctxKey{name: "requestId"}

// RequestID injects a request correlation id into the context. An incoming
// X-Request-Id header is honored; otherwise a fresh id is generated. The id is
// retrievable for logging via RequestArgs.
func RequestID(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		id := r.Header.Get("X-Request-Id")
		if id == "" {
			id = newRequestID()
		}
		ctx := context.WithValue(r.Context(), reqIDKey, id)
		next.ServeHTTP(w, r.WithContext(ctx))
	})
}

// RequestArgs returns the request correlation id as slog key-value args, ready
// to spread into a logger call. It returns nil when no id is present (slogx has
// no per-context child logger, so correlation is carried explicitly).
func RequestArgs(ctx context.Context) []any {
	id, ok := ctx.Value(reqIDKey).(string)
	if !ok || id == "" {
		return nil
	}
	return []any{"requestId", id}
}

// newRequestID returns a random 128-bit hex id.
func newRequestID() string {
	var b [16]byte
	// crypto/rand.Read never returns an error on supported platforms.
	_, _ = rand.Read(b[:])
	return hex.EncodeToString(b[:])
}

// Recoverer converts a panic in a downstream handler into a canonical 500 JSON
// error, keeping the server alive for subsequent requests.
func Recoverer(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		defer func() {
			if rec := recover(); rec != nil {
				respond.Error(w, http.StatusInternalServerError, "INTERNAL_ERROR", "internal server error")
			}
		}()
		next.ServeHTTP(w, r)
	})
}

// corsMethods and corsHeaders are the allowance advertised for cross-origin
// requests. The skeleton exposes GET/POST; POST is here so the future
// POST /v1/calculate works without re-touching CORS.
const (
	corsMethods = "GET, POST, OPTIONS"
	corsHeaders = "Content-Type"
)

// CORS returns a middleware that authorizes cross-origin requests whose Origin
// is in allowedOrigins. A preflight (OPTIONS with Access-Control-Request-Method)
// from an allowed origin short-circuits with 204. Requests from origins not in
// the list are still served but receive no Access-Control-Allow-Origin header,
// so the browser blocks the cross-origin read.
func CORS(allowedOrigins []string) Middleware {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			origin := r.Header.Get("Origin")
			allowed := origin != "" && slices.Contains(allowedOrigins, origin)

			if allowed {
				w.Header().Set("Access-Control-Allow-Origin", origin)
				w.Header().Set("Access-Control-Allow-Methods", corsMethods)
				w.Header().Set("Access-Control-Allow-Headers", corsHeaders)
				w.Header().Add("Vary", "Origin")
			}

			// Preflight: respond without invoking the downstream handler.
			if r.Method == http.MethodOptions && r.Header.Get("Access-Control-Request-Method") != "" {
				if allowed {
					w.WriteHeader(http.StatusNoContent)
				} else {
					w.WriteHeader(http.StatusForbidden)
				}
				return
			}

			next.ServeHTTP(w, r)
		})
	}
}

// WriteJSON serializes v as JSON with the given status and the
// application/json Content-Type. It delegates to the shared respond package so
// the wire format is identical everywhere.
func WriteJSON(w http.ResponseWriter, status int, v any) {
	respond.JSON(w, status, v)
}

// WriteError translates a domain error into the canonical envelope at the HTTP
// boundary: a *errs.Error (possibly wrapped) yields its public code and status;
// any other error becomes 500 INTERNAL_ERROR with a generic message. The
// request is accepted so callers have it in scope for correlated logging, which
// is the boundary's responsibility (log once, here).
func WriteError(_ *http.Request, w http.ResponseWriter, err error) {
	respond.ErrorFrom(w, err)
}

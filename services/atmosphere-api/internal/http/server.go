package http

import (
	"net/http"
	"time"
)

// NewServer builds the *http.Server for atmosphere-api. It registers the
// liveness route GET /health, lets the caller mount domain routes via mount
// (empty in the skeleton; calculation/units arrive in FG-2/3), and wraps the
// mux in the middleware chain (outermost first: RequestID -> Recoverer ->
// CORS). Server timeouts are always set to bound slow clients.
func NewServer(addr string, allowedOrigins []string, mount func(mux *http.ServeMux)) *http.Server {
	mux := http.NewServeMux()

	// GET /health is liveness (no /v1/ prefix, no auth): returns the canonical
	// health body. The Go 1.22+ method+path pattern makes other methods 405.
	mux.HandleFunc("GET /health", func(w http.ResponseWriter, _ *http.Request) {
		WriteJSON(w, http.StatusOK, map[string]any{
			"status":    "ok",
			"timestamp": time.Now().UTC().Format(time.RFC3339),
		})
	})

	mount(mux)

	handler := Chain(mux,
		RequestID,            // inject requestId into the context
		Recoverer,            // panic -> canonical 500
		CORS(allowedOrigins), // configurable cross-origin access
	)

	return &http.Server{
		Addr:              addr,
		Handler:           handler,
		ReadHeaderTimeout: 5 * time.Second,
		ReadTimeout:       15 * time.Second,
		WriteTimeout:      30 * time.Second,
		IdleTimeout:       60 * time.Second,
	}
}

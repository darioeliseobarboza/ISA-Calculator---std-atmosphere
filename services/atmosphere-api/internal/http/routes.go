package http

import "net/http"

// Mount registers the domain routes onto mux. It is the single seam where
// business modules (calculation, units — FG-2/3) plug their handlers, keeping
// NewServer free of domain wiring. In the skeleton it intentionally mounts
// nothing; only GET /health (registered in NewServer) is live.
func Mount(_ *http.ServeMux) {
	// No domain routes yet. POST /v1/calculate arrives with FG-2/3.
}

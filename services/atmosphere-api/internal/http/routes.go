package http

import (
	"net/http"

	"github.com/darioeliseobarboza/atmosphere-api/internal/calculation"
)

// Mount returns the route-mounting function for NewServer. It is the single
// seam where business modules plug their handlers, keeping NewServer free of
// domain wiring. In FG-2 it mounts the calculation handler (POST /v1/calculate);
// GET /health is registered directly in NewServer.
func Mount(calc *calculation.Handler) func(mux *http.ServeMux) {
	return func(mux *http.ServeMux) {
		calc.Routes(mux)
	}
}

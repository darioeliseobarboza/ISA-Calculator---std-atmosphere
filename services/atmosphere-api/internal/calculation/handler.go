package calculation

import (
	"encoding/json"
	"net/http"

	"github.com/darioeliseobarboza/atmosphere-api/internal/shared/errs"
	"github.com/darioeliseobarboza/atmosphere-api/internal/shared/respond"
)

// Handler is the HTTP transport for the calculation module: it decodes the
// request, delegates to the Service and writes the canonical response/error.
// It holds no business logic (the engine lives in the Service).
type Handler struct {
	svc *Service
}

// NewHandler builds a Handler over the given Service.
func NewHandler(svc *Service) *Handler {
	return &Handler{svc: svc}
}

// Routes registers the module's routes onto mux. The /v1/ prefix is mandatory
// (ADR-001); the Go 1.22+ method+path pattern makes other methods 405.
func (h *Handler) Routes(mux *http.ServeMux) {
	mux.HandleFunc("POST /v1/calculate", h.calculate)
}

// calculate decodes the body, runs the service and writes the result. A
// malformed/non-numeric body becomes invalidInput; the service maps range and
// semantic errors. On success it writes 200 with the resource directly (no
// envelope).
func (h *Handler) calculate(w http.ResponseWriter, r *http.Request) {
	var in CalculationRequest
	if err := json.NewDecoder(r.Body).Decode(&in); err != nil {
		respond.ErrorFrom(w, errs.NewInvalidInput("request body is not valid JSON").Wrap(err))
		return
	}

	res, err := h.svc.Calculate(r.Context(), in)
	if err != nil {
		respond.ErrorFrom(w, err)
		return
	}

	respond.JSON(w, http.StatusOK, res)
}

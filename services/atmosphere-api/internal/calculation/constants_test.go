package calculation_test

import (
	"testing"

	"github.com/darioeliseobarboza/atmosphere-api/internal/calculation"
	"github.com/stretchr/testify/assert"
)

// TS-11: derived constants are computed at runtime from the exact ISA 1976 base
// constants (never hardcoded rounded). We assert the expected derived values
// within tolerance.
func TestDerivedConstants(t *testing.T) {
	assert.InDelta(t, 287.0529, calculation.R, 1e-3, "R = R*/M0")
	assert.InDelta(t, 1.2250, calculation.Rho0, 1e-4, "rho0 = P0/(R*T0)")
	assert.InDelta(t, 340.294, calculation.A0, 1e-2, "a0 = sqrt(gamma*R*T0)")
	assert.InDelta(t, 1.7894e-5, calculation.Mu0, 1e-8, "mu0 = beta*T0^1.5/(T0+S)")
	assert.InDelta(t, 5.2559, calculation.PressureExponent, 1e-3, "n = g0/(R*|L|)")
}

// Base constants must be exactly the verbatim ISA 1976 values (ADR-005).
func TestBaseConstantsAreExact(t *testing.T) {
	assert.Equal(t, 8.31432, calculation.RStar)
	assert.Equal(t, 0.0289644, calculation.M0)
	assert.Equal(t, 288.15, calculation.T0)
	assert.Equal(t, 101325.0, calculation.P0)
	assert.Equal(t, 9.80665, calculation.G0)
	assert.Equal(t, 1.4, calculation.Gamma)
	assert.Equal(t, 1.458e-6, calculation.Beta)
	assert.Equal(t, 110.4, calculation.SutherlandS)
	assert.Equal(t, -0.0065, calculation.LapseRate)
}

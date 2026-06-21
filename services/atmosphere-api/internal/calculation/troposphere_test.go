package calculation_test

import (
	"testing"

	"github.com/darioeliseobarboza/atmosphere-api/internal/calculation"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// TS-12: the analytical formula at h = 0 ft yields exact sea-level ISA, with all
// relative ratios equal to 1.
func TestTroposphereAtSeaLevel(t *testing.T) {
	got := calculation.Troposphere(0)

	assert.InDelta(t, 288.15, got.Temperature, 1e-9, "T")
	assert.InDelta(t, 101325.0, got.Pressure, 1e-6, "P")
	assert.InDelta(t, 1.2250, got.Density, 1e-4, "rho")
	assert.InDelta(t, 340.294, got.SpeedOfSound, 1e-2, "a")

	assert.InDelta(t, 1.0, got.Theta, 1e-9, "theta")
	assert.InDelta(t, 1.0, got.Delta, 1e-9, "delta")
	assert.InDelta(t, 1.0, got.Sigma, 1e-9, "sigma")
	assert.InDelta(t, 1.0, got.SpeedOfSoundRatio, 1e-9, "a/a0")
	assert.InDelta(t, 1.0, got.ViscosityRatio, 1e-9, "mu/mu0")
}

// Subset cross-check at this unit level (full cross-check is Task 6).
// Reference rows from the UTN ISA table (pressure in mb -> Pa via ×100).
func TestTroposphereSubsetCrossCheck(t *testing.T) {
	tests := []struct {
		name    string
		altFt   float64
		thetaUT float64 // theta from table (3 decimals)
		deltaUT float64 // delta from table
		sigmaUT float64 // sigma from table
		tempC   float64 // temperature in °C from table
	}{
		{name: "5000 ft", altFt: 5000, thetaUT: 0.966, deltaUT: 0.832, sigmaUT: 0.862, tempC: 5.1},
		{name: "10000 ft", altFt: 10000, thetaUT: 0.931, deltaUT: 0.688, sigmaUT: 0.738, tempC: -4.8},
		{name: "20000 ft", altFt: 20000, thetaUT: 0.862, deltaUT: 0.459, sigmaUT: 0.533, tempC: -24.6},
	}
	const tol = 1e-3 // table is rounded to 3 decimals
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := calculation.Troposphere(tt.altFt)
			assert.InDelta(t, tt.thetaUT, got.Theta, tol, "theta")
			assert.InDelta(t, tt.deltaUT, got.Delta, tol, "delta")
			assert.InDelta(t, tt.sigmaUT, got.Sigma, tol, "sigma")
			// Temperature: °C -> K.
			assert.InDelta(t, tt.tempC+273.15, got.Temperature, 0.1, "T")
		})
	}
}

// At the tropopause boundary (36089 ft ≈ 11000 m) T must reach ~216.65 K.
func TestTroposphereAtTropopause(t *testing.T) {
	got := calculation.Troposphere(36089)
	require.InDelta(t, 216.65, got.Temperature, 0.1, "T at tropopause")
}

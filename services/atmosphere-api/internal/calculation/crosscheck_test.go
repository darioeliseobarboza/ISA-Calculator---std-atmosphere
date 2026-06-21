package calculation_test

import (
	"math"
	"strconv"
	"testing"

	"github.com/darioeliseobarboza/atmosphere-api/internal/calculation"
	"github.com/stretchr/testify/assert"
)

// knotToMPerSec converts knots to m/s (1 kt = 0.514444 m/s) — the UTN table
// reports the speed of sound in knots.
const knotToMPerSec = 0.514444

// utnRow is one reference row of the UTN ISA table
// (docs/references/atmosfera_tipo_internacional_ISA.pdf, pages 17–18). Values
// are transcribed verbatim from the table, which is rounded to 3 decimals for
// the relative columns. Pressure is reported in mb on p.17 (×100 -> Pa).
type utnRow struct {
	altFt     float64
	tempC     float64 // Temperatura °C
	pressMb   float64 // Presión p (mb)
	sigma     float64 // σ (density ratio)
	sqrtSigma float64 // √σ
	delta     float64 // δ (pressure ratio)
	theta     float64 // θ (temperature ratio)
	soundKt   float64 // V. sonido (kt)
	nu1e5     float64 // viscosidad cinemática ×10⁻⁵ m²/s
}

// TS-13: cross-check the analytical method against the UTN reference table for a
// representative set of altitudes in 0–36089 ft. The table rounds the relative
// columns to 3 decimals, so we compare θ/δ/σ/√σ within ±1e-3; absolute values
// (T, speed of sound, ν) use their own per-column tolerance reflecting the
// table's rounding after the unit conversion (°C->K, kt->m/s, ×10⁻⁵ m²/s).
func TestCrossCheckAgainstUTNTable(t *testing.T) {
	rows := []utnRow{
		{altFt: 0, tempC: 15.0, pressMb: 1013.25, sigma: 1.000, sqrtSigma: 1.000, delta: 1.000, theta: 1.000, soundKt: 661.5, nu1e5: 1.460},
		{altFt: 5000, tempC: 5.1, pressMb: 843.07, sigma: 0.862, sqrtSigma: 0.928, delta: 0.832, theta: 0.966, soundKt: 650.0, nu1e5: 1.649},
		{altFt: 10000, tempC: -4.8, pressMb: 696.81, sigma: 0.738, sqrtSigma: 0.859, delta: 0.688, theta: 0.931, soundKt: 638.3, nu1e5: 1.870},
		{altFt: 20000, tempC: -24.6, pressMb: 465.63, sigma: 0.533, sqrtSigma: 0.730, delta: 0.459, theta: 0.862, soundKt: 614.3, nu1e5: 2.438},
		{altFt: 30000, tempC: -44.4, pressMb: 300.89, sigma: 0.374, sqrtSigma: 0.612, delta: 0.297, theta: 0.794, soundKt: 589.3, nu1e5: 3.244},
		{altFt: 36000, tempC: -56.3, pressMb: 227.29, sigma: 0.298, sqrtSigma: 0.546, delta: 0.224, theta: 0.752, soundKt: 573.8, nu1e5: 3.895},
	}

	const relTol = 1e-3 // table is rounded to 3 decimals for θ/δ/σ/√σ

	for _, row := range rows {
		row := row
		t.Run(label(row.altFt), func(t *testing.T) {
			got := calculation.Troposphere(row.altFt)

			// Relative ratios: compare within the table's 3-decimal rounding.
			assert.InDelta(t, row.theta, got.Theta, relTol, "theta")
			assert.InDelta(t, row.delta, got.Delta, relTol, "delta")
			assert.InDelta(t, row.sigma, got.Sigma, relTol, "sigma")
			assert.InDelta(t, row.sqrtSigma, math.Sqrt(got.Sigma), relTol, "sqrt(sigma)")

			// Temperature: °C -> K. The table rounds °C to 0.1.
			assert.InDelta(t, row.tempC+273.15, got.Temperature, 0.15, "temperature K")

			// Pressure: mb -> Pa (×100). The table rounds mb to 0.01, so allow a
			// small relative tolerance.
			assert.InEpsilon(t, row.pressMb*100, got.Pressure, 2e-3, "pressure Pa")

			// Speed of sound: kt -> m/s. Table rounds kt to 0.1 -> ~0.05 m/s.
			assert.InDelta(t, row.soundKt*knotToMPerSec, got.SpeedOfSound, 0.3, "speed of sound m/s")

			// Kinematic viscosity: ×10⁻⁵ m²/s. Table rounds to 1e-3 of that unit.
			assert.InDelta(t, row.nu1e5*1e-5, got.KinematicViscosity, 5e-8, "kinematic viscosity m²/s")
		})
	}
}

func label(altFt float64) string {
	return strconv.FormatFloat(altFt, 'f', -1, 64) + "ft"
}

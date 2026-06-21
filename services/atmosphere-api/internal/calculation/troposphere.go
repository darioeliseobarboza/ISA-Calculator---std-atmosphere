package calculation

import (
	"math"

	"github.com/darioeliseobarboza/atmosphere-api/internal/units"
)

// Troposphere computes the ISA atmosphere analytically at the given geopotential
// altitude, expressed in feet (the canonical altitude unit, ADR-002), for the
// gradient layer 0–36089 ft (0–11000 m). Range validation is the caller's
// responsibility (the Service); this function applies the formulas as-is.
//
// The temperature model works in SI: the altitude is converted ft -> m so the
// metric lapse rate L = -0.0065 K/m applies directly. Pressure and density use
// the temperature ratio and the dimensionless exponent n, so they are
// independent of the altitude unit (see ADR-005 note).
func Troposphere(altitudeFt float64) Result {
	hMeters := units.MetersFromFeet(altitudeFt)

	// Temperature: T = T0 + L·h (h in m, L in K/m).
	temperature := T0 + LapseRate*hMeters
	theta := temperature / T0

	// Pressure: δ = θ^n, P = P0·δ.
	delta := math.Pow(theta, PressureExponent)
	pressure := P0 * delta

	// Density: σ = θ^(n-1) = δ/θ, ρ = ρ0·σ. Equivalent to ρ = P/(R·T); we use
	// the ratio form to keep δ and σ analytically consistent.
	sigma := math.Pow(theta, PressureExponent-1)
	density := Rho0 * sigma

	// Speed of sound: a = √(γ·R·T); a/a0 = √θ.
	speedOfSound := math.Sqrt(Gamma * R * temperature)
	speedOfSoundRatio := math.Sqrt(theta)

	// Dynamic viscosity (Sutherland): μ = β·T^1.5/(T+S); ν = μ/ρ.
	dynamicViscosity := Beta * math.Pow(temperature, 1.5) / (temperature + SutherlandS)
	kinematicViscosity := dynamicViscosity / density
	viscosityRatio := dynamicViscosity / Mu0

	return Result{
		Temperature:        temperature,
		Pressure:           pressure,
		Density:            density,
		DynamicViscosity:   dynamicViscosity,
		KinematicViscosity: kinematicViscosity,
		SpeedOfSound:       speedOfSound,
		Theta:              theta,
		Delta:              delta,
		Sigma:              sigma,
		SpeedOfSoundRatio:  speedOfSoundRatio,
		ViscosityRatio:     viscosityRatio,
	}
}

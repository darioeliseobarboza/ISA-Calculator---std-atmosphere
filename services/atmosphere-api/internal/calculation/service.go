package calculation

import (
	"context"
	"math"

	"github.com/darioeliseobarboza/atmosphere-api/internal/shared/errs"
	"github.com/darioeliseobarboza/atmosphere-api/internal/units"
)

// Altitude validation bounds in feet (the canonical unit, ADR-002). The upper
// bound is the troposphere ceiling (tropopause), inclusive.
const (
	minAltitudeFt = 0.0
	maxAltitudeFt = 36089.0

	unitMeters = "m"
	unitFeet   = "ft"

	methodAnalytical = "analytical"
)

// Service is the application layer of the calculation: it normalizes and
// validates the request, runs the analytical engine and assembles the
// {si, imperial} response. The computation is pure (no I/O); ctx is carried by
// convention as it crosses layers.
type Service struct{}

// NewService builds a Service. It takes no dependencies (the engine is pure).
func NewService() *Service { return &Service{} }

// Calculate normalizes the altitude to feet, validates the 0–36089 ft range,
// runs the analytical troposphere model and assembles the response with each
// absolute magnitude as {si, imperial} and the relative ratios as numbers.
//
// Returns *errs.Error with code invalidInput (missing/NaN/Inf altitude, unknown
// unit) or outOfRange (altitude outside the band); range validation is
// authoritative here (the client only checks format).
func (s *Service) Calculate(_ context.Context, in CalculationRequest) (CalculationResponse, error) {
	if in.GeopotentialAltitude == nil {
		return CalculationResponse{}, errs.NewInvalidInput("geopotentialAltitude is required")
	}
	raw := *in.GeopotentialAltitude
	if math.IsNaN(raw) || math.IsInf(raw, 0) {
		return CalculationResponse{}, errs.NewInvalidInput("geopotentialAltitude must be a finite number")
	}

	unit := in.AltitudeUnit
	if unit == "" {
		unit = unitFeet // default per ADR-002
	}

	// Normalize to feet (canonical unit).
	var altitudeFt, altitudeM float64
	switch unit {
	case unitFeet:
		altitudeFt = raw
		altitudeM = units.MetersFromFeet(raw)
	case unitMeters:
		altitudeM = raw
		altitudeFt = units.FeetFromMeters(raw)
	default:
		return CalculationResponse{}, errs.NewInvalidInput("altitudeUnit must be \"m\" or \"ft\"")
	}

	if altitudeFt < minAltitudeFt || altitudeFt > maxAltitudeFt {
		return CalculationResponse{}, errs.NewOutOfRange(
			"geopotentialAltitude out of range (0–36089 ft ≈ 0–11000 m)")
	}

	r := Troposphere(altitudeFt)

	resp := CalculationResponse{
		Input: CalculationInput{
			GeopotentialAltitude: AltitudeValue{M: altitudeM, Ft: altitudeFt},
			AltitudeUnit:         unit,
		},
		Results: CalculationResults{
			Analytical: AtmosphericResult{
				Method:             methodAnalytical,
				Temperature:        MagnitudeValue{SI: r.Temperature, Imperial: units.RankineFromKelvin(r.Temperature)},
				Pressure:           MagnitudeValue{SI: r.Pressure, Imperial: units.PSFFromPascal(r.Pressure)},
				Density:            MagnitudeValue{SI: r.Density, Imperial: units.SlugPerFt3FromKgPerM3(r.Density)},
				DynamicViscosity:   MagnitudeValue{SI: r.DynamicViscosity, Imperial: units.SlugPerFtSecFromPascalSec(r.DynamicViscosity)},
				KinematicViscosity: MagnitudeValue{SI: r.KinematicViscosity, Imperial: units.Ft2PerSecFromM2PerSec(r.KinematicViscosity)},
				SpeedOfSound:       MagnitudeValue{SI: r.SpeedOfSound, Imperial: units.FtPerSecFromMPerSec(r.SpeedOfSound)},
				Theta:              r.Theta,
				Delta:              r.Delta,
				Sigma:              r.Sigma,
				SpeedOfSoundRatio:  r.SpeedOfSoundRatio,
				ViscosityRatio:     r.ViscosityRatio,
			},
		},
	}
	return resp, nil
}

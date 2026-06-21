package calculation

// CalculationRequest is the POST /v1/calculate request body. JSON identifiers
// are English camelCase (ADR-001).
//
// GeopotentialAltitude is a pointer so a missing field (nil) is distinguishable
// from a legitimate 0 — a missing required field is invalidInput, while 0 is a
// valid sea-level altitude. TableStep is accepted but ignored in FG-2 (no grid
// / interpolation yet); it is not validated (invalidStep is inactive).
type CalculationRequest struct {
	GeopotentialAltitude *float64 `json:"geopotentialAltitude"`
	AltitudeUnit         string   `json:"altitudeUnit"`
	TableStep            *float64 `json:"tableStep"`
}

// MagnitudeValue is an absolute magnitude expressed in SI and imperial at once
// (ADR-002). Both fields are always present.
type MagnitudeValue struct {
	SI       float64 `json:"si"`
	Imperial float64 `json:"imperial"`
}

// AltitudeValue is an altitude echoed in both meters and feet (ADR-002).
type AltitudeValue struct {
	M  float64 `json:"m"`
	Ft float64 `json:"ft"`
}

// AtmosphericResult is one computed atmosphere: absolute magnitudes as
// {si, imperial} pairs and the relative ratios as dimensionless numbers.
// Method is "analytical" in FG-2.
type AtmosphericResult struct {
	Method             string         `json:"method"`
	Temperature        MagnitudeValue `json:"temperature"`
	Pressure           MagnitudeValue `json:"pressure"`
	Density            MagnitudeValue `json:"density"`
	DynamicViscosity   MagnitudeValue `json:"dynamicViscosity"`
	KinematicViscosity MagnitudeValue `json:"kinematicViscosity"`
	SpeedOfSound       MagnitudeValue `json:"speedOfSound"`
	Theta              float64        `json:"theta"`
	Delta              float64        `json:"delta"`
	Sigma              float64        `json:"sigma"`
	SpeedOfSoundRatio  float64        `json:"speedOfSoundRatio"`
	ViscosityRatio     float64        `json:"viscosityRatio"`
}

// CalculationInput echoes the request back: the altitude in {m, ft} and the
// effective unit. tableStep is omitted in FG-2.
type CalculationInput struct {
	GeopotentialAltitude AltitudeValue `json:"geopotentialAltitude"`
	AltitudeUnit         string        `json:"altitudeUnit"`
}

// CalculationResults carries the per-method results. In FG-2 only analytical is
// present; interpolation arrives in FG-3 (omitted via omitempty pointer).
type CalculationResults struct {
	Analytical AtmosphericResult `json:"analytical"`
	// Interpolation is FG-3; a nil pointer is omitted from the JSON.
	Interpolation *AtmosphericResult `json:"interpolation,omitempty"`
}

// CalculationResponse is the 200 body. comparison and table (FG-3) are omitted
// in FG-2 by simply not declaring them here — the additive evolution adds them
// in FG-3 without a breaking change.
type CalculationResponse struct {
	Input   CalculationInput   `json:"input"`
	Results CalculationResults `json:"results"`
}

package calculation

// Result groups the analytically computed atmosphere at one altitude: the
// absolute magnitudes in SI and the dimensionless relative ratios. The Service
// converts each absolute into its {si, imperial} pair via the units module; the
// ratios are emitted as-is (ADR-002).
type Result struct {
	// Absolute magnitudes in SI units.
	Temperature        float64 // K
	Pressure           float64 // Pa
	Density            float64 // kg/m³
	DynamicViscosity   float64 // Pa·s
	KinematicViscosity float64 // m²/s
	SpeedOfSound       float64 // m/s

	// Dimensionless relative ratios.
	Theta             float64 // T/T0
	Delta             float64 // P/P0
	Sigma             float64 // ρ/ρ0
	SpeedOfSoundRatio float64 // a/a0 = √θ
	ViscosityRatio    float64 // μ/μ0
}

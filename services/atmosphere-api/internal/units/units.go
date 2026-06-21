// Package units holds the pure unit conversions of atmosphere-api: altitude
// m<->ft and, per absolute magnitude, SI->imperial. Isolating every conversion
// factor in one place mitigates the conversion-error risk called out by ADR-002
// and ADR-005.
//
// All functions are pure (no state, no I/O, no context) and compute in float64
// without rounding — rounding is a presentation concern (5 sig figs) owned by
// the frontend, not by this module (ADR-005).
package units

// Conversion factors and reference constants (ADR-002). Kept as named
// constants — never magic numbers scattered through the code.
const (
	// MetersPerFoot is the exact international foot: 1 ft = 0.3048 m.
	MetersPerFoot = 0.3048

	// RankinePerKelvin converts an absolute temperature K -> °R (×1.8).
	RankinePerKelvin = 1.8

	// PascalPerPSF is the pascals in one pound-force per square foot
	// (1 lbf/ft² = 47.880259 Pa). Pa -> psf divides by this.
	PascalPerPSF = 47.880259

	// KgPerM3PerSlugPerFt3 is the kg/m³ in one slug/ft³
	// (1 slug/ft³ = 515.378818 kg/m³). kg/m³ -> slug/ft³ divides by this.
	KgPerM3PerSlugPerFt3 = 515.378818
)

// FeetFromMeters converts meters to feet (1 ft = 0.3048 m, exact).
func FeetFromMeters(m float64) float64 { return m / MetersPerFoot }

// MetersFromFeet converts feet to meters (1 ft = 0.3048 m, exact).
func MetersFromFeet(ft float64) float64 { return ft * MetersPerFoot }

// RankineFromKelvin converts a temperature in kelvin to degrees Rankine.
func RankineFromKelvin(k float64) float64 { return k * RankinePerKelvin }

// PSFFromPascal converts pressure in pascals to pounds-force per square foot.
func PSFFromPascal(pa float64) float64 { return pa / PascalPerPSF }

// SlugPerFt3FromKgPerM3 converts density in kg/m³ to slug/ft³.
func SlugPerFt3FromKgPerM3(kgPerM3 float64) float64 { return kgPerM3 / KgPerM3PerSlugPerFt3 }

// SlugPerFtSecFromPascalSec converts dynamic viscosity Pa·s to slug/(ft·s).
// Pa·s and lbf·s/ft² share the same numeric conversion as pressure
// (1 Pa·s = 1/47.880259 slug/(ft·s)).
func SlugPerFtSecFromPascalSec(paSec float64) float64 { return paSec / PascalPerPSF }

// Ft2PerSecFromM2PerSec converts kinematic viscosity m²/s to ft²/s
// (1 m²/s = 1/0.3048² ft²/s).
func Ft2PerSecFromM2PerSec(m2PerSec float64) float64 {
	return m2PerSec / (MetersPerFoot * MetersPerFoot)
}

// FtPerSecFromMPerSec converts a speed m/s to ft/s (1 m/s = 1/0.3048 ft/s).
func FtPerSecFromMPerSec(mPerSec float64) float64 { return mPerSec / MetersPerFoot }

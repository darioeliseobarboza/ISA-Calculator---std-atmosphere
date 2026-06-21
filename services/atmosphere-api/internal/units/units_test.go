package units_test

import (
	"testing"

	"github.com/darioeliseobarboza/atmosphere-api/internal/units"
	"github.com/stretchr/testify/assert"
)

func TestFeetMetersConversion(t *testing.T) {
	// TS-10: m<->ft exact with 1 ft = 0.3048 m.
	tests := []struct {
		name   string
		fn     func(float64) float64
		in     float64
		want   float64
		epsilo float64 // relative tolerance for InEpsilon, 0 means use InDelta
		delta  float64
	}{
		{name: "5000 m -> ft", fn: units.FeetFromMeters, in: 5000.0, want: 16404.199475, epsilo: 1e-6},
		{name: "16404 ft -> m", fn: units.MetersFromFeet, in: 16404.0, want: 5000.0, delta: 0.5},
		{name: "0 m -> 0 ft", fn: units.FeetFromMeters, in: 0.0, want: 0.0, delta: 1e-9},
		{name: "0 ft -> 0 m", fn: units.MetersFromFeet, in: 0.0, want: 0.0, delta: 1e-9},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := tt.fn(tt.in)
			if tt.epsilo > 0 {
				assert.InEpsilon(t, tt.want, got, tt.epsilo)
			} else {
				assert.InDelta(t, tt.want, got, tt.delta)
			}
		})
	}
}

func TestFeetMetersRoundTrip(t *testing.T) {
	for _, x := range []float64{0, 100.5, 5000, 16404, 36089} {
		got := units.MetersFromFeet(units.FeetFromMeters(x))
		assert.InDelta(t, x, got, 1e-6)
	}
}

func TestTemperatureSItoImperial(t *testing.T) {
	// 288.15 K -> 518.67 °R (K x 1.8).
	assert.InDelta(t, 518.67, units.RankineFromKelvin(288.15), 1e-9)
	assert.InDelta(t, 0.0, units.RankineFromKelvin(0.0), 1e-9)
}

func TestPressureSItoImperial(t *testing.T) {
	// 101325 Pa -> ~2116.22 lbf/ft² (psf). 1 Pa = 1/47.880259 psf.
	assert.InEpsilon(t, 2116.2166, units.PSFFromPascal(101325), 1e-4)
}

func TestDensitySItoImperial(t *testing.T) {
	// 1.2250 kg/m³ -> ~0.0023769 slug/ft³.
	assert.InEpsilon(t, 0.00237691, units.SlugPerFt3FromKgPerM3(1.2250), 1e-4)
}

func TestSpeedOfSoundSItoImperial(t *testing.T) {
	// 340.294 m/s -> ~1116.45 ft/s (1 m/s = 1/0.3048 ft/s).
	assert.InEpsilon(t, 1116.4501, units.FtPerSecFromMPerSec(340.294), 1e-5)
}

func TestKinematicViscositySItoImperial(t *testing.T) {
	// 1 m²/s = 1/0.3048² ft²/s ≈ 10.76391.
	assert.InEpsilon(t, 10.76391, units.Ft2PerSecFromM2PerSec(1.0), 1e-5)
}

func TestDynamicViscositySItoImperial(t *testing.T) {
	// 1 Pa·s = 1/47.880259 slug/(ft·s) ≈ 0.0208854.
	assert.InEpsilon(t, 0.0208854, units.SlugPerFtSecFromPascalSec(1.0), 1e-5)
}

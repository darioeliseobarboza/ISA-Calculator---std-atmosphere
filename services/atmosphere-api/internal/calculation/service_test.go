package calculation_test

import (
	"context"
	"errors"
	"testing"

	"github.com/darioeliseobarboza/atmosphere-api/internal/calculation"
	"github.com/darioeliseobarboza/atmosphere-api/internal/shared/errs"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func ptr(f float64) *float64 { return &f }

func TestServiceCalculateIntermediateFt(t *testing.T) {
	// TS-1: 16404 ft -> analytical result, method analytical, echo {m:5000, ft:16404}.
	svc := calculation.NewService()
	res, err := svc.Calculate(context.Background(), calculation.CalculationRequest{
		GeopotentialAltitude: ptr(16404),
		AltitudeUnit:         "ft",
	})
	require.NoError(t, err)

	assert.Equal(t, "analytical", res.Results.Analytical.Method)
	assert.InDelta(t, 255.65, res.Results.Analytical.Temperature.SI, 0.1)
	assert.InDelta(t, 460.2, res.Results.Analytical.Temperature.Imperial, 0.2)
	assert.InEpsilon(t, 54020.0, res.Results.Analytical.Pressure.SI, 1e-2)

	// Absolute magnitudes carry both si and imperial (non-zero where physical).
	assert.NotZero(t, res.Results.Analytical.Density.SI)
	assert.NotZero(t, res.Results.Analytical.Density.Imperial)
	assert.NotZero(t, res.Results.Analytical.SpeedOfSound.Imperial)

	// Relatives present as numbers.
	assert.InDelta(t, 0.8874, res.Results.Analytical.Theta, 1e-3)

	// Echo altitude {m, ft}.
	assert.InDelta(t, 5000.0, res.Input.GeopotentialAltitude.M, 0.5)
	assert.InDelta(t, 16404.0, res.Input.GeopotentialAltitude.Ft, 1e-6)
	assert.Equal(t, "ft", res.Input.AltitudeUnit)

	// FG-2: interpolation omitted.
	assert.Nil(t, res.Results.Interpolation)
}

func TestServiceCalculateSeaLevelMeters(t *testing.T) {
	// TS-2: 0 m -> sea level ISA, relatives = 1, echo {m:0, ft:0}.
	svc := calculation.NewService()
	res, err := svc.Calculate(context.Background(), calculation.CalculationRequest{
		GeopotentialAltitude: ptr(0),
		AltitudeUnit:         "m",
	})
	require.NoError(t, err)

	a := res.Results.Analytical
	assert.InDelta(t, 288.15, a.Temperature.SI, 1e-6)
	assert.InDelta(t, 101325.0, a.Pressure.SI, 1e-3)
	assert.InDelta(t, 1.2250, a.Density.SI, 1e-4)
	assert.InDelta(t, 340.29, a.SpeedOfSound.SI, 1e-2)

	assert.InDelta(t, 1.0, a.Theta, 1e-6)
	assert.InDelta(t, 1.0, a.Delta, 1e-6)
	assert.InDelta(t, 1.0, a.Sigma, 1e-6)
	assert.InDelta(t, 1.0, a.SpeedOfSoundRatio, 1e-6)
	assert.InDelta(t, 1.0, a.ViscosityRatio, 1e-6)

	assert.InDelta(t, 0.0, res.Input.GeopotentialAltitude.M, 1e-9)
	assert.InDelta(t, 0.0, res.Input.GeopotentialAltitude.Ft, 1e-9)
}

func TestServiceCalculateOutOfRange(t *testing.T) {
	svc := calculation.NewService()

	t.Run("TS-3 above range", func(t *testing.T) {
		_, err := svc.Calculate(context.Background(), calculation.CalculationRequest{
			GeopotentialAltitude: ptr(40000), AltitudeUnit: "ft",
		})
		var de *errs.Error
		require.True(t, errors.As(err, &de))
		assert.Equal(t, "outOfRange", de.Code)
	})

	t.Run("TS-4 negative altitude", func(t *testing.T) {
		_, err := svc.Calculate(context.Background(), calculation.CalculationRequest{
			GeopotentialAltitude: ptr(-100), AltitudeUnit: "ft",
		})
		var de *errs.Error
		require.True(t, errors.As(err, &de))
		assert.Equal(t, "outOfRange", de.Code)
	})
}

func TestServiceCalculateInvalidInput(t *testing.T) {
	svc := calculation.NewService()

	t.Run("TS-6 missing required field", func(t *testing.T) {
		_, err := svc.Calculate(context.Background(), calculation.CalculationRequest{
			AltitudeUnit: "ft", // no altitude
		})
		var de *errs.Error
		require.True(t, errors.As(err, &de))
		assert.Equal(t, "invalidInput", de.Code)
	})

	t.Run("unknown unit", func(t *testing.T) {
		_, err := svc.Calculate(context.Background(), calculation.CalculationRequest{
			GeopotentialAltitude: ptr(0), AltitudeUnit: "miles",
		})
		var de *errs.Error
		require.True(t, errors.As(err, &de))
		assert.Equal(t, "invalidInput", de.Code)
	})
}

func TestServiceDefaultUnitIsFeet(t *testing.T) {
	// TS-8: omitted altitudeUnit defaults to ft.
	svc := calculation.NewService()
	res, err := svc.Calculate(context.Background(), calculation.CalculationRequest{
		GeopotentialAltitude: ptr(0), // no unit
	})
	require.NoError(t, err)
	assert.Equal(t, "ft", res.Input.AltitudeUnit)
	assert.InDelta(t, 0.0, res.Input.GeopotentialAltitude.Ft, 1e-9)
	assert.InDelta(t, 288.15, res.Results.Analytical.Temperature.SI, 1e-6)
}

func TestServiceTableStepIgnored(t *testing.T) {
	// TS-9: tableStep is accepted but does not change the result.
	svc := calculation.NewService()
	step := 500.0
	withStep, err := svc.Calculate(context.Background(), calculation.CalculationRequest{
		GeopotentialAltitude: ptr(16404), AltitudeUnit: "ft", TableStep: &step,
	})
	require.NoError(t, err)
	noStep, err := svc.Calculate(context.Background(), calculation.CalculationRequest{
		GeopotentialAltitude: ptr(16404), AltitudeUnit: "ft",
	})
	require.NoError(t, err)
	assert.Equal(t, noStep.Results.Analytical, withStep.Results.Analytical)
}

func TestServiceUpperBoundInclusive(t *testing.T) {
	// TS-7: 36089 ft is valid.
	svc := calculation.NewService()
	res, err := svc.Calculate(context.Background(), calculation.CalculationRequest{
		GeopotentialAltitude: ptr(36089), AltitudeUnit: "ft",
	})
	require.NoError(t, err)
	assert.InDelta(t, 216.65, res.Results.Analytical.Temperature.SI, 0.1)
}

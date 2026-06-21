package calculation_test

import (
	"bytes"
	"encoding/json"
	stdhttp "net/http"
	"net/http/httptest"
	"testing"

	"github.com/darioeliseobarboza/atmosphere-api/internal/calculation"
	apihttp "github.com/darioeliseobarboza/atmosphere-api/internal/http"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// newCalcServer builds the fully assembled handler (server + mounted route)
// in-process, the same wiring main.go uses.
func newCalcServer(t *testing.T) *httptest.Server {
	t.Helper()
	handler := calculation.NewHandler(calculation.NewService())
	srv := apihttp.NewServer(":0", nil, apihttp.Mount(handler))
	ts := httptest.NewServer(srv.Handler)
	t.Cleanup(ts.Close)
	return ts
}

// post sends a raw JSON body to /v1/calculate and returns the response.
func post(t *testing.T, ts *httptest.Server, body string) *stdhttp.Response {
	t.Helper()
	resp, err := ts.Client().Post(ts.URL+"/v1/calculate", "application/json", bytes.NewBufferString(body))
	require.NoError(t, err)
	t.Cleanup(func() { _ = resp.Body.Close() })
	return resp
}

func TestCalculateEndpointHappyPath(t *testing.T) {
	if testing.Short() {
		t.Skip("skipping integration test in short mode")
	}
	ts := newCalcServer(t)

	t.Run("TS-1 intermediate altitude (ft)", func(t *testing.T) {
		resp := post(t, ts, `{"geopotentialAltitude":16404,"altitudeUnit":"ft"}`)
		require.Equal(t, stdhttp.StatusOK, resp.StatusCode)

		var body calculation.CalculationResponse
		require.NoError(t, json.NewDecoder(resp.Body).Decode(&body))
		a := body.Results.Analytical
		assert.Equal(t, "analytical", a.Method)
		assert.InDelta(t, 255.65, a.Temperature.SI, 0.1)
		assert.InDelta(t, 460.2, a.Temperature.Imperial, 0.3)
		assert.InEpsilon(t, 54020.0, a.Pressure.SI, 1e-2)
		assert.InEpsilon(t, 1128.0, a.Pressure.Imperial, 2e-2)
		// each absolute has both si and imperial
		assert.NotZero(t, a.Density.Imperial)
		assert.NotZero(t, a.SpeedOfSound.Imperial)
		assert.NotZero(t, a.DynamicViscosity.SI)
		assert.NotZero(t, a.KinematicViscosity.SI)
		// echo {m, ft}
		assert.InDelta(t, 5000.0, body.Input.GeopotentialAltitude.M, 0.5)
		assert.InDelta(t, 16404.0, body.Input.GeopotentialAltitude.Ft, 1e-6)
		assert.Equal(t, "ft", body.Input.AltitudeUnit)
		// FG-2: interpolation omitted
		assert.Nil(t, body.Results.Interpolation)
	})

	t.Run("TS-2 sea level (m)", func(t *testing.T) {
		resp := post(t, ts, `{"geopotentialAltitude":0,"altitudeUnit":"m"}`)
		require.Equal(t, stdhttp.StatusOK, resp.StatusCode)

		var body calculation.CalculationResponse
		require.NoError(t, json.NewDecoder(resp.Body).Decode(&body))
		a := body.Results.Analytical
		assert.InDelta(t, 288.15, a.Temperature.SI, 1e-6)
		assert.InDelta(t, 101325.0, a.Pressure.SI, 1e-3)
		assert.InDelta(t, 1.2250, a.Density.SI, 1e-4)
		assert.InDelta(t, 340.29, a.SpeedOfSound.SI, 1e-2)
		assert.InDelta(t, 1.0, a.Theta, 1e-6)
		assert.InDelta(t, 1.0, a.Delta, 1e-6)
		assert.InDelta(t, 1.0, a.Sigma, 1e-6)
		assert.InDelta(t, 1.0, a.SpeedOfSoundRatio, 1e-6)
		assert.InDelta(t, 1.0, a.ViscosityRatio, 1e-6)
		assert.Equal(t, 0.0, body.Input.GeopotentialAltitude.Ft)
	})

	t.Run("TS-7 upper bound (36089 ft) is valid", func(t *testing.T) {
		resp := post(t, ts, `{"geopotentialAltitude":36089,"altitudeUnit":"ft"}`)
		require.Equal(t, stdhttp.StatusOK, resp.StatusCode)
		var body calculation.CalculationResponse
		require.NoError(t, json.NewDecoder(resp.Body).Decode(&body))
		assert.InDelta(t, 216.65, body.Results.Analytical.Temperature.SI, 0.1)
	})

	t.Run("TS-8 default unit is ft when omitted", func(t *testing.T) {
		resp := post(t, ts, `{"geopotentialAltitude":0}`)
		require.Equal(t, stdhttp.StatusOK, resp.StatusCode)
		var body calculation.CalculationResponse
		require.NoError(t, json.NewDecoder(resp.Body).Decode(&body))
		assert.Equal(t, "ft", body.Input.AltitudeUnit)
		assert.Equal(t, 0.0, body.Input.GeopotentialAltitude.Ft)
		assert.InDelta(t, 288.15, body.Results.Analytical.Temperature.SI, 1e-6)
	})

	t.Run("TS-9 tableStep accepted but ignored; FG-3 fields absent", func(t *testing.T) {
		resp := post(t, ts, `{"geopotentialAltitude":16404,"altitudeUnit":"ft","tableStep":500}`)
		require.Equal(t, stdhttp.StatusOK, resp.StatusCode)

		// decode into a generic map to assert absence of FG-3 fields and input.tableStep
		var raw map[string]any
		require.NoError(t, json.NewDecoder(resp.Body).Decode(&raw))
		_, hasComparison := raw["comparison"]
		_, hasTable := raw["table"]
		assert.False(t, hasComparison)
		assert.False(t, hasTable)
		results := raw["results"].(map[string]any)
		_, hasInterp := results["interpolation"]
		assert.False(t, hasInterp)
		input := raw["input"].(map[string]any)
		_, hasStep := input["tableStep"]
		assert.False(t, hasStep)
	})
}

func TestCalculateEndpointErrors(t *testing.T) {
	if testing.Short() {
		t.Skip("skipping integration test in short mode")
	}
	ts := newCalcServer(t)

	assertErrorCode := func(t *testing.T, resp *stdhttp.Response, wantCode string) {
		t.Helper()
		require.Equal(t, stdhttp.StatusBadRequest, resp.StatusCode)
		var raw map[string]any
		require.NoError(t, json.NewDecoder(resp.Body).Decode(&raw))
		errObj, ok := raw["error"].(map[string]any)
		require.True(t, ok, "body must have error object")
		assert.Equal(t, wantCode, errObj["code"])
		assert.NotEmpty(t, errObj["message"])
		_, hasResults := raw["results"]
		assert.False(t, hasResults, "error body must not include results")
	}

	t.Run("TS-3 out of range (high)", func(t *testing.T) {
		assertErrorCode(t, post(t, ts, `{"geopotentialAltitude":40000,"altitudeUnit":"ft"}`), "outOfRange")
	})
	t.Run("TS-4 negative altitude", func(t *testing.T) {
		assertErrorCode(t, post(t, ts, `{"geopotentialAltitude":-100,"altitudeUnit":"ft"}`), "outOfRange")
	})
	t.Run("TS-5 non-numeric body", func(t *testing.T) {
		assertErrorCode(t, post(t, ts, `{"geopotentialAltitude":"abc","altitudeUnit":"ft"}`), "invalidInput")
	})
	t.Run("TS-5b malformed JSON", func(t *testing.T) {
		assertErrorCode(t, post(t, ts, `{not json`), "invalidInput")
	})
	t.Run("TS-6 missing required field", func(t *testing.T) {
		assertErrorCode(t, post(t, ts, `{"altitudeUnit":"ft"}`), "invalidInput")
	})
}

func TestCalculateEndpointContentTypeAndShape(t *testing.T) {
	if testing.Short() {
		t.Skip("skipping integration test in short mode")
	}
	ts := newCalcServer(t)

	// TS-15: success response Content-Type is application/json.
	resp := post(t, ts, `{"geopotentialAltitude":16404,"altitudeUnit":"ft"}`)
	require.Equal(t, stdhttp.StatusOK, resp.StatusCode)
	assert.Equal(t, "application/json", resp.Header.Get("Content-Type"))

	// TS-14: absolutes are {si, imperial} objects; relatives are numbers.
	var raw map[string]any
	require.NoError(t, json.NewDecoder(resp.Body).Decode(&raw))
	analytical := raw["results"].(map[string]any)["analytical"].(map[string]any)
	assert.Equal(t, "analytical", analytical["method"])

	for _, abs := range []string{"temperature", "pressure", "density", "dynamicViscosity", "kinematicViscosity", "speedOfSound"} {
		obj, ok := analytical[abs].(map[string]any)
		require.True(t, ok, "%s must be an object", abs)
		_, hasSI := obj["si"]
		_, hasImp := obj["imperial"]
		assert.True(t, hasSI, "%s.si present", abs)
		assert.True(t, hasImp, "%s.imperial present", abs)
	}
	for _, rel := range []string{"theta", "delta", "sigma", "speedOfSoundRatio", "viscosityRatio"} {
		_, isNumber := analytical[rel].(float64)
		assert.True(t, isNumber, "%s must be a number", rel)
	}
}

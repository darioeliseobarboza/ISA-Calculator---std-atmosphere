package http_test

import (
	"encoding/json"
	stdhttp "net/http"
	"net/http/httptest"
	"testing"
	"time"

	apihttp "github.com/darioeliseobarboza/atmosphere-api/internal/http"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

const allowedOrigin = "https://app.example.com"

func TestNewServerConfig(t *testing.T) {
	srv := apihttp.NewServer(":9090", []string{allowedOrigin}, func(*stdhttp.ServeMux) {})

	require.NotNil(t, srv)
	assert.Equal(t, ":9090", srv.Addr)
	assert.NotNil(t, srv.Handler)
	assert.Equal(t, 5*time.Second, srv.ReadHeaderTimeout)
	assert.Equal(t, 15*time.Second, srv.ReadTimeout)
	assert.Equal(t, 30*time.Second, srv.WriteTimeout)
	assert.Equal(t, 60*time.Second, srv.IdleTimeout)
}

// newTestServer spins up the fully assembled handler in-process.
func newTestServer(t *testing.T) *httptest.Server {
	t.Helper()
	srv := apihttp.NewServer(":0", []string{allowedOrigin}, func(*stdhttp.ServeMux) {})
	ts := httptest.NewServer(srv.Handler)
	t.Cleanup(ts.Close)
	return ts
}

func TestHealthIntegration(t *testing.T) {
	if testing.Short() {
		t.Skip("skipping integration test in short mode")
	}
	ts := newTestServer(t)
	client := ts.Client()

	t.Run("TS-1 happy path: status ok and RFC3339 timestamp", func(t *testing.T) {
		resp, err := client.Get(ts.URL + "/health")
		require.NoError(t, err)
		defer resp.Body.Close()

		assert.Equal(t, stdhttp.StatusOK, resp.StatusCode)

		var body struct {
			Status    string `json:"status"`
			Timestamp string `json:"timestamp"`
		}
		require.NoError(t, json.NewDecoder(resp.Body).Decode(&body))
		assert.Equal(t, "ok", body.Status)
		require.NotEmpty(t, body.Timestamp)
		_, err = time.Parse(time.RFC3339, body.Timestamp)
		assert.NoError(t, err, "timestamp must be RFC3339")
	})

	t.Run("TS-2 content-type is application/json", func(t *testing.T) {
		resp, err := client.Get(ts.URL + "/health")
		require.NoError(t, err)
		defer resp.Body.Close()
		assert.Equal(t, "application/json", resp.Header.Get("Content-Type"))
	})

	t.Run("TS-3 method not allowed on /health", func(t *testing.T) {
		resp, err := client.Post(ts.URL+"/health", "application/json", nil)
		require.NoError(t, err)
		defer resp.Body.Close()
		assert.Equal(t, stdhttp.StatusMethodNotAllowed, resp.StatusCode)
	})

	t.Run("TS-4 unknown route is 404", func(t *testing.T) {
		resp, err := client.Get(ts.URL + "/nope")
		require.NoError(t, err)
		defer resp.Body.Close()
		assert.Equal(t, stdhttp.StatusNotFound, resp.StatusCode)
	})
}

func TestHealthCORSIntegration(t *testing.T) {
	if testing.Short() {
		t.Skip("skipping integration test in short mode")
	}
	ts := newTestServer(t)
	client := ts.Client()

	t.Run("TS-5 preflight from allowed origin", func(t *testing.T) {
		req, err := stdhttp.NewRequest(stdhttp.MethodOptions, ts.URL+"/health", nil)
		require.NoError(t, err)
		req.Header.Set("Origin", allowedOrigin)
		req.Header.Set("Access-Control-Request-Method", "GET")

		resp, err := client.Do(req)
		require.NoError(t, err)
		defer resp.Body.Close()

		assert.Equal(t, stdhttp.StatusNoContent, resp.StatusCode)
		assert.Equal(t, allowedOrigin, resp.Header.Get("Access-Control-Allow-Origin"))
	})

	t.Run("TS-6 simple request from allowed origin", func(t *testing.T) {
		req, err := stdhttp.NewRequest(stdhttp.MethodGet, ts.URL+"/health", nil)
		require.NoError(t, err)
		req.Header.Set("Origin", allowedOrigin)

		resp, err := client.Do(req)
		require.NoError(t, err)
		defer resp.Body.Close()

		assert.Equal(t, stdhttp.StatusOK, resp.StatusCode)
		assert.Equal(t, allowedOrigin, resp.Header.Get("Access-Control-Allow-Origin"))
	})

	t.Run("TS-7 request from disallowed origin", func(t *testing.T) {
		req, err := stdhttp.NewRequest(stdhttp.MethodGet, ts.URL+"/health", nil)
		require.NoError(t, err)
		req.Header.Set("Origin", "https://evil.example.com")

		resp, err := client.Do(req)
		require.NoError(t, err)
		defer resp.Body.Close()

		assert.Equal(t, stdhttp.StatusOK, resp.StatusCode)
		assert.Empty(t, resp.Header.Get("Access-Control-Allow-Origin"))
	})
}

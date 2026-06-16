package http_test

import (
	"encoding/json"
	stdhttp "net/http"
	"net/http/httptest"
	"testing"

	apihttp "github.com/darioeliseobarboza/atmosphere-api/internal/http"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestRecoverer(t *testing.T) {
	// TS-12: a handler that panics, wrapped by recoverer, yields a canonical 500
	// and the server keeps serving subsequent requests.
	var calls int
	h := apihttp.Recoverer(stdhttp.HandlerFunc(func(w stdhttp.ResponseWriter, r *stdhttp.Request) {
		calls++
		if r.URL.Path == "/boom" {
			panic("boom")
		}
		w.WriteHeader(stdhttp.StatusOK)
	}))

	// First request panics -> 500 canonical error body.
	rec := httptest.NewRecorder()
	h.ServeHTTP(rec, httptest.NewRequest(stdhttp.MethodGet, "/boom", nil))

	require.Equal(t, stdhttp.StatusInternalServerError, rec.Code)
	assert.Equal(t, "application/json", rec.Header().Get("Content-Type"))

	var body struct {
		Error struct {
			Code    string `json:"code"`
			Message string `json:"message"`
		} `json:"error"`
	}
	require.NoError(t, json.Unmarshal(rec.Body.Bytes(), &body))
	assert.Equal(t, "INTERNAL_ERROR", body.Error.Code)
	assert.NotEmpty(t, body.Error.Message)

	// Second request must succeed: the recoverer did not tear down the handler.
	rec2 := httptest.NewRecorder()
	h.ServeHTTP(rec2, httptest.NewRequest(stdhttp.MethodGet, "/ok", nil))
	assert.Equal(t, stdhttp.StatusOK, rec2.Code)
	assert.Equal(t, 2, calls)
}

func TestRequestID(t *testing.T) {
	t.Run("generates a request id visible to the inner handler", func(t *testing.T) {
		var gotArgs []any
		h := apihttp.RequestID(stdhttp.HandlerFunc(func(w stdhttp.ResponseWriter, r *stdhttp.Request) {
			gotArgs = apihttp.RequestArgs(r.Context())
			w.WriteHeader(stdhttp.StatusOK)
		}))

		rec := httptest.NewRecorder()
		h.ServeHTTP(rec, httptest.NewRequest(stdhttp.MethodGet, "/", nil))

		require.Len(t, gotArgs, 2)
		assert.Equal(t, "requestId", gotArgs[0])
		assert.NotEmpty(t, gotArgs[1])
	})

	t.Run("respects incoming X-Request-Id header", func(t *testing.T) {
		var gotArgs []any
		h := apihttp.RequestID(stdhttp.HandlerFunc(func(w stdhttp.ResponseWriter, r *stdhttp.Request) {
			gotArgs = apihttp.RequestArgs(r.Context())
			w.WriteHeader(stdhttp.StatusOK)
		}))

		req := httptest.NewRequest(stdhttp.MethodGet, "/", nil)
		req.Header.Set("X-Request-Id", "fixed-id-123")
		rec := httptest.NewRecorder()
		h.ServeHTTP(rec, req)

		require.Len(t, gotArgs, 2)
		assert.Equal(t, "requestId", gotArgs[0])
		assert.Equal(t, "fixed-id-123", gotArgs[1])
	})
}

func TestRequestArgsEmptyWhenNoID(t *testing.T) {
	// No requestID middleware in the chain -> RequestArgs returns empty.
	args := apihttp.RequestArgs(httptest.NewRequest(stdhttp.MethodGet, "/", nil).Context())
	assert.Empty(t, args)
}

func TestCORS(t *testing.T) {
	allowed := []string{"https://app.example.com"}
	ok := stdhttp.HandlerFunc(func(w stdhttp.ResponseWriter, r *stdhttp.Request) {
		w.WriteHeader(stdhttp.StatusOK)
		_, _ = w.Write([]byte("ok"))
	})

	t.Run("TS-5 preflight from allowed origin", func(t *testing.T) {
		h := apihttp.CORS(allowed)(ok)
		req := httptest.NewRequest(stdhttp.MethodOptions, "/health", nil)
		req.Header.Set("Origin", "https://app.example.com")
		req.Header.Set("Access-Control-Request-Method", "GET")
		rec := httptest.NewRecorder()
		h.ServeHTTP(rec, req)

		assert.Equal(t, stdhttp.StatusNoContent, rec.Code)
		assert.Equal(t, "https://app.example.com", rec.Header().Get("Access-Control-Allow-Origin"))
		assert.NotEmpty(t, rec.Header().Get("Access-Control-Allow-Methods"))
	})

	t.Run("TS-6 simple request from allowed origin", func(t *testing.T) {
		h := apihttp.CORS(allowed)(ok)
		req := httptest.NewRequest(stdhttp.MethodGet, "/health", nil)
		req.Header.Set("Origin", "https://app.example.com")
		rec := httptest.NewRecorder()
		h.ServeHTTP(rec, req)

		assert.Equal(t, stdhttp.StatusOK, rec.Code)
		assert.Equal(t, "https://app.example.com", rec.Header().Get("Access-Control-Allow-Origin"))
		assert.Equal(t, "ok", rec.Body.String())
	})

	t.Run("TS-7 request from disallowed origin", func(t *testing.T) {
		h := apihttp.CORS(allowed)(ok)
		req := httptest.NewRequest(stdhttp.MethodGet, "/health", nil)
		req.Header.Set("Origin", "https://evil.example.com")
		rec := httptest.NewRecorder()
		h.ServeHTTP(rec, req)

		// Request still served; but no allow header for the disallowed origin.
		assert.Equal(t, stdhttp.StatusOK, rec.Code)
		assert.Empty(t, rec.Header().Get("Access-Control-Allow-Origin"))
		assert.Equal(t, "ok", rec.Body.String())
	})

	t.Run("no Origin header is a no-op pass-through", func(t *testing.T) {
		h := apihttp.CORS(allowed)(ok)
		rec := httptest.NewRecorder()
		h.ServeHTTP(rec, httptest.NewRequest(stdhttp.MethodGet, "/health", nil))

		assert.Equal(t, stdhttp.StatusOK, rec.Code)
		assert.Empty(t, rec.Header().Get("Access-Control-Allow-Origin"))
	})
}

func TestChainOrder(t *testing.T) {
	// chain applies the outermost middleware first: order of recorded labels
	// must reflect mw1 (outer) wrapping mw2 (inner) wrapping the handler.
	var order []string
	mk := func(label string) apihttp.Middleware {
		return func(next stdhttp.Handler) stdhttp.Handler {
			return stdhttp.HandlerFunc(func(w stdhttp.ResponseWriter, r *stdhttp.Request) {
				order = append(order, label)
				next.ServeHTTP(w, r)
			})
		}
	}
	final := stdhttp.HandlerFunc(func(w stdhttp.ResponseWriter, r *stdhttp.Request) {
		order = append(order, "handler")
		w.WriteHeader(stdhttp.StatusOK)
	})

	h := apihttp.Chain(final, mk("outer"), mk("inner"))
	rec := httptest.NewRecorder()
	h.ServeHTTP(rec, httptest.NewRequest(stdhttp.MethodGet, "/", nil))

	assert.Equal(t, []string{"outer", "inner", "handler"}, order)
}

func TestWriteJSON(t *testing.T) {
	rec := httptest.NewRecorder()
	apihttp.WriteJSON(rec, stdhttp.StatusTeapot, map[string]any{"hello": "world"})

	assert.Equal(t, stdhttp.StatusTeapot, rec.Code)
	assert.Equal(t, "application/json", rec.Header().Get("Content-Type"))

	var got map[string]any
	require.NoError(t, json.Unmarshal(rec.Body.Bytes(), &got))
	assert.Equal(t, "world", got["hello"])
}

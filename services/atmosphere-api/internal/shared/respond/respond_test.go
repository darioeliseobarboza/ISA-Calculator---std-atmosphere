package respond_test

import (
	"encoding/json"
	"errors"
	stdhttp "net/http"
	"net/http/httptest"
	"testing"

	"github.com/darioeliseobarboza/atmosphere-api/internal/shared/errs"
	"github.com/darioeliseobarboza/atmosphere-api/internal/shared/respond"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestJSON(t *testing.T) {
	rec := httptest.NewRecorder()
	respond.JSON(rec, stdhttp.StatusTeapot, map[string]any{"hello": "world"})

	assert.Equal(t, stdhttp.StatusTeapot, rec.Code)
	assert.Equal(t, "application/json", rec.Header().Get("Content-Type"))

	var got map[string]any
	require.NoError(t, json.Unmarshal(rec.Body.Bytes(), &got))
	assert.Equal(t, "world", got["hello"])
}

func TestErrorCanonicalEnvelope(t *testing.T) {
	rec := httptest.NewRecorder()
	respond.Error(rec, stdhttp.StatusBadRequest, "outOfRange", "h > 36089")

	require.Equal(t, stdhttp.StatusBadRequest, rec.Code)
	assert.Equal(t, "application/json", rec.Header().Get("Content-Type"))

	var body struct {
		Error struct {
			Code    string `json:"code"`
			Message string `json:"message"`
		} `json:"error"`
	}
	require.NoError(t, json.Unmarshal(rec.Body.Bytes(), &body))
	assert.Equal(t, "outOfRange", body.Error.Code)
	assert.Equal(t, "h > 36089", body.Error.Message)
}

func TestErrorFromTypedError(t *testing.T) {
	// A *errs.Error must translate to its public code + 400, body has no results.
	rec := httptest.NewRecorder()
	respond.ErrorFrom(rec, errs.NewOutOfRange("altitude out of range"))

	require.Equal(t, stdhttp.StatusBadRequest, rec.Code)

	var body map[string]any
	require.NoError(t, json.Unmarshal(rec.Body.Bytes(), &body))
	errObj, ok := body["error"].(map[string]any)
	require.True(t, ok)
	assert.Equal(t, "outOfRange", errObj["code"])
	assert.NotEmpty(t, errObj["message"])
	_, hasResults := body["results"]
	assert.False(t, hasResults)
}

func TestErrorFromInvalidInput(t *testing.T) {
	rec := httptest.NewRecorder()
	respond.ErrorFrom(rec, errs.NewInvalidInput("not a number"))

	require.Equal(t, stdhttp.StatusBadRequest, rec.Code)

	var body struct {
		Error struct {
			Code string `json:"code"`
		} `json:"error"`
	}
	require.NoError(t, json.Unmarshal(rec.Body.Bytes(), &body))
	assert.Equal(t, "invalidInput", body.Error.Code)
}

func TestErrorFromUntypedErrorIsInternal(t *testing.T) {
	// A plain error must not leak its message; it becomes 500 INTERNAL_ERROR.
	rec := httptest.NewRecorder()
	respond.ErrorFrom(rec, errors.New("sensitive internal detail"))

	require.Equal(t, stdhttp.StatusInternalServerError, rec.Code)

	var body struct {
		Error struct {
			Code    string `json:"code"`
			Message string `json:"message"`
		} `json:"error"`
	}
	require.NoError(t, json.Unmarshal(rec.Body.Bytes(), &body))
	assert.Equal(t, "INTERNAL_ERROR", body.Error.Code)
	assert.NotContains(t, body.Error.Message, "sensitive internal detail")
}

func TestErrorFromWrappedTypedError(t *testing.T) {
	// errors.As must see a typed error even when wrapped with %w.
	rec := httptest.NewRecorder()
	wrapped := errs.NewInvalidInput("invalid body").Wrap(errors.New("EOF"))
	respond.ErrorFrom(rec, wrapped)

	require.Equal(t, stdhttp.StatusBadRequest, rec.Code)
	var body struct {
		Error struct {
			Code string `json:"code"`
		} `json:"error"`
	}
	require.NoError(t, json.Unmarshal(rec.Body.Bytes(), &body))
	assert.Equal(t, "invalidInput", body.Error.Code)
}

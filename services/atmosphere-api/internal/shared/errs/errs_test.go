package errs_test

import (
	"errors"
	"fmt"
	"net/http"
	"testing"

	"github.com/darioeliseobarboza/atmosphere-api/internal/shared/errs"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestNewOutOfRange(t *testing.T) {
	err := errs.NewOutOfRange("altitude out of range")

	assert.Equal(t, "outOfRange", err.Code)
	assert.Equal(t, "altitude out of range", err.Message)
	assert.Equal(t, http.StatusBadRequest, err.Status())
	assert.Contains(t, err.Error(), "outOfRange")
	assert.Contains(t, err.Error(), "altitude out of range")
}

func TestNewInvalidInput(t *testing.T) {
	err := errs.NewInvalidInput("not a number")

	assert.Equal(t, "invalidInput", err.Code)
	assert.Equal(t, "not a number", err.Message)
	assert.Equal(t, http.StatusBadRequest, err.Status())
}

func TestUnwrap(t *testing.T) {
	cause := errors.New("boom")
	err := errs.NewInvalidInput("decode failed").Wrap(cause)

	// Unwrap returns the wrapped cause.
	require.Equal(t, cause, errors.Unwrap(err))
	// errors.Is sees through the wrap to the cause.
	assert.True(t, errors.Is(err, cause))
}

func TestErrorsAsRecoversTypedError(t *testing.T) {
	// A typed error wrapped with %w must still be recoverable via errors.As.
	wrapped := fmt.Errorf("at boundary: %w", errs.NewOutOfRange("h > 36089"))

	var target *errs.Error
	require.True(t, errors.As(wrapped, &target))
	assert.Equal(t, "outOfRange", target.Code)
	assert.Equal(t, http.StatusBadRequest, target.Status())
}

func TestWrapReturnsSameError(t *testing.T) {
	// Wrap mutates and returns the receiver for fluent use; the code is preserved.
	cause := errors.New("json: cannot unmarshal")
	err := errs.NewInvalidInput("invalid body").Wrap(cause)

	assert.Equal(t, "invalidInput", err.Code)
	assert.Equal(t, cause, errors.Unwrap(err))
}

package logging_test

import (
	"testing"

	"github.com/darioeliseobarboza/atmosphere-api/internal/shared/logging"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestNew(t *testing.T) {
	dir := t.TempDir()

	logger, err := logging.New(dir, false)
	require.NoError(t, err)
	require.NotNil(t, logger)

	// The logger must be usable and closeable without error.
	logger.Info("test message", "key", "value")
	assert.NoError(t, logger.Close())
}

func TestNewDebugEnabled(t *testing.T) {
	dir := t.TempDir()

	logger, err := logging.New(dir, true)
	require.NoError(t, err)
	require.NotNil(t, logger)

	t.Cleanup(func() { _ = logger.Close() })

	logger.Debug("debug message")
}

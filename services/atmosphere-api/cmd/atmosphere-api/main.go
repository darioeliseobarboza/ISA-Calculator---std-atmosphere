package main

import (
	"context"
	"errors"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/darioeliseobarboza/atmosphere-api/internal/calculation"
	apihttp "github.com/darioeliseobarboza/atmosphere-api/internal/http"
	"github.com/darioeliseobarboza/atmosphere-api/internal/shared/logging"
)

// shutdownTimeout bounds how long graceful shutdown waits for in-flight
// requests to drain before the process exits.
const shutdownTimeout = 10 * time.Second

func main() {
	os.Exit(run())
}

// run wires the service together (config -> logger -> server), starts the
// server and blocks until a termination signal triggers a graceful shutdown.
// It returns the process exit code so main stays a thin os.Exit wrapper and
// deferred cleanup (logger.Close) always runs.
func run() int {
	cfg, err := loadConfig()
	if err != nil {
		// No logger yet; bootstrap failure goes to stderr before exit.
		os.Stderr.WriteString("config error: " + err.Error() + "\n")
		return 1
	}

	logger, err := logging.New(cfg.LogDir, cfg.LogDebug)
	if err != nil {
		os.Stderr.WriteString("logger init error: " + err.Error() + "\n")
		return 1
	}
	defer func() { _ = logger.Close() }()

	// Build the calculation engine and its HTTP handler, then mount its routes.
	calcHandler := calculation.NewHandler(calculation.NewService())
	srv := apihttp.NewServer(cfg.HTTPAddr, cfg.CORSAllowedOrigins, apihttp.Mount(calcHandler))

	// Signal-aware context: SIGINT/SIGTERM cancel ctx and start shutdown.
	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()

	serverErr := make(chan error, 1)
	go func() {
		logger.Info("server started", "addr", cfg.HTTPAddr, "env", cfg.Env)
		if err := srv.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
			serverErr <- err
		}
	}()

	select {
	case err := <-serverErr:
		logger.Error("server stopped unexpectedly", "error", err)
		return 1
	case <-ctx.Done():
		logger.Info("shutdown signal received")
	}

	shutdownCtx, cancel := context.WithTimeout(context.Background(), shutdownTimeout)
	defer cancel()
	if err := srv.Shutdown(shutdownCtx); err != nil {
		logger.Error("graceful shutdown failed", "error", err)
		return 1
	}

	logger.Info("server stopped")
	return 0
}

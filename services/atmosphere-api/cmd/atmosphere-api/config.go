package main

import (
	"fmt"
	"strings"

	"github.com/darioeliseobarboza/dotenv"
)

// Config holds all runtime configuration for atmosphere-api. It is the single
// typed source of configuration: nothing else in the service reads the
// environment directly. Construct it with loadConfig.
type Config struct {
	// Env is the runtime environment ("development" | "production").
	Env string
	// HTTPAddr is the address the HTTP server listens on (e.g. ":8080").
	HTTPAddr string
	// LogDir is the directory where structured log files are written.
	LogDir string
	// LogDebug enables debug-level logging.
	LogDebug bool
	// CORSAllowedOrigins is the list of origins allowed for cross-origin requests.
	CORSAllowedOrigins []string
}

// loadConfig reads configuration from the environment (best-effort .env first),
// applying defaults. It fails fast: in production an empty CORS_ALLOWED_ORIGINS
// is a fatal misconfiguration and returns an error.
func loadConfig() (Config, error) {
	// Best-effort: in development a missing .env file is not an error.
	_ = dotenv.Load()

	cfg := Config{
		Env:                dotenv.Get("ENV", "development"),
		HTTPAddr:           dotenv.Get("HTTP_ADDR", ":8080"),
		LogDir:             dotenv.Get("LOG_DIR", "./logs"),
		LogDebug:           dotenv.Get("LOG_DEBUG", "false") == "true",
		CORSAllowedOrigins: splitCSV(dotenv.Get("CORS_ALLOWED_ORIGINS", "")),
	}

	if cfg.Env == "production" && len(cfg.CORSAllowedOrigins) == 0 {
		return Config{}, fmt.Errorf("config: CORS_ALLOWED_ORIGINS is required in production")
	}

	return cfg, nil
}

// splitCSV splits a comma-separated string into a slice, trimming surrounding
// whitespace from each element and dropping empty segments. An empty or
// whitespace-only input yields nil.
func splitCSV(s string) []string {
	var out []string
	for _, part := range strings.Split(s, ",") {
		if v := strings.TrimSpace(part); v != "" {
			out = append(out, v)
		}
	}
	return out
}

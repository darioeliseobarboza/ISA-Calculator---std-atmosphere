---
id: config
display_name: Configuración de entorno (dotenv)
language: golang
description: Env loading via a lightweight .env loader, into a typed Config validated at startup
applies_to: [api, worker, cli]
required_by: []
package: github.com/darioeliseobarboza/dotenv
---

# Configuration (Go, dotenv)

Configuration comes from environment variables loaded with
[dotenv](https://github.com/darioeliseobarboza/dotenv) — a lightweight `.env` loader with a
`Get(key, default)` API. Service-local replacement of the catalog default (caarlos0/env).
Because dotenv has no struct-tags or `required` support, the typed `Config` and its
validation are built **by hand** in one place, **at startup** (fail fast).

## When to use

- Every service. The `Config` struct is the single typed source of configuration; the rest of the code consumes it, never `dotenv.Get` directly.

## Package

```
github.com/darioeliseobarboza/dotenv
```

## Base configuration

```go
// cmd/atmosphere-api/config.go
package main

type Config struct {
	Env                string   // ENV
	HTTPAddr           string   // HTTP_ADDR
	LogDir             string   // LOG_DIR
	LogDebug           bool     // LOG_DEBUG
	CORSAllowedOrigins []string // CORS_ALLOWED_ORIGINS (comma-separated)
}
```

```go
// cmd/atmosphere-api/main.go
import (
	"fmt"
	"strings"

	"github.com/darioeliseobarboza/dotenv"
)

func loadConfig() (Config, error) {
	_ = dotenv.Load() // best-effort in dev; no error if .env is absent

	cfg := Config{
		Env:                dotenv.Get("ENV", "development"),
		HTTPAddr:           dotenv.Get("HTTP_ADDR", ":8080"),
		LogDir:             dotenv.Get("LOG_DIR", "./logs"),
		LogDebug:           dotenv.Get("LOG_DEBUG", "false") == "true",
		CORSAllowedOrigins: splitCSV(dotenv.Get("CORS_ALLOWED_ORIGINS", "")),
	}

	// Manual validation (dotenv has no required/validation): fail fast.
	if cfg.Env == "production" && len(cfg.CORSAllowedOrigins) == 0 {
		return Config{}, fmt.Errorf("load config: CORS_ALLOWED_ORIGINS is required in production")
	}
	return cfg, nil
}

func splitCSV(s string) []string {
	if s == "" {
		return nil
	}
	parts := strings.Split(s, ",")
	for i := range parts {
		parts[i] = strings.TrimSpace(parts[i])
	}
	return parts
}
```

`loadConfig` runs before serving traffic; if a required value is missing or unparseable it
returns an error and `main` exits.

## Structure

- One `Config` struct, defined in `cmd/{service}/config.go`; built and validated in `loadConfig`.
- Parsing/validation is explicit: bools (`== "true"`), durations (`time.ParseDuration`), lists (`splitCSV`). No struct tags.
- A committed `.env.dist` lists every variable with safe placeholder values. The real `.env` is git-ignored.

## Rules

- All configuration is read in **one place** (`loadConfig`) and validated at startup. Fail fast on missing/invalid values.
- The rest of the code receives the typed `Config` (or a sub-struct). **No `dotenv.Get` outside `loadConfig`.**
- Required values are checked manually (no default → return an error). Non-secret values use a default via the second arg of `Get`.
- Secrets come from env, never from committed files or code. `.env` is git-ignored; `.env.dist` documents the keys.
- Durations are parsed to `time.Duration` (`time.ParseDuration`), not kept as raw strings/ints.
- Never log the full config or secret values (see `logging`).

## Framework variant

dotenv is a service-local replacement of the catalog default (caarlos0/env), chosen for its
minimal `Load`/`Get` API. For services that genuinely need layered/file-based config,
`viper` or `koanf` remain acceptable. Document any deviation in `overview.md`.

---
id: logging
display_name: Logging estructurado (slogx)
language: golang
description: Structured logging (console + per-level JSON files), one logger per service
applies_to: [api, worker, cli]
required_by: []
package: github.com/darioeliseobarboza/slogx
---

# Logging (Go, slogx)

Structured logging with [slogx](https://github.com/darioeliseobarboza/slogx): a small
`log/slog`-style logger that writes to the console and to per-level JSON files. Service-local
replacement of the catalog default (zerolog). One logger is built at startup and injected;
request correlation is carried as fields (slogx has no context-scoped child logger).

## When to use

- Any Go service that needs observability: APIs, workers, long-running CLIs.
- atmosphere-api builds one logger in `main` and injects it into the HTTP layer and the ISA engine.

## Package

```
github.com/darioeliseobarboza/slogx
```

## Base configuration

```go
// internal/shared/logging/logging.go
package logging

import "github.com/darioeliseobarboza/slogx"

// New builds the service logger. `dir` is where per-level files are written;
// `debug` toggles the debug level/file.
func New(dir string, debug bool) (*slogx.Logger, error) {
	cfg := slogx.DefaultConfig()
	cfg.Dir = dir
	cfg.InfoEnabled = true
	cfg.WarnEnabled = true
	cfg.ErrorEnabled = true
	cfg.DebugEnabled = debug
	return slogx.New(cfg)
}
```

The logger is created once in `main`, `defer logger.Close()` is registered there, and the
logger is passed as a dependency (`*slogx.Logger`). No package-level global logger.

> In a container, point `Dir` at an ephemeral path or a mounted volume; aggregated logs can
> still be read from the console (stdout) that slogx also writes to.

## How to use

### Logging with fields

```go
logger.Info("calculation done", "altitudeFt", 16404, "method", "analytical")
```

The message is a short static string; variable data goes in **key-value args**, never interpolated into the message.

### Request correlation (no context child logger)

slogx does not provide a context-scoped child logger. Carry the `requestId` (and any base
fields) as args. The `http-server` `requestID` middleware stores the id in the context; a
small helper turns it into args:

```go
// internal/http/middleware.go
type reqIDKey struct{}

func RequestArgs(ctx context.Context) []any {
	if rid, ok := ctx.Value(reqIDKey{}).(string); ok {
		return []any{"requestId", rid}
	}
	return nil
}

// handler / service:
logger.Info("processing request", append(logging.RequestArgs(ctx), "altitudeFt", in.GeopotentialAltitude)...)
```

This preserves correlation per request without a child logger.

### Logging errors

```go
logger.Error("failed to build ISA table", append(logging.RequestArgs(ctx), "err", err)...)
```

Pass the error under an `"err"` key so the full message is captured. Expected domain errors
are logged at `warn` without the cause; unexpected at `error` with the cause.

## Levels

| Level | Use |
|---|---|
| `debug` | Development detail. Off in production by default (`DebugEnabled=false`). |
| `info` | Normal lifecycle events (started, request handled). |
| `warn` | Expected, handled problems (validation rejected, out-of-range input). |
| `error` | Unexpected failures the service recovered from. |

slogx has no `fatal` method: an unrecoverable startup failure is logged with `Error` and the
process exits via `os.Exit(1)` (or `log.Fatal`) in `main`/bootstrap only.

## Rules

- One logger per service, built at startup (`slogx.New`) and injected; `defer logger.Close()` in `main`. No global logger, no `log.Print`/`fmt.Println` in service code.
- Output is **structured** (console + per-level JSON files); levels are toggled via config.
- Messages are short, static, lowercase. Variable data goes in **key-value args**, not in the string.
- Never log: passwords, tokens, API keys, full auth headers, other users' PII.
- Within a request, include the correlation fields via `RequestArgs(ctx)` so every line keeps the `requestId`.
- Log an error **once**, at the boundary (see `error-handling`). Do not log-and-return at every layer.
- Log level and `Dir` are configurable via env (see `config`); default level `info`.

## Framework variant

slogx is a service-local wrapper over the standard library `log/slog` style (key-value args).
This service uses it on purpose, replacing the catalog default (zerolog). Keep one logger for
the service and document the choice in `overview.md`.

## Integration with other conventions

- **http-server**: the `requestID` middleware stores the correlation id in the context; handlers/services pass `RequestArgs(ctx)`.
- **error-handling**: the boundary handler logs the cause of internal errors here, once.
- **config**: log level and `Dir` come from configuration (env).
- **observability**: deferred (out of v1 scope); when added, the trace/span id would be included as fields.

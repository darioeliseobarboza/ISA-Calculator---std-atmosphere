# Reusable Code - atmosphere-api

## Overview

This document lists all reusable code available in the `atmosphere-api` service.
Each category has its own file with detailed documentation. By reading this
index you can see every reusable element available for new features.

Bootstrapped by story **S-001** (service skeleton + `GET /health`).

## Components

N/A (Backend service)

## Utils/Helpers

**Total: 3**

- **WriteJSON** (`internal/http/middleware.go`) - Writes any value as a JSON response with status and `application/json` Content-Type.
- **RequestArgs** (`internal/http/middleware.go`) - Extracts the request correlation id from the context as slog key-value args.
- **splitCSV** (`cmd/atmosphere-api/config.go`) - Splits a comma-separated string into a trimmed, non-empty slice (empty input → nil).

See full details in [utils.md](./utils.md)

## Middlewares

**Total: 4** (plus the `Chain` composer)

- **Chain** (`internal/http/middleware.go`) - Composes middlewares around a handler, outermost first.
- **RequestID** (`internal/http/middleware.go`) - Injects a request correlation id into the context (honors `X-Request-Id`).
- **Recoverer** (`internal/http/middleware.go`) - Converts a downstream panic into a canonical 500 JSON error, keeping the server alive.
- **CORS** (`internal/http/middleware.go`) - Authorizes cross-origin requests against a configurable allow-list; handles preflight.

See full details in [middlewares.md](./middlewares.md)

## Services/Repositories

**Total: 2**

- **NewServer** (`internal/http/server.go`) - Builds the `*http.Server` with `GET /health`, a domain-route mount seam, the middleware chain and bounded timeouts.
- **logging.New** (`internal/shared/logging/logging.go`) - Constructs the single per-service structured logger (slogx).

See full details in [services.md](./services.md)

## Styles

N/A (Backend service)

## Hooks

N/A (Backend service)

## Types/Interfaces

**Total: 2**

- **Config** (`cmd/atmosphere-api/config.go`) - Typed runtime configuration (the single source; nothing else reads the environment).
- **Middleware** (`internal/http/middleware.go`) - `func(http.Handler) http.Handler` alias used by the chain.

See full details in [types.md](./types.md)

## Validators

No validators documented yet.

## Constants

No constants documented yet.

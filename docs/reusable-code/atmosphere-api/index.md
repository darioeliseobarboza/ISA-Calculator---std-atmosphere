# Reusable Code - atmosphere-api

## Overview

This document lists all reusable code available in the `atmosphere-api` service.
Each category has its own file with detailed documentation. By reading this
index you can see every reusable element available for new features.

Bootstrapped by story **S-001** (service skeleton + `GET /health`). Extended by
story **S-004** (ISA analytical engine + `POST /v1/calculate`): the typed error
infrastructure (`errs`), the response writers (`respond`), the unit conversions
(`units`) and the calculation engine (`calculation`).

## Components

N/A (Backend service)

## Utils/Helpers

**Total: 4**

- **WriteJSON** (`internal/http/middleware.go`) - Writes any value as a JSON response with status and `application/json` Content-Type (delegates to `respond.JSON`).
- **WriteError** (`internal/http/middleware.go`) - Translates a domain error into the canonical error envelope at the HTTP boundary (delegates to `respond.ErrorFrom`).
- **RequestArgs** (`internal/http/middleware.go`) - Extracts the request correlation id from the context as slog key-value args.
- **splitCSV** (`cmd/atmosphere-api/config.go`) - Splits a comma-separated string into a trimmed, non-empty slice (empty input → nil).

See full details in [utils.md](./utils.md)

## Response Writers

**Total: 3** (package `internal/shared/respond`)

- **respond.JSON** (`internal/shared/respond/respond.go`) - Canonical JSON success writer (status + `application/json`). Neutral package so both transport and domain handlers can use it without an import cycle.
- **respond.Error** (`internal/shared/respond/respond.go`) - Writes the canonical `{ "error": { code, message } }` envelope with an explicit status/code.
- **respond.ErrorFrom** (`internal/shared/respond/respond.go`) - Translates any error into the envelope: a `*errs.Error` (even wrapped) yields its public code/status; anything else becomes 500 `INTERNAL_ERROR` without leaking internals.

See full details in [respond.md](./respond.md)

## Unit Conversions

**Total: 8** (package `internal/units`)

- **units.FeetFromMeters / MetersFromFeet** (`internal/units/units.go`) - Exact altitude m↔ft (`1 ft = 0.3048 m`).
- **units.RankineFromKelvin** (`internal/units/units.go`) - Temperature K→°R.
- **units.PSFFromPascal** (`internal/units/units.go`) - Pressure Pa→lbf/ft² (psf).
- **units.SlugPerFt3FromKgPerM3** (`internal/units/units.go`) - Density kg/m³→slug/ft³.
- **units.SlugPerFtSecFromPascalSec** (`internal/units/units.go`) - Dynamic viscosity Pa·s→slug/(ft·s).
- **units.Ft2PerSecFromM2PerSec** (`internal/units/units.go`) - Kinematic viscosity m²/s→ft²/s.
- **units.FtPerSecFromMPerSec** (`internal/units/units.go`) - Speed m/s→ft/s.

See full details in [utils.md](./utils.md)

## Middlewares

**Total: 4** (plus the `Chain` composer)

- **Chain** (`internal/http/middleware.go`) - Composes middlewares around a handler, outermost first.
- **RequestID** (`internal/http/middleware.go`) - Injects a request correlation id into the context (honors `X-Request-Id`).
- **Recoverer** (`internal/http/middleware.go`) - Converts a downstream panic into a canonical 500 JSON error, keeping the server alive.
- **CORS** (`internal/http/middleware.go`) - Authorizes cross-origin requests against a configurable allow-list; handles preflight.

See full details in [middlewares.md](./middlewares.md)

## Services/Repositories

**Total: 4**

- **NewServer** (`internal/http/server.go`) - Builds the `*http.Server` with `GET /health`, a domain-route mount seam, the middleware chain and bounded timeouts.
- **logging.New** (`internal/shared/logging/logging.go`) - Constructs the single per-service structured logger (slogx).
- **calculation.Service / NewService** (`internal/calculation/service.go`) - Application layer of the ISA calculation: normalizes altitude to ft, validates the 0–36089 ft range, runs the analytical engine and assembles the `{si, imperial}` response. Stateless, pure.
- **calculation.Handler / NewHandler** (`internal/calculation/handler.go`) - HTTP transport for the calculation module; mounts `POST /v1/calculate` via `Routes(mux)`.

See full details in [services.md](./services.md)

## Domain Engine

**Total: 2** (package `internal/calculation`)

- **calculation.Troposphere** (`internal/calculation/troposphere.go`) - Pure analytical ISA solver for the 0–36089 ft gradient layer: given altitude in ft, returns T, P, ρ, μ (Sutherland), ν, a and the relatives θ/δ/σ/(a/a₀)/(μ/μ₀) in SI.
- **calculation ISA constants** (`internal/calculation/constants.go`) - Exact ISA 1976 base constants (`RStar`, `M0`, `T0`, `P0`, `LapseRate`, `G0`, `Gamma`, `Beta`, `SutherlandS`) plus runtime-derived `R`, `Rho0`, `A0`, `Mu0`, `PressureExponent`.

See full details in [engine.md](./engine.md)

## Styles

N/A (Backend service)

## Hooks

N/A (Backend service)

## Types/Interfaces

**Total: 6**

- **Config** (`cmd/atmosphere-api/config.go`) - Typed runtime configuration (the single source; nothing else reads the environment).
- **Middleware** (`internal/http/middleware.go`) - `func(http.Handler) http.Handler` alias used by the chain.
- **errs.Error** (`internal/shared/errs/errs.go`) - Typed domain error carrying the public `Code` (camelCase, ADR-001), `Message` and an optional wrapped cause; `Status()` maps to the HTTP status. Constructors `NewOutOfRange`, `NewInvalidInput`.
- **MagnitudeValue** (`internal/calculation/dto.go`) - `{ si, imperial }` pair for an absolute magnitude (ADR-002).
- **AltitudeValue** (`internal/calculation/dto.go`) - `{ m, ft }` altitude echo.
- **AtmosphericResult / CalculationRequest / CalculationResponse** (`internal/calculation/dto.go`) - Request/response DTOs for `POST /v1/calculate` with English camelCase JSON tags; FG-3 fields omitted in FG-2.

See full details in [types.md](./types.md)

## Validators

No validators documented yet.

## Constants

ISA 1976 physical constants live with the engine — see **Domain Engine** above and [engine.md](./engine.md).

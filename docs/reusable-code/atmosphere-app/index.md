# Reusable Code - atmosphere-app

## Overview

This document lists all reusable code available in the `atmosphere-app` service.
Each category has its own file with detailed documentation. By reading this
index you can see every reusable element available for new features.

Bootstrapped by story **S-002** (Flutter skeleton). Extended by **S-005** (FG-2
calculator screen): the provisional health domain was removed and superseded by
the `calculator` domain. The cross-cutting elements below are catalogued as
reusable.

## Components

**Total: 1**

- **AppAlert** (`lib/shared/widgets/app_alert.dart`) - Reusable alert banner (icon + message) that announces itself via `Semantics(liveRegion: true)`. Used for validation and system/connection errors. Added in S-005.

See full details in [components.md](./components.md)

## Utils/Helpers

**Total: 1**

- **pumpApp** (`test/helpers/pump_app.dart`) - `WidgetTester` extension that mounts a widget inside `ProviderScope` + `MaterialApp` with the real theme and the localization delegates, and accepts provider overrides. Base helper for every widget test.

See full details in [utils.md](./utils.md)

## Format

**Total: 2**

- **formatSigFigs** (`lib/shared/format/number_format.dart`) - Presentation formatter (`intl`, locale `es`): 5 significant figures, scientific notation `m·10ⁿ` for very small/large magnitudes, decimal `,` separator. Presentation-only (ADR-005). Added in S-005.
- **formatAltitude** (`lib/shared/format/number_format.dart`) - Formats an altitude for the `{m, ft}` echo: thousands `.` / decimal `,`, no scientific notation. Added in S-005.

See full details in [format.md](./format.md)

## Services/Repositories

**Total: 2**

- **ApiClient** (`lib/shared/services/api_client.dart`) - Thin wrapper over `http.Client` that centralizes base URL, explicit timeout and error mapping to `AppException`. Provided via `apiClientProvider`. Exposes `getJson` and `postJson` (`postJson` added in S-005 for `POST /v1/calculate`).
- **CalculationRepository** (`lib/shared/calculation/calculation_repository.dart`) - Port of the `calculator` domain: `calculate(CalculationRequest) -> CalculationResponse`. Impl uses `ApiClient.postJson('/v1/calculate', ...)`; provided via `calculationRepositoryProvider`. Added in S-005.

See full details in [services.md](./services.md)

## Hooks

N/A (Flutter / Riverpod service - no React-style hooks).

## Styles

**Total: 4**

- **AppColors** (`lib/shared/theme/app_colors.dart`) - Semantic color palette (brand, surface, text-variant, border, `success`/`warning`/`info`/`error`, `errorContainer`). Extended with the variant/border/semantic tokens in S-005.
- **AppTypography** (`lib/shared/theme/app_typography.dart`) - Text style tokens (headline, title, body).
- **AppSpacing** (`lib/shared/theme/app_spacing.dart`) - Spacing scale (xs..xl).
- **AppTheme** (`lib/shared/theme/app_theme.dart`) - Builds `ThemeData` from the tokens; passed once to `MaterialApp.router`.

See full details in [styles.md](./styles.md)

## State

**Total: 1**

- **CalculationNotifier / CalculatorState** (`lib/shared/state/calculation_notifier.dart`) - `StateNotifier` of the `calculator` domain with an immutable `CalculatorState` (status `empty`/`loading`/`success`/`validationError`/`connectionError`, `result`, `error`, `errorCode`, last input). Intent method `calculate(...)`. Provided via `calculationProvider`. Added in S-005.

See full details in [state.md](./state.md)

## Types/Interfaces

**Total: 4**

- **AppException** (`lib/shared/errors/app_exception.dart`) - Sealed domain-error hierarchy (`NetworkException`, `NotFoundException`, `UnauthorizedException`, `ValidationException`, `UnexpectedException`) with the `fromResponse(status, body)` factory mapping transport to domain.
- **Calculation models** (`lib/shared/models/`) - `CalculationRequest`, `CalculationResponse` (+ `CalculationInput`, `AtmosphericResult`, `MagnitudeValue` `{si,imperial}`, `AltitudeValue` `{m,ft}`) and the `AltitudeUnit` enum (`m`/`ft`, default `ft`). DTOs of the `POST /v1/calculate` contract (FG-2 slice). Added in S-005.
- **Env** (`lib/shared/config/env.dart`) - Typed, fail-fast environment config (`apiBaseUrl`); `envProvider` overridden in `main`.
- **Routes / routerProvider** (`lib/shared/router/routes.dart`, `lib/shared/router/app_router.dart`) - Path constants + the single `GoRouter` route table provider (root mounts `CalculatorScreen`).

See full details in [types.md](./types.md)

## Validators

No standalone validators yet (numeric-format validation lives inline in `CalculatorScreen`).

## Constants

See **Routes** under Types/Interfaces (`lib/shared/router/routes.dart`).

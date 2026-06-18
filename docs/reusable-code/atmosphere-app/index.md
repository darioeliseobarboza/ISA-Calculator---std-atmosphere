# Reusable Code - atmosphere-app

## Overview

This document lists all reusable code available in the `atmosphere-app` service.
Each category has its own file with detailed documentation. By reading this
index you can see every reusable element available for new features.

Bootstrapped by story **S-002** (Flutter skeleton + provisional health screen).
The health domain itself (repository/state/notifier) is provisional and will be
superseded by the calculator domain in FG-2; only the cross-cutting,
domain-agnostic elements below are catalogued as reusable.

## Components

No reusable widgets yet (the only screen, `HealthScreen`, is provisional).

## Utils/Helpers

**Total: 1**

- **pumpApp** (`test/helpers/pump_app.dart`) - `WidgetTester` extension that mounts a widget inside `ProviderScope` + `MaterialApp` with the real theme and accepts provider overrides. Base helper for every widget test.

See full details in [utils.md](./utils.md)

## Services/Repositories

**Total: 1**

- **ApiClient** (`lib/shared/services/api_client.dart`) - Thin wrapper over `http.Client` that centralizes base URL, explicit timeout and error mapping to `AppException`. Provided via `apiClientProvider`. `getJson` exists today; `postJson` is added in FG-2 for `/v1/calculate`.

See full details in [services.md](./services.md)

## Styles

**Total: 4**

- **AppColors** (`lib/shared/theme/app_colors.dart`) - Semantic color palette (brand, surface, `success`, `error`).
- **AppTypography** (`lib/shared/theme/app_typography.dart`) - Text style tokens (headline, title, body).
- **AppSpacing** (`lib/shared/theme/app_spacing.dart`) - Spacing scale (xs..xl).
- **AppTheme** (`lib/shared/theme/app_theme.dart`) - Builds `ThemeData` from the tokens; passed once to `MaterialApp.router`.

See full details in [styles.md](./styles.md)

## Hooks

N/A (Flutter / Riverpod service - no React-style hooks).

## Types/Interfaces

**Total: 3**

- **AppException** (`lib/shared/errors/app_exception.dart`) - Sealed domain-error hierarchy (`NetworkException`, `NotFoundException`, `UnauthorizedException`, `ValidationException`, `UnexpectedException`) with the `fromResponse(status, body)` factory mapping transport to domain.
- **Env** (`lib/shared/config/env.dart`) - Typed, fail-fast environment config (`apiBaseUrl`); `envProvider` overridden in `main`.
- **Routes / routerProvider** (`lib/shared/router/routes.dart`, `lib/shared/router/app_router.dart`) - Path constants + the single `GoRouter` route table provider.

See full details in [types.md](./types.md)

## Validators

No validators documented yet.

## Constants

See **Routes** under Types/Interfaces (`lib/shared/router/routes.dart`).

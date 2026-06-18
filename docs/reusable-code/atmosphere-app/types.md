# Reusable Code - Types/Interfaces - atmosphere-app

## Overview

Cross-cutting domain types: the sealed error hierarchy, the typed environment
config, and the router contract. All are domain-agnostic and reused in FG-2.

## AppException

**Location:** `lib/shared/errors/app_exception.dart`
**Description:** Sealed base for all domain errors. Widgets and notifiers handle
`AppException`, never raw platform/transport exceptions. The `fromResponse`
factory maps transport (HTTP status + body) to a domain subtype; `status == null`
means "no network / timeout". The 400 case parses the API error shape
`{ "error": { "code", "message" } }` (ADR-001) into a `ValidationException`,
reused by `/v1/calculate` in FG-2.

**Interface:**
```dart
sealed class AppException implements Exception {
  const AppException(this.message);
  final String message;
  factory AppException.fromResponse(int? status, dynamic body);
}
class NetworkException     extends AppException { ... } // sin red / timeout
class NotFoundException    extends AppException { ... } // 404
class UnauthorizedException extends AppException { ... } // 401
class ValidationException  extends AppException { final Map<String, String> fields; } // 400
class UnexpectedException  extends AppException { ... } // otros >= 400
```

**Usage:**
```dart
try {
  await repository.check();
} on AppException catch (e) {
  state = state.copyWith(status: HealthStatus.error, error: e.message);
}
```

---

## Env

**Location:** `lib/shared/config/env.dart`
**Description:** Typed, immutable environment config loaded once at startup
(fail-fast). The app consumes the typed `Env`, never `dotenv.env[...]` directly.
`envProvider` is defined as `throw UnimplementedError()` and overridden in `main`
with the value built from the loaded `.env`. Re-exported from
`lib/shared/providers/env_provider.dart`.

**Interface:**
```dart
class Env {
  final String apiBaseUrl;
  factory Env.fromDotenv(); // throws StateError('missing env API_BASE_URL') if absent/empty
}
final envProvider = Provider<Env>((_) => throw UnimplementedError());
```

**Usage:**
```dart
// main.dart
await dotenv.load(fileName: '.env');
final env = Env.fromDotenv();
runApp(ProviderScope(overrides: [envProvider.overrideWithValue(env)], child: const App()));
```

---

## Routes / routerProvider

**Location:** `lib/shared/router/routes.dart`, `lib/shared/router/app_router.dart`
**Description:** `Routes` holds path constants (no literal route strings in
widgets); `routerProvider` exposes the single `GoRouter` route table with an
`errorBuilder` (404). No session guards (no auth, ADR-003). FG-2 adds the
calculator route here.

**Interface:**
```dart
abstract final class Routes { static const String root = '/'; }
final routerProvider = Provider<GoRouter>((ref) { ... });
```

**Usage:**
```dart
// main.dart
final router = ref.watch(routerProvider);
return MaterialApp.router(routerConfig: router, theme: AppTheme.dark());
```

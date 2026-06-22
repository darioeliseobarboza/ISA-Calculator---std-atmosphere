# Reusable Code - Types/Interfaces - atmosphere-app

## Overview

Cross-cutting domain types: the sealed error hierarchy, the `calculator` DTOs,
the typed environment config, and the router contract.

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
  final response = await repository.calculate(request);
} on ValidationException catch (e) {
  state = state.copyWith(status: CalculatorStatus.validationError, error: e.message);
} on NetworkException catch (e) {
  state = state.copyWith(status: CalculatorStatus.connectionError, error: e.message);
}
```

---

## Calculation models

**Location:** `lib/shared/models/calculation_request.dart`,
`lib/shared/models/calculation_response.dart`,
`lib/shared/models/altitude_unit.dart`
**Description:** Hand-written DTOs of the `POST /v1/calculate` contract (FG-2
slice — `models-serialization` manual variant, consistent with the rest of the
app). `CalculationRequest.toJson()` emits `{geopotentialAltitude, altitudeUnit}`
and never `tableStep`. `CalculationResponse.fromJson(...)` parses `input`
(`AltitudeValue` `{m,ft}` + `AltitudeUnit`) and `results.analytical`
(`AtmosphericResult`: 6 absolute `MagnitudeValue` `{si,imperial}` + 5 relative
`num`); `interpolation`/`comparison`/`table` are optional and stay `null` in
FG-2 (additive contract). `AltitudeUnit` (de)serializes by wire value `m`/`ft`
(default `ft`), not enum index.

**Interface:**
```dart
enum AltitudeUnit { meters('m'), feet('ft'); final String wire; static AltitudeUnit fromWire(String); }

class CalculationRequest {
  const CalculationRequest({required num geopotentialAltitude, AltitudeUnit altitudeUnit = AltitudeUnit.feet});
  Map<String, dynamic> toJson(); // { geopotentialAltitude, altitudeUnit }
}

class MagnitudeValue { final num si, imperial; }      // absolute magnitude
class AltitudeValue  { final num meters, feet; }       // {m, ft}
class AtmosphericResult { final String method; final MagnitudeValue temperature, pressure, ...; final num theta, delta, sigma, speedOfSoundRatio, viscosityRatio; }
class CalculationResponse {
  final CalculationInput input;             // geopotentialAltitude {m,ft} + altitudeUnit
  final AtmosphericResult analytical;
  final AtmosphericResult? interpolation;   // null in FG-2
  factory CalculationResponse.fromJson(Map<String, dynamic> json);
}
```

**Usage:**
```dart
final req = const CalculationRequest(geopotentialAltitude: 16404, altitudeUnit: AltitudeUnit.feet);
final res = CalculationResponse.fromJson(json);
res.analytical.temperature.si; // 255.65
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
`errorBuilder` (404). No session guards (no auth, ADR-003). The root route (`/`)
mounts `CalculatorScreen` (S-005 — replaced the provisional health screen).

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

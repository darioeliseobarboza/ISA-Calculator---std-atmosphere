# Reusable Code - Services - atmosphere-app

## Overview

The HTTP plumbing of the app: a single thin `ApiClient` over `http.Client`,
provided via Riverpod. Repositories depend on it; widgets/notifiers never touch
`http` directly.

## ApiClient

**Location:** `lib/shared/services/api_client.dart`
**Description:** Thin wrapper over `http.Client` (the `http` package has no
interceptors, so URL building, the explicit `.timeout(...)`, safe JSON decoding
of empty bodies and error mapping to `AppException` are centralized here). Maps
`status >= 400` via `AppException.fromResponse` and transport failures
(`SocketException`, `TimeoutException`, `http.ClientException`) to
`NetworkException`. Never logs full responses or headers. Provided by
`apiClientProvider`, which reads `baseUrl` from `envProvider`.

**Signature:**
```dart
class ApiClient {
  ApiClient({required String baseUrl, required http.Client inner, required Duration timeout});
  Future<Map<String, dynamic>> getJson(String path);
  Future<Map<String, dynamic>> postJson(String path, Map<String, dynamic> body); // S-005
}

final apiClientProvider = Provider<ApiClient>((ref) { ... });
```

`postJson` (added in S-005) mirrors `getJson`: sends `Content-Type:
application/json`, `jsonEncode(body)`, explicit `.timeout(...)`, and the same
`status >= 400` / transport-failure mapping to `AppException`.

**Usage:**
```dart
// Inside a repository (DI via Riverpod, never `new` of http.Client in a widget):
final api = ref.read(apiClientProvider);
final json = await api.postJson('/v1/calculate', request.toJson()); // -> Map, or throws AppException
```

---

## CalculationRepository

**Location:** `lib/shared/calculation/calculation_repository.dart`
(impl `calculation_repository_impl.dart`)
**Description:** Port of the `calculator` domain. Notifiers depend on this
interface, never on `ApiClient`/`http` directly. The impl maps the request to
JSON, calls `ApiClient.postJson('/v1/calculate', ...)` and decodes the response
to domain (`CalculationResponse`); `AppException` from the client propagates
unchanged. Provided via `calculationRepositoryProvider` (built from
`apiClientProvider`). Added in S-005.

**Signature:**
```dart
abstract interface class CalculationRepository {
  Future<CalculationResponse> calculate(CalculationRequest request);
}

final calculationRepositoryProvider = Provider<CalculationRepository>((ref) =>
    CalculationRepositoryImpl(ref.read(apiClientProvider)));
```

**Usage:**
```dart
final repo = ref.read(calculationRepositoryProvider);
final response = await repo.calculate(const CalculationRequest(geopotentialAltitude: 16404));
```

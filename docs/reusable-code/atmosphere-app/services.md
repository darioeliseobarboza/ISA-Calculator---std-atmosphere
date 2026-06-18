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
  // postJson(...) added in FG-2 for POST /v1/calculate
}

final apiClientProvider = Provider<ApiClient>((ref) { ... });
```

**Usage:**
```dart
// Inside a repository (DI via Riverpod, never `new` of http.Client in a widget):
final api = ref.read(apiClientProvider);
final json = await api.getJson('/health'); // -> Map, or throws AppException
```

---
id: networking
display_name: Networking (http + repository)
language: flutter
description: HTTP client (package:http) wrapped in an ApiClient, repository layer, and error mapping
applies_to: [frontend]
required_by: []
package: http
---

# Networking (Flutter, http + repository)

Data access through the official [`http`](https://pub.dev/packages/http) client wrapped by a
thin **`ApiClient`** and a **repository** per domain. Widgets and notifiers depend on
repositories (interfaces), never on the raw client. Because `http` has no interceptors,
cross-cutting concerns (base URL, timeouts, headers, error mapping) live in the `ApiClient`.
Service-local replacement of the catalog default (dio), per ADR-001.

## When to use

- Any app that talks to a backend over HTTP. atmosphere-app calls `atmosphere-api` (`POST /v1/calculate`, `GET /health`).
- For real-time transports, see `## Real-time variant` — not used in this app.

## Package

```
http                 # official Dart HTTP client
```

## Structure

```
lib/shared/
├── services/
│   └── api_client.dart          # configured ApiClient over http.Client (base URL, timeout, error mapping)
└── {domain}/
    ├── {domain}_repository.dart      # interface (the port)
    └── {domain}_repository_impl.dart # uses ApiClient + maps DTO -> domain
```

## How to use

### Configured client (provided via Riverpod)

```dart
// lib/shared/services/api_client.dart
final apiClientProvider = Provider<ApiClient>((ref) {
  final env = ref.read(envProvider);
  return ApiClient(baseUrl: env.apiBaseUrl, inner: http.Client(), timeout: const Duration(seconds: 15));
});

class ApiClient {
  ApiClient({required this.baseUrl, required http.Client inner, required this.timeout}) : _inner = inner;
  final String baseUrl;
  final Duration timeout;
  final http.Client _inner;

  Future<Map<String, dynamic>> postJson(String path, Map<String, dynamic> body) async {
    final res = await _inner
        .post(Uri.parse('$baseUrl$path'),
            headers: const {'Content-Type': 'application/json'}, body: jsonEncode(body))
        .timeout(timeout);
    final decoded = res.body.isEmpty ? <String, dynamic>{} : jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 400) {
      throw AppException.fromResponse(res.statusCode, decoded); // maps {"error":{...}}
    }
    return decoded;
  }
}
```

### Repository (interface + impl)

```dart
// lib/shared/calculation/calculation_repository.dart
abstract interface class CalculationRepository {
  Future<CalculationResult> calculate(CalculationRequest req);
}

class CalculationRepositoryImpl implements CalculationRepository {
  CalculationRepositoryImpl(this._api);
  final ApiClient _api;

  @override
  Future<CalculationResult> calculate(CalculationRequest req) async {
    final json = await _api.postJson('/v1/calculate', req.toJson());
    return CalculationResponseDto.fromJson(json).toDomain();
  }
}

final calculationRepositoryProvider = Provider<CalculationRepository>(
  (ref) => CalculationRepositoryImpl(ref.read(apiClientProvider)),
);
```

### Error mapping (in the ApiClient, no interceptor)

```dart
// turns transport errors into domain AppExceptions (see error-handling).
// http has no interceptors, so mapping happens where the response is read.
factory AppException.fromResponse(int status, Map<String, dynamic> body) {
  final err = body['error'] as Map<String, dynamic>?;
  return AppException(code: err?['code'] as String? ?? 'unknown', message: err?['message'] as String? ?? 'request failed', status: status);
}
```

## Rules

- Notifiers/widgets depend on a **repository interface**, never on `http.Client`/`ApiClient` directly. The client is an implementation detail behind the repository.
- One repository per domain, provided via Riverpod (see `state-management`).
- Base URL, timeouts, and headers come from the **`ApiClient`** + `env-config` — never hardcoded per call (`http` has no interceptors, so the wrapper centralizes them).
- Repositories return **domain models**; DTO→domain mapping happens at this layer (see `models-serialization`). Transport types do not leak to the UI.
- Transport errors are mapped to domain `AppException`s **in the `ApiClient`/repository** based on status + body `{"error":{code,message}}` (see `error-handling`). Widgets handle domain errors, not raw `http` exceptions.
- Every request has an explicit timeout (`.timeout(...)`). Cancel/ignore in-flight requests on dispose when relevant.
- Never log full responses or auth headers.

## Real-time variant

**N/A for this app.** atmosphere-app uses synchronous HTTP request/response only (one `POST /v1/calculate` per calculation). If a real-time transport were added later, the repository/service pattern would stay the same — only the client behind the repository would change.

## Integration with other conventions

- **models-serialization**: repositories map DTOs (`CalculationResponseDto`) to domain models.
- **error-handling**: the `ApiClient` translates transport errors to `AppException` (from the `{"error":{...}}` shape).
- **state-management**: repositories are provided and consumed by notifiers (Riverpod).
- **env-config**: `apiBaseUrl` comes from the typed env (`flutter_dotenv`).

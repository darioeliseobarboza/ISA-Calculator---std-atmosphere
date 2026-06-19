# atmosphere-app

Flutter frontend for the ISA (International Standard Atmosphere) calculator.
Targets **Windows, Linux and Web** (ADR-001). The app does **not** calculate: it
presents what `atmosphere-api` returns. State with Riverpod, HTTP with the `http`
package wrapped by a thin `ApiClient`, config via `flutter_dotenv`, routing with
`go_router` (ADR-001).

This skeleton (story S-002) ships a **provisional** health screen that pings
`GET /health` and shows whether the system is alive or unreachable. The real
calculator screen arrives with FG-2.

## Configuration

A single environment variable, loaded once at startup and validated **fail-fast**
(the app aborts if it is missing). See [`.env.example`](./.env.example); copy it
to `.env` for local dev (`.env` is git-ignored, bundled as an asset).

| Variable | Example | Required | Description |
|----------|---------|----------|-------------|
| `API_BASE_URL` | `http://localhost:8080` | **yes** | Base URL of `atmosphere-api` (no trailing slash). The web target never assumes same-origin — the base URL always comes from here. |

```bash
# from services/atmosphere-app
cp .env.example .env
```

## Run locally

The three targets share the same code; pick a device:

```bash
# from services/atmosphere-app
flutter pub get

flutter run -d chrome     # web
flutter run -d linux      # Linux desktop
flutter run -d windows    # Windows desktop
```

With the API up and `API_BASE_URL` pointing at it, the health screen shows
**"Sistema vivo"**. If the API is down / unreachable / returns `>= 400`, it shows
**"Error de conexión"**.

## Test

```bash
flutter analyze           # static analysis (must be clean)
flutter test              # full unit + widget suite
dart format .             # formatting (unformatted code does not merge)
```

## Build

### Web (containerized — `atmosphere-web`)

Per ADR-004, the web target is served by an nginx container. The image is a
multi-stage build: a pinned `ghcr.io/cirruslabs/flutter:3.44.0` builder runs
`flutter build web`, then nginx serves the static output with SPA fallback.
(The local SDK is `3.44.1`, but that exact tag is not published on GHCR, so the
builder image pins the latest published patch of the same minor, `3.44.0`.)
`API_BASE_URL` is injected at **build time** (never hardcoded):

```bash
# from services/atmosphere-app
docker build \
  --build-arg API_BASE_URL=https://api.example.com \
  -t atmosphere-web:dev .

docker run --rm -p 8081:80 atmosphere-web:dev
# open http://localhost:8081
```

A plain web build without Docker:

```bash
flutter build web --release        # output in build/web/
```

> Compose orchestration (dev/prod overrides, ingress network) lives in `docker/`
> and is delivered by story S-003 — this service only ships its `Dockerfile`.

### Desktop (native binaries — NOT containerized)

Per ADR-004, the desktop targets are native binaries, not containers:

```bash
flutter build windows --release    # output in build/windows/x64/runner/Release/
flutter build linux --release      # output in build/linux/x64/release/bundle/
```

The resulting executable reads `.env` from its bundle (shipped as a Flutter
asset), so set `API_BASE_URL` before building or alongside the distributed app.

## Cross-origin (web)

When the web app is served from one origin and the API from another, the
`GET /health` call must work without CORS errors. CORS is enabled on
`atmosphere-api` (`CORS_ALLOWED_ORIGINS`, ADR-004); the app does nothing special
beyond never assuming same-origin — `API_BASE_URL` is always absolute.

## Layout

```
lib/
  main.dart                 entry: dotenv.load, Env (fail-fast), ProviderScope, MaterialApp.router
  screens/health/           provisional health screen (loading / alive / error)
  shared/
    config/                 typed Env + envProvider
    errors/                 sealed AppException + fromResponse
    health/                 health domain: repository (port + impl)
    services/               ApiClient over http.Client
    state/                  HealthState + HealthNotifier
    providers/              Riverpod providers (DI)
    router/                 GoRouter table + path constants
    theme/                  design tokens (colors, typography, spacing)
test/                       mirrors lib/ (helpers/, unit, widget)
Dockerfile, nginx.conf      web image (nginx + SPA fallback)
```

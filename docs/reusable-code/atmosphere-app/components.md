# Reusable Code - Components - atmosphere-app

## Overview

Reusable widgets built on the `theming` tokens (the `app-calculadora` design
system is still a placeholder — DS Gap — so primitives are assembled from tokens
and the accessibility/content guidelines). Added in S-005.

## AppAlert

**Location:** `lib/shared/widgets/app_alert.dart`
**Description:** Alert banner (icon + message) for error feedback. Communicates
state with icon + color + text (not color alone — a11y) and announces itself to
assistive tech via `Semantics(liveRegion: true)`. Default icon is
`error_outline`; the connection-error variant passes `Icons.wifi_off`. Used by
the calculator's validation and system alerts.

**Signature:**
```dart
class AppAlert extends StatelessWidget {
  const AppAlert({super.key, required String message, IconData icon = Icons.error_outline});
}
```

**Usage:**
```dart
const AppAlert(key: Key('validation-alert'), message: 'Altitud fuera de rango: …');
AppAlert(message: 'No se pudo conectar…', icon: Icons.wifi_off);
```

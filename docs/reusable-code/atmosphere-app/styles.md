# Reusable Code - Styles - atmosphere-app

## Overview

Design tokens (convention `theming`). Widgets consume these — no inline
`Color(0x...)`, magic `EdgeInsets`, or ad-hoc `TextStyle`. `AppTheme` assembles
them into a single `ThemeData`.

## AppColors

**Location:** `lib/shared/theme/app_colors.dart`
**Description:** Semantic color palette as `static const`. Brand/surface colors,
secondary text + border tokens, and the semantic `success`/`warning`/`info`/
`error` plus `errorContainer` (alert background). The variant/border/semantic
tokens were added in S-005 for the calculator UI (per `theming` — no inline
`Color(0x...)` in feature widgets).

**Interface:**
```dart
abstract final class AppColors {
  static const Color primary, background, surface, onSurface;
  static const Color onSurfaceVariant; // texto secundario
  static const Color border;           // bordes neutros
  static const Color success, warning, info, error;
  static const Color errorContainer;   // fondo de alertas de error
}
```

**Usage:**
```dart
Text(label, style: AppTypography.body.copyWith(color: AppColors.onSurfaceVariant));
```

---

## AppTypography

**Location:** `lib/shared/theme/app_typography.dart`
**Description:** Text style tokens (`headline`, `title`, `body`) colored from
`AppColors`.

**Interface:**
```dart
abstract final class AppTypography {
  static const TextStyle headline, title, body;
}
```

---

## AppSpacing

**Location:** `lib/shared/theme/app_spacing.dart`
**Description:** Spacing scale to avoid magic numbers in layout.

**Interface:**
```dart
abstract final class AppSpacing {
  static const double xs = 4, sm = 8, md = 16, lg = 24, xl = 32;
}
```

**Usage:**
```dart
const SizedBox(height: AppSpacing.md);
```

---

## AppTheme

**Location:** `lib/shared/theme/app_theme.dart`
**Description:** Builds the app's `ThemeData` (Material 3, dark) from the tokens.
Constructed once and passed to `MaterialApp.router`.

**Interface:**
```dart
abstract final class AppTheme {
  static ThemeData dark();
}
```

**Usage:**
```dart
MaterialApp.router(theme: AppTheme.dark(), routerConfig: router);
```

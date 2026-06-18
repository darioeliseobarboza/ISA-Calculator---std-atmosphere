# Reusable Code - Styles - atmosphere-app

## Overview

Design tokens (convention `theming`). Widgets consume these — no inline
`Color(0x...)`, magic `EdgeInsets`, or ad-hoc `TextStyle`. `AppTheme` assembles
them into a single `ThemeData`.

## AppColors

**Location:** `lib/shared/theme/app_colors.dart`
**Description:** Semantic color palette as `static const`. Includes brand/surface
colors and the semantic `success` / `error` used to distinguish the health
screen's alive vs error states.

**Interface:**
```dart
abstract final class AppColors {
  static const Color primary, background, surface, onSurface;
  static const Color success; // verde - estado vivo
  static const Color error;   // rojo  - estado error
}
```

**Usage:**
```dart
Icon(Icons.check_circle, color: AppColors.success);
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

# Reusable Code - Format - atmosphere-app

## Overview

Number presentation helpers (`intl`, locale `es`). Presentation-only rounding
(ADR-005 — the frontend never calculates). Added in S-005.

## formatSigFigs

**Location:** `lib/shared/format/number_format.dart`
**Description:** Formats a magnitude with 5 significant figures for display.
Decimal with `,` separator for "normal" magnitudes; scientific notation
`m·10ⁿ` (mantissa with `,`, Unicode superscript exponent) for very small
(`abs < 1e-2`) or large (`abs >= 1e4`) magnitudes (μ, ν, P, ρ imperial); `0`
renders as `"0"` (never scientific). Thresholds are calibrated against the
calculator wireframe example values.

**Signature:**
```dart
String formatSigFigs(num value, {int sig = 5});
```

**Usage:**
```dart
formatSigFigs(255.65);    // "255,65"
formatSigFigs(54020);     // "5,4020·10⁴"
formatSigFigs(1.6286e-5); // "1,6286·10⁻⁵"
```

---

## formatAltitude

**Location:** `lib/shared/format/number_format.dart`
**Description:** Formats an altitude for the `{m, ft}` echo badge: thousands `.`
/ decimal `,` (locale `es`), no scientific notation (distinct from
`formatSigFigs`, which is for ISA magnitudes).

**Signature:**
```dart
String formatAltitude(num value);
```

**Usage:**
```dart
formatAltitude(5000.0); // "5.000"
formatAltitude(16404);  // "16.404"
```

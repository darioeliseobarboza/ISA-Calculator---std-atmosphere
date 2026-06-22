# Reusable Code - Utils/Helpers - atmosphere-app

## Overview

Test helpers shared across the suite (convention `testing`). `test/` mirrors
`lib/`.

## pumpApp

**Location:** `test/helpers/pump_app.dart`
**Description:** `WidgetTester` extension that mounts a widget inside a
`ProviderScope` + `MaterialApp` using the real `AppTheme.dark()`, the `es` locale
and the `AppLocalizations` + global Material/Widgets/Cupertino delegates (so
widgets that read `AppLocalizations.of(context)` resolve), and accepts a list of
provider `overrides`. The base for every widget test (override providers with
fakes/mocks, then `pumpApp(widget, overrides: [...])`).

**Signature:**
```dart
extension PumpApp on WidgetTester {
  Future<void> pumpApp(Widget child, {List<Override> overrides = const []});
}
```

**Usage:**
```dart
await tester.pumpApp(
  const CalculatorScreen(),
  overrides: [calculationProvider.overrideWith((ref) => FakeCalculationNotifier(state))],
);
```

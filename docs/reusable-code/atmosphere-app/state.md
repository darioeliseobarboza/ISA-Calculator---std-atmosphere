# Reusable Code - State - atmosphere-app

## Overview

Riverpod `StateNotifier`s + immutable state classes (convention
`state-management`). State lives in `shared/state/`, wired via providers in
`shared/providers/`. Added in S-005.

## CalculationNotifier / CalculatorState

**Location:** `lib/shared/state/calculation_notifier.dart`
**Description:** `StateNotifier` of the `calculator` domain. Exposes the intent
method `calculate({geopotentialAltitude, altitudeUnit})` which transitions
`loading → success | validationError | connectionError`, catching
`AppException` into state fields (never rethrows). `CalculatorState` is immutable
with `copyWith` (sentinel-based so nullable fields can be cleared). It keeps the
last input (`lastAltitude`/`lastUnit`) so the user can retry after an error.
Exposed via `calculationProvider` (`StateNotifierProvider`), which builds the
notifier from `calculationRepositoryProvider`.

**Interface:**
```dart
enum CalculatorStatus { empty, loading, success, validationError, connectionError }

class CalculatorState {
  const CalculatorState({CalculatorStatus status, CalculationResponse? result,
    String? error, String? errorCode, num? lastAltitude, AltitudeUnit lastUnit});
  CalculatorState copyWith({...});
}

class CalculationNotifier extends StateNotifier<CalculatorState> {
  Future<void> calculate({required num geopotentialAltitude, AltitudeUnit altitudeUnit});
}

final calculationProvider =
    StateNotifierProvider<CalculationNotifier, CalculatorState>((ref) { ... });
```

**Usage:**
```dart
ref.read(calculationProvider.notifier)
   .calculate(geopotentialAltitude: 16404, altitudeUnit: AltitudeUnit.feet);
final state = ref.watch(calculationProvider); // status / result / error
```

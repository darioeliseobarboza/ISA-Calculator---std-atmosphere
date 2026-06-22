import 'package:atmosphere_app/shared/calculation/calculation_repository.dart';
import 'package:atmosphere_app/shared/models/altitude_unit.dart';
import 'package:atmosphere_app/shared/models/calculation_request.dart';
import 'package:atmosphere_app/shared/models/calculation_response.dart';
import 'package:atmosphere_app/shared/state/calculation_notifier.dart';

/// Repository de cálculo que nunca toca la red (tests deterministas).
class _NoopCalculationRepository implements CalculationRepository {
  const _NoopCalculationRepository();

  @override
  Future<CalculationResponse> calculate(CalculationRequest request) async {
    throw UnimplementedError('repo no usado en este fake');
  }
}

/// Notifier de cálculo seedeado a un estado fijo. [calculate] es no-op para que
/// el estado lo fije el test (override del `calculationProvider` en widget tests).
class FakeCalculationNotifier extends CalculationNotifier {
  FakeCalculationNotifier(CalculatorState initial)
    : super(const _NoopCalculationRepository()) {
    state = initial;
  }

  @override
  Future<void> calculate({
    required num geopotentialAltitude,
    AltitudeUnit altitudeUnit = AltitudeUnit.feet,
  }) async {
    // No-op.
  }
}

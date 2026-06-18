import 'package:atmosphere_app/shared/errors/app_exception.dart';
import 'package:atmosphere_app/shared/health/health_repository.dart';
import 'package:atmosphere_app/shared/health/health_status.dart';
import 'package:atmosphere_app/shared/state/health_notifier.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockHealthRepository extends Mock implements HealthRepository {}

void main() {
  late _MockHealthRepository repository;
  late HealthNotifier notifier;

  setUp(() {
    repository = _MockHealthRepository();
    notifier = HealthNotifier(repository);
  });

  group('HealthNotifier.checkHealth', () {
    test('TS-8: éxito -> estado alive (pasa por loading antes)', () async {
      when(() => repository.check()).thenAnswer((_) async {});

      final seenStatuses = <HealthStatus>[];
      notifier.addListener(
        (state) => seenStatuses.add(state.status),
        fireImmediately: false,
      );

      await notifier.checkHealth();

      expect(notifier.state.status, HealthStatus.alive);
      expect(notifier.state.error, isNull);
      expect(seenStatuses, contains(HealthStatus.loading));
    });

    test('TS-9: error -> estado error con el mensaje, sin relanzar', () async {
      when(
        () => repository.check(),
      ).thenThrow(const NetworkException('network error'));

      // No debe relanzar.
      await expectLater(notifier.checkHealth(), completes);

      expect(notifier.state.status, HealthStatus.error);
      expect(notifier.state.error, 'network error');
    });
  });
}

import 'package:atmosphere_app/screens/health/health_screen.dart';
import 'package:atmosphere_app/shared/health/health_status.dart';
import 'package:atmosphere_app/shared/providers/health_provider.dart';
import 'package:atmosphere_app/shared/router/app_router.dart';
import 'package:atmosphere_app/shared/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fakes.dart';
import '../../helpers/pump_app.dart';

void main() {
  group('HealthScreen', () {
    testWidgets(
      'TS-10: estado alive muestra "sistema vivo" con color success',
      (tester) async {
        await tester.pumpApp(
          const HealthScreen(),
          overrides: [
            healthProvider.overrideWith(
              (ref) => FakeHealthNotifier(HealthStatus.alive),
            ),
          ],
        );
        await tester.pump();

        expect(find.text('Sistema vivo'), findsOneWidget);
        expect(find.text('API disponible'), findsOneWidget);

        final icon = tester.widget<Icon>(
          find.byKey(HealthScreen.statusIconKey),
        );
        expect(icon.color, AppColors.success);
      },
    );

    testWidgets(
      'TS-11: estado error muestra "error de conexión" con color error y NO "vivo"',
      (tester) async {
        await tester.pumpApp(
          const HealthScreen(),
          overrides: [
            healthProvider.overrideWith(
              (ref) => FakeHealthNotifier(HealthStatus.error, error: 'boom'),
            ),
          ],
        );
        await tester.pump();

        expect(find.text('Error de conexión'), findsOneWidget);
        expect(find.text('Sistema vivo'), findsNothing);

        final icon = tester.widget<Icon>(
          find.byKey(HealthScreen.statusIconKey),
        );
        expect(icon.color, AppColors.error);
      },
    );

    testWidgets('TS-12: estado loading muestra indicador de carga', (
      tester,
    ) async {
      await tester.pumpApp(
        const HealthScreen(),
        overrides: [
          healthProvider.overrideWith(
            (ref) => FakeHealthNotifier(HealthStatus.loading),
          ),
        ],
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('TS-13: el router resuelve "/" a HealthScreen', (tester) async {
      final container = ProviderContainer(
        overrides: [
          healthProvider.overrideWith(
            (ref) => FakeHealthNotifier(HealthStatus.alive),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: container.read(routerProvider),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(HealthScreen), findsOneWidget);
    });
  });
}

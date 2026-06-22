import 'package:atmosphere_app/l10n/app_localizations.dart';
import 'package:atmosphere_app/screens/calculator/calculator_screen.dart';
import 'package:atmosphere_app/shared/calculation/calculation_repository.dart';
import 'package:atmosphere_app/shared/models/calculation_request.dart';
import 'package:atmosphere_app/shared/models/calculation_response.dart';
import 'package:atmosphere_app/shared/providers/calculation_provider.dart';
import 'package:atmosphere_app/shared/router/app_router.dart';
import 'package:atmosphere_app/shared/router/routes.dart';
import 'package:atmosphere_app/shared/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Repo noop: el router monta el screen pero no se dispara ningún cálculo.
class _NoopRepository implements CalculationRepository {
  const _NoopRepository();
  @override
  Future<CalculationResponse> calculate(CalculationRequest request) =>
      throw UnimplementedError();
}

void main() {
  testWidgets('TS-16: la ruta raíz monta CalculatorScreen (reemplaza health)', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        calculationRepositoryProvider.overrideWithValue(
          const _NoopRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);

    final router = container.read(routerProvider);
    expect(Routes.root, '/');

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          theme: AppTheme.dark(),
          locale: const Locale('es'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(CalculatorScreen), findsOneWidget);
  });
}

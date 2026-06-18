import 'package:atmosphere_app/shared/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Monta [child] dentro de un `ProviderScope` + `MaterialApp` con el tema real
/// de la app (helper de la convención `testing`). Permite overridear providers.
extension PumpApp on WidgetTester {
  Future<void> pumpApp(Widget child, {List<Override> overrides = const []}) {
    return pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: MaterialApp(theme: AppTheme.dark(), home: child),
      ),
    );
  }
}

import 'package:atmosphere_app/l10n/app_localizations.dart';
import 'package:atmosphere_app/shared/config/env.dart';
import 'package:atmosphere_app/shared/router/app_router.dart';
import 'package:atmosphere_app/shared/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Config cargada y validada una sola vez al arranque (fail-fast).
  await dotenv.load(fileName: '.env');
  final env = Env.fromDotenv();

  runApp(
    ProviderScope(
      overrides: [envProvider.overrideWithValue(env)],
      child: const App(),
    ),
  );
}

/// Raíz de la app: tema desde tokens + router por URL (convenciones `theming`
/// y `navigation`).
class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'atmosphere-app',
      theme: AppTheme.dark(),
      routerConfig: router,
      // App en español (v1, convención `i18n`).
      locale: const Locale('es'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      debugShowCheckedModeBanner: false,
    );
  }
}

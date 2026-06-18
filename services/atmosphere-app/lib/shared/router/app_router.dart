import 'package:atmosphere_app/screens/health/health_screen.dart';
import 'package:atmosphere_app/shared/router/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Tabla de rutas única (convención `navigation`). Sin guards de sesión: la app
/// no tiene auth (ADR-003).
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: Routes.root,
    routes: <RouteBase>[
      GoRoute(
        path: Routes.root,
        builder: (context, state) => const HealthScreen(),
      ),
    ],
    errorBuilder: (context, state) => const _NotFoundScreen(),
  );
});

/// Pantalla 404 simple para rutas desconocidas.
class _NotFoundScreen extends StatelessWidget {
  const _NotFoundScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('404 — página no encontrada')),
    );
  }
}

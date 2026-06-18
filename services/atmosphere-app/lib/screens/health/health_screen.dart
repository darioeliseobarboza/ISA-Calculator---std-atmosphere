import 'package:atmosphere_app/shared/health/health_status.dart';
import 'package:atmosphere_app/shared/providers/health_provider.dart';
import 'package:atmosphere_app/shared/state/health_state.dart';
import 'package:atmosphere_app/shared/theme/app_colors.dart';
import 'package:atmosphere_app/shared/theme/app_spacing.dart';
import 'package:atmosphere_app/shared/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Pantalla **provisional** de health (prueba de vida del sistema).
///
/// Dispara `checkHealth()` al abrir y renderiza tres estados:
/// loading (indicador), `alive` ("sistema vivo") y `error` ("error de
/// conexión"). FG-2 la reemplaza por la pantalla `calculator`.
class HealthScreen extends ConsumerStatefulWidget {
  const HealthScreen({super.key});

  /// Key del icono de estado (para aserciones de color en tests).
  static const Key statusIconKey = Key('health-status-icon');

  @override
  ConsumerState<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends ConsumerState<HealthScreen> {
  @override
  void initState() {
    super.initState();
    // Side-effect fuera de build: disparar el check una sola vez al montar.
    Future.microtask(() => ref.read(healthProvider.notifier).checkHealth());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(healthProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('atmosphere-app')),
      body: Center(child: _buildContent(state)),
    );
  }

  Widget _buildContent(HealthState state) {
    return switch (state.status) {
      HealthStatus.loading => const CircularProgressIndicator(),
      HealthStatus.alive => const _StatusView(
        icon: Icons.check_circle,
        color: AppColors.success,
        title: 'Sistema vivo',
        subtitle: 'API disponible',
      ),
      HealthStatus.error => const _StatusView(
        icon: Icons.cancel,
        color: AppColors.error,
        title: 'Error de conexión',
        subtitle: 'No se pudo contactar la API',
      ),
    };
  }
}

/// Vista de un estado terminal (vivo / error): icono + título + subtítulo.
class _StatusView extends StatelessWidget {
  const _StatusView({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 64, key: HealthScreen.statusIconKey),
        const SizedBox(height: AppSpacing.md),
        Text(title, style: AppTypography.title),
        const SizedBox(height: AppSpacing.xs),
        Text(subtitle, style: AppTypography.body),
      ],
    );
  }
}

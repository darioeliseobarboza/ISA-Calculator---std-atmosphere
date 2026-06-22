import 'package:atmosphere_app/l10n/app_localizations.dart';
import 'package:atmosphere_app/screens/calculator/widgets/altitude_echo.dart';
import 'package:atmosphere_app/screens/calculator/widgets/altitude_input.dart';
import 'package:atmosphere_app/screens/calculator/widgets/calculator_states.dart';
import 'package:atmosphere_app/screens/calculator/widgets/relative_values.dart';
import 'package:atmosphere_app/screens/calculator/widgets/results_table.dart';
import 'package:atmosphere_app/screens/formulas/formulas_drawer.dart';
import 'package:atmosphere_app/shared/models/altitude_unit.dart';
import 'package:atmosphere_app/shared/providers/calculation_provider.dart';
import 'package:atmosphere_app/shared/state/calculation_notifier.dart';
import 'package:atmosphere_app/shared/theme/app_colors.dart';
import 'package:atmosphere_app/shared/theme/app_spacing.dart';
import 'package:atmosphere_app/shared/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Pantalla `calculator`: entrada (altitud + unidad) + resultados ISA en doble
/// unidad. Vista raíz de la app (reemplaza la `HealthScreen` provisional, CA-6).
///
/// Construida según el wireframe `calculadora.md`. La validación de **formato**
/// es client-side (bloquea el envío); el **rango** lo decide la API (400).
class CalculatorScreen extends ConsumerStatefulWidget {
  const CalculatorScreen({super.key});

  @override
  ConsumerState<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends ConsumerState<CalculatorScreen> {
  final TextEditingController _altitudeController = TextEditingController();
  AltitudeUnit _unit = AltitudeUnit.feet;
  String? _formatError;

  @override
  void dispose() {
    _altitudeController.dispose();
    super.dispose();
  }

  void _onCalculate() {
    final raw = _altitudeController.text.trim().replaceAll(',', '.');
    final value = num.tryParse(raw);
    if (value == null) {
      // Validación de formato: bloquea el envío y marca el campo.
      setState(
        () => _formatError = AppLocalizations.of(context).calcNotANumber,
      );
      return;
    }
    setState(() => _formatError = null);
    // El rango lo valida la API (Flow Context Paso 1).
    ref
        .read(calculationProvider.notifier)
        .calculate(geopotentialAltitude: value, altitudeUnit: _unit);
  }

  /// Abre el overlay O-01 (fórmulas de conversión) como panel lateral derecho.
  ///
  /// No es una ruta de `go_router` (convención `navigation`): es una capa de
  /// diálogo que monta el [FormulasDrawer] al abrir y lo desmonta al cerrar,
  /// dejando `CalculatorScreen` intacta detrás (CA-3). El barrier (scrim) y la
  /// tecla `Esc` cierran el panel; el botón "Cerrar" hace `Navigator.pop`.
  void _openFormulas(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: l10n.formulasTitle,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (dialogContext, _, _) => Align(
        alignment: Alignment.centerRight,
        child: FractionallySizedBox(
          widthFactor: 0.42,
          heightFactor: 1,
          child: FormulasDrawer(
            onClose: () => Navigator.of(dialogContext).pop(),
          ),
        ),
      ),
      transitionBuilder: (_, animation, _, child) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
        child: child,
      ),
    );
  }

  /// Microcopy de error del Campo altitud ante un 400 de la API
  /// (`validationError`), según el `error.code`: `outOfRange` →
  /// [AppLocalizations.calcFieldOutOfRange]; `invalidInput` →
  /// [AppLocalizations.calcFieldInvalidInput]. Devuelve `null` fuera de
  /// `validationError` o para códigos desconocidos (basta con la alerta banner).
  String? _fieldErrorForValidation(
    AppLocalizations l10n,
    CalculatorState state,
  ) {
    if (state.status != CalculatorStatus.validationError) return null;
    switch (state.errorCode) {
      case 'outOfRange':
        return l10n.calcFieldOutOfRange;
      case 'invalidInput':
        return l10n.calcFieldInvalidInput;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(calculationProvider);
    final isLoading = state.status == CalculatorStatus.loading;

    // El campo refleja la validación de formato client-side y, ante un 400 de la
    // API (`validationError`), entra en estado de error con el microcopy de campo
    // según el `error.code` (wireframe: state_override del Campo altitud).
    final fieldError = _formatError ?? _fieldErrorForValidation(l10n, state);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.calcTitle)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 880),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AltitudeInput(
                    controller: _altitudeController,
                    unit: _unit,
                    enabled: !isLoading,
                    errorText: fieldError,
                    onUnitChanged: (u) => setState(() => _unit = u),
                    onSubmitted: _onCalculate,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const TableStepControl(),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      FilledButton.icon(
                        key: const Key('calculate-button'),
                        onPressed: isLoading ? null : _onCalculate,
                        icon: const Icon(Icons.arrow_forward),
                        label: Text(
                          isLoading ? l10n.calcCalculating : l10n.calcCalculate,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      TextButton.icon(
                        key: const Key('formulas-button'),
                        onPressed: () => _openFormulas(context),
                        icon: Semantics(
                          label: l10n.calcFormulasA11y,
                          child: const Icon(Icons.description_outlined),
                        ),
                        label: Text(l10n.calcFormulas),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _ResultsArea(state: state),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    l10n.calcFooter,
                    style: AppTypography.body.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Área de resultados: cambia según el estado del notifier (wireframe — bloques
/// 7..13 con sus reglas de visibilidad).
class _ResultsArea extends StatelessWidget {
  const _ResultsArea({required this.state});

  final CalculatorState state;

  @override
  Widget build(BuildContext context) {
    switch (state.status) {
      case CalculatorStatus.empty:
        return const CalculatorEmptyState();
      case CalculatorStatus.loading:
        return const CalculatorLoader();
      case CalculatorStatus.validationError:
        return ValidationAlert(
          errorCode: state.errorCode,
          backendMessage: state.error,
        );
      case CalculatorStatus.connectionError:
        return const SystemAlert();
      case CalculatorStatus.success:
        final result = state.result!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AltitudeEcho(altitude: result.input.geopotentialAltitude),
            const SizedBox(height: AppSpacing.lg),
            ResultsTable(result: result.analytical),
            const SizedBox(height: AppSpacing.lg),
            RelativeValues(result: result.analytical),
          ],
        );
    }
  }
}

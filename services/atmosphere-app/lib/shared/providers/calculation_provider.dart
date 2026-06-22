import 'package:atmosphere_app/shared/calculation/calculation_repository.dart';
import 'package:atmosphere_app/shared/calculation/calculation_repository_impl.dart';
import 'package:atmosphere_app/shared/services/api_client.dart';
import 'package:atmosphere_app/shared/state/calculation_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Repository del dominio `calculator`, construido sobre el [apiClientProvider]
/// (DI vía Riverpod — no se hace `new` del cliente dentro del notifier).
final calculationRepositoryProvider = Provider<CalculationRepository>((ref) {
  return CalculationRepositoryImpl(ref.read(apiClientProvider));
});

/// Estado de la calculadora expuesto a la UI (convención `state-management`).
final calculationProvider =
    StateNotifierProvider<CalculationNotifier, CalculatorState>((ref) {
      return CalculationNotifier(ref.read(calculationRepositoryProvider));
    });

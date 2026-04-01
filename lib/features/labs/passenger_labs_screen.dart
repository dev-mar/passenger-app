import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/session/passenger_internal_tools_gate.dart';
import '../../core/theme/app_colors.dart';

/// Pantalla de pruebas internas; acceso por allowlist de teléfono o `TEXI_PASSENGER_INTERNAL_TOOLS`.
class PassengerLabsScreen extends ConsumerWidget {
  const PassengerLabsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gate = ref.watch(passengerInternalToolsVisibleProvider);

    return gate.when(
      data: (allowed) {
        if (!allowed) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(title: const Text('Labs')),
            body: const Center(
              child: Text('No disponible.'),
            ),
          );
        }
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Labs (beta)'),
            backgroundColor: AppColors.surface,
          ),
          body: ListView(
            padding: const EdgeInsets.all(24),
            children: const [
              Text(
                'Espacio reservado para pruebas de producto (mapa, sockets, flags). '
                'El icono de matraz en Home solo aparece con número QA o dart-define.',
                style: TextStyle(color: AppColors.textSecondary, height: 1.4),
              ),
            ],
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      ),
      error: (Object err, StackTrace stack) {
        if (kDebugMode) {
          debugPrint('[PassengerLabs] gate error: $err');
        }
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(title: const Text('Labs')),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Error al comprobar acceso.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.9)),
              ),
            ),
          ),
        );
      },
    );
  }
}

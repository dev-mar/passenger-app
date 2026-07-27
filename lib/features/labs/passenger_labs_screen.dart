import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/session/passenger_internal_tools_gate.dart';
import '../../core/theme/app_colors.dart';
import '../../gen_l10n/app_localizations.dart';

/// Pantalla de pruebas internas; acceso por allowlist de teléfono o `TEXI_PASSENGER_INTERNAL_TOOLS`.
class PassengerLabsScreen extends ConsumerWidget {
  const PassengerLabsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final gate = ref.watch(passengerInternalToolsVisibleProvider);

    return gate.when(
      data: (allowed) {
        if (!allowed) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(title: Text(l10n.passengerLabsTitle)),
            body: Center(
              child: Text(l10n.passengerLabsNotAvailable),
            ),
          );
        }
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text(l10n.passengerLabsTitleBeta),
            backgroundColor: AppColors.surface,
          ),
          body: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                l10n.passengerLabsDescription,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
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
          appBar: AppBar(title: Text(l10n.passengerLabsTitle)),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                l10n.passengerLabsGateError,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary.withValues(alpha: 0.9),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';

/// Pantalla Buscando conductor: loading y mensaje. Luego integrar WebSocket/polling.
class TripSearchingScreen extends ConsumerWidget {
  const TripSearchingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // La búsqueda de conductor se hace en el mapa (trip_request). Redirigir.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      context.goNamed('trip_request');
    });
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );
  }
}

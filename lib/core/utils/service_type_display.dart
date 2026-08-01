import 'package:flutter/material.dart';

import '../constants/app_assets.dart';
import '../../gen_l10n/app_localizations.dart';

/// Etiqueta amigable para tipos de servicio mostrados al usuario (API puede traer nombres legacy).
String displayServiceTypeName(String raw, AppLocalizations l10n) {
  final s = raw.trim().toLowerCase();
  if (s.contains('económico') ||
      s.contains('economico') ||
      s == 'economy' ||
      s.contains('economy') ||
      s.contains('economic')) {
    return l10n.serviceTypeNameStandard;
  }
  if (s.contains('moto') ||
      s.contains('motorbike') ||
      s.contains('two_wheel') ||
      s.contains('two wheel') ||
      s.contains('dos ruedas')) {
    return l10n.serviceTypeNameTwoWheels;
  }
  if (s.contains('confort') || s.contains('comfort')) {
    return l10n.serviceTypeNameComfort;
  }
  if (s.contains('exclus') ||
      s.contains('vip') ||
      s.contains('premium')) {
    return l10n.serviceTypeNamePremium;
  }
  return raw;
}

/// Icono Material coherente con el tipo de servicio (cotización / selector).
String serviceTypeIconKey(String raw) {
  final s = raw.trim().toLowerCase();
  if (s.contains('moto') ||
      s.contains('motorbike') ||
      s.contains('two_wheel') ||
      s.contains('dos ruedas')) {
    return 'two_wheeler';
  }
  if (s.contains('confort') || s.contains('comfort')) {
    return 'comfort';
  }
  if (s.contains('exclus') ||
      s.contains('vip') ||
      s.contains('premium')) {
    return 'premium';
  }
  return 'standard';
}

/// Capacidad típica mostrada en la tarjeta de oferta (guía UI).
int serviceTypeSeatCapacity(String raw) {
  switch (serviceTypeIconKey(raw)) {
    case 'two_wheeler':
      return 1;
    case 'premium':
      return 3;
    case 'comfort':
      return 4;
    default:
      return 4;
  }
}

/// Asset PNG del vehículo (orden visual: Estándar → Moto → Confort → Premium).
String serviceTypeVehicleAsset(String raw) {
  switch (serviceTypeIconKey(raw)) {
    case 'two_wheeler':
      return AppAssets.serviceTypeMoto;
    case 'comfort':
      return AppAssets.serviceTypeComfort;
    case 'premium':
      return AppAssets.serviceTypePremium;
    default:
      return AppAssets.serviceTypeStandard;
  }
}

/// Orden de carrusel: Estándar, Moto, Confort, Premium.
int serviceTypeCarouselSortKey(String raw) {
  switch (serviceTypeIconKey(raw)) {
    case 'standard':
      return 0;
    case 'two_wheeler':
      return 1;
    case 'comfort':
      return 2;
    case 'premium':
      return 3;
    default:
      return 50;
  }
}

/// Icono Material coherente con el tipo de servicio (cotización / selector).
IconData serviceTypeIconData(String raw) {
  switch (serviceTypeIconKey(raw)) {
    case 'two_wheeler':
      return Icons.two_wheeler_outlined;
    case 'comfort':
      return Icons.airline_seat_recline_extra_rounded;
    case 'premium':
      return Icons.workspace_premium_rounded;
    default:
      return Icons.local_taxi_rounded;
  }
}

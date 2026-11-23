import 'package:flutter/material.dart';

import '../constants/app_assets.dart';
import '../../gen_l10n/app_localizations.dart';

String? _iconKeyFromServiceTypeId(int? serviceTypeId) {
  switch (serviceTypeId) {
    case 1:
      return 'standard';
    case 2:
      return 'comfort';
    case 3:
      return 'premium';
    case 4:
      return 'two_wheeler';
    default:
      return null;
  }
}

String? _displayNameFromServiceTypeId(int? serviceTypeId, AppLocalizations l10n) {
  switch (serviceTypeId) {
    case 1:
      return l10n.serviceTypeNameStandard;
    case 2:
      return l10n.serviceTypeNameComfort;
    case 3:
      return l10n.serviceTypeNamePremium;
    case 4:
      return l10n.serviceTypeNameTwoWheels;
    default:
      return null;
  }
}

String displayServiceTypeName(
  String raw,
  AppLocalizations l10n, {
  int? serviceTypeId,
}) {
  final fromId = _displayNameFromServiceTypeId(serviceTypeId, l10n);
  if (fromId != null) return fromId;
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

String serviceTypeIconKey(String raw, {int? serviceTypeId}) {
  final fromId = _iconKeyFromServiceTypeId(serviceTypeId);
  if (fromId != null) return fromId;
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

int serviceTypeSeatCapacity(String raw, {int? serviceTypeId}) {
  switch (serviceTypeIconKey(raw, serviceTypeId: serviceTypeId)) {
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

String serviceTypeVehicleAsset(String raw, {int? serviceTypeId}) {
  switch (serviceTypeIconKey(raw, serviceTypeId: serviceTypeId)) {
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

int serviceTypeCarouselSortKey(String raw, {int? serviceTypeId}) {
  switch (serviceTypeIconKey(raw, serviceTypeId: serviceTypeId)) {
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

IconData serviceTypeIconData(String raw, {int? serviceTypeId}) {
  switch (serviceTypeIconKey(raw, serviceTypeId: serviceTypeId)) {
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

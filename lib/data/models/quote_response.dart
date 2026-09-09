/// Respuesta de POST /passengers/trips/quote.
class QuoteResponse {
  const QuoteResponse({
    required this.city,
    required this.currencyCode,
    required this.distanceKm,
    required this.durationMinutes,
    required this.options,
    this.specialRequirementSurchargePct = 50,
  });

  final QuoteCity city;
  final String currencyCode;
  final double distanceKm;
  final int durationMinutes;
  final List<QuoteOption> options;
  final double specialRequirementSurchargePct;

  factory QuoteResponse.fromJson(Map<String, dynamic> json) {
    final optionsList = json['options'] as List<dynamic>? ?? [];
    final distanceKm = json['distanceKm'];
    return QuoteResponse(
      city: QuoteCity.fromJson(
        (json['city'] as Map<String, dynamic>?) ?? {},
      ),
      currencyCode:
          (json['currencyCode'] ?? json['currency'] ?? json['city']?['currencyCode'] ?? json['city']?['currency'])
              ?.toString() ??
          'BOB',
      distanceKm: distanceKm != null ? (distanceKm as num).toDouble() : 0.0,
      durationMinutes: () {
        final raw = json['durationMinutes'];
        if (raw is int) return raw;
        if (raw is num) return raw.round();
        return 0;
      }(),
      options: optionsList
          .whereType<Map>()
          .map((e) => QuoteOption.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      specialRequirementSurchargePct: () {
        final raw = json['specialRequirementSurchargePct'] ??
            json['special_requirement_surcharge_pct'];
        if (raw is num) return raw.toDouble();
        if (raw is String) return double.tryParse(raw) ?? 50.0;
        return 50.0;
      }(),
    );
  }

  Map<String, dynamic> toJson() => {
        'city': city.toJson(),
        'currencyCode': currencyCode,
        'distanceKm': distanceKm,
        'durationMinutes': durationMinutes,
        'specialRequirementSurchargePct': specialRequirementSurchargePct,
        'options': options.map((e) => e.toJson()).toList(),
      };
}

class QuoteCity {
  const QuoteCity({
    required this.id,
    required this.name,
    required this.currencyCode,
  });
  final String id;
  final String name;
  final String currencyCode;

  factory QuoteCity.fromJson(Map<String, dynamic> json) {
    return QuoteCity(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      currencyCode: (json['currencyCode'] ?? json['currency'])?.toString() ?? 'BOB',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'currencyCode': currencyCode,
      };
}

class PromoPreview {
  const PromoPreview({
    required this.campaignId,
    required this.cashDuePassenger,
    required this.companyGuaranteeToDriver,
    required this.discountAmount,
    this.displayCopyEs,
    this.displayCopyEn,
  });

  final String campaignId;
  final double cashDuePassenger;
  final double companyGuaranteeToDriver;
  final double discountAmount;
  final String? displayCopyEs;
  final String? displayCopyEn;

  factory PromoPreview.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      throw const FormatException('promoPreview vacío');
    }
    double parseNum(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0;
      return 0;
    }

    final copy = json['displayCopy'];
    return PromoPreview(
      campaignId: json['campaignId']?.toString() ?? '',
      cashDuePassenger: parseNum(json['cashDuePassenger']),
      companyGuaranteeToDriver: parseNum(json['companyGuaranteeToDriver']),
      discountAmount: parseNum(json['discountAmount']),
      displayCopyEs: copy is Map ? copy['es']?.toString() : null,
      displayCopyEn: copy is Map ? copy['en']?.toString() : null,
    );
  }

  String rulesForLocale(String languageCode) {
    if (languageCode == 'en') {
      final en = displayCopyEn?.trim();
      if (en != null && en.isNotEmpty) return en;
    }
    final es = displayCopyEs?.trim();
    if (es != null && es.isNotEmpty) return es;
    return displayCopyEn?.trim() ?? '';
  }
}

class TripSupportPreview {
  const TripSupportPreview({
    required this.source,
    required this.supportAmount,
    required this.cashDuePassenger,
    required this.companyGuaranteeToDriver,
    this.maxPerTrip,
    this.expiresAt,
    this.currencyCode,
  });

  final String source;
  final double supportAmount;
  final double cashDuePassenger;
  final double companyGuaranteeToDriver;
  final double? maxPerTrip;
  final DateTime? expiresAt;
  final String? currencyCode;

  factory TripSupportPreview.fromJson(Map<String, dynamic> json) {
    double parseNum(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0;
      return 0;
    }

    DateTime? exp;
    final rawExp = json['expiresAt'] ?? json['expires_at'];
    if (rawExp is String && rawExp.trim().isNotEmpty) {
      exp = DateTime.tryParse(rawExp);
    }
    double? maxPer;
    final rawMax = json['maxPerTrip'] ?? json['max_per_trip'];
    if (rawMax is num) maxPer = rawMax.toDouble();
    if (rawMax is String) maxPer = double.tryParse(rawMax);

    return TripSupportPreview(
      source: json['source']?.toString() ?? 'passenger_referral',
      supportAmount: parseNum(json['supportAmount'] ?? json['support_amount']),
      cashDuePassenger: parseNum(json['cashDuePassenger'] ?? json['cash_due_passenger']),
      companyGuaranteeToDriver: parseNum(
        json['companyGuaranteeToDriver'] ?? json['company_guarantee_to_driver'],
      ),
      maxPerTrip: maxPer,
      expiresAt: exp,
      currencyCode: (json['currencyCode'] ?? json['currency'])?.toString(),
    );
  }
}

class QuoteOption {
  const QuoteOption({
    required this.serviceTypeId,
    required this.serviceTypeName,
    required this.estimatedPrice,
    required this.currencyCode,
    this.promoPreview,
    this.tripSupport,
  });

  final int serviceTypeId;
  final String serviceTypeName;
  final double estimatedPrice;
  final String currencyCode;
  final PromoPreview? promoPreview;
  final TripSupportPreview? tripSupport;

  bool get hasCampaignPreview =>
      promoPreview != null && promoPreview!.campaignId.isNotEmpty;

  bool get hasTripSupport =>
      tripSupport != null && tripSupport!.supportAmount > 0;

  double? get youPayCashDue {
    if (hasCampaignPreview) return promoPreview!.cashDuePassenger;
    if (hasTripSupport) return tripSupport!.cashDuePassenger;
    return null;
  }

  /// Campaña/apoyo cubierto sobre la tarifa **base** de quote (sin recargo de especiales).
  double get coveredBenefitAmount {
    final due = youPayCashDue;
    if (due == null) return 0;
    final covered = estimatedPrice - due;
    return covered > 0 ? covered : 0;
  }

  /// “Tú pagas” contra el precio que la UI muestra (base + recargo de especiales).
  /// Evita pintar un descuento fantasma cuando el recargo se aplica solo en cliente.
  double? youPayForDisplayedGross(double displayedGross) {
    if (youPayCashDue == null) return null;
    final due = displayedGross - coveredBenefitAmount;
    return due < 0 ? 0 : due;
  }

  factory QuoteOption.fromJson(Map<String, dynamic> json) {
    final rawId = json['serviceTypeId'];
    int serviceTypeId = 0;
    if (rawId is int) {
      serviceTypeId = rawId;
    } else if (rawId is String) {
      serviceTypeId = int.tryParse(rawId) ?? 0;
    } else if (rawId is num) {
      serviceTypeId = rawId.toInt();
    }

    final rawPrice = json['estimatedPrice'];
    double estimatedPrice = 0;
    if (rawPrice is num) {
      estimatedPrice = rawPrice.toDouble();
    } else if (rawPrice is String) {
      estimatedPrice = double.tryParse(rawPrice) ?? 0;
    }

    PromoPreview? promoPreview;
    final rawPromo = json['promoPreview'] ?? json['promo_preview'];
    if (rawPromo is Map) {
      try {
        promoPreview = PromoPreview.fromJson(Map<String, dynamic>.from(rawPromo));
        if (promoPreview.campaignId.isEmpty) promoPreview = null;
      } catch (_) {
        promoPreview = null;
      }
    }

    TripSupportPreview? tripSupport;
    final rawSupport = json['tripSupport'] ?? json['trip_support'];
    if (rawSupport is Map) {
      try {
        tripSupport = TripSupportPreview.fromJson(
          Map<String, dynamic>.from(rawSupport),
        );
        if (tripSupport.supportAmount <= 0) tripSupport = null;
      } catch (_) {
        tripSupport = null;
      }
    }

    return QuoteOption(
      serviceTypeId: serviceTypeId,
      serviceTypeName: json['serviceTypeName'] as String? ?? '',
      estimatedPrice: estimatedPrice,
      currencyCode: (json['currencyCode'] ?? json['currency'])?.toString() ?? 'BOB',
      promoPreview: promoPreview,
      tripSupport: tripSupport,
    );
  }

  Map<String, dynamic> toJson() => {
        'serviceTypeId': serviceTypeId,
        'serviceTypeName': serviceTypeName,
        'estimatedPrice': estimatedPrice,
        'currencyCode': currencyCode,
        if (promoPreview != null)
          'promoPreview': {
            'campaignId': promoPreview!.campaignId,
            'cashDuePassenger': promoPreview!.cashDuePassenger,
            'companyGuaranteeToDriver': promoPreview!.companyGuaranteeToDriver,
            'discountAmount': promoPreview!.discountAmount,
            'displayCopy': {
              'es': promoPreview!.displayCopyEs,
              'en': promoPreview!.displayCopyEn,
            },
          },
        if (tripSupport != null)
          'tripSupport': {
            'source': tripSupport!.source,
            'supportAmount': tripSupport!.supportAmount,
            'cashDuePassenger': tripSupport!.cashDuePassenger,
            'companyGuaranteeToDriver': tripSupport!.companyGuaranteeToDriver,
            if (tripSupport!.maxPerTrip != null)
              'maxPerTrip': tripSupport!.maxPerTrip,
            if (tripSupport!.expiresAt != null)
              'expiresAt': tripSupport!.expiresAt!.toIso8601String(),
            if (tripSupport!.currencyCode != null)
              'currencyCode': tripSupport!.currencyCode,
          },
      };
}

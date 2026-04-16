/// Respuesta de POST /passengers/trips/quote.
class QuoteResponse {
  const QuoteResponse({
    required this.city,
    required this.currencyCode,
    required this.distanceKm,
    required this.durationMinutes,
    required this.options,
  });

  final QuoteCity city;
  final String currencyCode;
  final double distanceKm;
  final int durationMinutes;
  final List<QuoteOption> options;

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
      durationMinutes: (json['durationMinutes'] as int?) ?? 0,
      options: optionsList
          .map((e) => QuoteOption.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'city': city.toJson(),
        'currencyCode': currencyCode,
        'distanceKm': distanceKm,
        'durationMinutes': durationMinutes,
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

class QuoteOption {
  const QuoteOption({
    required this.serviceTypeId,
    required this.serviceTypeName,
    required this.estimatedPrice,
    required this.currencyCode,
  });

  final int serviceTypeId;
  final String serviceTypeName;
  final double estimatedPrice;
  final String currencyCode;

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

    return QuoteOption(
      serviceTypeId: serviceTypeId,
      serviceTypeName: json['serviceTypeName'] as String? ?? '',
      estimatedPrice: estimatedPrice,
      currencyCode: (json['currencyCode'] ?? json['currency'])?.toString() ?? 'BOB',
    );
  }

  Map<String, dynamic> toJson() => {
        'serviceTypeId': serviceTypeId,
        'serviceTypeName': serviceTypeName,
        'estimatedPrice': estimatedPrice,
        'currencyCode': currencyCode,
      };
}

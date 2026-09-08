import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/passenger_api_client.dart';
import '../../core/network/passenger_api_providers.dart';

final passengerPromoCodeProvider = StateProvider<String?>((ref) => null);

final passengerPromotionsRepositoryProvider =
    Provider<PassengerPromotionsRepository>(
    (ref) => PassengerPromotionsRepository(ref.watch(passengerApiClientProvider)),
);

class PassengerPromotionItem {
  const PassengerPromotionItem({
    required this.campaignId,
    required this.rulesText,
  });

  final String campaignId;
  final String rulesText;
}

class PassengerReferralWallet {
  const PassengerReferralWallet({
    required this.balance,
    this.expiresAt,
    this.maxPerTrip,
  });

  final double balance;
  final DateTime? expiresAt;
  final double? maxPerTrip;
}

class PassengerReferralInvitee {
  const PassengerReferralInvitee({required this.status});

  final String status;
}

class PassengerPromotionsSnapshot {
  const PassengerPromotionsSnapshot({
    required this.items,
    this.referralCode,
    this.claimedReferral = false,
    this.claimGraceEndsAt,
    this.wallet,
    this.invitees = const [],
  });

  final List<PassengerPromotionItem> items;
  final String? referralCode;
  final bool claimedReferral;
  final DateTime? claimGraceEndsAt;
  final PassengerReferralWallet? wallet;
  final List<PassengerReferralInvitee> invitees;
}

class PassengerPromotionsRepository {
  PassengerPromotionsRepository(this._client);

  final PassengerApiClient _client;

  Future<PassengerPromotionsSnapshot> fetchMine({String? languageCode}) async {
    PassengerPromotionsSnapshot fromMe = const PassengerPromotionsSnapshot(items: []);
    try {
      final res = await _client.getAuthWithRetry<Map<String, dynamic>>(
        path: '/promotions/me',
        flow: 'passenger_promotions_me',
      );
      final data = PassengerApiClient.parseSuccessData(res.data);
      fromMe = _parseSnapshot(data, languageCode);
    } catch (_) {}

    try {
      final res = await _client.getAuthWithRetry<Map<String, dynamic>>(
        path: '/promotions/referral',
        flow: 'passenger_promotions_referral_get',
      );
      final data = PassengerApiClient.parseSuccessData(res.data);
      return _mergeReferral(fromMe, data);
    } catch (_) {
      return fromMe;
    }
  }

  Future<bool> applyCode(String code) async {
    try {
      final res = await _client.postAuthWithRetry<Map<String, dynamic>>(
        path: '/promotions/codes/apply',
        flow: 'passenger_promotions_code',
        data: {'code': code.trim()},
      );
      final data = PassengerApiClient.parseSuccessData(res.data);
      return data['eligible'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> claimReferral(String code, {String? deviceId}) async {
    try {
      final res = await _client.postAuthWithRetry<Map<String, dynamic>>(
        path: '/promotions/referral/claim',
        flow: 'passenger_promotions_referral',
        data: {
          'code': code.trim(),
          if (deviceId != null && deviceId.isNotEmpty) 'deviceId': deviceId,
        },
      );
      final data = PassengerApiClient.parseSuccessData(res.data);
      return data['claimed'] == true;
    } catch (_) {
      return false;
    }
  }

  PassengerPromotionsSnapshot _mergeReferral(
    PassengerPromotionsSnapshot base,
    Map<String, dynamic> data,
  ) {
    final parsed = _parseReferralMap(data);
    return PassengerPromotionsSnapshot(
      items: base.items,
      referralCode: parsed.referralCode ?? base.referralCode,
      claimedReferral: parsed.claimedReferral || base.claimedReferral,
      claimGraceEndsAt: parsed.claimGraceEndsAt ?? base.claimGraceEndsAt,
      wallet: parsed.wallet ?? base.wallet,
      invitees: parsed.invitees.isNotEmpty ? parsed.invitees : base.invitees,
    );
  }

  PassengerPromotionsSnapshot _parseSnapshot(
    Map<String, dynamic> data,
    String? languageCode,
  ) {
    final itemsRaw = data['items'];
    final items = <PassengerPromotionItem>[];
    if (itemsRaw is List) {
      for (final raw in itemsRaw) {
        if (raw is! Map) continue;
        final rules = _rulesFromCopy(raw['displayCopy'], languageCode);
        items.add(
          PassengerPromotionItem(
            campaignId: raw['campaignId']?.toString() ?? '',
            rulesText: rules,
          ),
        );
      }
    }
    final referral = data['referral'];
    final fromReferral = referral is Map
        ? _parseReferralMap(Map<String, dynamic>.from(referral))
        : const PassengerPromotionsSnapshot(items: []);
    return PassengerPromotionsSnapshot(
      items: items,
      referralCode: fromReferral.referralCode,
      claimedReferral: fromReferral.claimedReferral,
      claimGraceEndsAt: fromReferral.claimGraceEndsAt,
      wallet: fromReferral.wallet,
      invitees: fromReferral.invitees,
    );
  }

  PassengerPromotionsSnapshot _parseReferralMap(Map<String, dynamic> data) {
    final c = data['code']?.toString().trim();
    DateTime? grace;
    final rawGrace = data['claimGraceEndsAt'] ?? data['claim_grace_ends_at'];
    if (rawGrace is String && rawGrace.trim().isNotEmpty) {
      grace = DateTime.tryParse(rawGrace);
    }
    PassengerReferralWallet? wallet;
    final rawWallet = data['wallet'];
    if (rawWallet is Map) {
      final bal = rawWallet['balance'];
      double balance = 0;
      if (bal is num) balance = bal.toDouble();
      if (bal is String) balance = double.tryParse(bal) ?? 0;
      DateTime? exp;
      final rawExp = rawWallet['expiresAt'] ?? rawWallet['expires_at'];
      if (rawExp is String && rawExp.trim().isNotEmpty) {
        exp = DateTime.tryParse(rawExp);
      }
      double? maxPer;
      final rawMax = rawWallet['maxPerTrip'] ?? rawWallet['max_per_trip'];
      if (rawMax is num) maxPer = rawMax.toDouble();
      if (rawMax is String) maxPer = double.tryParse(rawMax);
      wallet = PassengerReferralWallet(
        balance: balance,
        expiresAt: exp,
        maxPerTrip: maxPer,
      );
    }
    final invitees = <PassengerReferralInvitee>[];
    final rawInvitees = data['invitees'];
    if (rawInvitees is List) {
      for (final raw in rawInvitees) {
        if (raw is! Map) continue;
        final status = raw['status']?.toString().trim() ?? '';
        if (status.isEmpty) continue;
        invitees.add(PassengerReferralInvitee(status: status));
      }
    }
    return PassengerPromotionsSnapshot(
      items: const [],
      referralCode: (c != null && c.isNotEmpty) ? c : null,
      claimedReferral: data['claimed'] == true,
      claimGraceEndsAt: grace,
      wallet: wallet,
      invitees: invitees,
    );
  }

  static String _rulesFromCopy(dynamic copy, String? languageCode) {
    if (copy is! Map) return '';
    final map = Map<String, dynamic>.from(copy);

    String pickLocale(String loc) {
      final v = map[loc];
      if (v is String && v.trim().isNotEmpty) return v.trim();
      if (v is Map) {
        final rules = v['rulesText']?.toString().trim() ?? '';
        if (rules.isNotEmpty) return rules;
        return v['title']?.toString().trim() ?? '';
      }
      return '';
    }

    if (languageCode == 'en') {
      final en = pickLocale('en');
      if (en.isNotEmpty) return en;
    }
    final es = pickLocale('es');
    if (es.isNotEmpty) return es;
    final rules = map['rulesText']?.toString().trim() ?? '';
    if (rules.isNotEmpty) return rules;
    return map['title']?.toString().trim() ?? '';
  }
}

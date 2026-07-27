import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../../features/profile/passenger_profile_repository.dart';
import '../../features/support/passenger_support_repository.dart';
import 'passenger_api_client.dart';
import 'request_policy_cache.dart';

final passengerApiClientProvider = Provider<PassengerApiClient>(
  (ref) => PassengerApiClient(),
);

const _meProfileCacheKey = 'passenger_me_profile';

final _meProfileCache = RequestPolicyCache<Map<String, dynamic>>(
  defaultTtl: const Duration(seconds: 15),
);

/// Perfil plano `GET /api/v2/auth/me` → `data` (cache 15 s).
class PassengerMeProfileService {
  PassengerMeProfileService(this._client);

  final PassengerApiClient _client;

  Future<Map<String, dynamic>> fetchData({bool forceRefresh = false}) {
    return _meProfileCache.run(
      key: _meProfileCacheKey,
      ttl: const Duration(seconds: 15),
      forceRefresh: forceRefresh,
      fetcher: () async {
        final response = await _client.getAuthWithRetry<Map<String, dynamic>>(
          path: AppConfig.authMePath,
          flow: 'passenger_me_profile',
          validateStatus: (status) => status != null && status < 600,
        );
        return PassengerApiClient.parseSuccessData(response.data);
      },
    );
  }
}

final passengerMeProfileServiceProvider = Provider<PassengerMeProfileService>(
  (ref) => PassengerMeProfileService(ref.watch(passengerApiClientProvider)),
);

final passengerMeProfileDataProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  return ref.watch(passengerMeProfileServiceProvider).fetchData();
});

final passengerProfileRepositoryProvider = Provider<PassengerProfileRepository>(
  (ref) => PassengerProfileRepository(
    ref.watch(passengerApiClientProvider),
    ref.watch(passengerMeProfileServiceProvider),
  ),
);

final passengerSupportRepositoryProvider = Provider<PassengerSupportRepository>(
  (ref) => PassengerSupportRepository(ref.watch(passengerApiClientProvider)),
);

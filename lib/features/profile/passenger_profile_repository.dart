import 'package:dio/dio.dart';

import '../../core/config/app_config.dart';
import '../../core/network/passenger_api_client.dart';
import '../../core/network/passenger_api_providers.dart';
import 'passenger_profile_models.dart';

class PassengerProfileRepository {
  PassengerProfileRepository(this._client, this._meProfileService);

  final PassengerApiClient _client;
  final PassengerMeProfileService _meProfileService;

  Future<PassengerProfileVm> fetchProfile({bool forceRefresh = false}) async {
    try {
      final data = await _meProfileService.fetchData(
        forceRefresh: forceRefresh,
      );
      return PassengerProfileVm.fromJson(data);
    } on PassengerApiSessionException {
      throw PassengerProfileLoadError.noSession;
    } on PassengerApiResponseException catch (e) {
      throw PassengerProfileApiException(e.code, e.message ?? 'profile');
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      final body = e.response?.data;
      if (body is Map) {
        final m = Map<String, dynamic>.from(body);
        final apiCode = m['code']?.toString();
        final msg = m['message']?.toString();
        if (code == 401) {
          throw PassengerProfileApiException(apiCode, msg ?? '');
        }
        if (msg != null && msg.isNotEmpty) {
          throw PassengerProfileApiException(apiCode, msg);
        }
      }
      if (code == 401) throw PassengerProfileLoadError.noSession;
      final msg = e.message ?? 'network';
      throw Exception(msg);
    }
  }

  Future<void> updateProfile({
    required String displayName,
    String? email,
    String? profilePictureBase64,
  }) async {
    final res = await _client.patchAuthWithRetry<Map<String, dynamic>>(
      path: AppConfig.authMePath,
      flow: 'passenger_profile_update',
      data: <String, dynamic>{
        'display_name': displayName,
        if (email != null && email.isNotEmpty) 'email': email,
        'profile_picture': profilePictureBase64,
      },
    );
    final root = res.data;
    final ok = root != null && root['success'] == true;
    if (!ok) {
      throw Exception(root?['message']?.toString() ?? 'save_failed');
    }
    await _meProfileService.fetchData(forceRefresh: true);
  }
}

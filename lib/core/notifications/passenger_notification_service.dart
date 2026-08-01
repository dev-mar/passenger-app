import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../gen_l10n/app_localizations.dart';
import '../l10n/passenger_locale_holder.dart';
import 'passenger_fcm_navigation.dart';

class PassengerNotificationService {
  PassengerNotificationService._();
  static final PassengerNotificationService instance =
      PassengerNotificationService._();

  static const String _channelId = 'texi_passenger_trip_updates';
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  static const int _quietHoursStart = 22; // 22:00
  static const int _quietHoursEnd = 7; // 07:00
  static const String _chatVibrationLevel = 'medium'; // low | medium | high
  static final Set<String> _arrivedNotifiedTripIds = <String>{};

  AppLocalizations _l10nForCurrentLocale() => PassengerLocaleHolder.l10n();

  Future<void> initialize() async {
    if (_initialized) return;
    final l10n = _l10nForCurrentLocale();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        schedulePassengerLocalNotificationTripTap(response.payload);
      },
    );
    final channel = AndroidNotificationChannel(
      _channelId,
      l10n.passengerNotificationChannelName,
      description: l10n.passengerNotificationChannelDescription,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
    _initialized = true;
  }

  /// Android 13+: solicitar tras divulgación in-app (Google Play).
  Future<bool> areAndroidNotificationsEnabled() async {
    if (!Platform.isAndroid) return true;
    try {
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      return await androidPlugin?.areNotificationsEnabled() ?? true;
    } catch (_) {
      return true;
    }
  }

  Future<void> requestAndroidPostNotificationsPermission() async {
    if (!Platform.isAndroid) return;
    try {
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await androidPlugin?.requestNotificationsPermission();
    } catch (_) {
      // Permiso ya concedido o no disponible en esta versión.
    }
  }

  /// Mensaje solo `data` (sin `notification`): mostrar en isolate de background.
  static Future<void> showFcmDataOnlyMessage(RemoteMessage message) async {
    final inst = PassengerNotificationService.instance;
    await inst.initialize();
    final title = message.data['title']?.toString().trim();
    final body = message.data['body']?.toString().trim();
    if ((title == null || title.isEmpty) && (body == null || body.isEmpty)) {
      return;
    }
    final tripId =
        message.data['tripId']?.toString() ??
        message.data['trip_id']?.toString();
    await inst._showRaw(
      title: title?.isNotEmpty == true ? title! : 'TEXIAPP',
      body: body ?? '',
      payload: tripId,
    );
  }

  /// En primer plano Android no muestra banner FCM: duplicamos con notificación local.
  Future<void> showFcmForegroundMessage(RemoteMessage message) async {
    if (!_initialized) await initialize();
    final n = message.notification;
    final title = n?.title?.trim().isNotEmpty == true
        ? n!.title!.trim()
        : (message.data['title']?.toString().trim().isNotEmpty == true
              ? message.data['title']!.trim()
              : 'TEXIAPP');
    final body = n?.body?.trim().isNotEmpty == true
        ? n!.body!.trim()
        : (message.data['body']?.toString() ?? '');
    final tripId =
        message.data['tripId']?.toString() ??
        message.data['trip_id']?.toString();
    await _showRaw(title: title, body: body, payload: tripId);
  }

  Future<void> _showRaw({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) await initialize();
    final l10n = _l10nForCurrentLocale();
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        l10n.passengerNotificationChannelName,
        channelDescription: l10n.passengerNotificationChannelFcmDescription,
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      ),
    );
    final id = (payload ?? title + body).hashCode.abs() % 2147483647;
    await _plugin.show(id, title, body, details, payload: payload);
  }

  Future<void> showDriverArrivedIfBackground({
    required bool isAppInForeground,
    required String tripId,
    String? driverName,
    bool notifyInForeground = true,
  }) async {
    await initialize();
    if (isAppInForeground && !notifyInForeground) return;
    // Dedupe: un solo aviso de llegada por tripId (socket + REST resume).
    if (_arrivedNotifiedTripIds.contains(tripId)) return;
    _arrivedNotifiedTripIds.add(tripId);
    final l10n = _l10nForCurrentLocale();
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        l10n.passengerNotificationChannelName,
        channelDescription:
            l10n.passengerNotificationChannelDriverArrivedDescription,
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      ),
    );
    final title = l10n.passengerNotifyDriverArrivedTitle;
    final who = (driverName ?? '').trim();
    final body = who.isEmpty
        ? l10n.passengerNotifyDriverArrivedBody
        : l10n.passengerNotifyDriverArrivedBodyNamed(who);
    await _plugin.show(
      tripId.hashCode.abs() % 2147483647,
      title,
      body,
      details,
      payload: tripId,
    );
  }

  /// Llamar al cerrar viaje (completed/cancelled) para no arrastrar dedupe.
  static void clearArrivedNotificationDedupe(String tripId) {
    _arrivedNotifiedTripIds.remove(tripId);
  }

  Future<void> showTripChatMessageIfBackground({
    required bool isAppInForeground,
    required String tripId,
    required String senderRole,
    required String messageText,
    bool notifyInForeground = false,
    bool includeSenderPrefix = true,
    String? titleOverride,
  }) async {
    await initialize();
    if (isAppInForeground && !notifyInForeground) return;
    final l10n = _l10nForCurrentLocale();
    final quiet = isWithinQuietHours();
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        l10n.passengerNotificationChannelName,
        channelDescription: l10n.passengerNotificationChannelChatDescription,
        importance: Importance.high,
        priority: Priority.high,
        playSound: !quiet,
        enableVibration: !quiet,
        vibrationPattern: quiet ? null : _chatVibrationPattern(),
      ),
    );
    final who = senderRole == 'driver'
        ? l10n.passengerNotifyChatSenderDriver
        : l10n.passengerNotifyChatSenderPassenger;
    final trimmed = messageText.trim();
    final body = includeSenderPrefix ? '$who: $trimmed' : trimmed;
    await _plugin.show(
      (tripId + trimmed).hashCode.abs() % 2147483647,
      titleOverride ?? l10n.passengerNotifyChatNewTitle,
      body,
      details,
      payload: 'chat:$tripId',
    );
  }

  static bool isWithinQuietHours([DateTime? now]) {
    final h = (now ?? DateTime.now()).hour;
    if (_quietHoursStart < _quietHoursEnd) {
      return h >= _quietHoursStart && h < _quietHoursEnd;
    }
    return h >= _quietHoursStart || h < _quietHoursEnd;
  }

  static bool shouldPlayForegroundChatAlert([DateTime? now]) {
    return !isWithinQuietHours(now);
  }

  static Int64List? _chatVibrationPattern() {
    switch (_chatVibrationLevel) {
      case 'low':
        return Int64List.fromList(<int>[0, 80, 80, 80]);
      case 'high':
        return Int64List.fromList(<int>[0, 180, 110, 180, 110, 180]);
      case 'medium':
      default:
        return Int64List.fromList(<int>[0, 120, 90, 120]);
    }
  }
}

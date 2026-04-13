import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'passenger_fcm_navigation.dart';

class PassengerNotificationService {
  PassengerNotificationService._();
  static final PassengerNotificationService instance = PassengerNotificationService._();

  static const String _channelId = 'texi_passenger_trip_updates';
  static const String _channelName = 'Actualizaciones de viaje';
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        schedulePassengerLocalNotificationTripTap(response.payload);
      },
    );
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'Notificaciones de estado de viaje para pasajero.',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
    if (Platform.isAndroid) {
      final androidPlugin =
          _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.requestNotificationsPermission();
    }
    _initialized = true;
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
        message.data['tripId']?.toString() ?? message.data['trip_id']?.toString();
    await inst._showRaw(
      title: title?.isNotEmpty == true ? title! : 'Texi',
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
            : 'Texi');
    final body = n?.body?.trim().isNotEmpty == true
        ? n!.body!.trim()
        : (message.data['body']?.toString() ?? '');
    final tripId =
        message.data['tripId']?.toString() ?? message.data['trip_id']?.toString();
    await _showRaw(
      title: title,
      body: body,
      payload: tripId,
    );
  }

  Future<void> _showRaw({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) await initialize();
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: 'Avisos FCM y estado de viaje.',
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
  }) async {
    await initialize();
    if (isAppInForeground) return;
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: 'Avisos cuando el conductor llega al punto de recogida.',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      ),
    );
    final title = 'Tu conductor ya llegó';
    final who = (driverName ?? '').trim();
    final body = who.isEmpty
        ? 'Tu viaje está listo para iniciar. Revisa los detalles.'
        : '$who ya llegó al punto de recogida.';
    await _plugin.show(
      tripId.hashCode.abs() % 2147483647,
      title,
      body,
      details,
      payload: tripId,
    );
  }
}


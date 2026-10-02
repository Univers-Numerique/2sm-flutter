import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Thin wrapper around `flutter_local_notifications`. This app has no push
/// infrastructure (Firebase was explicitly declined) — notifications shown
/// here are purely local, fired in response to something the app itself just
/// observed (a sync pull, a message fetch), never from a remote push.
///
/// Known limitation: tapping a shown notification is a no-op (see
/// [_onNotificationTap]) — deep-linking to the relevant screen would need a
/// navigator key wired up here, which is out of scope for this pass.
class LocalNotificationsService {
  LocalNotificationsService._();
  static final LocalNotificationsService instance = LocalNotificationsService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const _channelId = 'default_channel';
  static const _channelName = 'Notifications 2SM';
  static const _channelDescription = 'Notifications et messages de l\'application 2SM';

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    // Required on Windows even though this app has no Windows-specific icon
    // or activation callback beyond the shared no-op tap handler — the
    // plugin throws at startup ("Windows settings must be set when
    // targeting Windows platform") without it.
    const windowsSettings = WindowsInitializationSettings(
      appName: '2SM',
      appUserModelId: 'Com.App2sm.App2sm',
      guid: '5d0b8e9a-4b3a-4f5e-9c1d-2a7e6f8b3c4d',
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
      windows: windowsSettings,
    );

    await _plugin.initialize(
      settings: initSettings,
      // No-op: see the class doc comment above.
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    // Android 13+ (API 33) requires runtime notification permission.
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await _plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    await _plugin
        .resolvePlatformSpecificImplementation<MacOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  static void _onNotificationTap(NotificationResponse response) {
    // Known limitation (see class doc comment): tapping a notification
    // doesn't deep-link anywhere in this pass.
  }

  Future<void> show({required int id, required String title, required String body}) async {
    if (!_initialized) return;
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
      macOS: DarwinNotificationDetails(),
    );
    await _plugin.show(id: id, title: title, body: body, notificationDetails: details);
  }
}

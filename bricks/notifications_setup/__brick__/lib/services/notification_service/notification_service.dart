import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  factory NotificationService() {
    return _instance;
  }

  NotificationService.internal();

  static final NotificationService _instance = NotificationService.internal();
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  bool isFlutterLocalNotificationsInitialized = false;

  FirebaseMessaging get firebaseMessaging => _firebaseMessaging;

  final AndroidNotificationChannel _channel = const AndroidNotificationChannel(
    'max_importance_channel',
    'Max Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.max,
  );

  Future<void> setupLocalNotifications() async {
    if (isFlutterLocalNotificationsInitialized) {
      return;
    }

    final hasGrantedPermissions = await requestPermissions();

    if (hasGrantedPermissions == null || !hasGrantedPermissions) {
      log('User did not grant notification permissions');
      return;
    }

    await _flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(_channel);

    const initializationSettingsAndroid =
      AndroidInitializationSettings('ic_launch_image');
    const initializationSettingsIOS = DarwinInitializationSettings();

    const initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (response) {
        if (response.payload == null) {
          return;
        }

        // Get the payload from the notification response
        final payload = jsonDecode(response.payload!) as Map<String, dynamic>;

        // Process the notification
        processNotification(messageData: payload);
      },
    );

    // Configure how Firebase handles foreground notifications
    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    isFlutterLocalNotificationsInitialized = true;
  }

  // Request permissions for notifications
  Future<bool?> requestPermissions() async {
    if (Platform.isAndroid) {
    return await _flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
      ?.requestNotificationsPermission();
    } else if (Platform.isIOS) {
      final settings = await FirebaseMessaging.instance.requestPermission();

      log('User granted permission: ${settings.authorizationStatus}');
      return settings.authorizationStatus == AuthorizationStatus.authorized;
    }

    return null;
  }

  void handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null && android != null) {
      _flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: _channel.importance,
            priority: Priority.max,
            icon: 'ic_launch_image',
            // icon: 'launch_background',
          ),
        ),
        payload: jsonEncode(message.data),
      );
    }
  }

  Future<RemoteMessage?> getInitialMessage() async {
    return _firebaseMessaging.getInitialMessage();
  }

  Future<String?> getToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e, st) {
      log(e.toString(), stackTrace: st);
      return null;
    }
  }

  Future<void> processNotification({Map<String, dynamic>? messageData}) async {
    // TODO: Implement this method
    throw UnimplementedError();
  }
}
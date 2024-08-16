import 'dart:async';
import 'package:{{project-name}}/bootstrap.dart';
import 'package:{{project-name}}/firebase_config/firebase_options_dev.dart';
import 'package:{{project-name}}/services/notification_service/notification_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

NotificationService notificationService = NotificationService();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await notificationService.setupLocalNotifications();
  notificationService.handleForegroundMessage(message);
  // Note: This function runs in a separate isolate and cannot
  // directly update the UI
  // or trigger navigation. It's primarily used for data processing
  // or local notifications.
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Set the background messaging handler early on, as a named top-level function
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await bootstrap(
    notificationService: notificationService,
  );
}
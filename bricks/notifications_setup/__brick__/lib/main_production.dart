import 'package:{{project-name}}/bootstrap.dart';
import 'package:{{project-name}}/services/notification_service/notification_service.dart';
import 'package:flutter/material.dart';

final notificationService = NotificationService();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await bootstrap(notificationService: notificationService);
}
import 'package:auto_route/auto_route.dart';
import 'package:{{project-name}}/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:{{project-name}}/setup/setup.dart';
import 'package:{{project-name}}/routes/routes.dart';
import 'package:{{project-name}}/services/notification_service/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late RouterConfig<UrlState> appRouterConfig;

  @override
  void initState() {
    super.initState();

    // Auto Router config
    final appRouter = getIt.get<AppRouter>();
    appRouterConfig = appRouter.config();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      final notificationService = getIt.get<NotificationService>();

      await notificationService.setupLocalNotifications();

      // handle notifications opened in the foreground
      FirebaseMessaging.onMessage.listen(
        notificationService.handleForegroundMessage,
      );

      // Handle notifications opened when the app is in the background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        notificationService.processNotification(
          messageData: message.data,
        );
      });

      // Process any notifications that opened the app when it was terminated
      await notificationService.processNotification();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      theme: ThemeData(
        appBarTheme: AppBarTheme(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        useMaterial3: true,
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: appRouterConfig,
    );
  }
}
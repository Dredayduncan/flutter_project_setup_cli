import 'package:auto_route/auto_route.dart';
import 'package:{{project-name}}/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:{{project-name}}/setup/setup.dart';
import 'package:{{project-name}}/routes/routes.dart';

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
    appRouterConfig = appRouter.config(

    );
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
import 'package:auto_route/annotations.dart';
import 'package:auto_route/auto_route.dart';
import 'package:{{project-name}}/home/home_screen.dart';
part 'routes.gr.dart';

@AutoRouterConfig(replaceInRouteName: 'Screen,Route')
class AppRouter extends RootStackRouter {
  AppRouter();

  @override
  List<AutoRoute> get routes {
    return [
      AutoRoute(page: HomeRoute.page, path: '/home', initial: true),
    ];
  }
}
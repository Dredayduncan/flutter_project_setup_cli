import 'package:get_it/get_it.dart';
import 'package:{{project-name}}/routes/routes.dart';

final getIt = GetIt.instance;

Future<void> registerDependencies() async {
  // Register dependencies here
  getIt.registerSingleton<AppRouter>(AppRouter());

}

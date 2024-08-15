import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
final getIt = GetIt.instance;

final dio = Dio(
  BaseOptions(
    connectTimeout: const Duration(seconds: 30),
  ),
);

Future<void> registerDependencies() async {
  getIt.registerSingleton<Dio>(dio);

}

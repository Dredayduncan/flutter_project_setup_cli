import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:{{project-name}}/api_utils/interceptors/custom_dio_interceptor.dart';
import 'package:{{project-name}}/services/auth_service.dart';
import 'package:{{project-name}}/services/platform_services/storage_services/token_storage_service.dart';
import 'package:{{project-name}}/routes/routes.dart';

final getIt = GetIt.instance;

final dio = Dio(
  BaseOptions(
    connectTimeout: const Duration(seconds: 30),
  ),
);

Future<void> registerDependencies() async {

  // Setup secure storage
  const secureStorage = FlutterSecureStorage();

  getIt..registerSingleton<Dio>(dio)
    ..registerSingleton<AppRouter>(AppRouter())

  ..registerSingleton<AuthService>(AuthService())
    ..registerSingleton<TokenStorageService>(
        TokenStorageService(
          secureStorage,
          getIt.get<AuthService>(),
        )
    );

  // Safely assign it to the refresh token interceptor
  getIt.get<Dio>().interceptors.add(
    CustomDioInterceptor(
      tokenStorageService: getIt.get<TokenStorageService>(),
      dio: getIt.get<Dio>(),
      onRefreshTokenExpired: () {},
    ),
  );

}

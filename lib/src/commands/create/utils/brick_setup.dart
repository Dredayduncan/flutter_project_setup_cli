import 'dart:io';

class BrickSetup {
  const BrickSetup({
    required this.projectName,
  });

  final String projectName;

  // A function to set up Get_it, AutoRoute, Dynamic Links if requested
  Future<Process> basicSetup({
    required bool useRiverpod,
    required Uri? deeplinkUri,
  }) async {
    final makeBasicSetup = await Process.start(
      'mason',
      [
        'make',
        'basic_setup',
        '-o',
        projectName,
        '--project-name',
        projectName,
        '--on-conflict',
        'overwrite',
        '--deeplink-scheme',
        deeplinkUri?.scheme ?? '',
        '--deeplink-host',
        deeplinkUri?.host ?? '',
        '--use-riverpod',
        useRiverpod.toString(),
      ],
      mode: ProcessStartMode.inheritStdio,
    );

    return makeBasicSetup;
  }

  // A function to create the API Services that should be inherited
  // by any Service making API calls
  Future<Process> externalBackend() async {
    final makeSetupWithExternalBackend = await Process.start(
      'mason',
      [
        'make',
        'basic_setup_with_external_backend',
        '-o',
        projectName,
        '--project-name',
        projectName,
        '--on-conflict',
        'overwrite',
      ],
      mode: ProcessStartMode.inheritStdio,
    );

    return makeSetupWithExternalBackend;
  }

  // A function to create the API Interceptor as well as the TokenStorage
  // and Auth services for the JWT authentication
  Future<Process> jwtBackend() async {
    final makeSetupJWT = await Process.start(
      'mason',
      [
        'make',
        'backend_setup_with_jwt',
        '-o',
        projectName,
        '--project-name',
        projectName,
        '--on-conflict',
        'overwrite',
      ],
      mode: ProcessStartMode.inheritStdio,
    );

    return makeSetupJWT;
  }

  Future<Process> notificationsSetup({
    required String applicationId,
    required bool useRiverpod,
    required Uri? deeplinkUri,
  }) async {
    final makeSetupPushNotifications = await Process.start(
      'mason',
      [
        'make',
        'notifications_setup',
        '-o',
        projectName,
        '--project-name',
        projectName,
        '--application-id',
        applicationId,
        '--on-conflict',
        'overwrite',
        '--deeplink-scheme',
        deeplinkUri?.scheme ?? '',
        '--deeplink-host',
        deeplinkUri?.host ?? '',
        '--use-riverpod',
        useRiverpod.toString(),
      ],
      mode: ProcessStartMode.inheritStdio,
    );

    return makeSetupPushNotifications;
  }
}

import 'dart:io';

import 'package:mason_logger/mason_logger.dart';

Future<String?> createFirebaseProject({
  required String projectNameWithoutUnderscores,
  required String projectId,
}) async {

  // Create a firebase project
  final firebaseSetup = await Process.start(
    'firebase',
    [
      'projects:create',
      '--display-name',
      projectNameWithoutUnderscores,
      projectId,
    ],
    mode: ProcessStartMode.inheritStdio,
  );

  if ((await firebaseSetup.exitCode) != 0) {
    return 'Failed to create firebase account. ${firebaseSetup.stderr}';
  }

  return null;
}

// A function to integrate firebase project into the flutter project
Future<String?> integrateFirebaseProject({
  required String projectId,
  required String applicationId,
  required String projectName,
}) async {
  final bundleId = '$applicationId.dev';

  final firebaseIntegration = await Process.start(
    'flutterfire',
    [
      'config',
      '--project',
      projectId,
      '--out',
      'lib/firebase_config/firebase_options_dev.dart',
      '--ios-bundle-id',
      bundleId,
      '--macos-bundle-id',
      bundleId,
      '--android-package-name',
      bundleId,
      '--platforms',
      'android,ios,macos,web,linux,windows',
    ],
    workingDirectory: projectName,
    mode: ProcessStartMode.inheritStdio,
  );

  if ((await firebaseIntegration.exitCode) != 0) {
    return 'Failed to setup notifications. ${firebaseIntegration.stderr}';
  }

  return null;
}

Future<bool> firebaseProjectExists({
  required String projectId,
}) async {
  try {
    final result = await Process.run(
      'firebase',
      ['projects:list'],
    );
    if (result.exitCode != 0) {
      return false;
    }

    return result.stdout.toString().contains(projectId);
  } catch (e) {
    return false;
  }
}

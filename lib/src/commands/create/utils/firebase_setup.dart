import 'dart:io';

import 'package:mason_logger/mason_logger.dart';

class FirebaseConfig {
  FirebaseConfig({
    required this.projectName,
    required this.firebaseProjectId,
    required this.applicationId,
  });

  final String projectName;
  String? firebaseProjectId;
  final String applicationId;

  Future<String?> _createFirebaseProject({
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
  Future<String?> _integrateFirebaseProject({
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

  Future<bool> _firebaseProjectExists({
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

  Future<bool> setupFirebase({
    required Logger logger,
  }) async {
    // Check if the user provided a firebase project ID and check if it exists
    if (firebaseProjectId != null && firebaseProjectId!.isNotEmpty) {
      logger.info(
        blue.wrap(
          'Checking if the firebase project ($firebaseProjectId) exists...',
        ),
      );

      final projectExists = await _firebaseProjectExists(
        projectId: firebaseProjectId ?? '',
      );

      // Check if the project does not exist
      if (!projectExists) {
        logger.err('The provided firebase project ID does not exist.');
        return false;
      }
    } else {
      // Create a new firebase project
      logger.info(blue.wrap('Creating a new firebase project...'));
      // Replace the all underscores with a hyphen
      final projectNameWithoutUnderscores = projectName.replaceAll('_', '-');
      firebaseProjectId = '$projectNameWithoutUnderscores-flavors-dev';

      final firebaseProjectCreation = await _createFirebaseProject(
        projectNameWithoutUnderscores: projectNameWithoutUnderscores,
        projectId: firebaseProjectId ?? '',
      );

      // Check if an error occurred during the firebase project creation
      if (firebaseProjectCreation is String) {
        logger.err(firebaseProjectCreation);
        return false;
      }

      // Continuously check for the created firebase project
      const maxRetries = 10;
      var attempt = 1;

      while (!await _firebaseProjectExists(
        projectId: firebaseProjectId ?? '',
      )) {
        logger.err(
          "Project with ID '$firebaseProjectId' not found. "
          'Attempt $attempt/$maxRetries...',
        );

        // Increment attempt counter
        attempt++;

        // Exit if maximum retries reached
        if (attempt > maxRetries) {
          logger.err(
            'Unable to integrate firebase. Max retries reached. Exiting...',
          );
          return false;
        }

        // Wait before retrying
        await Future<void>.delayed(const Duration(seconds: 1));
      }
    }

    // Integrate the firebase project
    logger.info(blue.wrap('Integrating firebase...'));
    final firebaseIntegration = await _integrateFirebaseProject(
      projectId: firebaseProjectId ?? '',
      applicationId: applicationId,
      projectName: projectName,
    );

    // Check if the firebase integration failed
    if (firebaseIntegration is String) {
      logger.err(firebaseIntegration);
      return false;
    }

    return true;
  }

  static Future<int> checkFirebaseInstallation() async {
    // Check if the user has the firebase CLI tool installed to integrate
    // the firebase project
    final firebaseResult = await Process.run(
      'firebase',
      [
        '--version',
      ],
    );

    return firebaseResult.exitCode;
  }

  static Future<int> checkFlutterfireInstallation({
    required Logger logger,
  }) async {
    // Check if the user has the flutterfire CLI tool installed to integrate
    // the firebase project
    final flutterfireResult = await Process.run(
      'flutterfire',
      [
        '--version',
      ],
    );

    // If the exit code is not 0, the command failed
    if (flutterfireResult.exitCode != 0) {
      // Install the flutterfire CLI tool
      logger.info(blue.wrap('Installing flutterfire CLI tool...'));
      final installFlutterFire = await Process.run(
        'dart',
        [
          'pub',
          'global',
          'activate',
          'flutterfire_cli',
        ],
      );

      return installFlutterFire.exitCode;
    }

    return 0;
  }
}

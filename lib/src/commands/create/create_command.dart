import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:flutter_project_setup_cli/src/commands/create/utils/firebase_setup.dart';
import 'package:mason_logger/mason_logger.dart';

/// {@template sample_command}
///
/// `flutter_project_setup_cli sample`
/// A [Command] to exemplify a sub command
/// {@endtemplate}
class CreateCommand extends Command<int> {
  /// {@macro sample_command}
  CreateCommand({
    required Logger logger,
  }) : _logger = logger {
    argParser
      ..addOption(
        'project-name',
        abbr: 'p',
        help: 'Project name',
      )
      ..addOption(
        'application-id',
        abbr: 'a',
        help: 'The bundle identifier on iOS or application id on Android.',
      )
      ..addOption(
        'application-name',
        abbr: 'i',
        help: 'Application name',
      )
      ..addFlag(
        'integrate-firebase',
        abbr: 'f',
        help: 'Integrate a firebase project',
        negatable: false,
      )
      ..addFlag(
        'has-external-backend',
        abbr: 'e',
        negatable: false,
      )
      ..addFlag(
        'use-riverpod',
        abbr: 'r',
        help: 'Implement Riverpod state management',
        negatable: false,
      )
      ..addFlag(
        'use-deep-linking',
        abbr: 'd',
        negatable: false,
      )
      ..addFlag(
        'add-push-notifications',
        abbr: 'n',
        help: 'Enable Push notifications with Firebase messaging',
        negatable: false,
      );
  }

  @override
  String get description => 'A sub command to create a flutter project';

  @override
  String get name => 'create';

  final Logger _logger;

  // A function to copy a directory to the specified destination
  Future<void> copyDirectory(Directory source, Directory destination) async {
    // Create the destination directory if it doesn't exist
    await destination.create(recursive: true);

    // Copy all files and directories from the source to the destination
    await for (final entity in source.list()) {
      if (entity is Directory) {
        // Get the path segment of the directory
        final pathSegments = entity.uri.pathSegments;

        // Get the last path segment of the directory
        final lastPath = pathSegments.lastOrNull;

        late String newDirectoryPath;

        // If the last path segment is empty, use the second-to-last path
        // segment as the new directory name
        if ((lastPath == null || lastPath.trim().isEmpty) &&
            pathSegments.length > 1) {
          newDirectoryPath =
              '${destination.path}/${entity.uri.pathSegments[entity.uri.pathSegments.length - 2]}';
        } else {
          newDirectoryPath = '${destination.path}/${pathSegments.last}';
        }

        await copyDirectory(entity, Directory(newDirectoryPath));
      } else if (entity is File) {
        final newFile =
            File('${destination.path}/${entity.uri.pathSegments.last}');
        await entity.copy(newFile.path);
      }
    }
  }

  Future<bool> deleteFolder(String folderPath) async {
    final directory = Directory(folderPath);

    if (directory.existsSync()) {
      try {
        await directory.delete(recursive: true);
        _logger.success('Successfully deleted folder: $folderPath');
        return true;
      } catch (e) {
        _logger.err('Error deleting folder: $e');
        return false;
      }
    } else {
      _logger.err('Folder does not exist: $folderPath');
      return false;
    }
  }

  Future<bool> setupFirebase({
    required String projectName,
    required String? firebaseProjectId,
    required String applicationId,
  }) async {
    // Check if the user provided a firebase project ID and check if it exists
    if (firebaseProjectId != null) {
      _logger.info(
        blue.wrap(
          'Checking if the firebase project ($firebaseProjectId) exists...',
        ),
      );
      final projectExists = await firebaseProjectExists(
        projectId: firebaseProjectId,
      );

      // Check if the project does not exist
      if (!projectExists) {
        _logger.err('The provided firebase project ID does not exist.');
        return false;
      }
    } else {
      // Create a new firebase project
      _logger.info(blue.wrap('Creating a new firebase project...'));
      // Replace the all underscores with a hyphen
      final projectNameWithoutUnderscores = projectName.replaceAll('_', '-');
      firebaseProjectId = '$projectNameWithoutUnderscores-flavors-dev';

      final firebaseProjectCreation = await createFirebaseProject(
        projectNameWithoutUnderscores: projectNameWithoutUnderscores,
        projectId: firebaseProjectId,
      );

      // Check if an error occurred during the firebase project creation
      if (firebaseProjectCreation is String) {
        _logger.err(firebaseProjectCreation);
        return false;
      }

      // Continuously check for the created firebase project
      const maxRetries = 10;
      int attempt = 1;

      while (!await firebaseProjectExists(
        projectId: firebaseProjectId,
      )) {
        _logger.err(
          "Project with ID '$firebaseProjectId' not found. Attempt $attempt/$maxRetries...",
        );

        // Increment attempt counter
        attempt++;

        // Exit if maximum retries reached
        if (attempt > maxRetries) {
          _logger.err(
              'Unable to integrate firebase. Max retries reached. Exiting...');
          return false;
        }

        // Wait before retrying
        await Future<void>.delayed(const Duration(seconds: 1));
      }
    }

    // Integrate the firebase project
    _logger.info(blue.wrap('Integrating firebase...'));
    final firebaseIntegration = await integrateFirebaseProject(
      projectId: firebaseProjectId,
      applicationId: applicationId,
      projectName: projectName,
    );

    // Check if the firebase integration failed
    if (firebaseIntegration is String) {
      _logger.err(firebaseIntegration);
      return false;
    }

    return true;
  }

  @override
  Future<int> run() async {
    String? projectName = argResults?['project-name'] as String?;
    final applicationId =
        (argResults?['application-id'] as String?) ?? 'com.example.app';
    final applicationName = argResults?['application-name'] as String?;
    final integrateFirebase = argResults?['integrate-firebase'] as bool;
    final useRiverpod = argResults?['use-riverpod'] as bool;
    final hasExternalBackend = argResults?['has-external-backend'] as bool;
    final addPushNotifications = argResults?['add-push-notifications'] as bool;
    final useDeepLinking = argResults?['use-deep-linking'] as bool;
    String? firebaseProjectId;

    // Check if the user has very_good_cli installed
    // Run the 'firebase --version' command
    final veryGoodCLIResult = await Process.run('very_good', ['--version']);

    // If the exit code is not 0, the command failed
    if (veryGoodCLIResult.exitCode != 0) {
      usageException(
        'very_good_cli is not installed or not in PATH. You can '
        'install it with this command: pub global activate very_good_cli',
      );
    }

    // Ensure the user has firebase installed if the firebase option is selected
    if (integrateFirebase || addPushNotifications) {
      // Get the user's firebase project ID
      stdout.write(
        'Enter your firebase project ID (leave blank to create a new firebase project): ',
      );
      firebaseProjectId = stdin.readLineSync()?.trim();

      // if the user didn't enter a project ID
      if (firebaseProjectId == null || firebaseProjectId.isEmpty) {
        // check if the user has the firebase CLI tool installed because
        // we need it to create a new project

        // Run the 'firebase --version' command
        final firebaseResult = await Process.run('firebase', ['--version']);

        // If the exit code is not 0, the command failed
        if (firebaseResult.exitCode != 0) {
          usageException(
            'Firebase CLI is not installed or not in PATH. You can '
            'install it here: https://firebase.google.com/docs/cli',
          );
        }
      }

      // check if the user has the flutterfire CLI tool installed to integrate
      // the firebase project
      final flutterfireResult = await Process.run('flutterfire', ['--version']);

      // If the exit code is not 0, the command failed
      if (flutterfireResult.exitCode != 0) {
        // Install the flutterfire CLI tool
        _logger.info(blue.wrap('Installing flutterfire CLI tool...'));
        final installFlutterFire = await Process.run(
          'dart',
          [
            'pub',
            'global',
            'activate',
            'flutterfire_cli',
          ],
        );

        // check if the command failed
        if (installFlutterFire.exitCode != 0) {
          _logger.err('Failed to install flutterfire CLI tool.');
          return ExitCode.software.code;
        }

        _logger.success('flutterfire CLI tool installed.');
      }

    }

    // Check if the project name was provided
    if (projectName == null) {
      // validate the project name
      while (projectName == null) {
        stdout.write(
          'Enter your project name (lowercase letters and underscores only): ',
        );
        projectName = stdin.readLineSync()?.trim();
        if (projectName != null && RegExp(r'^[a-z_]+$').hasMatch(projectName)) {
          break;
        }

        _logger.err(
          'Invalid project name. Please use only lowercase letters and '
          'underscores.',
        );
      }
    }

    // Check if the user wants to implement deep linking and get
    // the deeplink URI
    Uri? deeplinkUri;

    if (useDeepLinking) {
      // validate the project name
      while (deeplinkUri == null) {
        stdout.write(
          'Enter your deeplink url (https://example.com): ',
        );
        // read the input from the user
        final deeplinkUriInput = stdin.readLineSync()?.trim();

        // check if the input is a valid URI
        if (deeplinkUriInput != null &&
            Uri.tryParse(deeplinkUriInput) != null) {
          deeplinkUri = Uri.parse(deeplinkUriInput);
          break;
        }

        _logger.err(
          'Invalid deep link. Please ensure it has the format '
          '((https://example.com)).',
        );
      }
    }

    // Create the very_good flutter_app
    _logger.info(blue.wrap('Creating very_good flutter app...'));
    final createVeryGoodFlutterApp = await Process.start(
      'very_good',
      [
        'create',
        'flutter_app',
        projectName,
        '--application-id',
        applicationId,
      ],
      mode: ProcessStartMode.inheritStdio,
    );

    // Check if the create command failed
    if ((await createVeryGoodFlutterApp.exitCode) != 0) {
      _logger.err(
        'Failed to create very_good_flutter_app. '
        '${createVeryGoodFlutterApp.stderr}',
      );
      return ExitCode.software.code;
    }

    _logger
      ..success('very_good_flutter_app have been setup.')

      // Delete the counter folders
      ..info(blue.wrap('Deleting counter folders...'));
    final deleteAppCounterFolder =
        await deleteFolder('$projectName/lib/counter');
    final deleteTestCounterViewFolder =
        await deleteFolder('$projectName/test/counter');

    // check if any of them failed to delete
    if (!deleteAppCounterFolder || !deleteTestCounterViewFolder) {
      _logger.err('Failed to delete counter folders.');
      return ExitCode.software.code;
    }

    // Install the required packages for setup
    _logger.info(blue.wrap('Installing required packages...'));
    await Process.run(
      'flutter',
      [
        'pub',
        'add',
        hasExternalBackend ? 'dio' : '',
        'get_it',
        'auto_route',
        'equatable',
        useRiverpod ? 'flutter_riverpod' : '',
      ],
      workingDirectory: projectName,
    );

    // Remove the flutter_gen package created by very_good_cli
    await Process.run(
      'flutter',
      [
        'pub',
        'remove',
        'flutter_gen',
        ...(useRiverpod ? ['flutter_bloc', 'bloc', 'bloc_test'] : []),
      ],
      workingDirectory: projectName,
    );

    // Install the required dev dependencies for setup
    await Process.run(
      'flutter',
      [
        'pub',
        'add',
        '--dev',
        'build_runner',
        'auto_route_generator',
      ],
      workingDirectory: projectName,
    );

    if (applicationName != null) {
      _logger.info(blue.wrap('Setting application name...'));
      //   TODO: Change Application name
    }

    // Create basic setup files which include Get_it, Equatable,
    // and AutoRoute setup
    _logger.info(blue.wrap('Setting up setup files...'));

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

    if ((await makeBasicSetup.exitCode) != 0) {
      _logger.err(
        'Failed to setup setup files. ${makeBasicSetup.stderr}',
      );
      return ExitCode.software.code;
    }
    _logger
      ..success('Setup files have been setup.')

      // Execute build runner to build the auto_route files
      ..info(blue.wrap('Building auto_route files...'));
    final buildRunner = await Process.run(
      'dart',
      [
        'run',
        'build_runner',
        'build',
        '--delete-conflicting-outputs',
      ],
      workingDirectory: projectName,
    );

    if (buildRunner.exitCode != 0) {
      _logger.err(
        'Failed to build auto route files. ${buildRunner.stderr}',
      );
      return ExitCode.software.code;
    }
    _logger
      ..info('Auto route files have been built.')

      // run the flutter pub get command
      ..info('Running flutter pub get...');
    await Process.run(
      'flutter',
      [
        'pub',
        'get',
      ],
      workingDirectory: projectName,
    );

    // check if the user opted for an external backend and create the
    // api_utils folder
    if (hasExternalBackend) {
      _logger.info(blue.wrap('Setting up api_utils...'));

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

      if ((await makeSetupWithExternalBackend.exitCode) != 0) {
        _logger.err(
          'Failed to setup external backend setup files. '
          '${makeSetupWithExternalBackend.stderr}',
        );
        return ExitCode.software.code;
      }
      _logger.info('External backend files have been setup.');

      String? usesJWT;

      // Ask the user if the backend uses JWT for authentication
      while (usesJWT == null) {
        stdout.write(
          'Does the backend use JWT for authentication? (y/n): ',
        );
        final usesJWTResponse = stdin.readLineSync()?.trim();
        if (usesJWTResponse != 'y' && usesJWTResponse != 'n') {
          _logger.err(
            'Invalid option. Please use y or n.',
          );
        } else {
          usesJWT = usesJWTResponse;
        }
      }

      // check if the user opted for an external backend with JWT and create
      // the api_utils folder
      if (usesJWT == 'y') {
        _logger.info(blue.wrap('Installing flutter_secure_storage...'));
        await Process.run(
          'flutter',
          [
            'pub',
            'add',
            'flutter_secure_storage',
          ],
          workingDirectory: projectName,
        );

        _logger.info(blue.wrap('Setting up API Interceptor...'));

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

        if ((await makeSetupJWT.exitCode) != 0) {
          _logger.err(
            'Failed to setup API Interceptor for JWT authentication. '
            '${makeSetupJWT.stderr}',
          );
          return ExitCode.software.code;
        }
        _logger.success(
          'Note: API, Auth, and TokenStorage services as well as the API '
          'Interceptor have been configured, and you will have to '
          'implement the refreshToken function in the AuthService.',
        );
      }
    }

    // Check if the user wants to integrate Firebase without adding push notifications
    if (integrateFirebase && !addPushNotifications) {
      final firebaseSetup = await setupFirebase(
        projectName: projectName,
        firebaseProjectId: firebaseProjectId,
        applicationId: applicationId,
      );

      if (!firebaseSetup) {
        return ExitCode.software.code;
      }
    }

    // Check if the user wants to add notifications
    if (addPushNotifications) {
      final firebaseSetup = await setupFirebase(
        projectName: projectName,
        firebaseProjectId: firebaseProjectId,
        applicationId: applicationId,
      );

      if (!firebaseSetup) {
        return ExitCode.software.code;
      }

      _logger.info(
        blue.wrap(
          'Installing firebase_messaging, firebase_core, '
          'and flutter_local_notifications...',
        ),
      );

      await Process.run(
        'flutter',
        [
          'pub',
          'add',
          'firebase_messaging',
          'firebase_core',
          'flutter_local_notifications',
        ],
        workingDirectory: projectName,
      );

      _logger.info(blue.wrap('Setting up push notifications...'));

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

      if ((await makeSetupPushNotifications.exitCode) != 0) {
        _logger.err(
          'Failed to setup notifications. ${makeSetupPushNotifications.stderr}',
        );
        return ExitCode.software.code;
      }
      _logger.success('Notifications have been setup.');
    }

    // Run dart fix command to fix any lint issues
    _logger.info(blue.wrap('Running dart fix --apply...'));
    await Process.run(
      'dart',
      [
        'fix',
        '--apply',
      ],
      workingDirectory: projectName,
    );

    // Remove the flutter_gen package created by the dart fix --apply
    await Process.run(
      'flutter',
      [
        'pub',
        'remove',
        'flutter_gen',
      ],
      workingDirectory: projectName,
    );

    // Project setup complete message
    _logger.success(
      'Project setup complete! To run your project, '
      "navigate to the project directory and use 'flutter run'",
    );

    // State management choice
    if (useRiverpod) {
      _logger.success(
        'Note: Basic Riverpod setup has been done, but you may need to manually'
        ' adjust some code for full Riverpod integration.',
      );
    }

    // Firebase choice
    if (integrateFirebase) {
      _logger.success(
          'Note: Firebase integration has been set up, but you will need to '
          'manually configure the Firebase project for staging and production'
          ' environments.');
    }

    // Messaging choice
    if (addPushNotifications) {
      _logger.success(
        'Note: Firebase Messaging notifications have been set up, but you may'
        ' need to implement the processNotification method in '
        'the NotificationService.',
      );
    }

    // Dynamic Link choice
    if (useDeepLinking) {
      _logger.success('Note: Dynamic Links have been set up, navigate to your '
          'Info.plist to update the links, and to the '
          'appRouterConfig variable in the lib/app/view/app.dart to configure them.');
    }

    return ExitCode.success.code;
  }
}

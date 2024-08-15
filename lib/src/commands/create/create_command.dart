import 'dart:io';

import 'package:args/command_runner.dart';
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
      ..addOption(
        'firebase-project-id',
        abbr: 'f',
        help: 'The ID of an existing Firebase project',
      )
      ..addFlag('has-external-backend', abbr: 'e', negatable: false)
      ..addFlag(
        'use-bloc',
        abbr: 'b',
        help: 'Implement bloc state management',
      )
      ..addFlag(
        'use-riverpod',
        abbr: 'r',
        help: 'Implement Riverpod state management',
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

        // If the last path segment is empty, use the second-to-last path segment as the new directory name
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

  @override
  Future<int> run() async {
    String? projectName = argResults?['project-name'] as String?;
    final applicationId =
        (argResults?['application-id'] as String?) ?? 'com.example.app';
    final applicationName = argResults?['application-name'] as String?;
    final firebaseProjectId = argResults?['firebase-project-id'] as String?;
    final useRiverpod = argResults?['use-riverpod'] as bool;
    final useBloc = argResults?['use-bloc'] as bool;
    final hasExternalBackend = argResults?['has-external-backend'] as bool;
    final addPushNotifications = argResults?['add-push-notifications'] as bool;
    final useDeepLinking = argResults?['use-deep-linking'] as bool;

    // Check if the project name was provided
    if (projectName == null) {
      // validate the project name
      while (projectName == null) {
        stdout.write(
          'Enter your project name (lowercase letters and underscores only): ',
        );
        projectName = stdin.readLineSync();
        if (projectName != null && RegExp(r'^[a-z_]+$').hasMatch(projectName)) {
          break;
        }

        _logger.err(
          'Invalid project name. Please use only lowercase letters and underscores.',
        );
      }
    }

    // Ensure that only one of the Riverpod or Bloc options is selected
    if (useRiverpod && useBloc) {
      usageException(
        'You can only specify one of the Riverpod or Bloc options',
      );
    }

    Uri? deeplinkUri;

    if (useDeepLinking) {
      // validate the project name
      while (deeplinkUri == null) {
        stdout.write(
          'Enter your deeplink url (https://example.com): ',
        );
        final deeplinkUriInput = stdin.readLineSync();
        if (deeplinkUriInput != null &&
            Uri.tryParse(deeplinkUriInput) != null) {
          deeplinkUri = Uri.parse(deeplinkUriInput);
          break;
        }

        _logger.err(
          'Invalid deep link. Please ensure it has the format ((https://example.com)).',
        );
      }
    }

    // Check if the user has installed the very_good_cli package
    _logger.info('Creating very_good flutter app...');
    final createVeryGoodFlutterApp = await Process.start('very_good', [
      'create',
      'flutter_app',
      projectName,
      '--application-id',
      applicationId,
    ], mode: ProcessStartMode.inheritStdio);

    if ((await createVeryGoodFlutterApp.exitCode) != 0) {
      _logger.err('Failed to create very_good_flutter_app. '
          '${createVeryGoodFlutterApp.stderr}',);
      return ExitCode.software.code;
    }
    _logger
      ..info('very_good_flutter_app have been setup.')

      // Install the required packages for setup
      ..info('Installing required packages...');
    await Process.run(
      'flutter',
      [
        'pub',
        'add',
        hasExternalBackend ? 'dio' : '',
        'get_it',
        'auto_route',
        'equatable',
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
      _logger.info('Setting application name...');
      //   TODO: Change Application name
    }

    // Create basic setup files which include Get_it, Equatable, and AutoRoute setup
    _logger.info('Setting up setup files...');

    final makeBasicSetup = await Process.start(
      'mason',
      [
        'make',
        'basic_setup',
        '-o',
        projectName,
        '--project_name',
        projectName,
        '--on-conflict',
        'overwrite',
        '--deep_link_scheme',
        deeplinkUri?.scheme ?? '',
        '--deep_link_host',
        deeplinkUri?.host ?? '',
      ],
      mode: ProcessStartMode.inheritStdio,
    );

    if ((await makeBasicSetup.exitCode) != 0) {
      _logger.err(
          'Failed to setup setup files. ${makeBasicSetup.stderr.toString()}');
      return ExitCode.software.code;
    }
    _logger
      ..info('Setup files have been setup.')

      // Execute build runner to build the auto_route files
      ..info('Building auto_route files...');
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

    // check if the user opted for an external backend and create the api_utils folder
    if (hasExternalBackend) {
      _logger.info('Setting up api_utils...');

      final makeSetupWithExternalBackend = await Process.start(
        'mason',
        [
          'make',
          'basic_setup_with_external_backend',
          '-o',
          projectName,
          '--project_name',
          projectName,
          '--on-conflict',
          'overwrite',
        ],
        mode: ProcessStartMode.inheritStdio,
      );

      if ((await makeSetupWithExternalBackend.exitCode) != 0) {
        _logger.err(
          'Failed to setup external backend setup files. '
              '${makeSetupWithExternalBackend.stderr.toString()}',
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
        final usesJWTResponse = stdin.readLineSync();
        if (usesJWTResponse != 'y' && usesJWTResponse != 'n') {
          _logger.err(
            'Invalid option. Please use y or n.',
          );
        } else {
          usesJWT = usesJWTResponse;
        }
      }

      // check if the user opted for an external backend with JWT and create the api_utils folder
      if (usesJWT == 'y') {
        _logger.info('Installing flutter_secure_storage...');
        await Process.run(
          'flutter',
          [
            'pub',
            'add',
            'flutter_secure_storage',
          ],
          workingDirectory: projectName,
        );

        _logger.info('Setting up API Interceptor...');

        final makeSetupJWT = await Process.start(
          'mason',
          [
            'make',
            'backend_setup_with_jwt',
            '-o',
            projectName,
            '--project_name',
            projectName,
            '--on-conflict',
            'overwrite',
          ],
          mode: ProcessStartMode.inheritStdio,
        );

        if ((await makeSetupJWT.exitCode) != 0) {
          _logger.err(
            'Failed to setup API Interceptor for JWT authentication. ${makeSetupJWT.stderr.toString()}',
          );
          return ExitCode.software.code;
        }
        _logger.info('API Interceptor for JWT authentication has been setup.');
      }
    }

    // Check if the user wants to add notifications
    if (addPushNotifications) {
      _logger.info('Installing firebase_messaging, firebase_core, and flutter_local_notifications...');
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

      _logger.info('Setting up push notifications...');

      final makeSetupPushNotifications = await Process.start(
        'mason',
        [
          'make',
          'notification_setup',
          '-o',
          projectName,
          '--project_name',
          projectName,
          '--application_id',
          applicationId,
          '--on-conflict',
          'overwrite',
          '--deep_link_scheme',
          deeplinkUri?.scheme ?? '',
          '--deep_link_host',
          deeplinkUri?.host ?? '',
        ],
        mode: ProcessStartMode.inheritStdio,
      );

      if ((await makeSetupPushNotifications.exitCode) != 0) {
        _logger.err(
          'Failed to setup notifications. ${makeSetupPushNotifications.stderr.toString()}',
        );
        return ExitCode.software.code;
      }
      _logger.info('Notifications have been setup.');
    }

    return ExitCode.success.code;
  }
}

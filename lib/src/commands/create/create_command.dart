import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:flutter_project_setup_cli/src/commands/create/utils/brick_setup.dart';
import 'package:flutter_project_setup_cli/src/commands/create/utils/directory_management.dart';
import 'package:flutter_project_setup_cli/src/commands/create/utils/firebase_setup.dart';
import 'package:flutter_project_setup_cli/src/commands/create/utils/package_management.dart';
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

  String? getProjectName() => argResults?['project-name'] as String?;

  @override
  Future<int> run() async {
    final projectName = getProjectName();
    final applicationId =
        (argResults?['application-id'] as String?) ?? 'com.example.app';
    final applicationName = argResults?['application-name'] as String?;
    final integrateFirebase =
        (argResults?['integrate-firebase'] as bool?) ?? false;
    final useRiverpod = (argResults?['use-riverpod'] as bool?) ?? false;
    final hasExternalBackend =
        (argResults?['has-external-backend'] as bool?) ?? false;
    final addPushNotifications =
        (argResults?['add-push-notifications'] as bool?) ?? false;
    final useDeepLinking = (argResults?['use-deep-linking'] as bool?) ?? false;
    String? firebaseProjectId;

    // Check if the project name was provided
    if (projectName == null) {
      throw usageException('Project name is required.');
    } else if (!RegExp(r'^[a-z_]+$').hasMatch(projectName)) {
      throw usageException(
        'Invalid project name. Please use only lowercase letters '
        'and underscores.',
      );
    }

    // Check if the user has very_good_cli installed
    // Run the 'firebase --version' command
    final veryGoodCLIResult = await Process.run('very_good', ['--version']);

    // If the exit code is not 0, the command failed
    if (veryGoodCLIResult.exitCode != 0) {
      throw usageException(
        'very_good_cli is not installed or not in PATH. You can '
        'install it with this command: pub global activate very_good_cli',
      );
    }

    // Ensure the user has firebase installed if the firebase option is selected
    if (integrateFirebase || addPushNotifications) {
      // Get the user's firebase project ID
      stdout.write(
        'Enter your firebase project ID '
        '(leave blank to create a new firebase project): ',
      );
      firebaseProjectId = stdin.readLineSync()?.trim();

      // if the user didn't enter a project ID
      if (firebaseProjectId == null || firebaseProjectId.isEmpty) {
        // check if the user has the firebase CLI tool installed because
        // we need it to create a new project

        // Run the 'firebase --version' command
        final firebaseResult = await FirebaseConfig.checkFirebaseInstallation();

        // If the exit code is not 0, the command failed
        if (firebaseResult != 0) {
          throw usageException(
            'Firebase CLI is not installed or not in PATH. You can '
            'install it here: https://firebase.google.com/docs/cli',
          );
        }
      }

      // check if the user has the flutterfire CLI tool installed to integrate
      // the firebase project
      final flutterFireResult =
          await FirebaseConfig.checkFlutterfireInstallation(
        logger: _logger,
      );

      // If the exit code is not 0, the command failed
      if (flutterFireResult != 0) {
        throw usageException(
          'Failed to install flutterfire CLI tool.',
        );
      }

      _logger.success('flutterfire CLI tool installed.');
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
      throw usageException(
        'Failed to create very_good_flutter_app. '
        '${createVeryGoodFlutterApp.stderr}',
      );
    }

    _logger
      ..success('very_good_flutter_app have been setup.')

      // Delete the counter folders
      ..info(blue.wrap('Deleting counter folders...'));
    final deleteCounter = await deleteCounterFolders(
      projectName: projectName,
      logger: _logger,
    );

    // check if any of them failed to delete
    if (!deleteCounter) {
      throw usageException('Failed to delete counter folders.');
    }

    // Instantiate the PackageManagement class to manage the packages
    final packageManagement = PackageManagement(
      projectName: projectName,
    );

    // Install the required packages for setup
    _logger.info(blue.wrap('Installing required packages...'));
    await packageManagement.setupEssentialPackages(
      hasExternalBackend: hasExternalBackend,
      useRiverpod: useRiverpod,
    );

    if (applicationName != null) {
      _logger.info(blue.wrap('Setting application name...'));
      // TODO(felix): Change Application name
    }

    // Instantiate the BrickSetup class
    final brickSetup = BrickSetup(
      projectName: projectName,
      logger: _logger,
    );

    // Create basic setup files which include Get_it, Equatable,
    // and AutoRoute setup
    _logger.info(blue.wrap('Creating up setup files...'));

    final makeBasicSetup = await brickSetup.setupBasicFiles(
      useRiverpod: useRiverpod,
      deeplinkUri: deeplinkUri,
    );

    if (makeBasicSetup is String) {
      throw usageException(
        'Failed to create setup files. $makeBasicSetup',
      );
    }

    // Execute build runner to build the auto_route files
    _logger.info(blue.wrap('Building auto_route files...'));

    final buildRunner = await packageManagement.buildAutoRouteFiles();

    if (buildRunner.exitCode != 0) {
      throw usageException(
        'Failed to build auto route files. ${buildRunner.stderr}',
      );
    }

    _logger
      ..success('Auto route files have been built.')

      // run the flutter pub get command
      ..info('Running flutter pub get...');
    await packageManagement.pubGet();

    // check if the user opted for an external backend and create the
    // api_utils folder
    if (hasExternalBackend) {
      // Create the external backend files
      final makeSetupWithExternalBackend =
          await brickSetup.setupExternalBackendFiles();

      if (makeSetupWithExternalBackend is String) {
        throw usageException(
          'Failed to setup external backend setup files. '
          '$makeSetupWithExternalBackend',
        );
      }

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
        await packageManagement.addPackages(
          packages: ['flutter_secure_storage'],
        );

        // Create the JWT backend files
        final makeSetupJWT = await brickSetup.setupJWTBackendFiles();

        if (makeSetupJWT is String) {
          throw usageException(
            'Failed to setup API Interceptor for JWT authentication. '
            '$makeSetupJWT',
          );
        }
      }
    }

    // Instantiate the FirebaseConfig class to setup Firebase
    final firebaseconfig = FirebaseConfig(
      projectName: projectName,
      firebaseProjectId: firebaseProjectId,
      applicationId: applicationId,
    );

    // Check if the user wants to integrate Firebase without adding
    // push notifications
    if (integrateFirebase && !addPushNotifications) {
      final firebaseSetup = await firebaseconfig.setupFirebase(
        logger: _logger,
      );

      // Check if the firebase setup failed
      if (!firebaseSetup) {
        return ExitCode.software.code;
      }
    }

    // Check if the user wants to add notifications
    if (addPushNotifications) {
      final firebaseSetup = await firebaseconfig.setupFirebase(
        logger: _logger,
      );

      // Check if the firebase setup failed
      if (!firebaseSetup) {
        return ExitCode.software.code;
      }

      // Install the required packages for push notifications
      _logger.info(
        blue.wrap(
          'Installing firebase_messaging, firebase_core, '
          'and flutter_local_notifications...',
        ),
      );
      await packageManagement.addPackages(
        packages: [
          'firebase_messaging',
          'firebase_core',
          'flutter_local_notifications',
        ],
      );

      // Create the push notifications files
      final makeSetupPushNotifications =
          await brickSetup.setupNotificationFiles(
        applicationId: applicationId,
        useRiverpod: useRiverpod,
        deeplinkUri: deeplinkUri,
      );

      if (makeSetupPushNotifications is String) {
        throw usageException(
          'Failed to setup notifications. $makeSetupPushNotifications',
        );
      }
    }

    // Run dart fix command to fix any lint issues
    _logger.info(blue.wrap('Running dart fix --apply...'));
    await packageManagement.dartFix();

    // Remove the flutter_gen package created by the dart fix --apply
    await packageManagement.removeUnusedPackages(
      useRiverpod: useRiverpod,
      onlyFlutterGen: true,
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

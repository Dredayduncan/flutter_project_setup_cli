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
        final firebaseResult = await FirebaseConfig.checkFirebaseInstallation();

        // If the exit code is not 0, the command failed
        if (firebaseResult != 0) {
          usageException(
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
        usageException(
          'Failed to install flutterfire CLI tool.',
        );
      }

      _logger.success('flutterfire CLI tool installed.');
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
      usageException(
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
      usageException('Failed to delete counter folders.');
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
      //   TODO: Change Application name
    }

    // Instantiate the BrickSetup class
    final brickSetup = BrickSetup(
      projectName: projectName,
    );

    // Create basic setup files which include Get_it, Equatable,
    // and AutoRoute setup
    _logger.info(blue.wrap('Setting up setup files...'));

    final makeBasicSetup = await brickSetup.basicSetup(
      useRiverpod: useRiverpod,
      deeplinkUri: deeplinkUri,
    );

    if ((await makeBasicSetup.exitCode) != 0) {
      usageException('Failed to setup setup files. ${makeBasicSetup.stderr}');
    }

    _logger
      ..success('Setup files have been setup.')

      // Execute build runner to build the auto_route files
      ..info(blue.wrap('Building auto_route files...'));

    final buildRunner = await packageManagement.buildAutoRouteFiles();

    if (buildRunner.exitCode != 0) {
      usageException('Failed to build auto route files. ${buildRunner.stderr}');
    }

    _logger
      ..info('Auto route files have been built.')

      // run the flutter pub get command
      ..info('Running flutter pub get...');
    await packageManagement.pubGet();

    // check if the user opted for an external backend and create the
    // api_utils folder
    if (hasExternalBackend) {
      _logger.info(blue.wrap('Setting up api_utils...'));

      final makeSetupWithExternalBackend = await brickSetup.externalBackend();

      if ((await makeSetupWithExternalBackend.exitCode) != 0) {
        usageException(
          'Failed to setup external backend setup files. '
          '${makeSetupWithExternalBackend.stderr}',
        );
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
        await packageManagement.addPackages(
          packages: ['flutter_secure_storage'],
        );

        _logger.info(blue.wrap('Setting up API Interceptor...'));

        final makeSetupJWT = await brickSetup.jwtBackend();

        if ((await makeSetupJWT.exitCode) != 0) {
          usageException(
            'Failed to setup API Interceptor for JWT authentication. '
            '${makeSetupJWT.stderr}',
          );
        }

        _logger.success(
          'Note: API, Auth, and TokenStorage services as well as the API '
          'Interceptor have been configured, and you will have to '
          'implement the refreshToken function in the AuthService.',
        );
      }
    }

    // Instantiate the FirebaseConfig class to setup Firebase
    final firebaseconfig = FirebaseConfig(
      projectName: projectName,
      firebaseProjectId: firebaseProjectId,
      applicationId: applicationId,
    );

    // Check if the user wants to integrate Firebase without adding push notifications
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

      _logger.info(blue.wrap('Setting up push notifications...'));
      final makeSetupPushNotifications = await brickSetup.notificationsSetup(
        applicationId: applicationId,
        useRiverpod: useRiverpod,
        deeplinkUri: deeplinkUri,
      );

      if ((await makeSetupPushNotifications.exitCode) != 0) {
        usageException(
          'Failed to setup notifications. ${makeSetupPushNotifications.stderr}',
        );
      }

      _logger.success('Notifications have been setup.');
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

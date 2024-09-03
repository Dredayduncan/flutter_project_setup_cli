import 'dart:io';

import 'package:mason/mason.dart';

typedef MasonGeneratorFactory = Future<MasonGenerator> Function(
  MasonBrick masonBrick,
  String gitUrl,
);

enum MasonBrick {
  basicSetup('bricks/basic_setup'),
  basicSetupWithExternalBackend('bricks/basic_setup_with_external_backend'),
  backendSetupWithJWT('bricks/backend_setup_with_jwt'),
  notificationsSetup('bricks/notifications_setup');

  const MasonBrick(this.brickPath);
  final String brickPath;
}

Future<MasonGenerator> defaultGeneratorFactory(
  MasonBrick masonBrick,
  String gitUrl,
) async {
  final brick = Brick.git(
    GitPath(gitUrl, path: masonBrick.brickPath, ref: 'main'),
  );
  return MasonGenerator.fromBrick(brick);
}

class BrickSetup {
  BrickSetup({
    required this.projectName,
    required this.logger,
    MasonGeneratorFactory? generatorFactory,
    DirectoryGeneratorTarget? targetDirectory,
  })  : _generatorFactory = generatorFactory ?? defaultGeneratorFactory,
        _targetDirectory = targetDirectory ??
            DirectoryGeneratorTarget(
              Directory(
                projectName,
              ),
            );

  final String projectName;
  final Logger logger;
  final MasonGeneratorFactory _generatorFactory;

  set projectName(String name) => projectName = name;
  set logger(Logger masonLogger) => logger = masonLogger;

  final DirectoryGeneratorTarget _targetDirectory;
  final String _gitUrl = 'https://github.com/Dredayduncan/mason_bricks.git';

  // Generate a MasonGenerator from a brick name
  Future<MasonGenerator> _getGenerator(MasonBrick masonBrick) async {
    return _generatorFactory(masonBrick, _gitUrl);
  }

  // A function to set up Get_it, AutoRoute, Dynamic Links if requested
  Future<String?> setupBasicFiles({
    required bool useRiverpod,
    required Uri? deeplinkUri,
  }) async {
    try {
      // Get the mason generator for the basic setup brick
      final generator = await _getGenerator(MasonBrick.basicSetup);

      // Generate the files from the mason brick template
      await generator.generate(
        _targetDirectory,
        vars: <String, dynamic>{
          'project-name': projectName,
          'deeplink-scheme': deeplinkUri?.scheme ?? '',
          'deeplink-host': deeplinkUri?.host ?? '',
          'use-riverpod': useRiverpod,
        },
        logger: logger,
        fileConflictResolution: FileConflictResolution.overwrite,
      );

      logger.success('Basic setup completed for $projectName');

      return null;
    } catch (e) {
      return 'Basic setup files: $e';
    }
  }

  // A function to create the API Services that should be inherited
  // by any Service making API calls
  Future<String?> setupExternalBackendFiles() async {
    try {
      logger.info(blue.wrap('Setting up api_utils...'));

      // Get the mason generator for the basic setup brick
      final generator = await _getGenerator(
        MasonBrick.basicSetupWithExternalBackend,
      );

      // Generate the files from the mason brick template
      await generator.generate(
        _targetDirectory,
        vars: <String, dynamic>{
          'project-name': projectName,
        },
        logger: logger,
        fileConflictResolution: FileConflictResolution.overwrite,
      );

      logger.success('External backend files have been setup for $projectName');

      return null;
    } catch (e) {
      return 'External backend files: $e';
    }
  }

  // A function to create the API Interceptor as well as the TokenStorage
  // and Auth services for the JWT authentication
  Future<String?> setupJWTBackendFiles() async {
    try {
      logger.info(blue.wrap('Setting up API Interceptor...'));

      // Get the mason generator for the basic setup brick
      final generator = await _getGenerator(MasonBrick.backendSetupWithJWT);

      // Generate the files from the mason brick template
      await generator.generate(
        _targetDirectory,
        vars: <String, dynamic>{
          'project-name': projectName,
        },
        logger: logger,
        fileConflictResolution: FileConflictResolution.overwrite,
      );

      logger.success(
        'Note: API, Auth, and TokenStorage services as well as the API '
        'Interceptor have been configured for $projectName. '
        'You will have to implement the refreshToken function in the '
        'AuthService.',
      );

      return null;
    } catch (e) {
      return 'JWT files: $e';
    }
  }

  Future<String?> setupNotificationFiles({
    required String applicationId,
    required bool useRiverpod,
    required Uri? deeplinkUri,
  }) async {
    try {
      logger.info(blue.wrap('Setting up push notifications...'));

      // Get the mason generator for the basic setup brick
      final generator = await _getGenerator(MasonBrick.notificationsSetup);

      // Generate the files from the mason brick template
      await generator.generate(
        _targetDirectory,
        vars: <String, dynamic>{
          'project-name': projectName,
          'application-id': applicationId,
          'deeplink-scheme': deeplinkUri?.scheme ?? '',
          'deeplink-host': deeplinkUri?.host ?? '',
          'use-riverpod': useRiverpod,
        },
        logger: logger,
        fileConflictResolution: FileConflictResolution.overwrite,
      );

      logger.success('Notification files have been setup for $projectName');

      return null;
    } catch (e) {
      return 'Notification files: $e';
    }
  }
}

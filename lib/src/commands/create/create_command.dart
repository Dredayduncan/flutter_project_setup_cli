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
      ..addFlag(
        'external-backend-with-jwt',
        abbr: 'j',
        help: 'Implement external backend with JWT configuration',
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
    _logger.info(argResults?.arguments.toString());
    final projectName = argResults?['project-name'] as String?;
    final applicationId = (argResults?['application-id'] as String?) ?? 'com.example.app';
    final applicationName = argResults?['application-name'] as String?;
    final firebaseProjectId = argResults?['firebase-project-id'] as String?;
    final externalBackendWithJwt = argResults?['external-backend-with-jwt'] as bool;
    final addPushNotifications = argResults?['add-push-notifications'] as bool;

    if (projectName == null) {
      usageException('Project name is required');
    }

    if (applicationName != null) {
      //   TODO: Change Application name
    }

    return ExitCode.success.code;
  }
}

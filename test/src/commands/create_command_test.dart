import 'dart:io';
import 'package:flutter_project_setup_cli/src/commands/create/create_command.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockLogger extends Mock implements Logger {}

class MockProcess extends Mock implements Process {}

void main() {
  group('CreateCommand', () {
    late CreateCommand command;
    late MockLogger mockLogger;

    setUp(() {
      mockLogger = MockLogger();
      command = CreateCommand(logger: mockLogger);
    });

    test('has correct name', () {
      expect(command.name, equals('create'));
    });

    test('has correct description', () {
      expect(
        command.description,
        equals('A sub command to create a flutter project'),
      );
    });

    test('has correct usage', () {
      final usage = command.argParser.usage;
      expect(usage, contains('--project-name'));
      expect(usage, contains('--application-id'));
      expect(usage, contains('--application-name'));
      expect(usage, contains('--integrate-firebase'));
      expect(usage, contains('--has-external-backend'));
      expect(usage, contains('--use-riverpod'));
      expect(usage, contains('--use-deep-linking'));
      expect(usage, contains('--add-push-notifications'));
    });
  });
}

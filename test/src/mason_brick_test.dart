import 'package:flutter_project_setup_cli/src/commands/create/utils'
    '/brick_setup.dart';
import 'package:mason/mason.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

// Mock classes
class MockLogger extends Mock implements Logger {}

class MockDirectory extends Mock implements DirectoryGeneratorTarget {}

class MockMasonGenerator extends Mock implements MasonGenerator {}

void main() {
  late BrickSetup brickSetup;
  late MockLogger mockLogger;
  late MockDirectory mockDirectory;
  late MockMasonGenerator mockGenerator;

  setUp(() {
    mockLogger = MockLogger();
    mockGenerator = MockMasonGenerator();
    mockDirectory = MockDirectory();

    Future<MasonGenerator> mockGeneratorFactory(
      MasonBrick masonBrick,
      String gitUrl,
    ) async {
      return mockGenerator;
    }

    brickSetup = BrickSetup(
      projectName: 'test_project',
      logger: mockLogger,
      generatorFactory: mockGeneratorFactory,
      targetDirectory: mockDirectory,
    );
  });

  group('BrickSetup', () {
    test('initializes correctly', () {
      expect(brickSetup.projectName, equals('test_project'));
      expect(brickSetup.logger, equals(mockLogger));
    });

    group('successfulTests', () {
      setUp(() {
        when(
          () => mockGenerator.generate(
            mockDirectory,
            vars: any(named: 'vars'),
            logger: mockLogger,
            fileConflictResolution: any(named: 'fileConflictResolution'),
          ),
        ).thenAnswer((_) async => []);
      });

      test('generates basic setup files successfully', () async {
        final result = await brickSetup.setupBasicFiles(
          useRiverpod: true,
          deeplinkUri: Uri.parse('myapp://example.com'),
        );

        // Expect
        expect(result, isNull);
        verify(() => mockLogger.success(any())).called(1);
      });

      test('generates external backend files successfully', () async {
        final result = await brickSetup.setupExternalBackendFiles();

        // Expect
        expect(result, isNull);
        verify(() => mockLogger.success(any())).called(1);
      });

      test('generates JWT files successfully', () async {
        final result = await brickSetup.setupJWTBackendFiles();

        // Expect
        expect(result, isNull);
        verify(() => mockLogger.success(any())).called(1);
      });

      test('generates notification files successfully', () async {
        final result = await brickSetup.setupNotificationFiles(
          useRiverpod: true,
          applicationId: 'com.example.app',
          deeplinkUri: Uri.parse('myapp://example.com'),
        );

        // Expect
        expect(result, isNull);
        verify(() => mockLogger.success(any())).called(1);
      });
    });

    group('FailedTests', () {
      test('handle basic setup errors', () async {
        // Stub
        when(
          () => mockGenerator.generate(
            mockDirectory,
            vars: any(named: 'vars'),
            logger: mockLogger,
            fileConflictResolution: FileConflictResolution.overwrite,
          ),
        ).thenThrow(Exception('Test error'));

        final result = await brickSetup.setupBasicFiles(
          useRiverpod: true,
          deeplinkUri: Uri.parse('myapp://example.com'),
        );

        expect(result, contains('Basic setup files'));
      });

      test('handle external backend setup errors', () async {
        // Stub
        when(
          () => mockGenerator.generate(
            mockDirectory,
            vars: any(named: 'vars'),
            logger: mockLogger,
            fileConflictResolution: FileConflictResolution.overwrite,
          ),
        ).thenThrow(Exception('Test error'));

        final result = await brickSetup.setupExternalBackendFiles();

        expect(result, contains('External backend files'));
      });

      test('handle jwt setup errors', () async {
        // Stub
        when(
          () => mockGenerator.generate(
            mockDirectory,
            vars: any(named: 'vars'),
            logger: mockLogger,
            fileConflictResolution: FileConflictResolution.overwrite,
          ),
        ).thenThrow(Exception('Test error'));

        final result = await brickSetup.setupJWTBackendFiles();

        expect(result, contains('JWT files'));
      });

      test('handle notification setup errors', () async {
        // Stub
        when(
          () => mockGenerator.generate(
            mockDirectory,
            vars: any(named: 'vars'),
            logger: mockLogger,
            fileConflictResolution: FileConflictResolution.overwrite,
          ),
        ).thenThrow(Exception('Test error'));

        final result = await brickSetup.setupNotificationFiles(
          useRiverpod: true,
          deeplinkUri: Uri.parse('myapp://example.com'),
          applicationId: 'com.example.app',
        );

        expect(result, contains('Notification files'));
      });
    });
  });
}

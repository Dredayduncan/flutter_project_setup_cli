import 'package:flutter_project_setup_cli/src/commands/create/utils/brick_setup.dart';
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
    );
  });

  group('BrickSetup', () {
    test('initializes correctly', () {
      expect(brickSetup.projectName, equals('test_project'));
      expect(brickSetup.logger, equals(mockLogger));
    });

    group('setupBasicFiles', () {

      test('generates files successfully', () async {

        // Stub
        when(() => mockGenerator.generate(
          mockDirectory,
          vars: any(named: 'vars'),
          logger: mockLogger,
          fileConflictResolution: any(named: 'fileConflictResolution'),
        ),).thenAnswer((_) async => []);

        final result = await brickSetup.setupBasicFiles(
          useRiverpod: true,
          deeplinkUri: Uri.parse('myapp://example.com'),
        );

        print("here: ${result.toString()}");

        // Expect
        expect(result, isNull);
        verify(() => mockLogger.success(any())).called(1);
      });

      test('handles errors', () async {
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
    });

    // group('setupExternalBackendFiles', () {
    //   test('generates files successfully', () async {
    //     when(
    //       () => mockGenerator.generate(
    //         any(),
    //         vars: any(named: 'vars'),
    //         logger: mockLogger,
    //         fileConflictResolution: any(named: 'fileConflictResolution'),
    //       ),
    //     ).thenAnswer((_) async {});
    //
    //     final result = await brickSetup.setupExternalBackendFiles();
    //
    //     expect(result, isNull);
    //     verify(() => mockLogger.success(any())).called(1);
    //   });
    //
    //   test('handles errors', () async {
    //     when(
    //       () => mockGenerator.generate(
    //         any(),
    //         vars: any(named: 'vars'),
    //         logger: mockLogger,
    //         fileConflictResolution: any(named: 'fileConflictResolution'),
    //       ),
    //     ).thenThrow(Exception('Test error'));
    //
    //     final result = await brickSetup.setupExternalBackendFiles();
    //
    //     expect(result, contains('Error generating files'));
    //   });
    // });
    //
    // group('setupJWTBackendFiles', () {
    //   test('generates files successfully', () async {
    //     when(
    //       () => mockGenerator.generate(
    //         any(),
    //         vars: any(named: 'vars'),
    //         logger: mockLogger,
    //         fileConflictResolution: any(named: 'fileConflictResolution'),
    //       ),
    //     ).thenAnswer((_) async {});
    //
    //     final result = await brickSetup.setupJWTBackendFiles();
    //
    //     expect(result, isNull);
    //     verify(() => mockLogger.success(any())).called(1);
    //   });
    //
    //   test('handles errors', () async {
    //     when(
    //       () => mockGenerator.generate(
    //         any(),
    //         vars: any(named: 'vars'),
    //         logger: mockLogger,
    //         fileConflictResolution: any(named: 'fileConflictResolution'),
    //       ),
    //     ).thenThrow(Exception('Test error'));
    //
    //     final result = await brickSetup.setupJWTBackendFiles();
    //
    //     expect(result, contains('Error generating files'));
    //   });
    // });
    //
    // group('setupNotificationFiles', () {
    //   test('generates files successfully', () async {
    //     when(
    //       () => mockGenerator.generate(
    //         any(),
    //         vars: any(named: 'vars'),
    //         logger: mockLogger,
    //         fileConflictResolution: any(named: 'fileConflictResolution'),
    //       ),
    //     ).thenAnswer((_) async {});
    //
    //     final result = await brickSetup.setupNotificationFiles(
    //       applicationId: 'com.example.app',
    //       useRiverpod: true,
    //       deeplinkUri: Uri.parse('myapp://example.com'),
    //     );
    //
    //     expect(result, isNull);
    //     verify(() => mockLogger.success(any())).called(1);
    //   });
    //
    //   test('handles errors', () async {
    //     when(
    //       () => mockGenerator.generate(
    //         any(),
    //         vars: any(named: 'vars'),
    //         logger: mockLogger,
    //         fileConflictResolution: any(named: 'fileConflictResolution'),
    //       ),
    //     ).thenThrow(Exception('Test error'));
    //
    //     final result = await brickSetup.setupNotificationFiles(
    //       applicationId: 'com.example.app',
    //       useRiverpod: true,
    //       deeplinkUri: Uri.parse('myapp://example.com'),
    //     );
    //
    //     expect(result, contains('Error generating files'));
    //   });
    // });
  });
}

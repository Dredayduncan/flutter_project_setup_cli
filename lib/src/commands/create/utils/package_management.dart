import 'dart:io';

class PackageManagement {
  const PackageManagement({required this.projectName});

  final String projectName;

  // Add the essential packages to the project
  Future<void> addPackages({
    required List<String> packages,
  }) async {
    await Process.run(
      'flutter',
      [
        'pub',
        'add',
        ...packages,
      ],
      workingDirectory: projectName,
    );
  }

  // Install the required dev dependencies for setup
  Future<void> _addDevPackages() async {
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
  }

  // Remove the flutter_gen package created by very_good_cli and
  // optionally the bloc packages
  Future<void> removeUnusedPackages({
    required bool useRiverpod,
    bool onlyFlutterGen = false,
  }) async {
    await Process.run(
      'flutter',
      [
        'pub',
        'remove',
        'flutter_gen',
        ...(!onlyFlutterGen && useRiverpod
            ? [
                'flutter_bloc',
                'bloc',
                'bloc_test',
              ]
            : []),
      ],
      workingDirectory: projectName,
    );
  }

  Future<void> dartFix() async {
    await Process.run(
      'dart',
      [
        'fix',
        '--apply',
      ],
      workingDirectory: projectName,
    );
  }

  // Setup the essential packages to the project
  Future<void> setupEssentialPackages({
    required bool hasExternalBackend,
    required bool useRiverpod,
  }) async {
    await addPackages(
      packages: [
        'get_it',
        'auto_route',
        'equatable',
        if (hasExternalBackend) 'dio' else '',
        if (useRiverpod) 'flutter_riverpod' else '',
      ],
    );

    await removeUnusedPackages(
      useRiverpod: useRiverpod,
    );

    await _addDevPackages();
  }

  Future<ProcessResult> buildAutoRouteFiles() async {
    return Process.run(
      'dart',
      [
        'run',
        'build_runner',
        'build',
        '--delete-conflicting-outputs',
      ],
      workingDirectory: projectName,
    );
  }

  Future<void> pubGet() async {
    await Process.run(
      'flutter',
      [
        'pub',
        'get',
      ],
      workingDirectory: projectName,
    );
  }
}

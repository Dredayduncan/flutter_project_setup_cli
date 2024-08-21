// A function to copy a directory to the specified destination
import 'dart:io';

import 'package:mason_logger/mason_logger.dart';

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

Future<bool> deleteFolder({
  required String folderPath,
  required Logger logger,
}) async {
  final directory = Directory(folderPath);

  if (directory.existsSync()) {
    try {
      await directory.delete(recursive: true);
      logger.success('Successfully deleted folder: $folderPath');
      return true;
    } catch (e) {
      logger.err('Error deleting folder: $e');
      return false;
    }
  } else {
    logger.err('Folder does not exist: $folderPath');
    return false;
  }
}

Future<bool> deleteCounterFolders({
  required String projectName,
  required Logger logger,
}) async {
  final deleteAppCounterFolder = await deleteFolder(
    folderPath: '$projectName/lib/counter',
    logger: logger,
  );
  final deleteTestCounterViewFolder = await deleteFolder(
    folderPath: '$projectName/test/counter',
    logger: logger,
  );

  return deleteAppCounterFolder && deleteTestCounterViewFolder;
}

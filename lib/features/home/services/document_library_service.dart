import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../../../app/core/app_colors.dart';
import '../models/document_item.dart';
import '../models/folder_item.dart';

class DocumentLibrarySnapshot {
  const DocumentLibrarySnapshot({
    required this.folders,
    required this.documents,
  });

  final List<FolderItem> folders;
  final List<DocumentItem> documents;
}

class DocumentLibraryService {
  static const scanFolderName = 'Scans';
  static const importFolderName = 'Imports';

  static const _libraryDirectoryName = 'doc_scanner_library';
  static const _libraryFileName = 'library.json';

  Directory? _libraryDirectory;

  Future<DocumentLibrarySnapshot> load() async {
    _libraryDirectory = await _prepareLibraryDirectory();
    final folders = <FolderItem>[];
    final documents = <DocumentItem>[];
    final file = _libraryIndexFile;

    if (await file.exists()) {
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      folders.addAll(
        (json['folders'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>()
            .map(FolderItem.fromJson),
      );
      documents.addAll(
        (json['documents'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>()
            .map((docJson) {
              // Stored path may be a full absolute path (old data) or just a
              // filename (new data). We always reconstruct from the current
              // library directory so iOS container-UUID changes don't lose data.
              final stored = docJson['path'] as String;
              final filename = stored.split('/').last;
              final absolutePath = '${_libraryDirectory!.path}/$filename';
              return DocumentItem.fromJson(
                {...docJson, 'path': absolutePath},
              );
            })
            .where((document) => File(document.path).existsSync()),
      );
    }

    _ensureDefaultFolders(folders);
    return DocumentLibrarySnapshot(folders: folders, documents: documents);
  }

  Future<void> save({
    required List<FolderItem> folders,
    required List<DocumentItem> documents,
  }) async {
    if (_libraryDirectory == null) {
      return;
    }

    // Store only the filename, not the full absolute path.
    // Full paths contain the iOS app-container UUID which changes after
    // OS updates or reinstalls, causing all imports to disappear on restart.
    final payload = {
      'folders': folders.map((folder) => folder.toJson()).toList(),
      'documents': documents.map((document) {
        final json = document.toJson();
        json['path'] = document.path.split('/').last; // filename only
        return json;
      }).toList(),
    };

    await _libraryIndexFile.writeAsString(jsonEncode(payload));
  }

  Future<File> copyIntoLibrary({
    required String sourcePath,
    required String fallbackName,
  }) async {
    await _ensureReady();
    final source = File(sourcePath);
    final cleanName = _safeFileName(fileName(fallbackName));
    final extension = fileExtension(cleanName);
    final baseName = extension.isEmpty
        ? cleanName
        : cleanName.substring(0, cleanName.length - extension.length - 1);
    final destinationName =
        '${baseName}_${DateTime.now().millisecondsSinceEpoch}'
        '${extension.isEmpty ? '' : '.$extension'}';
    final destination = File('${_libraryDirectory!.path}/$destinationName');

    return source.copy(destination.path);
  }

  /// Copies raw [bytes] into the library directory. Use this instead of
  /// [copyIntoLibrary] when the source is an [XFile] from file_selector or
  /// image_picker, because their paths may be content:// URIs on Android that
  /// [File] cannot open directly.
  Future<File> copyBytesIntoLibrary({
    required List<int> bytes,
    required String fallbackName,
  }) async {
    await _ensureReady();
    final cleanName = _safeFileName(fileName(fallbackName));
    final extension = fileExtension(cleanName);
    final baseName = extension.isEmpty
        ? cleanName
        : cleanName.substring(0, cleanName.length - extension.length - 1);
    final destinationName =
        '${baseName}_${DateTime.now().millisecondsSinceEpoch}'
        '${extension.isEmpty ? '' : '.$extension'}';
    final destination = File('${_libraryDirectory!.path}/$destinationName');

    await destination.writeAsBytes(bytes);
    return destination;
  }

  Future<bool> fileExists(String path) {
    return File(path).exists();
  }

  Future<FileStat> fileStat(String path) {
    return File(path).stat();
  }

  Future<void> deleteFile(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  FolderItem newFolder(String name, int index) {
    return FolderItem(
      name: name,
      date: formatDate(DateTime.now()),
      fileCount: 0,
      accent: accentForIndex(index),
    );
  }

  DocumentType typeFromFileName(String fileName) {
    return switch (fileExtension(fileName)) {
      'pdf' => DocumentType.pdf,
      'doc' || 'docx' => DocumentType.word,
      _ => DocumentType.image,
    };
  }

  String fileName(String path) {
    return Uri.file(path).pathSegments.last;
  }

  String fileExtension(String fileName) {
    final index = fileName.lastIndexOf('.');
    if (index == -1 || index == fileName.length - 1) {
      return '';
    }

    return fileName.substring(index + 1).toLowerCase();
  }

  String formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final value = DateTime(date.year, date.month, date.day);
    if (value == today) {
      return 'Today';
    }
    if (value == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    }

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String formatBytes(int bytes) {
    if (bytes < 1024) {
      return '${bytes}b';
    }
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).round()}kb';
    }

    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}mb';
  }

  Color accentForIndex(int index) {
    const accents = [
      AppColors.primary,
      AppColors.accent,
      AppColors.red,
      AppColors.grey,
    ];
    return accents[index % accents.length];
  }

  Future<void> _ensureReady() async {
    _libraryDirectory ??= await _prepareLibraryDirectory();
  }

  Future<Directory> _prepareLibraryDirectory() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final libraryDirectory = Directory(
      '${documentsDirectory.path}/$_libraryDirectoryName',
    );
    if (!await libraryDirectory.exists()) {
      await libraryDirectory.create(recursive: true);
    }

    return libraryDirectory;
  }

  File get _libraryIndexFile {
    return File('${_libraryDirectory!.path}/$_libraryFileName');
  }

  void _ensureDefaultFolders(List<FolderItem> folders) {
    void addIfMissing(String name, Color accent) {
      if (!folders.any((folder) => folder.name == name)) {
        folders.add(
          FolderItem(
            name: name,
            date: formatDate(DateTime.now()),
            fileCount: 0,
            accent: accent,
          ),
        );
      }
    }

    addIfMissing(scanFolderName, AppColors.primary);
    addIfMissing(importFolderName, AppColors.accent);
  }

  String _safeFileName(String value) {
    return value.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
  }
}

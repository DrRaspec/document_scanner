import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../../../app/core/app_colors.dart';
import '../models/document_item.dart';
import '../models/folder_item.dart';

enum DocumentFilter { all, pdf, word, image }

enum HomeViewMode { list, grid }

class HomeController extends GetxController {
  static const _scanFolderName = 'Scans';
  static const _importFolderName = 'Imports';
  static const _libraryFileName = 'library.json';
  static const _googleVisionApiKey = String.fromEnvironment(
    'GOOGLE_VISION_API_KEY',
  );

  final searchController = TextEditingController();
  final _imagePicker = ImagePicker();
  final _dio = Dio(
    BaseOptions(
      baseUrl: 'https://vision.googleapis.com/v1',
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 45),
    ),
  );

  final isSearching = false.obs;
  final isLoading = true.obs;
  final selectedFilter = DocumentFilter.all.obs;
  final selectedFolderName = RxnString();
  final viewMode = HomeViewMode.list.obs;
  final query = ''.obs;
  final recognizingDocumentIds = <String>{}.obs;

  final folders = <FolderItem>[].obs;
  final documents = <DocumentItem>[].obs;

  Directory? _libraryDirectory;

  List<DocumentItem> get visibleDocuments {
    return documents.where((document) {
      final filterMatches = switch (selectedFilter.value) {
        DocumentFilter.all => true,
        DocumentFilter.pdf => document.type == DocumentType.pdf,
        DocumentFilter.word => document.type == DocumentType.word,
        DocumentFilter.image => document.type == DocumentType.image,
      };

      final selectedFolder = selectedFolderName.value;
      final folderMatches =
          selectedFolder == null || document.folder == selectedFolder;

      return filterMatches && folderMatches && document.matches(query.value);
    }).toList();
  }

  int get totalPages {
    return documents.fold(0, (total, document) => total + document.pages);
  }

  String get headerSubtitle {
    return '${documents.length} scans / $totalPages pages';
  }

  @override
  void onInit() {
    super.onInit();
    loadLibrary();
  }

  Future<void> loadLibrary() async {
    isLoading.value = true;
    try {
      _libraryDirectory = await _prepareLibraryDirectory();
      final file = _libraryIndexFile;

      if (await file.exists()) {
        final content = await file.readAsString();
        final json = jsonDecode(content) as Map<String, dynamic>;
        final savedFolders = (json['folders'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>()
            .map(FolderItem.fromJson)
            .toList();
        final savedDocuments = (json['documents'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>()
            .map(DocumentItem.fromJson)
            .where((document) => File(document.path).existsSync())
            .toList();

        folders.assignAll(savedFolders);
        documents.assignAll(savedDocuments);
      }

      _ensureDefaultFolders();
      _refreshFolderCounts();
      await _saveLibrary();
    } catch (_) {
      _showActionMessage('Could not load the local document library.');
    } finally {
      isLoading.value = false;
    }
  }

  void toggleSearch() {
    isSearching.toggle();
    if (!isSearching.value) {
      searchController.clear();
      query.value = '';
    }
  }

  void updateSearch(String value) {
    query.value = value;
  }

  void selectFilter(DocumentFilter filter) {
    selectedFilter.value = filter;
  }

  void toggleFolder(FolderItem folder) {
    selectedFolderName.value = selectedFolderName.value == folder.name
        ? null
        : folder.name;
  }

  void setViewMode(HomeViewMode mode) {
    viewMode.value = mode;
  }

  Future<void> startScan() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 92,
      );
      if (image == null) {
        return;
      }

      final savedFile = await _copyIntoLibrary(
        sourcePath: image.path,
        fallbackName: 'scan_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      final stat = await savedFile.stat();
      final document = DocumentItem(
        id: _newId(),
        title: _fileName(savedFile.path),
        date: _formatDate(DateTime.now()),
        sizeLabel: _formatBytes(stat.size),
        type: DocumentType.image,
        pages: 1,
        folder: _targetFolderName(_scanFolderName),
        path: savedFile.path,
        createdAt: DateTime.now(),
      );

      documents.insert(0, document);
      _refreshFolderCounts();
      await _saveLibrary();
      _showActionMessage('Scan saved.');
    } catch (_) {
      _showActionMessage('Camera scan was not completed.');
    }
  }

  Future<void> importPhoto() async {
    try {
      final result = await FilePicker.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: const [
          'pdf',
          'doc',
          'docx',
          'jpg',
          'jpeg',
          'png',
          'heic',
          'webp',
        ],
      );
      if (result == null || result.files.isEmpty) {
        return;
      }

      var importedCount = 0;
      for (final pickedFile in result.files) {
        final path = pickedFile.path;
        if (path == null) {
          continue;
        }

        final savedFile = await _copyIntoLibrary(
          sourcePath: path,
          fallbackName: pickedFile.name,
        );
        final stat = await savedFile.stat();
        documents.insert(
          0,
          DocumentItem(
            id: _newId(),
            title: pickedFile.name,
            date: _formatDate(DateTime.now()),
            sizeLabel: _formatBytes(stat.size),
            type: _typeFromFileName(pickedFile.name),
            pages: 1,
            folder: _targetFolderName(_importFolderName),
            path: savedFile.path,
            createdAt: DateTime.now(),
          ),
        );
        importedCount++;
      }

      if (importedCount == 0) {
        _showActionMessage('No supported files were imported.');
        return;
      }

      _refreshFolderCounts();
      await _saveLibrary();
      _showActionMessage('$importedCount file(s) imported.');
    } catch (_) {
      _showActionMessage('Import was not completed.');
    }
  }

  Future<void> createFolder() async {
    final nameController = TextEditingController();
    final name = await Get.dialog<String>(
      AlertDialog(
        title: const Text('New folder'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'Folder name'),
          onSubmitted: (value) => Get.back(result: value),
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Get.back(result: nameController.text),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    nameController.dispose();

    final cleanName = name?.trim();
    if (cleanName == null || cleanName.isEmpty) {
      return;
    }
    if (folders.any(
      (folder) => folder.name.toLowerCase() == cleanName.toLowerCase(),
    )) {
      _showActionMessage('That folder already exists.');
      return;
    }

    folders.add(
      FolderItem(
        name: cleanName,
        date: _formatDate(DateTime.now()),
        fileCount: 0,
        accent: _accentForIndex(folders.length),
      ),
    );
    selectedFolderName.value = cleanName;
    await _saveLibrary();
    _showActionMessage('$cleanName created.');
  }

  Future<void> openDocument(DocumentItem document) async {
    final file = File(document.path);
    if (!await file.exists()) {
      _showActionMessage('This file is missing from local storage.');
      return;
    }

    final result = await OpenFilex.open(document.path);
    if (result.type != ResultType.done) {
      _showActionMessage(result.message);
    }
  }

  Future<void> showDocumentMenu(DocumentItem document) async {
    final action = await Get.bottomSheet<_DocumentAction>(
      SafeArea(
        child: Material(
          color: AppColors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (document.type == DocumentType.image)
                ListTile(
                  leading: const Icon(Icons.translate),
                  title: const Text('Recognize Khmer text'),
                  subtitle: const Text('Uses Google Vision OCR with km hint'),
                  onTap: () => Get.back(result: _DocumentAction.recognizeText),
                ),
              if (document.hasOcrText)
                ListTile(
                  leading: const Icon(Icons.notes_outlined),
                  title: const Text('View extracted text'),
                  onTap: () => Get.back(result: _DocumentAction.viewText),
                ),
              ListTile(
                leading: const Icon(Icons.open_in_new),
                title: const Text('Open'),
                onTap: () => Get.back(result: _DocumentAction.open),
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.red),
                title: const Text('Delete'),
                onTap: () => Get.back(result: _DocumentAction.delete),
              ),
            ],
          ),
        ),
      ),
    );

    if (action == _DocumentAction.open) {
      await openDocument(document);
    } else if (action == _DocumentAction.recognizeText) {
      await recognizeKhmerText(document);
    } else if (action == _DocumentAction.viewText) {
      _showExtractedText(document);
    } else if (action == _DocumentAction.delete) {
      await _deleteDocument(document);
    }
  }

  Future<void> recognizeKhmerText(DocumentItem document) async {
    final apiKey = _googleVisionApiKeyFromEnv;
    if (apiKey.isEmpty) {
      _showActionMessage(
        'Missing GOOGLE_VISION_API_KEY in .env or --dart-define.',
      );
      return;
    }
    if (document.type != DocumentType.image) {
      _showActionMessage('OCR currently supports image scans only.');
      return;
    }
    if (recognizingDocumentIds.contains(document.id)) {
      return;
    }

    recognizingDocumentIds.add(document.id);
    try {
      final imageBytes = await File(document.path).readAsBytes();
      final response = await _dio.post<Map<String, dynamic>>(
        '/images:annotate',
        queryParameters: {'key': apiKey},
        data: {
          'requests': [
            {
              'image': {'content': base64Encode(imageBytes)},
              'features': [
                {'type': 'DOCUMENT_TEXT_DETECTION'},
              ],
              'imageContext': {
                'languageHints': ['km', 'en'],
              },
            },
          ],
        },
      );
      final text = _extractVisionText(response.data);
      final cleanText = text.trim();
      if (cleanText.isEmpty) {
        _showActionMessage('No Khmer text was found in this image.');
        return;
      }

      final index = documents.indexWhere((item) => item.id == document.id);
      if (index == -1) {
        return;
      }

      final updated = documents[index].copyWith(ocrText: cleanText);
      documents[index] = updated;
      await _saveLibrary();
      _showExtractedText(updated);
    } on DioException catch (error) {
      final responseData = error.response?.data;
      final responseError = responseData is Map ? responseData['error'] : null;
      final message = responseError is Map
          ? responseError['message']?.toString()
          : null;
      _showActionMessage(message ?? 'Khmer OCR request failed.');
    } catch (_) {
      _showActionMessage('Khmer OCR failed for this image.');
    } finally {
      recognizingDocumentIds.remove(document.id);
    }
  }

  String get _googleVisionApiKeyFromEnv {
    return dotenv.env['GOOGLE_VISION_API_KEY']?.trim().isNotEmpty == true
        ? dotenv.env['GOOGLE_VISION_API_KEY']!.trim()
        : _googleVisionApiKey;
  }

  String _extractVisionText(Map<String, dynamic>? data) {
    final responses = data?['responses'];
    if (responses is! List || responses.isEmpty) {
      return '';
    }

    final first = responses.first;
    if (first is! Map<String, dynamic>) {
      return '';
    }
    final annotation = first['fullTextAnnotation'];
    if (annotation is Map<String, dynamic>) {
      return annotation['text']?.toString() ?? '';
    }

    final textAnnotations = first['textAnnotations'];
    if (textAnnotations is List && textAnnotations.isNotEmpty) {
      final firstText = textAnnotations.first;
      if (firstText is Map<String, dynamic>) {
        return firstText['description']?.toString() ?? '';
      }
    }

    return '';
  }

  void _showExtractedText(DocumentItem document) {
    final text = document.ocrText?.trim();
    if (text == null || text.isEmpty) {
      _showActionMessage('No extracted text saved yet.');
      return;
    }

    Get.dialog<void>(
      AlertDialog(
        title: Text(document.title),
        content: SingleChildScrollView(child: SelectableText(text)),
        actions: [TextButton(onPressed: Get.back, child: const Text('Close'))],
      ),
    );
  }

  Future<void> _deleteDocument(DocumentItem document) async {
    documents.removeWhere((item) => item.id == document.id);
    final file = File(document.path);
    if (await file.exists()) {
      await file.delete();
    }
    _refreshFolderCounts();
    await _saveLibrary();
    _showActionMessage('${document.title} deleted.');
  }

  Future<Directory> _prepareLibraryDirectory() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final libraryDirectory = Directory(
      '${documentsDirectory.path}/doc_scanner_library',
    );
    if (!await libraryDirectory.exists()) {
      await libraryDirectory.create(recursive: true);
    }

    return libraryDirectory;
  }

  File get _libraryIndexFile {
    return File('${_libraryDirectory!.path}/$_libraryFileName');
  }

  Future<File> _copyIntoLibrary({
    required String sourcePath,
    required String fallbackName,
  }) async {
    final source = File(sourcePath);
    final cleanName = _safeFileName(_fileName(fallbackName));
    final extension = _extension(cleanName);
    final baseName = extension.isEmpty
        ? cleanName
        : cleanName.substring(0, cleanName.length - extension.length - 1);
    final destinationName =
        '${baseName}_${DateTime.now().millisecondsSinceEpoch}'
        '${extension.isEmpty ? '' : '.$extension'}';
    final destination = File('${_libraryDirectory!.path}/$destinationName');

    return source.copy(destination.path);
  }

  void _ensureDefaultFolders() {
    void addIfMissing(String name, Color accent) {
      if (!folders.any((folder) => folder.name == name)) {
        folders.add(
          FolderItem(
            name: name,
            date: _formatDate(DateTime.now()),
            fileCount: 0,
            accent: accent,
          ),
        );
      }
    }

    addIfMissing(_scanFolderName, AppColors.primary);
    addIfMissing(_importFolderName, AppColors.accent);
  }

  String _targetFolderName(String fallback) {
    final selected = selectedFolderName.value;
    if (selected == null || selected.isEmpty) {
      return fallback;
    }

    return selected;
  }

  void _refreshFolderCounts() {
    folders.assignAll(
      folders.map((folder) {
        final count = documents
            .where((document) => document.folder == folder.name)
            .length;
        return folder.copyWith(fileCount: count);
      }).toList(),
    );
  }

  Future<void> _saveLibrary() async {
    if (_libraryDirectory == null) {
      return;
    }

    final payload = {
      'folders': folders.map((folder) => folder.toJson()).toList(),
      'documents': documents.map((document) => document.toJson()).toList(),
    };

    await _libraryIndexFile.writeAsString(jsonEncode(payload));
  }

  String _newId() {
    return DateTime.now().microsecondsSinceEpoch.toString();
  }

  String _fileName(String path) {
    return Uri.file(path).pathSegments.last;
  }

  String _safeFileName(String value) {
    return value.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
  }

  String _extension(String fileName) {
    final index = fileName.lastIndexOf('.');
    if (index == -1 || index == fileName.length - 1) {
      return '';
    }

    return fileName.substring(index + 1).toLowerCase();
  }

  DocumentType _typeFromFileName(String fileName) {
    return switch (_extension(fileName)) {
      'pdf' => DocumentType.pdf,
      'doc' || 'docx' => DocumentType.word,
      _ => DocumentType.image,
    };
  }

  String _formatDate(DateTime date) {
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

  String _formatBytes(int bytes) {
    if (bytes < 1024) {
      return '${bytes}b';
    }
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).round()}kb';
    }

    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}mb';
  }

  Color _accentForIndex(int index) {
    const accents = [
      AppColors.primary,
      AppColors.accent,
      AppColors.red,
      AppColors.grey,
    ];
    return accents[index % accents.length];
  }

  void _showActionMessage(String message) {
    Get.snackbar(
      'Document Scanner',
      message,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 132),
      backgroundColor: AppColors.primaryBlack,
      colorText: AppColors.white,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
}

enum _DocumentAction { recognizeText, viewText, open, delete }

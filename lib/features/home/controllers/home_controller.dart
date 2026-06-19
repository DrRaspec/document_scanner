import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../viewer/screens/document_viewer_screen.dart';
import '../dialogs/home_dialogs.dart';
import '../models/document_item.dart';
import '../models/folder_item.dart';
import '../services/document_library_service.dart';
import '../services/ocr_service.dart';
import '../services/text_extraction_service.dart';

enum DocumentFilter { all, pdf, word, image }

enum HomeViewMode { list, grid }

class HomeController extends GetxController {
  final searchController = TextEditingController();
  final _dialogs = HomeDialogs();
  final _library = DocumentLibraryService();
  final _ocr = OcrService();
  final _textExtraction = TextExtractionService();
  final _imagePicker = ImagePicker();

  final isSearching = false.obs;
  final isLoading = true.obs;
  final selectedFilter = DocumentFilter.all.obs;
  final selectedFolderName = RxnString();
  final viewMode = HomeViewMode.list.obs;
  final query = ''.obs;
  final recognizingDocumentIds = <String>{}.obs;

  final folders = <FolderItem>[].obs;
  final documents = <DocumentItem>[].obs;

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
      final snapshot = await _library.load();
      folders.assignAll(snapshot.folders);
      documents.assignAll(snapshot.documents);
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
      final image = await _imagePicker.pickImage(source: ImageSource.camera);
      if (image == null) {
        return;
      }

      final bytes = await image.readAsBytes();
      final fallbackName = 'scan_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedFile = await _library.copyBytesIntoLibrary(
        bytes: bytes,
        fallbackName: fallbackName,
      );
      final document = await _scannedDocumentFrom(savedFile.path);

      documents.insert(0, document);
      _refreshFolderCounts();
      await _saveLibrary();
      _showActionMessage('Scan saved.');
    } catch (error) {
      _showActionMessage('Camera scan failed: $error');
    }
  }

  Future<void> importPhoto() async {
    final source = await _dialogs.showImportSourceDialog();
    switch (source) {
      case ImportSource.photos:
        await _importImageFromGallery();
      case ImportSource.files:
        await importFiles();
      case null:
        break;
    }
  }

  Future<void> _importImageFromGallery() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 92,
      );
      if (image == null) {
        return;
      }

      final bytes = await image.readAsBytes();
      final savedFile = await _library.copyBytesIntoLibrary(
        bytes: bytes,
        fallbackName: image.name,
      );
      final document = await _importedDocumentFrom(
        title: image.name,
        path: savedFile.path,
      );

      documents.insert(0, document);
      _refreshFolderCounts();
      await _saveLibrary();
      _showActionMessage('Image imported.');
    } catch (error) {
      _showActionMessage('Image import failed: $error');
    }
  }

  Future<void> importFiles() async {
    try {
      const typeGroup = XTypeGroup(
        label: 'Documents',
        // extensions: used on Android & desktop
        extensions: ['pdf', 'doc', 'docx'],
        // uniformTypeIdentifiers: required on iOS.
        uniformTypeIdentifiers: [
          'com.adobe.pdf', // .pdf
          'com.microsoft.word.doc', // .doc (legacy binary)
          // .docx — two UTIs for broad device support
          'org.openxmlformats.officedocument.wordprocessingml.document',
          'com.microsoft.word.wordml',
          'public.composite-content', // fallback for document-like files
        ],
      );
      final List<XFile> files;
      if (Platform.isIOS) {
        final file = await openFile();
        files = file == null ? <XFile>[] : <XFile>[file];
      } else {
        files = await openFiles(acceptedTypeGroups: [typeGroup]);
      }
      if (files.isEmpty) {
        return;
      }

      var importedCount = 0;
      for (final pickedFile in files) {
        if (!_isSupportedImportFile(pickedFile.name)) {
          continue;
        }

        // Use readAsBytes() instead of File(path).copy() so the code works
        // on Android where file_selector may return a content:// URI path
        // that File() cannot open directly.
        final bytes = await pickedFile.readAsBytes();
        final savedFile = await _library.copyBytesIntoLibrary(
          bytes: bytes,
          fallbackName: pickedFile.name,
        );
        final document = await _importedDocumentFrom(
          title: pickedFile.name,
          path: savedFile.path,
        );
        documents.insert(0, document);
        importedCount++;
      }

      if (importedCount == 0) {
        _showActionMessage('No supported files were imported.');
        return;
      }

      _refreshFolderCounts();
      await _saveLibrary();
      _showActionMessage('$importedCount file(s) imported.');
    } catch (error) {
      _showActionMessage('Import failed: $error');
    }
  }

  bool _isSupportedImportFile(String fileName) {
    const supportedExtensions = {'pdf', 'doc', 'docx'};
    return supportedExtensions.contains(_library.fileExtension(fileName));
  }

  Future<void> showHomeMenu() async {
    final action = await _dialogs.showHomeMenu();

    switch (action) {
      case HomeMenuAction.scan:
        await startScan();
      case HomeMenuAction.importFiles:
        await importFiles();
      case HomeMenuAction.newFolder:
        await createFolder();
      case HomeMenuAction.refresh:
        await loadLibrary();
      case null:
        break;
    }
  }

  Future<void> createFolder() async {
    final name = await _dialogs.showCreateFolderDialog();
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

    folders.add(_library.newFolder(cleanName, folders.length));
    selectedFolderName.value = cleanName;
    await _saveLibrary();
    _showActionMessage('$cleanName created.');
  }

  Future<void> openDocument(DocumentItem document) async {
    if (!await _library.fileExists(document.path)) {
      _showActionMessage('This file is missing from local storage.');
      return;
    }

    Get.to(() => DocumentViewerScreen(document: document));
  }

  Future<void> showDocumentMenu(DocumentItem document) async {
    final action = await _dialogs.showDocumentMenu(document);

    switch (action) {
      case DocumentMenuAction.open:
        await openDocument(document);
      case DocumentMenuAction.recognizeText:
        await recognizeText(document);
      case DocumentMenuAction.viewText:
        _showExtractedText(document);
      case DocumentMenuAction.delete:
        await _deleteDocument(document);
      case null:
        break;
    }
  }

  Future<void> recognizeText(DocumentItem document) async {
    if (recognizingDocumentIds.contains(document.id)) return;
    recognizingDocumentIds.add(document.id);

    try {
      final String extractedText;

      if (document.type == DocumentType.image) {
        // ── Image: use offline OCR (Tesseract on Android / Vision on iOS) ──
        if (!_ocr.supportsOfflineOcr) {
          _showActionMessage('OCR is not supported on this platform.');
          return;
        }
        extractedText = await _ocr.recognizeImageText(document.path);
        if (extractedText.isEmpty) {
          _showActionMessage('No readable text was found in this image.');
          return;
        }
      } else if (document.type == DocumentType.pdf && _ocr.supportsOfflineOcr) {
        extractedText = await _ocr.recognizePdfText(document.path);
        if (extractedText.isEmpty) {
          _showActionMessage('No readable text was found in this PDF.');
          return;
        }
      } else {
        // ── PDF / Word: extract embedded text layer ──
        extractedText = await _textExtraction.extractText(document.path);
      }

      final index = documents.indexWhere((item) => item.id == document.id);
      if (index == -1) return;

      final updated = documents[index].copyWith(ocrText: extractedText);
      documents[index] = updated;
      await _saveLibrary();
      _showExtractedText(updated);
    } on UnsupportedError catch (error) {
      _showActionMessage(error.message ?? 'This file type is not supported.');
    } on FormatException catch (error) {
      _showActionMessage(error.message);
    } on PlatformException catch (error) {
      _showActionMessage(error.message ?? 'Text recognition failed.');
    } catch (error) {
      _showActionMessage('Text extraction failed: $error');
    } finally {
      recognizingDocumentIds.remove(document.id);
    }
  }

  void _showExtractedText(DocumentItem document) {
    _dialogs.showExtractedText(document);
  }

  Future<void> _deleteDocument(DocumentItem document) async {
    documents.removeWhere((item) => item.id == document.id);
    await _library.deleteFile(document.path);
    _refreshFolderCounts();
    await _saveLibrary();
    _showActionMessage('${document.title} deleted.');
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

  Future<DocumentItem> _scannedDocumentFrom(String path) async {
    final stat = await _library.fileStat(path);
    return DocumentItem(
      id: _newId(),
      title: _library.fileName(path),
      date: _library.formatDate(DateTime.now()),
      sizeLabel: _library.formatBytes(stat.size),
      type: DocumentType.image,
      pages: 1,
      folder: _targetFolderName(DocumentLibraryService.scanFolderName),
      path: path,
      createdAt: DateTime.now(),
    );
  }

  Future<DocumentItem> _importedDocumentFrom({
    required String title,
    required String path,
  }) async {
    final stat = await _library.fileStat(path);
    return DocumentItem(
      id: _newId(),
      title: title,
      date: _library.formatDate(DateTime.now()),
      sizeLabel: _library.formatBytes(stat.size),
      type: _library.typeFromFileName(title),
      pages: 1,
      folder: _targetFolderName(DocumentLibraryService.importFolderName),
      path: path,
      createdAt: DateTime.now(),
    );
  }

  Future<void> _saveLibrary() async {
    await _library.save(folders: folders, documents: documents);
  }

  String _newId() {
    return DateTime.now().microsecondsSinceEpoch.toString();
  }

  void _showActionMessage(String message) {
    _dialogs.showMessage(message);
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
}

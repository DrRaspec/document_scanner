import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../app/core/app_colors.dart';
import '../models/document_item.dart';

enum HomeMenuAction { scan, importFiles, newFolder, refresh }

enum DocumentMenuAction { recognizeText, viewText, open, delete }

enum ImportSource { photos, files }

class HomeDialogs {
  Future<HomeMenuAction?> showHomeMenu() {
    return Get.bottomSheet<HomeMenuAction>(
      SafeArea(
        child: Material(
          color: AppColors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.document_scanner_outlined),
                title: const Text('Scan document'),
                onTap: () => Get.back(result: HomeMenuAction.scan),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Import files'),
                onTap: () => Get.back(result: HomeMenuAction.importFiles),
              ),
              ListTile(
                leading: const Icon(Icons.create_new_folder_outlined),
                title: const Text('New folder'),
                onTap: () => Get.back(result: HomeMenuAction.newFolder),
              ),
              ListTile(
                leading: const Icon(Icons.refresh),
                title: const Text('Refresh library'),
                onTap: () => Get.back(result: HomeMenuAction.refresh),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String?> showCreateFolderDialog() {
    var folderName = '';

    return Get.dialog<String>(
      AlertDialog(
        title: const Text('New folder'),
        content: TextField(
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'Folder name'),
          onChanged: (value) => folderName = value,
          onSubmitted: (value) => Get.back(result: value),
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Get.back(result: folderName),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<ImportSource?> showImportSourceDialog() {
    return Get.bottomSheet<ImportSource>(
      SafeArea(
        child: Material(
          color: AppColors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Photo library'),
                subtitle: const Text('Import an image from Photos'),
                onTap: () => Get.back(result: ImportSource.photos),
              ),
              ListTile(
                leading: const Icon(Icons.folder_open_outlined),
                title: const Text('Files'),
                subtitle: const Text('Import PDF or Word documents'),
                onTap: () => Get.back(result: ImportSource.files),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<DocumentMenuAction?> showDocumentMenu(DocumentItem document) {
    return Get.bottomSheet<DocumentMenuAction>(
      SafeArea(
        child: Material(
          color: AppColors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Extract / Recognize text ──────────────────────────────
              if (document.type == DocumentType.image)
                ListTile(
                  leading: const Icon(Icons.translate),
                  title: const Text('Recognize text'),
                  subtitle: const Text(
                    'Offline OCR — Android (Tesseract) & iOS (Vision)',
                  ),
                  onTap: () =>
                      Get.back(result: DocumentMenuAction.recognizeText),
                )
              else if (document.type == DocumentType.pdf)
                ListTile(
                  leading: const Icon(Icons.picture_as_pdf_outlined),
                  title: const Text('Extract text'),
                  subtitle: const Text('Pull all embedded text from this PDF'),
                  onTap: () =>
                      Get.back(result: DocumentMenuAction.recognizeText),
                )
              else if (document.type == DocumentType.word)
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: const Text('Extract text'),
                  subtitle: const Text(
                    'Read text content from this Word document (.docx)',
                  ),
                  onTap: () =>
                      Get.back(result: DocumentMenuAction.recognizeText),
                ),
              if (document.hasOcrText)
                ListTile(
                  leading: const Icon(Icons.notes_outlined),
                  title: const Text('View extracted text'),
                  onTap: () => Get.back(result: DocumentMenuAction.viewText),
                ),
              ListTile(
                leading: const Icon(Icons.open_in_new),
                title: const Text('Open'),
                onTap: () => Get.back(result: DocumentMenuAction.open),
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.red),
                title: const Text('Delete'),
                onTap: () => Get.back(result: DocumentMenuAction.delete),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void showExtractedText(DocumentItem document) {
    final text = document.ocrText?.trim();
    if (text == null || text.isEmpty) {
      showMessage('No extracted text saved yet.');
      return;
    }

    Get.dialog<void>(
      // barrierDismissible:false so a long-press to start text selection
      // doesn't accidentally dismiss the dialog.
      barrierDismissible: false,
      Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      document.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: Get.back,
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // ── Selectable text body ──
            // SelectionArea lets the OS handle text selection natively
            // without conflicting with scroll gestures.
            Flexible(
              child: SelectionArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Text(text),
                ),
              ),
            ),
            const Divider(height: 1),
            // ── Actions ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // One-tap copy for users who find text selection tricky
                  TextButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: text));
                      showMessage('Text copied to clipboard.');
                    },
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('Copy all'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(onPressed: Get.back, child: const Text('Close')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void showMessage(String message) {
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
}

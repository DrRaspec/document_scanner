import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class OcrService {
  static const _channel = MethodChannel('doc_scanner/ocr');

  /// Returns true on Android (Tesseract) and iOS 13+ (Vision framework).
  bool get supportsOfflineOcr => Platform.isAndroid || Platform.isIOS;

  Future<String> recognizeImageText(String imagePath) async {
    if (Platform.isIOS) {
      // iOS: delegate to the Vision framework handler in AppDelegate.swift.
      // No tessdata assets needed — the OS handles the model.
      final text = await _channel.invokeMethod<String>('recognizeText', {
        'imagePath': imagePath,
      });
      return text?.trim() ?? '';
    }

    // Android: Tesseract via native method channel.
    final tessDataPath = await _prepareTessData();
    final text = await _channel.invokeMethod<String>('recognizeText', {
      'imagePath': imagePath,
      'dataPath': tessDataPath,
      'language': _language,
    });
    return text?.trim() ?? '';
  }

  // ─── Android-only helpers ────────────────────────────────────────────────

  static const _language = 'khm+eng';
  static const _trainedDataFiles = ['khm.traineddata', 'eng.traineddata'];

  Future<String> _prepareTessData() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final tessDataDirectory = Directory('${documentsDirectory.path}/tessdata');
    if (!await tessDataDirectory.exists()) {
      await tessDataDirectory.create(recursive: true);
    }

    for (final fileName in _trainedDataFiles) {
      await _copyTessDataIfNeeded(tessDataDirectory, fileName);
    }

    return documentsDirectory.path;
  }

  Future<void> _copyTessDataIfNeeded(
    Directory tessDataDirectory,
    String fileName,
  ) async {
    final file = File('${tessDataDirectory.path}/$fileName');
    if (await file.exists()) {
      return;
    }

    final data = await rootBundle.load('assets/tessdata/$fileName');
    await file.writeAsBytes(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
  }
}

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class OcrService {
  static const _channel = MethodChannel('doc_scanner/ocr');

  /// Returns true on Android and iOS, both backed by Tesseract.
  bool get supportsOfflineOcr => Platform.isAndroid || Platform.isIOS;

  Future<String> recognizeImageText(
    String imagePath, {
    String language = _mixedLanguage,
  }) async {
    if (Platform.isIOS) {
      final tessDataPath = await _prepareTessDataDirectory();
      final text = await _channel.invokeMethod<String>('recognizeText', {
        'imagePath': imagePath,
        'dataPath': tessDataPath,
        'language': language,
      });
      return text?.trim() ?? '';
    }

    // Android: Tesseract via native method channel.
    final tessDataPath = await _prepareTessData();
    final text = await _channel.invokeMethod<String>('recognizeText', {
      'imagePath': imagePath,
      'dataPath': tessDataPath,
      'language': language,
    });
    return text?.trim() ?? '';
  }

  Future<String> recognizePdfText(
    String pdfPath, {
    String language = _khmerLanguage,
  }) async {
    if (!supportsOfflineOcr) {
      throw UnsupportedError('OCR is not supported on this platform.');
    }

    if (Platform.isIOS) {
      final tessDataPath = await _prepareTessDataDirectory();
      final text = await _channel.invokeMethod<String>('recognizePdfText', {
        'pdfPath': pdfPath,
        'dataPath': tessDataPath,
        'language': language,
      });
      return text?.trim() ?? '';
    }

    final tessDataPath = await _prepareTessData();
    final text = await _channel.invokeMethod<String>('recognizePdfText', {
      'pdfPath': pdfPath,
      'dataPath': tessDataPath,
      'language': language,
    });
    return text?.trim() ?? '';
  }

  // ─── Android-only helpers ────────────────────────────────────────────────

  static const _khmerLanguage = 'khm';
  static const _mixedLanguage = 'khm+eng';
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

  Future<String> _prepareTessDataDirectory() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final tessDataDirectory = Directory('${documentsDirectory.path}/tessdata');
    if (!await tessDataDirectory.exists()) {
      await tessDataDirectory.create(recursive: true);
    }

    for (final fileName in _trainedDataFiles) {
      await _copyTessDataIfNeeded(tessDataDirectory, fileName);
    }

    return tessDataDirectory.path;
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

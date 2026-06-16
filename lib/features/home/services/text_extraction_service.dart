import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// Extracts the readable text content from PDF and Word (DOCX) files.
///
/// * PDF   → `syncfusion_flutter_pdf` PdfTextExtractor (pure Dart, both platforms)
/// * DOCX  → unzip with `archive` + parse `word/document.xml` `w:t` nodes
/// * DOC   → unsupported (legacy binary format — advise re-save as .docx)
class TextExtractionService {
  // ─── Public API ────────────────────────────────────────────────────────────

  /// Returns true when this service can handle [path].
  bool supports(String path) {
    final ext = _ext(path);
    return ext == 'pdf' || ext == 'docx' || ext == 'doc';
  }

  /// Extracts and returns all readable text from the file at [path].
  ///
  /// Throws [UnsupportedError] for legacy .doc files.
  /// Throws [FormatException] if the file content is unreadable.
  Future<String> extractText(String path) async {
    switch (_ext(path)) {
      case 'pdf':
        return _extractFromPdf(path);
      case 'docx':
        return _extractFromDocx(path);
      case 'doc':
        throw UnsupportedError(
          'Legacy .doc format cannot be parsed directly.\n'
          'Open the file in Word, save it as .docx, then re-import.',
        );
      default:
        throw UnsupportedError('Unsupported file type: $path');
    }
  }

  // ─── PDF ───────────────────────────────────────────────────────────────────

  Future<String> _extractFromPdf(String path) async {
    final bytes = await File(path).readAsBytes();
    final document = PdfDocument(inputBytes: bytes);
    try {
      final text = PdfTextExtractor(document).extractText();
      if (text.trim().isEmpty) {
        // PDF may be image-based (scanned) — no embedded text layer
        throw const FormatException(
          'This PDF contains no embedded text. '
          'It may be a scanned/image PDF — try importing the original image instead.',
        );
      }
      return text.trim();
    } finally {
      document.dispose();
    }
  }

  // ─── DOCX ──────────────────────────────────────────────────────────────────

  Future<String> _extractFromDocx(String path) async {
    final bytes = await File(path).readAsBytes();
    late final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes);
    } catch (_) {
      throw const FormatException(
        'Could not read this .docx file. The file may be corrupted.',
      );
    }

    final docFile = archive.findFile('word/document.xml');
    if (docFile == null) {
      throw const FormatException(
        'Could not locate the document content inside this .docx file.',
      );
    }

    final xml = utf8.decode(docFile.content as List<int>);
    final text = _parseWordXml(xml);

    if (text.isEmpty) {
      throw const FormatException('No readable text was found in this document.');
    }
    return text;
  }

  /// Parses Office Open XML and reconstructs text paragraph by paragraph.
  String _parseWordXml(String xml) {
    final buffer = StringBuffer();

    // Each <w:p> is a paragraph
    final paraPattern = RegExp(r'<w:p[ >][\s\S]*?</w:p>', dotAll: true);

    for (final paraMatch in paraPattern.allMatches(xml)) {
      final paraXml = paraMatch.group(0)!;
      final lineBuffer = StringBuffer();

      // Each <w:t> is a text run; xml:space="preserve" runs keep whitespace
      final runPattern = RegExp(r'<w:t(?:\s[^>]*)?>([^<]*)</w:t>');
      for (final runMatch in runPattern.allMatches(paraXml)) {
        lineBuffer.write(runMatch.group(1));
      }

      final line = lineBuffer.toString().trim();
      if (line.isNotEmpty) {
        buffer.writeln(line);
      }
    }

    return buffer.toString().trim();
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  String _ext(String path) => path.split('.').last.toLowerCase();
}

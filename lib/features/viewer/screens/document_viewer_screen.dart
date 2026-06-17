import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../home/models/document_item.dart';
import '../../home/services/ocr_service.dart';
import '../../home/services/text_extraction_service.dart';

class DocumentViewerScreen extends StatefulWidget {
  final DocumentItem document;

  const DocumentViewerScreen({super.key, required this.document});

  @override
  State<DocumentViewerScreen> createState() => _DocumentViewerScreenState();
}

class _DocumentViewerScreenState extends State<DocumentViewerScreen> {
  final _pdfViewerController = PdfViewerController();
  final _ocrService = OcrService();
  final _textExtraction = TextExtractionService();
  bool _isExtractingPdfText = false;

  Widget _buildBody() {
    switch (widget.document.type) {
      case DocumentType.pdf:
        return SfPdfViewer.file(
          File(widget.document.path),
          controller: _pdfViewerController,
          enableTextSelection: true,
          initialZoomLevel: 1.25,
          pageSpacing: 0,
          canShowScrollHead: false,
          pageLayoutMode: PdfPageLayoutMode.continuous,
          onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Failed to load PDF: ${details.error} - ${details.description}',
                ),
                duration: const Duration(seconds: 10),
              ),
            );
          },
        );
      case DocumentType.image:
        return _ImageViewer(document: widget.document);
      case DocumentType.word:
        return _WordViewer(document: widget.document);
    }
  }

  Future<void> _showPdfTextBottomSheet() async {
    setState(() {
      _isExtractingPdfText = true;
    });

    String textToShow;
    try {
      textToShow = _ocrService.supportsOfflineOcr
          ? await _ocrService.recognizePdfText(widget.document.path)
          : await _textExtraction.extractText(widget.document.path);

      if (textToShow.trim().isEmpty && _ocrService.supportsOfflineOcr) {
        textToShow = await _extractPdfFallbackText();
      }
    } catch (e) {
      textToShow = 'Could not extract selectable text from this PDF.\n\n$e';
    } finally {
      if (mounted) {
        setState(() {
          _isExtractingPdfText = false;
        });
      }
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          minChildSize: 0.35,
          builder: (context, scrollController) {
            final canCopy = !textToShow.startsWith('Could not extract');

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'PDF Text',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Copy all',
                        icon: const Icon(Icons.copy),
                        onPressed: canCopy
                            ? () {
                                Clipboard.setData(
                                  ClipboardData(text: textToShow),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Copied to clipboard'),
                                  ),
                                );
                              }
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: SelectionArea(
                        child: Text(
                          textToShow.trim().isEmpty
                              ? 'No text found.'
                              : textToShow,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<String> _extractPdfFallbackText() async {
    try {
      final fallbackText = await _textExtraction.extractText(
        widget.document.path,
      );
      if (fallbackText.trim().isEmpty) {
        return 'OCR found no text in this PDF.';
      }

      return 'OCR found no text. Fallback text from the PDF layer is shown below, but it may be incorrect for Khmer.\n\n$fallbackText';
    } catch (_) {
      return 'OCR found no text in this PDF.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.document.title),
        actions: [
          if (widget.document.type == DocumentType.pdf)
            IconButton(
              tooltip: 'Extract text',
              onPressed: _isExtractingPdfText ? null : _showPdfTextBottomSheet,
              icon: _isExtractingPdfText
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.text_fields),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }
}

class _ImageViewer extends StatefulWidget {
  final DocumentItem document;

  const _ImageViewer({required this.document});

  @override
  State<_ImageViewer> createState() => _ImageViewerState();
}

class _ImageViewerState extends State<_ImageViewer> {
  final _ocrService = OcrService();
  bool _isExtracting = false;

  Future<void> _showTextBottomSheet(BuildContext context) async {
    final existingText = widget.document.ocrText;
    String textToShow = existingText ?? '';

    if (!widget.document.hasOcrText && _ocrService.supportsOfflineOcr) {
      setState(() {
        _isExtracting = true;
      });
      try {
        textToShow = await _ocrService.recognizeImageText(widget.document.path);
      } catch (e) {
        textToShow = 'Error extracting text: $e';
      } finally {
        if (mounted) {
          setState(() {
            _isExtracting = false;
          });
        }
      }
    }

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Extracted Text',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy),
                        onPressed: textToShow.isEmpty
                            ? null
                            : () {
                                Clipboard.setData(
                                  ClipboardData(text: textToShow),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Copied to clipboard'),
                                  ),
                                );
                              },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: SelectionArea(
                        child: Text(
                          textToShow.isEmpty ? 'No text found.' : textToShow,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: InteractiveViewer(
            child: Image.file(File(widget.document.path), fit: BoxFit.contain),
          ),
        ),
        Positioned(
          bottom: 24,
          left: 0,
          right: 0,
          child: Center(
            child: ElevatedButton.icon(
              onPressed: _isExtracting
                  ? null
                  : () => _showTextBottomSheet(context),
              icon: _isExtracting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.text_fields),
              label: Text(_isExtracting ? 'Extracting...' : 'Show Text'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _WordViewer extends StatefulWidget {
  final DocumentItem document;

  const _WordViewer({required this.document});

  @override
  State<_WordViewer> createState() => _WordViewerState();
}

class _WordViewerState extends State<_WordViewer> {
  final _textExtraction = TextExtractionService();
  bool _isLoading = true;
  String _extractedText = '';
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadText();
  }

  Future<void> _loadText() async {
    try {
      final text = await _textExtraction.extractText(widget.document.path);
      if (mounted) {
        setState(() {
          _extractedText = text;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Error: $_error',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.copy),
                label: const Text('Copy All'),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _extractedText));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copied to clipboard')),
                  );
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: SelectionArea(
              child: Text(_extractedText, style: const TextStyle(fontSize: 16)),
            ),
          ),
        ),
      ],
    );
  }
}

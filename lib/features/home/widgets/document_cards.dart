import 'package:flutter/material.dart';

import '../../../app/core/app_colors.dart';
import '../../../app/core/app_text_styles.dart';
import '../models/document_item.dart';
import 'circle_icon.dart';
import 'document_file_icon.dart';

class FileRow extends StatelessWidget {
  const FileRow({
    required this.document,
    required this.isRecognizing,
    required this.onTap,
    required this.onMoreTap,
    super.key,
  });

  final DocumentItem document;
  final bool isRecognizing;
  final VoidCallback onTap;
  final VoidCallback onMoreTap;

  @override
  Widget build(BuildContext context) {
    final color = documentColor(document.type);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 69,
        child: Row(
          children: [
            CircleIcon(
              color: color,
              size: 39,
              child: DocumentFileIcon(type: document.type, color: color),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    document.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.fileTitle,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    _documentSubtitle(document, isRecognizing),
                    style: AppTextStyles.meta,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(document.sizeLabel, style: AppTextStyles.meta),
            IconButton(
              tooltip: 'More',
              onPressed: onMoreTap,
              icon: const Icon(
                Icons.more_vert,
                color: AppColors.grey,
                size: 18,
              ),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}

class DocumentGridCard extends StatelessWidget {
  const DocumentGridCard({
    required this.document,
    required this.isRecognizing,
    required this.onTap,
    super.key,
  });

  final DocumentItem document;
  final bool isRecognizing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = documentColor(document.type);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleIcon(
              color: color,
              size: 39,
              child: DocumentFileIcon(type: document.type, color: color),
            ),
            const Spacer(),
            Text(
              document.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.fileTitle,
            ),
            const SizedBox(height: 2),
            Text(
              isRecognizing
                  ? 'Recognizing text'
                  : document.hasOcrText
                  ? 'Text saved / ${document.sizeLabel}'
                  : '${_pageLabel(document.pages)} / ${document.sizeLabel}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.meta,
            ),
          ],
        ),
      ),
    );
  }
}

String _pageLabel(int pages) {
  return pages == 1 ? '1 page' : '$pages pages';
}

String _documentSubtitle(DocumentItem document, bool isRecognizing) {
  if (isRecognizing) {
    return 'Recognizing text...';
  }
  if (document.hasOcrText) {
    return 'Text saved / ${document.date}';
  }

  return '${document.date} / ${_pageLabel(document.pages)}';
}

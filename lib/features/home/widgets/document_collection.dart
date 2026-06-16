import 'package:flutter/material.dart';

import '../../../app/core/app_colors.dart';
import '../models/document_item.dart';
import 'document_cards.dart';

class DocumentListSliver extends StatelessWidget {
  const DocumentListSliver({
    required this.documents,
    required this.recognizingDocumentIds,
    required this.bottomPadding,
    required this.onDocumentTap,
    required this.onDocumentMoreTap,
    super.key,
  });

  final List<DocumentItem> documents;
  final Set<String> recognizingDocumentIds;
  final double bottomPadding;
  final ValueChanged<DocumentItem> onDocumentTap;
  final ValueChanged<DocumentItem> onDocumentMoreTap;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, bottomPadding),
      sliver: SliverList.separated(
        itemCount: documents.length,
        itemBuilder: (context, index) {
          final document = documents[index];
          return FileRow(
            document: document,
            isRecognizing: recognizingDocumentIds.contains(document.id),
            onTap: () => onDocumentTap(document),
            onMoreTap: () => onDocumentMoreTap(document),
          );
        },
        separatorBuilder: (context, index) => const DividerLine(),
      ),
    );
  }
}

class DocumentGridSliver extends StatelessWidget {
  const DocumentGridSliver({
    required this.documents,
    required this.recognizingDocumentIds,
    required this.bottomPadding,
    required this.onDocumentTap,
    super.key,
  });

  final List<DocumentItem> documents;
  final Set<String> recognizingDocumentIds;
  final double bottomPadding;
  final ValueChanged<DocumentItem> onDocumentTap;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, bottomPadding),
      sliver: SliverGrid.builder(
        itemCount: documents.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 1.32,
        ),
        itemBuilder: (context, index) {
          final document = documents[index];
          return DocumentGridCard(
            document: document,
            isRecognizing: recognizingDocumentIds.contains(document.id),
            onTap: () => onDocumentTap(document),
          );
        },
      ),
    );
  }
}

class DividerLine extends StatelessWidget {
  const DividerLine({super.key});

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, thickness: 1, color: AppColors.divider);
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../app/core/app_colors.dart';
import '../../../app/core/app_text_styles.dart';
import '../controllers/home_controller.dart';
import '../models/document_item.dart';
import '../models/folder_item.dart';

class ScannerHomePage extends GetView<HomeController> {
  const ScannerHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final scale = (media.size.width / 375).clamp(0.92, 1.12).toDouble();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: AppColors.primary,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        body: Stack(
          children: [
            SafeArea(
              bottom: false,
              child: Obx(
                () => CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        20 * scale,
                        22 * scale,
                        20 * scale,
                        0,
                      ),
                      sliver: SliverList.list(
                        children: [
                          const _TopBar(),
                          SizedBox(height: 20 * scale),
                          const _HeaderSummary(),
                          SizedBox(height: 18 * scale),
                          if (controller.isSearching.value) ...[
                            const _SearchField(),
                            SizedBox(height: 18 * scale),
                          ],
                          const _RecentHeader(),
                          SizedBox(height: 14 * scale),
                          const _FilterChips(),
                          SizedBox(height: 24 * scale),
                          const Text(
                            'Folders',
                            style: AppTextStyles.sectionLabel,
                          ),
                          SizedBox(height: 11 * scale),
                          _FolderStrip(
                            folders: controller.folders,
                            selectedFolderName:
                                controller.selectedFolderName.value,
                            onFolderTap: controller.toggleFolder,
                          ),
                          SizedBox(height: 34 * scale),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Files',
                                style: AppTextStyles.sectionLabel,
                              ),
                              Text(
                                '${controller.visibleDocuments.length} items',
                                style: AppTextStyles.meta,
                              ),
                            ],
                          ),
                          SizedBox(height: 10 * scale),
                        ],
                      ),
                    ),
                    if (controller.isLoading.value)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        ),
                      )
                    else if (controller.visibleDocuments.isEmpty)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: _EmptyState(),
                      )
                    else if (controller.viewMode.value == HomeViewMode.list)
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          20 * scale,
                          0,
                          20 * scale,
                          168 * scale,
                        ),
                        sliver: SliverList.separated(
                          itemCount: controller.visibleDocuments.length,
                          itemBuilder: (context, index) {
                            final document = controller.visibleDocuments[index];
                            return _FileRow(
                              document: document,
                              isRecognizing: controller.recognizingDocumentIds
                                  .contains(document.id),
                              onTap: () => controller.openDocument(document),
                              onMoreTap: () =>
                                  controller.showDocumentMenu(document),
                            );
                          },
                          separatorBuilder: (context, index) =>
                              const _DividerLine(),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          20 * scale,
                          0,
                          20 * scale,
                          168 * scale,
                        ),
                        sliver: SliverGrid.builder(
                          itemCount: controller.visibleDocuments.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 14,
                                crossAxisSpacing: 14,
                                childAspectRatio: 1.32,
                              ),
                          itemBuilder: (context, index) {
                            final document = controller.visibleDocuments[index];
                            return _DocumentGridCard(
                              document: document,
                              isRecognizing: controller.recognizingDocumentIds
                                  .contains(document.id),
                              onTap: () => controller.openDocument(document),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: _QuickActionsPanel(controller: controller),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends GetView<HomeController> {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          tooltip: 'Menu',
          onPressed: controller.createFolder,
          icon: const Icon(Icons.menu, color: AppColors.iconGrey, size: 25),
          visualDensity: VisualDensity.compact,
        ),
        Obx(
          () => IconButton(
            tooltip: controller.isSearching.value ? 'Close search' : 'Search',
            onPressed: controller.toggleSearch,
            icon: Icon(
              controller.isSearching.value ? Icons.close : Icons.search,
              color: AppColors.grey,
              size: 28,
            ),
            visualDensity: VisualDensity.compact,
          ),
        ),
      ],
    );
  }
}

class _HeaderSummary extends GetView<HomeController> {
  const _HeaderSummary();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Document Scanner', style: AppTextStyles.title),
              const SizedBox(height: 2),
              Text(controller.headerSubtitle, style: AppTextStyles.subHeading),
            ],
          ),
        ),
        FilledButton.icon(
          onPressed: controller.startScan,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          icon: const Icon(Icons.document_scanner_outlined, size: 18),
          label: const Text('Scan'),
        ),
      ],
    );
  }
}

class _SearchField extends GetView<HomeController> {
  const _SearchField();

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller.searchController,
      onChanged: controller.updateSearch,
      autofocus: true,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search scans, folders, or file type',
        hintStyle: AppTextStyles.meta,
        prefixIcon: const Icon(Icons.search, color: AppColors.grey),
        filled: true,
        fillColor: AppColors.lightBlue,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _RecentHeader extends GetView<HomeController> {
  const _RecentHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        PopupMenuButton<DocumentFilter>(
          onSelected: controller.selectFilter,
          itemBuilder: (context) {
            return const [
              PopupMenuItem(
                value: DocumentFilter.all,
                child: Text('All scans'),
              ),
              PopupMenuItem(value: DocumentFilter.pdf, child: Text('PDF')),
              PopupMenuItem(value: DocumentFilter.word, child: Text('Word')),
              PopupMenuItem(value: DocumentFilter.image, child: Text('Images')),
            ];
          },
          child: Row(
            children: [
              Obx(
                () => Text(
                  _filterLabel(controller.selectedFilter.value),
                  style: AppTextStyles.subHeading,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.keyboard_arrow_down,
                size: 21,
                color: AppColors.grey,
              ),
            ],
          ),
        ),
        const Spacer(),
        Obx(
          () => _ViewModeButton(
            active: controller.viewMode.value == HomeViewMode.list,
            icon: Icons.view_headline_rounded,
            tooltip: 'List view',
            onPressed: () => controller.setViewMode(HomeViewMode.list),
          ),
        ),
        const SizedBox(width: 10),
        Obx(
          () => _ViewModeButton(
            active: controller.viewMode.value == HomeViewMode.grid,
            icon: Icons.grid_view_rounded,
            tooltip: 'Grid view',
            onPressed: () => controller.setViewMode(HomeViewMode.grid),
          ),
        ),
      ],
    );
  }

  String _filterLabel(DocumentFilter filter) {
    return switch (filter) {
      DocumentFilter.all => 'Recent files',
      DocumentFilter.pdf => 'PDF files',
      DocumentFilter.word => 'Word files',
      DocumentFilter.image => 'Image scans',
    };
  }
}

class _FilterChips extends GetView<HomeController> {
  const _FilterChips();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: const [
          _FilterChip(label: 'All', filter: DocumentFilter.all),
          SizedBox(width: 8),
          _FilterChip(label: 'PDF', filter: DocumentFilter.pdf),
          SizedBox(width: 8),
          _FilterChip(label: 'Word', filter: DocumentFilter.word),
          SizedBox(width: 8),
          _FilterChip(label: 'Images', filter: DocumentFilter.image),
        ],
      ),
    );
  }
}

class _FilterChip extends GetView<HomeController> {
  const _FilterChip({required this.label, required this.filter});

  final String label;
  final DocumentFilter filter;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selected = controller.selectedFilter.value == filter;

      return ChoiceChip(
        selected: selected,
        label: Text(label),
        onSelected: (_) => controller.selectFilter(filter),
        showCheckmark: false,
        labelStyle: AppTextStyles.meta.copyWith(
          color: selected ? AppColors.white : AppColors.grey,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        ),
        selectedColor: AppColors.primary,
        backgroundColor: AppColors.lightBlue,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      );
    });
  }
}

class _ViewModeButton extends StatelessWidget {
  const _ViewModeButton({
    required this.active,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final bool active;
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 24,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          backgroundColor: active ? AppColors.lightBlue : Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        icon: Icon(
          icon,
          color: active ? AppColors.primary : AppColors.grey2,
          size: active ? 18 : 19,
        ),
      ),
    );
  }
}

class _FolderStrip extends StatelessWidget {
  const _FolderStrip({
    required this.folders,
    required this.selectedFolderName,
    required this.onFolderTap,
  });

  final List<FolderItem> folders;
  final String? selectedFolderName;
  final ValueChanged<FolderItem> onFolderTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 66,
      child: ListView.separated(
        clipBehavior: Clip.none,
        scrollDirection: Axis.horizontal,
        itemCount: folders.length,
        itemBuilder: (context, index) {
          final folder = folders[index];
          return _FolderCard(
            folder: folder,
            selected: selectedFolderName == folder.name,
            onTap: () => onFolderTap(folder),
          );
        },
        separatorBuilder: (context, index) => const SizedBox(width: 23),
      ),
    );
  }
}

class _FolderCard extends StatelessWidget {
  const _FolderCard({
    required this.folder,
    required this.selected,
    required this.onTap,
  });

  final FolderItem folder;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 198,
        height: 66,
        padding: const EdgeInsets.fromLTRB(8, 14, 8, 12),
        decoration: BoxDecoration(
          color: folder.accent.withValues(alpha: selected ? 0.10 : 0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? folder.accent : Colors.transparent,
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            _CircleIcon(
              color: folder.accent,
              child: Icon(
                Icons.folder_copy_outlined,
                color: folder.accent,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    folder.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.cardTitle,
                  ),
                  const SizedBox(height: 1),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          folder.date,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.meta,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${folder.fileCount} files',
                        style: AppTextStyles.meta,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 7),
            const Icon(Icons.more_vert, color: AppColors.grey, size: 18),
          ],
        ),
      ),
    );
  }
}

class _FileRow extends StatelessWidget {
  const _FileRow({
    required this.document,
    required this.isRecognizing,
    required this.onTap,
    required this.onMoreTap,
  });

  final DocumentItem document;
  final bool isRecognizing;
  final VoidCallback onTap;
  final VoidCallback onMoreTap;

  @override
  Widget build(BuildContext context) {
    final color = _documentColor(document.type);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 69,
        child: Row(
          children: [
            _CircleIcon(
              color: color,
              size: 39,
              child: CustomPaint(
                size: const Size(22, 24),
                painter: _DocumentIconPainter(
                  type: document.type,
                  color: color,
                ),
              ),
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

class _DocumentGridCard extends StatelessWidget {
  const _DocumentGridCard({
    required this.document,
    required this.isRecognizing,
    required this.onTap,
  });

  final DocumentItem document;
  final bool isRecognizing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _documentColor(document.type);

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
            _CircleIcon(
              color: color,
              size: 39,
              child: CustomPaint(
                size: const Size(22, 24),
                painter: _DocumentIconPainter(
                  type: document.type,
                  color: color,
                ),
              ),
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
                  ? 'Recognizing Khmer text'
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

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 28, 32, 168),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const _CircleIcon(
            color: AppColors.primary,
            size: 56,
            child: Icon(
              Icons.manage_search_rounded,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'No scans found',
            style: AppTextStyles.cardTitle.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Try a different search or file filter.',
            textAlign: TextAlign.center,
            style: AppTextStyles.meta,
          ),
        ],
      ),
    );
  }
}

class _DividerLine extends StatelessWidget {
  const _DividerLine();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, thickness: 1, color: AppColors.divider);
  }
}

class _CircleIcon extends StatelessWidget {
  const _CircleIcon({required this.color, required this.child, this.size = 32});

  final Color color;
  final Widget child;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}

class _QuickActionsPanel extends StatelessWidget {
  const _QuickActionsPanel({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Container(
      height: 118 + bottomInset,
      width: double.infinity,
      padding: EdgeInsets.only(
        left: 28,
        top: 13,
        right: 28,
        bottom: bottomInset > 0 ? 8 : 10,
      ),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(36),
          topRight: Radius.circular(36),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            offset: Offset(0, 4),
            blurRadius: 40,
          ),
        ],
      ),
      child: Column(
        children: [
          CustomPaint(
            size: const Size(24, 16),
            painter: _DoubleChevronPainter(),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _QuickActionButton(
                icon: Icons.document_scanner_outlined,
                label: 'Scan',
                onTap: controller.startScan,
              ),
              _QuickActionButton(
                icon: Icons.photo_library_outlined,
                label: 'Import',
                onTap: controller.importPhoto,
              ),
              _QuickActionButton(
                icon: Icons.create_new_folder_outlined,
                label: 'Folder',
                onTap: controller.createFolder,
              ),
            ],
          ),
          const Spacer(),
          Container(
            width: 100,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Column(
          children: [
            Icon(icon, color: AppColors.white, size: 22),
            const SizedBox(height: 4),
            Text(label, style: AppTextStyles.quickAction),
          ],
        ),
      ),
    );
  }
}

class _DocumentIconPainter extends CustomPainter {
  const _DocumentIconPainter({required this.type, required this.color});

  final DocumentType type;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.white
      ..style = PaintingStyle.fill;
    final border = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(5, 1, size.width - 7, size.height - 2),
      const Radius.circular(2),
    );

    canvas.drawRRect(rect, paint);
    canvas.drawRRect(rect, border);

    final fold = Path()
      ..moveTo(size.width - 8, 1)
      ..lineTo(size.width - 2, 7)
      ..lineTo(size.width - 8, 7)
      ..close();
    canvas.drawPath(fold, Paint()..color = color.withValues(alpha: 0.14));
    canvas.drawPath(fold, border);

    switch (type) {
      case DocumentType.word:
        _paintWord(canvas, color);
      case DocumentType.pdf:
        _paintPdf(canvas, color);
      case DocumentType.image:
        _paintImage(canvas, color);
    }
  }

  void _paintWord(Canvas canvas, Color color) {
    final badge = RRect.fromRectAndRadius(
      const Rect.fromLTWH(0, 8, 13, 12),
      const Radius.circular(1.5),
    );
    canvas.drawRRect(badge, Paint()..color = color);
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'W',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 9,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, const Offset(2.5, 9.5));
    _drawLine(canvas, 8, 10.5, 17, color);
    _drawLine(canvas, 8, 14.5, 17, color);
    _drawLine(canvas, 8, 18.5, 14, color);
  }

  void _paintPdf(Canvas canvas, Color color) {
    final curvePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(5, 18)
      ..cubicTo(8, 14, 9, 9, 8, 5)
      ..cubicTo(9.5, 11, 13, 15, 18, 16)
      ..cubicTo(13, 15, 9, 16, 5, 18);
    canvas.drawPath(path, curvePaint);
  }

  void _paintImage(Canvas canvas, Color color) {
    final imagePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawCircle(const Offset(12, 9), 1.5, Paint()..color = color);
    final path = Path()
      ..moveTo(7, 18)
      ..lineTo(11, 14)
      ..lineTo(13, 16)
      ..lineTo(16.5, 12.5)
      ..lineTo(19, 18);
    canvas.drawPath(path, imagePaint);
  }

  void _drawLine(Canvas canvas, double x1, double y, double x2, Color color) {
    canvas.drawLine(
      Offset(x1, y),
      Offset(x2, y),
      Paint()
        ..color = color
        ..strokeWidth = 1.1
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _DocumentIconPainter oldDelegate) {
    return oldDelegate.type != type || oldDelegate.color != color;
  }
}

class _DoubleChevronPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    void drawChevron(double top) {
      final path = Path()
        ..moveTo(2, top + 8)
        ..lineTo(size.width / 2, top)
        ..lineTo(size.width - 2, top + 8);
      canvas.drawPath(path, paint);
    }

    drawChevron(1);
    drawChevron(6);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

Color _documentColor(DocumentType type) {
  return switch (type) {
    DocumentType.pdf => AppColors.red,
    DocumentType.word => AppColors.primary,
    DocumentType.image => AppColors.accent,
  };
}

String _pageLabel(int pages) {
  return pages == 1 ? '1 page' : '$pages pages';
}

String _documentSubtitle(DocumentItem document, bool isRecognizing) {
  if (isRecognizing) {
    return 'Recognizing Khmer text...';
  }
  if (document.hasOcrText) {
    return 'Text saved / ${document.date}';
  }

  return '${document.date} / ${_pageLabel(document.pages)}';
}

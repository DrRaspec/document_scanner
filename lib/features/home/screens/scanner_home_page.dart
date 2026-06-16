import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../app/core/app_colors.dart';
import '../../../app/core/app_text_styles.dart';
import '../controllers/home_controller.dart';
import '../widgets/document_collection.dart';
import '../widgets/empty_document_state.dart';
import '../widgets/filter_controls.dart';
import '../widgets/folder_strip.dart';
import '../widgets/home_top_bar.dart';
import '../widgets/quick_actions_panel.dart';

class ScannerHomePage extends GetView<HomeController> {
  const ScannerHomePage({super.key});

  static const _horizontalPadding = 20.0;
  static const _bottomContentPadding = 132.0;

  @override
  Widget build(BuildContext context) {
    final scale = _layoutScale(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: AppColors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        body: Stack(
          children: [
            SafeArea(
              bottom: false,
              child: _HomeScrollView(scale: scale),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: QuickActionsPanel(controller: controller),
            ),
          ],
        ),
      ),
    );
  }

  double _layoutScale(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return (width / 375).clamp(0.92, 1.12).toDouble();
  }
}

class _HomeScrollView extends GetView<HomeController> {
  const _HomeScrollView({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final documents = controller.visibleDocuments;
      final bottomPadding = ScannerHomePage._bottomContentPadding * scale;

      return CustomScrollView(
        slivers: [
          _HomeIntroSliver(scale: scale, itemCount: documents.length),
          if (controller.isLoading.value)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else if (documents.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyDocumentState(),
            )
          else if (controller.viewMode.value == HomeViewMode.list)
            DocumentListSliver(
              documents: documents,
              recognizingDocumentIds: controller.recognizingDocumentIds,
              bottomPadding: bottomPadding,
              onDocumentTap: controller.openDocument,
              onDocumentMoreTap: controller.showDocumentMenu,
            )
          else
            DocumentGridSliver(
              documents: documents,
              recognizingDocumentIds: controller.recognizingDocumentIds,
              bottomPadding: bottomPadding,
              onDocumentTap: controller.openDocument,
            ),
        ],
      );
    });
  }
}

class _HomeIntroSliver extends GetView<HomeController> {
  const _HomeIntroSliver({required this.scale, required this.itemCount});

  final double scale;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(
        ScannerHomePage._horizontalPadding * scale,
        22 * scale,
        ScannerHomePage._horizontalPadding * scale,
        0,
      ),
      sliver: SliverList.list(
        children: [
          const HomeTopBar(),
          SizedBox(height: 20 * scale),
          const HeaderSummary(),
          SizedBox(height: 18 * scale),
          Obx(() => controller.isSearching.value
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const HomeSearchField(),
                  SizedBox(height: 18 * scale),
                ],
              )
            : const SizedBox.shrink()),

          const RecentHeader(),
          SizedBox(height: 14 * scale),
          const HomeFilterChips(),
          SizedBox(height: 24 * scale),
          const Text('Folders', style: AppTextStyles.sectionLabel),
          SizedBox(height: 11 * scale),
          Obx(() => FolderStrip(
            folders: controller.folders,
            selectedFolderName: controller.selectedFolderName.value,
            onFolderTap: controller.toggleFolder,
          )),
          SizedBox(height: 34 * scale),
          _FilesSectionHeader(itemCount: itemCount),
          SizedBox(height: 10 * scale),
        ],
      ),
    );
  }
}

class _FilesSectionHeader extends StatelessWidget {
  const _FilesSectionHeader({required this.itemCount});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Files', style: AppTextStyles.sectionLabel),
        Text('$itemCount items', style: AppTextStyles.meta),
      ],
    );
  }
}

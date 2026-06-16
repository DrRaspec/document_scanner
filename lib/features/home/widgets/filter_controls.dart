import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/core/app_colors.dart';
import '../../../app/core/app_text_styles.dart';
import '../controllers/home_controller.dart';

class RecentHeader extends GetView<HomeController> {
  const RecentHeader({super.key});

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

class HomeFilterChips extends GetView<HomeController> {
  const HomeFilterChips({super.key});

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

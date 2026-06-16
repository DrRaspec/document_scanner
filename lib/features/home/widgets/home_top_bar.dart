import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/core/app_colors.dart';
import '../../../app/core/app_text_styles.dart';
import '../controllers/home_controller.dart';

class HomeTopBar extends GetView<HomeController> {
  const HomeTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          tooltip: 'Menu',
          onPressed: controller.showHomeMenu,
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

class HeaderSummary extends GetView<HomeController> {
  const HeaderSummary({super.key});

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

class HomeSearchField extends GetView<HomeController> {
  const HomeSearchField({super.key});

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

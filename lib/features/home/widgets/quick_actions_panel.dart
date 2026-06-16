import 'package:flutter/material.dart';

import '../../../app/core/app_colors.dart';
import '../../../app/core/app_text_styles.dart';
import '../controllers/home_controller.dart';

class QuickActionsPanel extends StatelessWidget {
  const QuickActionsPanel({required this.controller, super.key});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(18, 0, 18, bottomInset + 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.divider),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1F111111),
              offset: Offset(0, 14),
              blurRadius: 34,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: SizedBox(
            height: 68,
            child: Row(
              children: [
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.photo_library_outlined,
                    label: 'Import',
                    onTap: controller.importPhoto,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: _QuickActionButton(
                    icon: Icons.document_scanner_outlined,
                    label: 'Scan',
                    primary: true,
                    onTap: controller.startScan,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.create_new_folder_outlined,
                    label: 'Folder',
                    onTap: controller.createFolder,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.primary = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final foregroundColor = primary ? AppColors.white : AppColors.grey;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        height: 52,
        decoration: BoxDecoration(
          color: primary ? AppColors.primary : AppColors.lightBlue,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Center(
          child: primary
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: foregroundColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.quickAction.copyWith(
                        color: foregroundColor,
                      ),
                    ),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: AppColors.primary, size: 20),
                    const SizedBox(height: 3),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.meta.copyWith(
                        color: foregroundColor,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

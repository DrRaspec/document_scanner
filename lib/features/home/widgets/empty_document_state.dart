import 'package:flutter/material.dart';

import '../../../app/core/app_colors.dart';
import '../../../app/core/app_text_styles.dart';
import 'circle_icon.dart';

class EmptyDocumentState extends StatelessWidget {
  const EmptyDocumentState({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 28, 32, 168),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircleIcon(
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

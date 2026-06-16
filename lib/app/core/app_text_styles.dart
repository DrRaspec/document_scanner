import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTextStyles {
  const AppTextStyles._();

  static const title = TextStyle(
    color: AppColors.primaryBlack,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 36 / 24,
    letterSpacing: 0,
  );

  static const subHeading = TextStyle(
    color: AppColors.grey,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 21 / 14,
    letterSpacing: 0,
  );

  static const sectionLabel = TextStyle(
    color: AppColors.grey,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 18 / 12,
    letterSpacing: 0,
  );

  static const cardTitle = TextStyle(
    color: AppColors.primaryBlack,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 21 / 14,
    letterSpacing: 0,
  );

  static const fileTitle = TextStyle(
    color: AppColors.primaryBlack,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 21 / 14,
    letterSpacing: 0,
  );

  static const meta = TextStyle(
    color: AppColors.grey2,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 18 / 12,
    letterSpacing: 0,
  );

  static const quickAction = TextStyle(
    color: AppColors.white,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 18 / 14,
    letterSpacing: 0,
  );
}

import 'package:flutter/material.dart';

import '../../../app/core/app_colors.dart';
import '../../../app/core/app_text_styles.dart';
import '../models/folder_item.dart';
import 'circle_icon.dart';

class FolderStrip extends StatelessWidget {
  const FolderStrip({
    required this.folders,
    required this.selectedFolderName,
    required this.onFolderTap,
    super.key,
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
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
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
            CircleIcon(
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
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    folder.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.cardTitle.copyWith(height: 1.15),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          folder.date,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.meta.copyWith(height: 1.15),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${folder.fileCount} files',
                        style: AppTextStyles.meta.copyWith(height: 1.15),
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

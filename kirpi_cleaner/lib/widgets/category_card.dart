import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/clean_item.dart';

class CategoryCard extends StatelessWidget {
  final CleanCategory category;
  final List<CleanItem> items;
  final bool isExpanded;
  final VoidCallback onToggleExpand;
  final ValueChanged<int> onToggleItem;

  const CategoryCard({
    super.key,
    required this.category,
    required this.items,
    required this.isExpanded,
    required this.onToggleExpand,
    required this.onToggleItem,
  });

  int get totalSize => items.fold(0, (sum, i) => sum + i.sizeBytes);
  int get selectedCount => items.where((i) => i.isSelected).length;

  Color get categoryColor {
    switch (category) {
      case CleanCategory.cache:
        return AppTheme.accentCyan;
      case CleanCategory.temp:
        return AppTheme.accentOrange;
      case CleanCategory.thumbnails:
        return AppTheme.accentPurple;
      case CleanCategory.apkFiles:
        return const Color(0xFFFFD600);
      case CleanCategory.emptyFolders:
        return AppTheme.accentGreen;
      case CleanCategory.logs:
        return const Color(0xFFFF4081);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        children: [
          _buildHeader(),
          if (isExpanded) _buildItemList(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return InkWell(
      onTap: onToggleExpand,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: categoryColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  category.iconEmoji,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.displayName,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${items.length} файлов · ${CleanItem.formatBytes(totalSize)}',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  CleanItem.formatBytes(totalSize),
                  style: TextStyle(
                    color: categoryColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$selectedCount выбрано',
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            Icon(
              isExpanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              color: AppTheme.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemList() {
    return Column(
      children: [
        Divider(
          color: AppTheme.borderColor,
          height: 1,
          indent: 16,
          endIndent: 16,
        ),
        ...items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return _buildItemRow(item, index);
        }),
      ],
    );
  }

  Widget _buildItemRow(CleanItem item, int index) {
    return InkWell(
      onTap: () => onToggleItem(index),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: Checkbox(
                value: item.isSelected,
                onChanged: (_) => onToggleItem(index),
                activeColor: categoryColor,
                checkColor: AppTheme.bgDeep,
                side: BorderSide(color: AppTheme.textMuted),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    item.path,
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              item.formattedSize,
              style: TextStyle(
                color: item.sizeBytes > 0
                    ? AppTheme.textSecondary
                    : AppTheme.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

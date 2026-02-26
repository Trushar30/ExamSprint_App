import 'package:flutter/material.dart';
import '../config/theme.dart';

class TagChip extends StatelessWidget {
  final String tag;
  final bool selected;
  final VoidCallback? onTap;
  final bool removable;
  final VoidCallback? onRemove;

  const TagChip({
    super.key,
    required this.tag,
    this.selected = false,
    this.onTap,
    this.removable = false,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final color = AppColors.getTagColor(tag);
    final altColor = AppTheme.surfaceAlt(brightness);
    final borderColor = AppTheme.border(brightness);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppTheme.animFast,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.15) : altColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color.withOpacity(0.6) : borderColor,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              tag.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: selected ? color : AppTheme.textSecondary(brightness),
                letterSpacing: 0.5,
              ),
            ),
            if (removable) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onRemove,
                child: Icon(
                  Icons.close,
                  size: 14,
                  color: AppTheme.textTertiary(brightness),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

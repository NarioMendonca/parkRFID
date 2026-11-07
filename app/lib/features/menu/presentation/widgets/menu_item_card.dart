import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../data/models/menu_item_model.dart';
import 'category_chip.dart';


class MenuItemCard extends StatelessWidget {
  const MenuItemCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.onAvailabilityChanged,
  });

  final MenuItemModel item;
  final VoidCallback onTap;
  final ValueChanged<bool> onAvailabilityChanged;

  @override
  Widget build(BuildContext context) {
    final isAvailable = item.isAvailable;

    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Row(
        children: [
          IconBadge(
            icon: iconForMenuCategory(item.category),
            tone: isAvailable ? AppTone.primary : AppTone.neutral,
            size: 52,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.category.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: isAvailable ? AppTheme.primary : AppTheme.textSubtle,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                    color: isAvailable ? AppTheme.textDark : AppTheme.textSubtle,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.formattedPrice,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isAvailable ? AppTheme.textDark : AppTheme.textSubtle,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isAvailable,
            onChanged: (val) {
              HapticFeedback.lightImpact();
              onAvailabilityChanged(val);
            },
          ),
        ],
      ),
    );
  }
}

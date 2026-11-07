import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';


IconData iconForMenuCategory(String? category) {
  final c = (category ?? '').toLowerCase();
  if (c == 'todas') return Icons.apps_rounded;
  if (c.contains('bebida')) return Icons.local_drink_rounded;
  if (c.contains('sobremesa')) return Icons.icecream_rounded;
  if (c.contains('lanche') || c.contains('porç') || c.contains('porc')) {
    return Icons.lunch_dining_rounded;
  }
  if (c.contains('comida')) return Icons.restaurant_rounded;
  return Icons.restaurant_menu_rounded;
}


class CategoryChip extends StatelessWidget {
  const CategoryChip({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? AppTheme.onAccent : Colors.white;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: selected ? AppTheme.accent : Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: fg),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: fg),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

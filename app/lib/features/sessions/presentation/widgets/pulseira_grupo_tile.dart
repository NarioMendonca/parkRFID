import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../data/models/checkin_bracelet_model.dart';


class PulseiraGrupoTile extends StatelessWidget {
  const PulseiraGrupoTile({
    super.key,
    required this.bracelet,
    required this.onRemove,
  });

  final CheckinBraceletModel bracelet;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final isKid = bracelet.type.isKid;

    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
      radius: AppTheme.radiusMd,
      child: Row(
        children: [
          IconBadge(
            icon: isKid ? Icons.child_care_rounded : Icons.person_rounded,
            tone: isKid ? AppTone.accent : AppTone.primary,
            size: 46,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        bracelet.braceletId,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ),
                    if (bracelet.isLeader) ...[
                      const SizedBox(width: 8),
                      const StatusPill(
                        label: 'LÍDER',
                        icon: Icons.star_rounded,
                        tone: AppTone.warning,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  bracelet.type.label,
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Remover pulseira',
            onPressed: onRemove,
            icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.danger),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../data/models/comanda_model.dart';

class ComandaResumoCard extends StatelessWidget {
  const ComandaResumoCard({super.key, required this.comanda});

  final ComandaSessaoModel comanda;

  @override
  Widget build(BuildContext context) {
    final c = comanda;

    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconBadge(
                icon: c.isKid ? Icons.child_care_rounded : Icons.person_rounded,
                tone: c.isKid ? AppTone.accent : AppTone.primary,
                size: 52,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionLabel('Pulseira / tag'),
                    const SizedBox(height: 2),
                    Text(
                      c.braceletId,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusPill(
                label: c.isOpen ? 'Ativa' : 'Encerrada',
                icon: c.isOpen ? Icons.circle : Icons.lock_outline_rounded,
                tone: c.isOpen ? AppTone.success : AppTone.neutral,
              ),
            ],
          ),
          const SizedBox(height: 18),
          InfoRow(
            icon: Icons.badge_outlined,
            label: 'Tipo',
            value: c.isKid ? 'Infantil / Kid' : 'Adulto / Normal',
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          InfoRow(
            icon: Icons.login_rounded,
            label: 'Entrada',
            value: c.checkinDate == null ? '—' : 'às ${formatarHora(c.checkinDate)}',
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: _Valor(label: 'Consumido', value: formatarMoeda(c.totalConsumido))),
              const SizedBox(width: 10),
              Expanded(child: _Valor(label: 'Pago', value: formatarMoeda(c.totalPago))),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: c.saldoPendente > 0 ? AppTheme.accentSoft : AppTheme.successBg,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Text(
                  c.saldoPendente > 0 ? 'Saldo a pagar' : 'Conta quitada',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.textDark),
                ),
                const Spacer(),
                Text(
                  formatarMoeda(c.saldoPendente),
                  style: AppTheme.display(
                    size: 26,
                    color: c.saldoPendente > 0 ? AppTheme.textDark : AppTheme.success,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Valor extends StatelessWidget {
  const _Valor({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.inputBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 2),
          Text(value, style: AppTheme.display(size: 18, color: AppTheme.textDark)),
        ],
      ),
    );
  }
}

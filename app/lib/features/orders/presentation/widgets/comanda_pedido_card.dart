import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../data/models/comanda_model.dart';

class ComandaPedidoCard extends StatelessWidget {
  const ComandaPedidoCard({super.key, required this.pedido, required this.numero});

  final ComandaPedidoModel pedido;
  final int numero;

  @override
  Widget build(BuildContext context) {
    final hora = formatarHora(pedido.date);
    final mesa = pedido.tableNumber;
    final titulo = [
      'Pedido $numero',
      if (hora.isNotEmpty) hora,
      if (mesa != null && mesa.isNotEmpty) 'Mesa ${mesa.padLeft(2, '0')}',
    ].join(' · ');

    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      radius: AppTheme.radiusMd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long_rounded, size: 18, color: AppTheme.textSubtle),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  titulo,
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppTheme.textMuted),
                ),
              ),
              Text(
                formatarMoeda(pedido.total),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.textDark),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1),
          ),
          for (final item in pedido.items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    constraints: const BoxConstraints(minWidth: 40),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTone.primary.soft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${item.amount}x',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.primary, fontSize: 13.5),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.textDark),
                        ),
                        if (item.amount > 1)
                          Text(
                            '${formatarMoeda(item.unitPrice)} cada',
                            style: const TextStyle(fontSize: 12, color: AppTheme.textSubtle),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    formatarMoeda(item.subtotal),
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, color: AppTheme.textDark),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

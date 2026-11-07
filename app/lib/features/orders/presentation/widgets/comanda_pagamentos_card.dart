import 'package:flutter/material.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../data/models/comanda_model.dart';

class ComandaPagamentosCard extends StatelessWidget {
  const ComandaPagamentosCard({super.key, required this.pagamentos});

  final List<ComandaPagamentoModel> pagamentos;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Column(
        children: [
          for (var i = 0; i < pagamentos.length; i++) ...[
            if (i > 0)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(height: 1),
              ),
            InfoRow(
              icon: Icons.payments_outlined,
              label: pagamentos[i].date == null
                  ? 'Pagamento'
                  : 'Pagamento às ${formatarHora(pagamentos[i].date)}',
              value: formatarMoeda(pagamentos[i].amount),
            ),
          ],
        ],
      ),
    );
  }
}

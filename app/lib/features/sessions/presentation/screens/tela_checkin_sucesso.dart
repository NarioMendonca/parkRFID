import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../data/models/checkin_result_model.dart';


class TelaCheckinSucesso extends StatelessWidget {
  const TelaCheckinSucesso({
    super.key,
    required this.resultado,
    required this.onNovoCheckin,
  });

  final CheckinResultModel? resultado;
  final VoidCallback onNovoCheckin;

  @override
  Widget build(BuildContext context) {
    final r = resultado;
    final hora = r == null ? '' : TimeOfDay.fromDateTime(r.finishedAt).format(context);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ScrollFill(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    StatePanel(
                      icon: Icons.check_rounded,
                      tone: AppTone.success,
                      title: 'Check-in realizado',
                      message: 'Grupo liberado às $hora',
                    ),
                    const SizedBox(height: 32),
                    AppCard(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                      child: Column(
                        children: [
                          InfoRow(
                            icon: Icons.badge_outlined,
                            label: 'Responsável',
                            value: r?.responsibleCpf ?? '',
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            child: Divider(height: 1),
                          ),
                          InfoRow(
                            icon: Icons.phone_outlined,
                            label: 'Telefone',
                            value: r?.responsiblePhone ?? '',
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            child: Divider(height: 1),
                          ),
                          InfoRow(
                            icon: Icons.nfc_rounded,
                            label: 'Pulseiras',
                            value: '${r?.braceletCount ?? 0}',
                            emphasize: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            BottomActionBar(
              primary: AppButton(
                label: 'Novo check-in',
                icon: Icons.add_rounded,
                onPressed: onNovoCheckin,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../data/models/checkin_bracelet_model.dart';
import '../widgets/tipo_pulseira_option.dart';


class TelaCheckinTipoPulseira extends StatelessWidget {
  const TelaCheckinTipoPulseira({
    super.key,
    required this.braceletId,
    required this.tipoSelecionado,
    required this.onSelecionarTipo,
    required this.onVoltar,
    required this.onAdicionar,
  });

  final String braceletId;
  final SessionType tipoSelecionado;
  final ValueChanged<SessionType> onSelecionarTipo;
  final VoidCallback onVoltar;
  final VoidCallback onAdicionar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          AppHeader(
            title: 'Pulseira identificada',
            subtitle: 'Leitura RFID',
            onBack: () {
              HapticFeedback.lightImpact();
              onVoltar();
            },
            bottom: const StepProgress(current: 3, total: 4, label: 'Tipo da pulseira'),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              children: [
                AppCard(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      const IconBadge(icon: Icons.nfc_rounded, tone: AppTone.success, size: 56),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SectionLabel('Pulseira / tag'),
                            const SizedBox(height: 4),
                            Text(
                              braceletId,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                                color: AppTheme.textDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                const SectionLabel('Registrar esta pulseira como'),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: TipoPulseiraOption(
                        title: 'Normal',
                        subtitle: 'Adulto',
                        icon: Icons.person_rounded,
                        selected: tipoSelecionado == SessionType.normal,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          onSelecionarTipo(SessionType.normal);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TipoPulseiraOption(
                        title: 'Kid',
                        subtitle: 'Infantil',
                        icon: Icons.child_care_rounded,
                        selected: tipoSelecionado == SessionType.kid,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          onSelecionarTipo(SessionType.kid);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          BottomActionBar(
            primary: AppButton(
              label: 'Adicionar ao grupo',
              icon: Icons.add_circle_outline_rounded,
              onPressed: () {
                HapticFeedback.lightImpact();
                onAdicionar();
              },
            ),
          ),
        ],
      ),
    );
  }
}

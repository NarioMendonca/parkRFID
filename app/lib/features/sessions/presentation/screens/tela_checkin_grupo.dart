import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../data/models/checkin_bracelet_model.dart';
import '../widgets/pulseira_grupo_tile.dart';


class TelaCheckinGrupo extends StatelessWidget {
  const TelaCheckinGrupo({
    super.key,
    required this.cpfResponsavel,
    required this.pulseiras,
    required this.isLoading,
    required this.onVoltar,
    required this.onRemover,
    required this.onFinalizar,
    required this.onLerMais,
  });

  final String cpfResponsavel;
  final List<CheckinBraceletModel> pulseiras;
  final bool isLoading;
  final VoidCallback onVoltar;
  final ValueChanged<int> onRemover;
  final VoidCallback onFinalizar;
  final VoidCallback onLerMais;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          AppHeader(
            title: 'Grupo',
            subtitle: 'Responsável $cpfResponsavel',
            onBack: () {
              HapticFeedback.lightImpact();
              onVoltar();
            },
            bottom: const StepProgress(current: 4, total: 4, label: 'Revisão'),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              children: [
                SectionLabel('Pulseiras do grupo · ${pulseiras.length}'),
                const SizedBox(height: 12),
                if (pulseiras.isEmpty)
                  const AppCard(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 32),
                    child: Column(
                      children: [
                        IconBadge(icon: Icons.nfc_rounded, tone: AppTone.neutral, size: 60),
                        SizedBox(height: 16),
                        Text(
                          'Nenhuma pulseira no grupo',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textDark,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Leia ao menos uma pulseira para finalizar o check-in.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, height: 1.4, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  )
                else
                  for (var i = 0; i < pulseiras.length; i++)
                    PulseiraGrupoTile(
                      bracelet: pulseiras[i],
                      onRemove: () {
                        HapticFeedback.mediumImpact();
                        onRemover(i);
                      },
                    ),
              ],
            ),
          ),
          BottomActionBar(
            primary: AppButton(
              label: 'Finalizar check-in',
              icon: Icons.check_circle_outline_rounded,
              loading: isLoading,
              onPressed: isLoading
                  ? null
                  : () {
                      HapticFeedback.lightImpact();
                      onFinalizar();
                    },
            ),
            secondary: AppButton(
              label: 'Ler mais uma pulseira',
              icon: Icons.add_rounded,
              outlined: true,
              tone: AppTone.primary,
              height: 50,
              onPressed: isLoading
                  ? null
                  : () {
                      HapticFeedback.lightImpact();
                      onLerMais();
                    },
            ),
          ),
        ],
      ),
    );
  }
}

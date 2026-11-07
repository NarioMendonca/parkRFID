import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../../../core/widgets/nfc_radar_pulse.dart';


class TelaCheckinLeituraNfc extends StatelessWidget {
  const TelaCheckinLeituraNfc({
    super.key,
    required this.pulseirasNoGrupo,
    required this.onVoltar,
    required this.onVerGrupo,
  });


  final int pulseirasNoGrupo;
  final VoidCallback onVoltar;
  final VoidCallback onVerGrupo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: ScanBackdrop(
        child: SafeArea(
          child: Column(
            children: [
              ScanTopBar(
                title: 'Leitura RFID',
                subtitle: 'Pulseira ${pulseirasNoGrupo + 1} do grupo',
                onBack: () {
                  HapticFeedback.lightImpact();
                  onVoltar();
                },
              ),
              const Spacer(),
              const NfcRadarPulse(),
              const SizedBox(height: 28),
              Text(
                'APROXIME A PULSEIRA',
                style: AppTheme.display(size: 28, color: Colors.white),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Toque no anel ou aproxime a tag física da parte de trás do aparelho',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: 15,
                    height: 1.45,
                  ),
                ),
              ),
              const Spacer(),
              if (pulseirasNoGrupo > 0)
                BottomActionBar(
                  dark: true,
                  primary: AppButton(
                    label: 'Ver pulseiras do grupo · $pulseirasNoGrupo',
                    icon: Icons.groups_rounded,
                    outlined: true,
                    onDark: true,
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      onVerGrupo();
                    },
                  ),
                )
              else
                const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

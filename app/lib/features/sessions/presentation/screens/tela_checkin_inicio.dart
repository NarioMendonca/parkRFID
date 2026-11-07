import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_ui.dart';


class TelaCheckinInicio extends StatelessWidget {
  const TelaCheckinInicio({super.key, required this.onNovoCheckin});

  final VoidCallback onNovoCheckin;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppTheme.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const WaveBand(
            subtitle: 'Registre o responsável e as pulseiras do grupo.',
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: ScrollFill(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ActionCard(
                      title: 'Novo check-in',
                      subtitle: 'Vincular responsável e pulseiras',
                      icon: Icons.how_to_reg_rounded,
                      minHeight: 190,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        onNovoCheckin();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

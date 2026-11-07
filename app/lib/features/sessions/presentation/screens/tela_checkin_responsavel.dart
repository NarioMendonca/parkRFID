import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/masked_text_input_formatter.dart';
import '../../../../core/widgets/app_ui.dart';


class TelaCheckinResponsavel extends StatelessWidget {
  const TelaCheckinResponsavel({
    super.key,
    required this.cpfController,
    required this.phoneController,
    required this.onVoltar,
    required this.onContinuar,
  });

  final TextEditingController cpfController;
  final TextEditingController phoneController;
  final VoidCallback onVoltar;
  final VoidCallback onContinuar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          AppHeader(
            title: 'Novo check-in',
            subtitle: 'Identificação do responsável',
            onBack: () {
              FocusScope.of(context).unfocus();
              onVoltar();
            },
            bottom: const StepProgress(current: 1, total: 4, label: 'Responsável'),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              children: [
                AppCard(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionLabel('CPF do responsável'),
                      const SizedBox(height: 10),
                      TextField(
                        controller: cpfController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          MaskedTextInputFormatter(mask: '000.000.000-00', separator: '.'),
                        ],
                        decoration: const InputDecoration(
                          hintText: '000.000.000-00',
                          prefixIcon: Icon(Icons.badge_outlined),
                          contentPadding: EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                        ),
                      ),
                      const SizedBox(height: 22),
                      const SectionLabel('Telefone (WhatsApp)'),
                      const SizedBox(height: 10),
                      TextField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          MaskedTextInputFormatter(mask: '(00) 00000-0000', separator: ' '),
                        ],
                        decoration: const InputDecoration(
                          hintText: '(88) 90000-0000',
                          prefixIcon: Icon(Icons.phone_outlined),
                          contentPadding: EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          BottomActionBar(
            primary: AppButton(
              label: 'Continuar para leitura',
              icon: Icons.nfc_rounded,
              onPressed: () {
                FocusScope.of(context).unfocus();
                onContinuar();
              },
            ),
          ),
        ],
      ),
    );
  }
}

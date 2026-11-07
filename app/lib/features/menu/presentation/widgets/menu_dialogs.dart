import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/widgets/app_ui.dart';

Widget _dialogShell({required List<Widget> children}) {
  return Dialog(
    insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    ),
  );
}


Future<bool> confirmarExclusaoItem(BuildContext context) async {
  final confirmou = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => _dialogShell(
      children: [
        const StatePanel(
          icon: Icons.delete_outline_rounded,
          tone: AppTone.danger,
          title: 'Excluir Item',
          message: 'Tem certeza de que deseja remover este item do cardápio?',
        ),
        const SizedBox(height: 26),
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: 'Cancelar',
                outlined: true,
                tone: AppTone.neutral,
                height: 52,
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(dialogContext, false);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppButton(
                label: 'Excluir',
                icon: Icons.delete_outline_rounded,
                tone: AppTone.danger,
                height: 52,
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(dialogContext, true);
                },
              ),
            ),
          ],
        ),
      ],
    ),
  );
  return confirmou ?? false;
}


Future<void> mostrarAvisoCardapio(BuildContext context, String mensagem) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => _dialogShell(
      children: [
        StatePanel(
          icon: Icons.priority_high_rounded,
          tone: AppTone.warning,
          title: 'Atenção',
          message: mensagem,
        ),
        const SizedBox(height: 26),
        AppButton(
          label: 'Entendi',
          tone: AppTone.primary,
          height: 52,
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(dialogContext);
          },
        ),
      ],
    ),
  );
}

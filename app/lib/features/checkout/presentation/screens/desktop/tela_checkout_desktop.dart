import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/app_ui.dart';
import '../../../data/models/checkout_models.dart';
import '../../../data/repositories/checkout_repository.dart';
import '../../controllers/checkout_controller.dart';

/// Checkout (fechamento de comanda) — versão desktop.
///
/// Fluxo:
/// 1. Ler a pulseira (leitor USB ou digitação manual).
/// 2. Ver a comanda do grupo ou de cada pulseira e escolher quais pagar.
/// 3. Escolher a forma de pagamento e confirmar.
/// 4. Recibo + liberar a saída das pulseiras quitadas.
///
/// Por enquanto usa [MockCheckoutRepository]. Para usar a API, troque por
/// `ApiCheckoutRepository(ApiClient.dio)` quando o endpoint do grupo existir.
class TelaCheckoutDesktop extends StatelessWidget {
  const TelaCheckoutDesktop({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CheckoutController(MockCheckoutRepository()),
      child: const _TelaCheckoutDesktopContent(),
    );
  }
}

String _brl(double v) => 'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}';

String _hora(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

class _TelaCheckoutDesktopContent extends StatefulWidget {
  const _TelaCheckoutDesktopContent();

  @override
  State<_TelaCheckoutDesktopContent> createState() => _TelaCheckoutDesktopContentState();
}

class _TelaCheckoutDesktopContentState extends State<_TelaCheckoutDesktopContent> {
  final _manualController = TextEditingController();
  final _manualFocus = FocusNode();
  final _cashController = TextEditingController();
  final StringBuffer _usbBuffer = StringBuffer();
  Timer? _tagTimer;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleHardwareKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleHardwareKey);
    _tagTimer?.cancel();
    _manualController.dispose();
    _manualFocus.dispose();
    _cashController.dispose();
    super.dispose();
  }

  CheckoutController get _controller => context.read<CheckoutController>();

  bool _handleHardwareKey(KeyEvent event) {
    if (!mounted) return false;
    final c = _controller;
    if (c.group != null || c.isLoading) return false;
    if (_manualFocus.hasFocus) return false;
    if (FocusManager.instance.primaryFocus?.context?.widget is EditableText) return false;

    if (event is KeyDownEvent) {
      final char = event.character;
      if (char != null && char.isNotEmpty && char != '\n' && char != '\r') {
        _usbBuffer.write(char);
        _tagTimer?.cancel();
        _tagTimer = Timer(const Duration(milliseconds: 80), () {
          final raw = _usbBuffer.toString().trim();
          _usbBuffer.clear();
          if (raw.isNotEmpty) _search(raw);
        });
        return true;
      }
    }
    return false;
  }

  Future<void> _search(String raw) async {
    final uid = raw.trim().toUpperCase();
    if (uid.isEmpty) return;
    HapticFeedback.lightImpact();
    _cashController.clear();
    final ok = await _controller.loadByBracelet(uid);
    if (ok) _manualController.clear();
  }

  void _newCheckout() {
    HapticFeedback.lightImpact();
    _manualController.clear();
    _cashController.clear();
    _controller.reset();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<CheckoutController>();
    final step = c.group == null ? 1 : (c.lastPayment == null ? 2 : 3);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DesktopHeader(
            title: 'Checkout',
            subtitle: 'Fechamento da comanda e pagamento.',
            trailing: step > 1
                ? HeaderButton(
                    label: 'Novo checkout',
                    icon: Icons.restart_alt_rounded,
                    onPressed: _newCheckout,
                  )
                : null,
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: KeyedSubtree(
                key: ValueKey(step),
                child: switch (step) {
                  1 => _buildStepRead(c),
                  2 => _buildStepComanda(c),
                  _ => _buildStepReceipt(c),
                },
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildStepRead(CheckoutController c) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: AppCard(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const IconBadge(icon: Icons.point_of_sale_rounded, size: 84, solid: true),
                const SizedBox(height: 22),
                Text('Aproxime a pulseira', style: AppTheme.display(size: 30, color: AppTheme.textDark)),
                const SizedBox(height: 6),
                const Text(
                  'Qualquer pulseira do grupo abre a comanda completa.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15.5, color: AppTheme.textMuted),
                ),
                const SizedBox(height: 28),
                if (c.isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 22),
                    child: CircularProgressIndicator(),
                  )
                else ...[
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _manualController,
                          focusNode: _manualFocus,
                          textCapitalization: TextCapitalization.characters,
                          onSubmitted: _search,
                          decoration: const InputDecoration(
                            hintText: 'Ou digite o ID da pulseira',
                            prefixIcon: Icon(Icons.nfc_rounded),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 140,
                        child: AppButton(
                          label: 'Buscar',
                          icon: Icons.search_rounded,
                          height: 54,
                          onPressed: () => _search(_manualController.text),
                        ),
                      ),
                    ],
                  ),
                  if (c.errorMessage != null) ...[
                    const SizedBox(height: 16),
                    HintBanner(
                      text: c.errorMessage!,
                      icon: Icons.error_outline_rounded,
                      tone: AppTone.danger,
                    ),
                  ],
                ],
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const StatusPill(label: 'Dados simulados', icon: Icons.science_outlined, tone: AppTone.warning),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: c.isLoading
                          ? null
                          : () => _search(MockCheckoutRepository.testBraceletUids.first),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('Usar pulseira de teste'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildStepComanda(CheckoutController c) {
    final group = c.group!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 4, 32, 28),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 7,
            child: AppCard(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _GroupSummary(group: group),
                  const SizedBox(height: 22),
                  _ViewToggle(
                    value: c.view,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      c.setView(v);
                    },
                  ),
                  const SizedBox(height: 18),
                  Expanded(
                    child: c.view == CheckoutView.grupo
                        ? _GroupItemsTable(group: group)
                        : ListView(
                            children: [
                              for (final b in group.bracelets)
                                _BraceletComanda(
                                  bracelet: b,
                                  selected: c.selected.contains(b.braceletId),
                                  onToggle: () {
                                    HapticFeedback.selectionClick();
                                    c.toggleBracelet(b.braceletId);
                                  },
                                ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 24),
          SizedBox(
            width: 400,
            child: _PaymentPanel(
              controller: c,
              cashController: _cashController,
              onPay: () async {
                HapticFeedback.mediumImpact();
                await c.pay();
              },
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildStepReceipt(CheckoutController c) {
    final p = c.lastPayment!;
    final group = c.group!;
    final remaining = group.totalPending;
    final canRelease = !c.exitReleased && group.bracelets.any((b) => b.isSettled && !b.exited);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: AppCard(
            padding: const EdgeInsets.all(36),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                StatePanel(
                  icon: Icons.check_rounded,
                  tone: AppTone.success,
                  title: 'Pagamento confirmado',
                  message: '${_brl(p.paidAmount)} via ${p.method.label} às ${_hora(p.date)}',
                ),
                const SizedBox(height: 26),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.inputBg,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: [
                      InfoRow(label: 'Valor pago', value: _brl(p.paidAmount), icon: Icons.payments_outlined, emphasize: true),
                      const Divider(height: 26),
                      InfoRow(label: 'Forma de pagamento', value: p.method.label, icon: Icons.credit_card_rounded),
                      if (p.method == PaymentMethod.dinheiro) ...[
                        const Divider(height: 26),
                        InfoRow(label: 'Recebido', value: _brl(p.cashReceived ?? 0), icon: Icons.attach_money_rounded),
                        const Divider(height: 26),
                        InfoRow(label: 'Troco', value: _brl(p.change), icon: Icons.currency_exchange_rounded, emphasize: true),
                      ],
                      const Divider(height: 26),
                      InfoRow(
                        label: 'Pulseiras quitadas',
                        value: '${p.braceletIds.length}',
                        icon: Icons.watch_rounded,
                      ),
                    ],
                  ),
                ),
                if (remaining > 0) ...[
                  const SizedBox(height: 16),
                  HintBanner(
                    icon: Icons.warning_amber_rounded,
                    tone: AppTone.warning,
                    text: 'Ainda há ${_brl(remaining)} pendentes em '
                        '${c.pendingBracelets.length} pulseira(s) do grupo.',
                  ),
                ],
                if (c.errorMessage != null) ...[
                  const SizedBox(height: 16),
                  HintBanner(text: c.errorMessage!, icon: Icons.error_outline_rounded, tone: AppTone.danger),
                ],
                const SizedBox(height: 26),
                if (c.exitReleased)
                  const Center(
                    child: StatusPill(
                      label: 'Saída liberada para as pulseiras quitadas',
                      icon: Icons.logout_rounded,
                      tone: AppTone.success,
                    ),
                  )
                else if (canRelease)
                  AppButton(
                    label: 'Liberar saída',
                    icon: Icons.logout_rounded,
                    tone: AppTone.success,
                    loading: c.isLoading,
                    onPressed: c.isLoading
                        ? null
                        : () {
                            HapticFeedback.lightImpact();
                            c.releaseExit();
                          },
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (remaining > 0) ...[
                      Expanded(
                        child: AppButton(
                          label: 'Voltar à comanda',
                          icon: Icons.receipt_long_rounded,
                          outlined: true,
                          tone: AppTone.primary,
                          height: 52,
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            _cashController.clear();
                            c.backToComanda();
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: AppButton(
                        label: 'Novo checkout',
                        icon: Icons.restart_alt_rounded,
                        outlined: true,
                        tone: AppTone.neutral,
                        height: 52,
                        onPressed: _newCheckout,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}



class _GroupSummary extends StatelessWidget {
  const _GroupSummary({required this.group});

  final CheckoutGroup group;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const IconBadge(icon: Icons.groups_rounded, size: 54),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Comanda do grupo', style: AppTheme.display(size: 22, color: AppTheme.textDark)),
              Text(
                'Responsável ${group.responsibleCpf} · ${group.responsiblePhone}',
                style: const TextStyle(fontSize: 14, color: AppTheme.textMuted),
              ),
            ],
          ),
        ),
        _MiniStat(label: 'Pulseiras', value: '${group.bracelets.length}'),
        const SizedBox(width: 12),
        _MiniStat(label: 'Consumido', value: _brl(group.totalConsumed)),
        const SizedBox(width: 12),
        _MiniStat(label: 'Pendente', value: _brl(group.totalPending), highlight: true),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value, this.highlight = false});

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: highlight ? AppTheme.accentSoft : AppTheme.inputBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textMuted)),
          Text(value, style: AppTheme.display(size: 19, color: highlight ? AppTheme.accentInk : AppTheme.textDark)),
        ],
      ),
    );
  }
}

class _ViewToggle extends StatelessWidget {
  const _ViewToggle({required this.value, required this.onChanged});

  final CheckoutView value;
  final ValueChanged<CheckoutView> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget option(CheckoutView v, String label, IconData icon) {
      final selected = value == v;
      return Expanded(
        child: Material(
          color: selected ? AppTheme.primary : Colors.transparent,
          shape: const StadiumBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => onChanged(v),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 20, color: selected ? Colors.white : AppTheme.textMuted),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: selected ? Colors.white : AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(color: AppTheme.inputBg, borderRadius: BorderRadius.circular(40)),
      child: Row(
        children: [
          option(CheckoutView.grupo, 'Comanda compartilhada', Icons.groups_rounded),
          option(CheckoutView.individual, 'Por pulseira', Icons.watch_rounded),
        ],
      ),
    );
  }
}

class _GroupItemsTable extends StatelessWidget {
  const _GroupItemsTable({required this.group});

  final CheckoutGroup group;

  @override
  Widget build(BuildContext context) {
    final items = group.groupedItems;
    if (items.isEmpty) {
      return const Center(
        child: StatePanel(icon: Icons.receipt_long_rounded, tone: AppTone.neutral, title: 'Nenhum consumo registrado'),
      );
    }
    const head = TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.textSubtle, letterSpacing: 0.6);

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(child: Text('ITEM', style: head)),
              SizedBox(width: 70, child: Text('QTD', style: head, textAlign: TextAlign.center)),
              SizedBox(width: 110, child: Text('UNITÁRIO', style: head, textAlign: TextAlign.right)),
              SizedBox(width: 120, child: Text('SUBTOTAL', style: head, textAlign: TextAlign.right)),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final it = items[i];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(it.name, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700)),
                    ),
                    SizedBox(
                      width: 70,
                      child: Text('${it.amount}x', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                    SizedBox(
                      width: 110,
                      child: Text(_brl(it.unitPrice), textAlign: TextAlign.right, style: const TextStyle(color: AppTheme.textMuted)),
                    ),
                    SizedBox(
                      width: 120,
                      child: Text(_brl(it.subtotal), textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(color: AppTheme.inputBg, borderRadius: BorderRadius.circular(16)),
          child: Row(
            children: [
              const Expanded(child: Text('Total consumido pelo grupo', style: TextStyle(fontWeight: FontWeight.w800))),
              if (group.totalPaid > 0) ...[
                Text('Já pago ${_brl(group.totalPaid)}', style: const TextStyle(color: AppTheme.success, fontWeight: FontWeight.w700)),
                const SizedBox(width: 18),
              ],
              Text(_brl(group.totalConsumed), style: AppTheme.display(size: 20, color: AppTheme.textDark)),
            ],
          ),
        ),
      ],
    );
  }
}

class _BraceletComanda extends StatelessWidget {
  const _BraceletComanda({required this.bracelet, required this.selected, required this.onToggle});

  final CheckoutBracelet bracelet;
  final bool selected;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final b = bracelet;
    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.zero,
      borderColor: selected ? AppTheme.primary : null,
      shadow: false,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          leading: Checkbox(
            value: b.isSettled ? true : selected,
            onChanged: b.isSettled ? null : (_) => onToggle(),
          ),
          title: Row(
            children: [
              Text(b.isKid ? 'Infantil' : 'Adulto', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              if (b.isLeader) ...[
                const SizedBox(width: 8),
                const StatusPill(label: 'Líder', tone: AppTone.accent),
              ],
              const SizedBox(width: 8),
              StatusPill(
                label: b.isSettled ? 'Pago' : 'Pendente',
                tone: b.isSettled ? AppTone.success : AppTone.warning,
              ),
            ],
          ),
          subtitle: Text(
            '${b.braceletId} · entrada ${_hora(b.checkinDate)}',
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12.5, color: AppTheme.textMuted),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_brl(b.pending), style: AppTheme.display(size: 20, color: b.isSettled ? AppTheme.textSubtle : AppTheme.textDark)),
              if (b.paid > 0)
                Text('pago ${_brl(b.paid)}', style: const TextStyle(fontSize: 12, color: AppTheme.success, fontWeight: FontWeight.w700)),
            ],
          ),
          children: [
            for (final o in b.orders) ...[
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: Row(
                  children: [
                    Text(
                      'Pedido das ${_hora(o.date)}${o.tableNumber != null ? ' · mesa ${o.tableNumber}' : ''}',
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppTheme.textSubtle),
                    ),
                    const Spacer(),
                    Text(_brl(o.total), style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppTheme.textMuted)),
                  ],
                ),
              ),
              for (final it in o.items)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Text('${it.amount}x', style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.primary)),
                      const SizedBox(width: 10),
                      Expanded(child: Text(it.name)),
                      Text(_brl(it.subtotal), style: const TextStyle(fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PaymentPanel extends StatelessWidget {
  const _PaymentPanel({required this.controller, required this.cashController, required this.onPay});

  final CheckoutController controller;
  final TextEditingController cashController;
  final VoidCallback onPay;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final group = c.group!;

    return AppCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Pagamento', style: AppTheme.display(size: 22, color: AppTheme.textDark)),
          const SizedBox(height: 14),
          Row(
            children: [
              const Expanded(child: SectionLabel('Pulseiras a pagar')),
              if (c.pendingBracelets.length > 1)
                TextButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    c.selectAllPending();
                  },
                  child: const Text('Selecionar todas'),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Expanded(
            child: ListView(
              children: [
                for (final b in group.bracelets)
                  CheckboxListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                    controlAffinity: ListTileControlAffinity.leading,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    value: b.isSettled ? true : c.selected.contains(b.braceletId),
                    onChanged: b.isSettled
                        ? null
                        : (_) {
                            HapticFeedback.selectionClick();
                            c.toggleBracelet(b.braceletId);
                          },
                    title: Text(
                      '${b.isKid ? 'Infantil' : 'Adulto'}${b.isLeader ? ' · líder' : ''}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(b.braceletId, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
                    secondary: b.isSettled
                        ? const StatusPill(label: 'Pago', tone: AppTone.success)
                        : Text(_brl(b.pending), style: const TextStyle(fontWeight: FontWeight.w800)),
                  ),
              ],
            ),
          ),
          const Divider(height: 24),
          const SectionLabel('Forma de pagamento'),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 3.2,
            children: [
              for (final m in PaymentMethod.values)
                _MethodButton(
                  method: m,
                  selected: c.method == m,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    if (m != PaymentMethod.dinheiro) cashController.clear();
                    c.setMethod(m);
                  },
                ),
            ],
          ),
          if (c.method == PaymentMethod.dinheiro) ...[
            const SizedBox(height: 14),
            TextField(
              controller: cashController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: c.setCashReceived,
              decoration: InputDecoration(
                hintText: 'Valor recebido',
                prefixText: 'R\$ ',
                errorText: cashController.text.isNotEmpty && !c.cashIsEnough ? 'Valor menor que o total' : null,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Troco', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textMuted)),
                const Spacer(),
                Text(_brl(c.change), style: AppTheme.display(size: 18, color: AppTheme.success)),
              ],
            ),
          ],
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(color: AppTheme.accentSoft, borderRadius: BorderRadius.circular(18)),
            child: Row(
              children: [
                const Text('Total a pagar', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                const Spacer(),
                Text(_brl(c.selectedTotal), style: AppTheme.display(size: 28, color: AppTheme.textDark)),
              ],
            ),
          ),
          if (c.errorMessage != null) ...[
            const SizedBox(height: 12),
            HintBanner(text: c.errorMessage!, icon: Icons.error_outline_rounded, tone: AppTone.danger),
          ],
          const SizedBox(height: 14),
          AppButton(
            label: c.selectedTotal > 0 ? 'Confirmar ${_brl(c.selectedTotal)}' : 'Nada a pagar',
            icon: Icons.check_circle_outline_rounded,
            loading: c.isLoading,
            onPressed: c.canPay ? onPay : null,
          ),
        ],
      ),
    );
  }
}

class _MethodButton extends StatelessWidget {
  const _MethodButton({required this.method, required this.selected, required this.onTap});

  final PaymentMethod method;
  final bool selected;
  final VoidCallback onTap;

  IconData get _icon {
    switch (method) {
      case PaymentMethod.pix:
        return Icons.qr_code_2_rounded;
      case PaymentMethod.credito:
        return Icons.credit_card_rounded;
      case PaymentMethod.debito:
        return Icons.payment_rounded;
      case PaymentMethod.dinheiro:
        return Icons.payments_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : AppTheme.textDark;
    return Material(
      color: selected ? AppTheme.primary : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: selected ? AppTheme.primary : AppTheme.border, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_icon, size: 22, color: selected ? AppTheme.accent : AppTheme.primary),
            const SizedBox(width: 8),
            Text(method.label, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: fg)),
          ],
        ),
      ),
    );
  }
}

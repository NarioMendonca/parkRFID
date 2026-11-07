import 'package:flutter/material.dart';
import 'package:rfidparque/core/theme/app_theme.dart';
import 'package:rfidparque/features/bracelets/presentation/screens/desktop/gestao_pulseiras_desktop.dart';
import 'package:rfidparque/features/checkout/presentation/screens/desktop/tela_checkout_desktop.dart';

import 'package:rfidparque/features/menu/presentation/screens/desktop/menu_desktop.dart';
import 'package:rfidparque/features/reports/presentation/screens/desktop/tela_relatorios_desktop.dart';
import 'package:rfidparque/features/sessions/presentation/screens/desktop/checkin_desktop.dart';

class MainDesktopNavigationScreen extends StatefulWidget {
  const MainDesktopNavigationScreen({super.key});

  @override
  State<MainDesktopNavigationScreen> createState() => _MainDesktopNavigationScreenState();
}

class _MainDesktopNavigationScreenState extends State<MainDesktopNavigationScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;

  /// Avisa o Dashboard para atualizar em segundo plano quando ele volta a ser aberto.
  final ValueNotifier<int> _dashboardAberto = ValueNotifier(0);

  late final List<Widget> _screens = [
    TelaRelatoriosDesktop(refreshSignal: _dashboardAberto),
    const TelaCheckinDesktop(),
    const TelaGestaoPulseirasDesktop(),
    const TelaMenuDesktop(),
    const TelaCheckoutDesktop(),
  ];

  /// Telas que ficam vivas depois da primeira visita (as que carregam dados da API).
  /// Check-in, Pulseiras e Checkout são fluxos com leitor USB (handler global de
  /// teclado) e reiniciam ao sair, então continuam sendo recriadas a cada visita.
  static const Set<int> _manterVivas = {0, 3};

  /// Telas já abertas ao menos uma vez.
  final Set<int> _visitadas = {0};

  /// Fade curto ao trocar de tela, sem destruir a tela anterior.
  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
    value: 1,
  );
  late final Animation<double> _fadeCurve =
      CurvedAnimation(parent: _fade, curve: Curves.easeOutCubic);

  void _irPara(int index) {
    if (index == _currentIndex) return;
    setState(() {
      _currentIndex = index;
      _visitadas.add(index);
    });
    if (index == 0) _dashboardAberto.value++;
    _fade.forward(from: 0);
  }

  bool _montada(int i) =>
      i == _currentIndex || (_manterVivas.contains(i) && _visitadas.contains(i));

  @override
  void dispose() {
    _fade.dispose();
    _dashboardAberto.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Row(
        children: [
          Container(
            width: 112,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppTheme.primary, AppTheme.navy],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Image.asset('assets/images/logo.png', height: 52, fit: BoxFit.contain),
                  ),
                  const SizedBox(height: 28),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      children: [
                        _buildNavItem(
                          index: 0,
                          icon: Icons.analytics_outlined,
                          selectedIcon: Icons.analytics_rounded,
                          label: 'Dashboard',
                        ),
                        const SizedBox(height: 10),
                        _buildNavItem(
                          index: 1,
                          icon: Icons.how_to_reg_outlined,
                          selectedIcon: Icons.how_to_reg_rounded,
                          label: 'Check-in',
                        ),
                        const SizedBox(height: 10),
                        _buildNavItem(
                          index: 2,
                          icon: Icons.watch_outlined,
                          selectedIcon: Icons.watch_rounded,
                          label: 'Pulseiras',
                        ),
                        const SizedBox(height: 10),
                        _buildNavItem(
                          index: 3,
                          icon: Icons.restaurant_menu_outlined,
                          selectedIcon: Icons.restaurant_menu_rounded,
                          label: 'Cardápio',
                        ),
                      ],
                    ),
                  ),
                  // Checkout isolado no rodapé, em destaque
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 20),
                    child: Column(
                      children: [
                        Container(
                          height: 1,
                          margin: const EdgeInsets.only(bottom: 16),
                          color: Colors.white.withValues(alpha: 0.18),
                        ),
                        _buildCheckoutButton(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: FadeTransition(
              opacity: _fadeCurve,
              child: IndexedStack(
                index: _currentIndex,
                children: [
                  for (var i = 0; i < _screens.length; i++)
                    _montada(i)
                        // TickerMode pausa animações das telas escondidas.
                        ? TickerMode(enabled: i == _currentIndex, child: _screens[i])
                        : const SizedBox.shrink(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutButton() {
    const index = 4;
    final isSelected = _currentIndex == index;

    return Material(
      color: isSelected ? Colors.white : AppTheme.accent,
      borderRadius: BorderRadius.circular(20),
      elevation: isSelected ? 0 : 4,
      shadowColor: AppTheme.accent.withValues(alpha: 0.5),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _irPara(index),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.point_of_sale_rounded,
                size: 30,
                color: isSelected ? AppTheme.primary : AppTheme.onAccent,
              ),
              const SizedBox(height: 6),
              Text(
                'Checkout',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? AppTheme.primary : AppTheme.onAccent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData selectedIcon,
    required String label,
  }) {
    final isSelected = _currentIndex == index;
    final fg = isSelected ? AppTheme.onAccent : Colors.white.withValues(alpha: 0.85);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _irPara(index),
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(isSelected ? selectedIcon : icon, color: fg, size: 26),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: fg,
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

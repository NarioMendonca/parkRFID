import 'package:flutter/material.dart';
import 'package:rfidparque/features/bracelets/presentation/screens/desktop/gestao_pulseiras_desktop.dart';

import 'package:rfidparque/features/menu/presentation/screens/desktop/menu_desktop.dart';
import 'package:rfidparque/features/reports/presentation/screens/desktop/tela_relatorios_desktop.dart';
import 'package:rfidparque/features/sessions/presentation/screens/desktop/checkin_desktop.dart';

class MainDesktopNavigationScreen extends StatefulWidget {
  const MainDesktopNavigationScreen({super.key});

  @override
  State<MainDesktopNavigationScreen> createState() => _MainDesktopNavigationScreenState();
}

class _MainDesktopNavigationScreenState extends State<MainDesktopNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    TelaRelatoriosDesktop(),
    TelaCheckinDesktop(),
    TelaGestaoPulseirasDesktop(),
    TelaMenuDesktop(),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Row(
        children: [
          Container(
            width: 100,
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border(
                right: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5), width: 1),
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 32),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: [
                      _buildNavItem(
                        index: 0,
                        icon: Icons.analytics_outlined,
                        selectedIcon: Icons.analytics,
                        label: 'Dashboard',
                        colorScheme: colorScheme,
                      ),
                      const SizedBox(height: 12),
                      _buildNavItem(
                        index: 1,
                        icon: Icons.qr_code_scanner_outlined,
                        selectedIcon: Icons.qr_code_scanner,
                        label: 'Check-in',
                        colorScheme: colorScheme,
                      ),
                      const SizedBox(height: 12),
                      _buildNavItem(
                        index: 2,
                        icon: Icons.add_circle_outline,
                        selectedIcon: Icons.add_circle,
                        label: 'Pulseiras',
                        colorScheme: colorScheme,
                      ),
                      const SizedBox(height: 12),
                      _buildNavItem(
                        index: 3,
                        icon: Icons.restaurant_menu_outlined,
                        selectedIcon: Icons.restaurant_menu,
                        label: 'Cardápio',
                        colorScheme: colorScheme,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              switchInCurve: const Interval(0.5, 1.0, curve: Curves.easeOutCubic),
              switchOutCurve: const Interval(0.0, 0.5, curve: Curves.easeInCubic),
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.05, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: KeyedSubtree(
                key: ValueKey<int>(_currentIndex),
                child: _screens[_currentIndex],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required ColorScheme colorScheme,
  }) {
    final isSelected = _currentIndex == index;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _currentIndex = index;
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.primary.withOpacity(0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? selectedIcon : icon,
                color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                size: 26,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
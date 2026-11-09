import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:rfidparque/core/theme/app_theme.dart';
import 'package:rfidparque/core/widgets/step_fade.dart';
import 'package:rfidparque/features/bracelets/presentation/screens/tela_gestao_pulseiras.dart';
import 'package:rfidparque/features/menu/presentation/screens/tela_menu.dart';
import '../../../orders/presentation/screens/tela_fazer_pedido_inicio.dart';
import '../../../sessions/presentation/screens/tela_checkin.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  bool _showAppBar = true;


  final Set<int> _visitadas = {0};


  int? _abaPendente;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _aquecerAbas());
  }

  Future<void> _aquecerAbas() async {

    await Future.delayed(const Duration(milliseconds: 800));
    for (var i = 0; i < _screens.length; i++) {
      if (!mounted) return;
      if (_visitadas.contains(i)) continue;

      await SchedulerBinding.instance.scheduleTask(() {
        if (mounted) setState(() => _visitadas.add(i));
      }, Priority.idle);
      await SchedulerBinding.instance.endOfFrame;
      await Future.delayed(const Duration(milliseconds: 250));
    }
  }

  void _aplicarAbaPendente() {
    final index = _abaPendente;
    _abaPendente = null;
    if (index == null || !mounted || index == _currentIndex) return;

    if (_currentIndex == 0) TelaCheckin.resetarFluxo();
    if (_currentIndex == 2) TelaGestaoPulseiras.resetarFluxo();

    setState(() {
      _currentIndex = index;
      _visitadas.add(index);
    });
  }

  late final List<Widget> _screens = [
    TelaCheckin(
      onNavbarVisibilityChanged: (isVisible) {
        setState(() {
          _showAppBar = isVisible;
        });
      },
    ),
    const Center(child: Text('Tela de Sessões')),
    TelaGestaoPulseiras(
      onNavbarVisibilityChanged: (isVisible) {
        setState(() {
          _showAppBar = isVisible;
        });
      },
    ),
    const TelaMenu(),
  ];

  void _onItemTapped(int index) {
    HapticFeedback.lightImpact();

    _abaPendente = index;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final List<String> titulos = [
      'Check-in',
      'Sessões',
      'Cadastro de Pulseiras',
      'Cardápio',
    ];

    return Scaffold(
      resizeToAvoidBottomInset: false,
      onDrawerChanged: (isOpen) {
        if (!isOpen) _aplicarAbaPendente();
      },
      appBar: _showAppBar
          ? AppBar(
        toolbarHeight: 64,
        centerTitle: false,
        leading: Builder(builder: (context) {
          return IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              HapticFeedback.lightImpact();
              Scaffold.of(context).openDrawer();
            },
          );
        }),
        title: Text(
          titulos[_currentIndex],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
      )
          : null,
      drawer: _showAppBar
          ? Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppTheme.primary, AppTheme.navy],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    height: 48,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Gestão do Parque',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 2),
              child: ListTile(
                leading: const Icon(Icons.qr_code_scanner_outlined),
                title: const Text('Check-in'),
                selected: _currentIndex == 0,
                selectedColor: colorScheme.primary,
                onTap: () => _onItemTapped(0),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              child: ListTile(
                leading: const Icon(Icons.confirmation_number_outlined),
                title: const Text('Sessões'),
                selected: _currentIndex == 1,
                selectedColor: colorScheme.primary,
                onTap: () => _onItemTapped(1),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              child: ListTile(
                leading: const Icon(Icons.add_circle_outline),
                title: const Text('Cadastro de Pulseiras'),
                selected: _currentIndex == 2,
                selectedColor: colorScheme.primary,
                onTap: () => _onItemTapped(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              child: ListTile(
                leading: const Icon(Icons.restaurant_menu_outlined),
                title: const Text('Cardápio'),
                selected: _currentIndex == 3,
                selectedColor: colorScheme.primary,
                onTap: () => _onItemTapped(3),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Divider(),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              child: ListTile(
              leading: const Icon(Icons.add_shopping_cart_rounded, color: AppTheme.accentInk),
              title: const Text('Novo Pedido'),
              onTap: () {

                HapticFeedback.lightImpact();

                Navigator.pop(context);

                Navigator.push(
                  context,
                  StepFadeRoute(
                    builder: (context) => const TelaFazerPedidoInicio(),
                  ),
                );
              },
            ),
            ),
          ],
        ),
      )
          : null,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          for (var i = 0; i < _screens.length; i++)
            _visitadas.contains(i) ? _screens[i] : const SizedBox.shrink(),
        ],
      ),
    );
  }
}
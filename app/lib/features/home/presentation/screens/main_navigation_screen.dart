import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

    if (_currentIndex == 0 && index != 0) {
      TelaCheckin.resetarFluxo();
    }

    if (_currentIndex == 2 && index != 2) {
      TelaGestaoPulseiras.resetarFluxo();
    }

    setState(() {
      _currentIndex = index;
    });

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
      appBar: _showAppBar
          ? AppBar(
        toolbarHeight: 80,
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
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Image.asset(
              'assets/images/logo.png',
              height: 52,
              fit: BoxFit.contain,
            ),
          ),
        ],
      )
          : null,
      drawer: _showAppBar
          ? Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: colorScheme.primary,
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
            ListTile(
              leading: const Icon(Icons.qr_code_scanner_outlined),
              title: const Text('Check-in'),
              selected: _currentIndex == 0,
              selectedColor: colorScheme.primary,
              onTap: () => _onItemTapped(0),
            ),
            ListTile(
              leading: const Icon(Icons.confirmation_number_outlined),
              title: const Text('Sessões'),
              selected: _currentIndex == 1,
              selectedColor: colorScheme.primary,
              onTap: () => _onItemTapped(1),
            ),
            ListTile(
              leading: const Icon(Icons.add_circle_outline),
              title: const Text('Cadastro de Pulseiras'),
              selected: _currentIndex == 2,
              selectedColor: colorScheme.primary,
              onTap: () => _onItemTapped(2),
            ),
            ListTile(
              leading: const Icon(Icons.restaurant_menu_outlined),
              title: const Text('Cardápio'),
              selected: _currentIndex == 3,
              selectedColor: colorScheme.primary,
              onTap: () => _onItemTapped(3),
            ),
            ListTile(
              leading: const Icon(Icons.add_shopping_cart_rounded),
              title: const Text('Novo Pedido'),
              onTap: () {

                HapticFeedback.lightImpact();

                Navigator.pop(context);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TelaFazerPedidoInicio(),
                  ),
                );
              },
            )
          ],
        ),
      )
          : null,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
    );
  }
}
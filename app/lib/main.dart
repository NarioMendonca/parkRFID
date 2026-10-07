import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Importação do Provider adicionada

import 'core/theme/app_theme.dart';
import 'features/home/presentation/screens/main_navigation_screen.dart';

// Importa o teu provider aqui (ajusta o caminho exato para onde o teu arquivo estiver)
import 'features/orders/presentation/controllers/pedido_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PedidoProvider()),
      ],
      child: const MyApp(),
    ),
  );
} 

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aquapark Admin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const MainNavigationScreen(),
    );
  }
}
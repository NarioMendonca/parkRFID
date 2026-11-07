import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'features/home/presentation/screens/desktop/desktop_navigation.dart';
import 'features/home/presentation/screens/main_navigation_screen.dart';
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

  bool get _isDesktop =>
      kIsWeb || Platform.isWindows || Platform.isLinux || Platform.isMacOS;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Aquapark',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,

      home: _isDesktop
          ? const MainDesktopNavigationScreen()
          : const MainNavigationScreen(),
    );
  }
}


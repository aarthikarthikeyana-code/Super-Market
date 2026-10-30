import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'nummakadai/core/theme/numma_theme.dart';
import 'router/app_router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(
    const ProviderScope(
      child: AgaramSupermarketApp(),
    ),
  );
}

class AgaramSupermarketApp extends StatelessWidget {
  const AgaramSupermarketApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'AGARAM Supermarket',
      debugShowCheckedModeBanner: false,
      theme: NummaTheme.lightTheme,
      routerConfig: appRouter,
    );
  }
}

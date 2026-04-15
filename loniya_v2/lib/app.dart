import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

class LoniyaApp extends ConsumerWidget {
  const LoniyaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'LONIYA V2',
      debugShowCheckedModeBanner: false,

      // Material 3 theme
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,

      // GoRouter
      routerConfig: router,

      // Localization
      locale: const Locale('fr', 'BF'),
      supportedLocales: const [
        Locale('fr', 'BF'), // French (Burkina Faso)
        Locale('fr'),       // French fallback
      ],
    );
  }
}

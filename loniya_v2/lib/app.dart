import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_text_styles.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/presentation/providers/settings_provider.dart';

class LoniyaApp extends ConsumerWidget {
  const LoniyaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router   = ref.watch(appRouterProvider);
    final settings = ref.watch(currentSettingsProvider);

    final ThemeData activeLight = settings.isHighContrast
        ? _highContrastTheme
        : AppTheme.lightTheme;
    final ThemeData activeDark = settings.isHighContrast
        ? _highContrastTheme
        : AppTheme.darkTheme;
    final ThemeMode themeMode = settings.isHighContrast
        ? ThemeMode.dark
        : (settings.darkMode ? ThemeMode.dark : ThemeMode.system);

    return MaterialApp.router(
      title: 'LONIYA V2',
      debugShowCheckedModeBanner: false,

      theme:     activeLight,
      darkTheme: activeDark,
      themeMode: themeMode,

      routerConfig: router,

      locale: const Locale('fr', 'BF'),
      supportedLocales: const [Locale('fr', 'BF'), Locale('fr')],

      builder: (context, child) {
        final media = MediaQuery.of(context);
        // Large-text mode locks to 1.3×; otherwise honour system within 0.8–1.3
        final scale = settings.isLargeText
            ? 1.3
            : media.textScaler.scale(1.0).clamp(0.8, 1.3);
        final bounded = media.copyWith(textScaler: TextScaler.linear(scale));
        return MediaQuery(
          data: bounded,
          child: _AppErrorBoundary(child: child ?? const SizedBox.shrink()),
        );
      },
    );
  }

  // High-contrast theme: black background, gold primary, white text
  static final ThemeData _highContrastTheme = ThemeData(
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFFFFD700),
      onPrimary: Colors.black,
      secondary: Color(0xFF00FF88),
      onSecondary: Colors.black,
      surface: Color(0xFF121212),
      onSurface: Colors.white,
      error: Color(0xFFFF5252),
      onError: Colors.black,
    ),
    scaffoldBackgroundColor: Colors.black,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.black,
      foregroundColor: Color(0xFFFFD700),
      elevation: 0,
    ),
    iconTheme: const IconThemeData(color: Color(0xFFFFD700)),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.all(const Color(0xFFFFD700)),
      trackColor: WidgetStateProperty.all(
          const Color(0xFFFFD700).withOpacity(0.3)),
    ),
    useMaterial3: true,
  );
}

// ─── Error boundary ───────────────────────────────────────────────────────────

class _AppErrorBoundary extends StatefulWidget {
  final Widget child;
  const _AppErrorBoundary({required this.child});

  @override
  State<_AppErrorBoundary> createState() => _AppErrorBoundaryState();
}

class _AppErrorBoundaryState extends State<_AppErrorBoundary> {
  Object? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _error = null;
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return _FatalErrorScreen(
        error: _error!,
        onRetry: () => setState(() => _error = null),
      );
    }
    return widget.child;
  }

  static Widget errorBuilder(FlutterErrorDetails details) {
    return _FatalErrorScreen(error: details.exception, onRetry: null);
  }
}

class _FatalErrorScreen extends StatelessWidget {
  final Object error;
  final VoidCallback? onRetry;

  const _FatalErrorScreen({required this.error, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.warning_amber_rounded,
                    size: 72, color: AppColors.warning),
                const SizedBox(height: 24),
                Text('Une erreur inattendue est survenue',
                    style: AppTextStyles.titleMedium,
                    textAlign: TextAlign.center),
                const SizedBox(height: 12),
                Text(
                  'L\'application a rencontré un problème. '
                  'Vos données locales sont sécurisées.',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
                if (onRetry != null) ...[
                  const SizedBox(height: 28),
                  FilledButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Réessayer'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

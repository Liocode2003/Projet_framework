import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_text_styles.dart';
import 'core/theme/app_theme.dart';

class LoniyaApp extends ConsumerWidget {
  const LoniyaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'LONIYA V2',
      debugShowCheckedModeBanner: false,

      theme:     AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,

      routerConfig: router,

      locale: const Locale('fr', 'BF'),
      supportedLocales: const [
        Locale('fr', 'BF'),
        Locale('fr'),
      ],

      // Global widget-tree error boundary — catches errors during build/layout.
      builder: (context, child) {
        // Clamp text scaling so layout never breaks on accessibility settings
        final media = MediaQuery.of(context);
        final bounded = media.copyWith(
          textScaler: media.textScaler.clamp(
            minScaleFactor: 0.8,
            maxScaleFactor: 1.3,
          ),
        );
        return MediaQuery(
          data: bounded,
          child: _AppErrorBoundary(child: child ?? const SizedBox.shrink()),
        );
      },
    );
  }
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

  // Called by ErrorWidget when an uncaught error occurs in the widget tree
  static Widget errorBuilder(FlutterErrorDetails details) {
    return _FatalErrorScreen(
      error: details.exception,
      onRetry: null,
    );
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
                  style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.onSurfaceVariant),
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

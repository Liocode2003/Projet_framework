import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

final _log = Logger(
  printer: PrettyPrinter(methodCount: 2, printTime: true),
  level: kDebugMode ? Level.debug : Level.warning,
);

/// Catches unhandled Flutter framework errors (widget build failures,
/// painting errors, gesture handler exceptions, etc.).
///
/// In debug mode errors are re-thrown so they appear in DevTools.
/// In release mode they are logged and swallowed to avoid crashes.
void onFlutterError(FlutterErrorDetails details) {
  _log.e(
    'FlutterError: ${details.exceptionAsString()}',
    error: details.exception,
    stackTrace: details.stack,
  );
  if (kDebugMode) {
    FlutterError.dumpErrorToConsole(details);
  }
}

/// Catches unhandled Dart errors on the root isolate
/// (e.g. async Future errors that are never caught).
///
/// Returns true to prevent the isolate from crashing in release builds.
bool onPlatformError(Object error, StackTrace stack) {
  _log.e('PlatformDispatcher error', error: error, stackTrace: stack);
  return !kDebugMode; // let it propagate in debug, suppress in release
}

/// Riverpod observer — logs provider lifecycle and errors to the console.
class YikriProviderObserver extends ProviderObserver {
  @override
  void providerDidFail(
    ProviderBase<Object?> provider,
    Object error,
    StackTrace stackTrace,
    ProviderContainer container,
  ) {
    _log.e(
      'Provider failed: ${provider.name ?? provider.runtimeType}',
      error: error,
      stackTrace: stackTrace,
    );
  }

  @override
  void didAddProvider(
    ProviderBase<Object?> provider,
    Object? value,
    ProviderContainer container,
  ) {
    if (kDebugMode) {
      _log.t('Provider added: ${provider.name ?? provider.runtimeType}');
    }
  }

  @override
  void didDisposeProvider(
    ProviderBase<Object?> provider,
    ProviderContainer container,
  ) {
    if (kDebugMode) {
      _log.t('Provider disposed: ${provider.name ?? provider.runtimeType}');
    }
  }
}

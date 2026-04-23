import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/connectivity/connectivity_service.dart';
import '../services/sync/sync_notifier.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Animated connectivity banner shown at the top of the AppShell.
/// - Offline → dark grey bar "Mode hors-ligne"
/// - Just reconnected → green bar "Connexion rétablie" (auto-hides after 3s)
class OfflineBanner extends ConsumerStatefulWidget {
  const OfflineBanner({super.key});

  @override
  ConsumerState<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends ConsumerState<OfflineBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _slide;

  bool _justReconnected = false;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _slide = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();

    // Listen for reconnection events
    ref.listenManual<AsyncValue<bool>>(isOnlineProvider, (prev, next) {
      final wasOffline = prev?.valueOrNull == false;
      final nowOnline  = next.valueOrNull  == true;
      if (wasOffline && nowOnline && mounted) {
        setState(() => _justReconnected = true);
        _hideTimer?.cancel();
        _hideTimer = Timer(const Duration(seconds: 3), () {
          if (mounted) setState(() => _justReconnected = false);
        });
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _hideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final syncPending = ref.watch(syncNotifierProvider).pendingCount;

    final isReconnected = _justReconnected;
    final bg = isReconnected
        ? const Color(0xFF1B8A4B)
        : const Color(0xFF2C2C3E);

    return SizeTransition(
      sizeFactor: _slide,
      axisAlignment: -1,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        color: bg,
        child: SafeArea(
          bottom: false,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
            color: bg,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isReconnected
                      ? Icons.wifi_rounded
                      : Icons.wifi_off_rounded,
                  color: Colors.white70,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    isReconnected
                        ? syncPending > 0
                            ? 'Connexion rétablie — synchronisation en cours…'
                            : 'Connexion rétablie ✓'
                        : 'Mode hors-ligne — données locales uniquement',
                    style: AppTextStyles.offlineBanner,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (!isReconnected && syncPending > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$syncPending en attente',
                      style: const TextStyle(
                        color: AppColors.warning,
                        fontSize: 10,
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
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

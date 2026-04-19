import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_names.dart';
import '../../../../core/services/sync/sync_notifier.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/offline_banner.dart';
import '../providers/shell_provider.dart';

class AppShell extends ConsumerStatefulWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  static const List<_NavItem> _navItems = [
    _NavItem(label: 'Accueil',   icon: Icons.home_outlined,          activeIcon: Icons.home_rounded,          route: RouteNames.home),
    _NavItem(label: 'Contenus',  icon: Icons.store_outlined,         activeIcon: Icons.store_rounded,         route: RouteNames.marketplace),
    _NavItem(label: 'Apprendre', icon: Icons.menu_book_outlined,     activeIcon: Icons.menu_book_rounded,     route: RouteNames.learning),
    _NavItem(label: 'IA Tuteur', icon: Icons.psychology_outlined,    activeIcon: Icons.psychology_rounded,    route: RouteNames.aiTutor),
    _NavItem(label: 'Profil',    icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded,        route: RouteNames.gamification),
  ];

  static const List<_NavItem> _teacherNavItems = [
    _NavItem(label: 'Accueil',  icon: Icons.home_outlined,          activeIcon: Icons.home_rounded,       route: RouteNames.home),
    _NavItem(label: 'Classe',   icon: Icons.class_outlined,         activeIcon: Icons.class_rounded,      route: RouteNames.teacherDashboard),
    _NavItem(label: 'Contenus', icon: Icons.store_outlined,         activeIcon: Icons.store_rounded,      route: RouteNames.marketplace),
    _NavItem(label: 'Wi-Fi',    icon: Icons.wifi_outlined,          activeIcon: Icons.wifi_rounded,       route: RouteNames.localClassroom),
    _NavItem(label: 'Profil',   icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded,     route: RouteNames.gamification),
  ];

  static const List<_NavItem> _parentNavItems = [
    _NavItem(label: 'Accueil',   icon: Icons.home_outlined,          activeIcon: Icons.home_rounded,       route: RouteNames.home),
    _NavItem(label: 'Enfants',   icon: Icons.child_care_outlined,    activeIcon: Icons.child_care_rounded, route: RouteNames.home),
    _NavItem(label: 'Contenus',  icon: Icons.store_outlined,         activeIcon: Icons.store_rounded,      route: RouteNames.marketplace),
    _NavItem(label: 'IA Tuteur', icon: Icons.psychology_outlined,    activeIcon: Icons.psychology_rounded, route: RouteNames.aiTutor),
    _NavItem(label: 'Profil',    icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded,     route: RouteNames.gamification),
  ];

  int _currentIndex = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _currentIndex = _indexFromLocation(GoRouterState.of(context).matchedLocation);
  }

  int _indexFromLocation(String location) {
    final items = _itemsForRole(ref.read(userRoleProvider));
    for (int i = 0; i < items.length; i++) {
      if (location.startsWith(items[i].route)) return i;
    }
    return 0;
  }

  List<_NavItem> _itemsForRole(String? role) {
    if (role == 'teacher') return _teacherNavItems;
    if (role == 'parent')  return _parentNavItems;
    return _navItems;
  }

  void _onItemTapped(int index, String? role) {
    if (index == _currentIndex) return;
    if (role == 'parent' && index == 1) {
      context.push(RouteNames.parentDashboard);
      return;
    }
    final items = _itemsForRole(role);
    context.go(items[index].route);
  }

  @override
  Widget build(BuildContext context) {
    final isOffline   = ref.watch(offlineStatusProvider);
    final userRole    = ref.watch(userRoleProvider);
    final syncPending = ref.watch(syncNotifierProvider).pendingCount;
    final items       = _itemsForRole(userRole);
    final bottom      = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      extendBody: true,
      body: Column(
        children: [
          if (isOffline) const OfflineBanner(),
          Expanded(child: widget.child),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, bottom + 12),
        child: Container(
          height: 62,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.18),
                blurRadius: 28,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: List.generate(items.length, (i) {
              final item     = items[i];
              final selected = i == _currentIndex;
              final showBadge =
                  item.route == RouteNames.home && syncPending > 0;

              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _onItemTapped(i, userRole),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeInOut,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primary.withOpacity(0.12)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: showBadge
                            ? Badge(
                                label: Text('$syncPending',
                                    style: const TextStyle(fontSize: 10)),
                                backgroundColor: AppColors.accent,
                                child: Icon(
                                  selected ? item.activeIcon : item.icon,
                                  color: selected
                                      ? AppColors.primary
                                      : AppColors.grey400,
                                  size: 22,
                                ),
                              )
                            : Icon(
                                selected ? item.activeIcon : item.icon,
                                color: selected
                                    ? AppColors.primary
                                    : AppColors.grey400,
                                size: 22,
                              ),
                      ),
                      const SizedBox(height: 2),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 220),
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 10,
                          fontWeight: selected
                              ? FontWeight.w800
                              : FontWeight.w500,
                          color: selected
                              ? AppColors.primary
                              : AppColors.grey400,
                        ),
                        child: Text(item.label),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String route;
  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.route,
  });
}

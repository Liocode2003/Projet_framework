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
  // Student nav items
  static const List<_NavItem> _navItems = [
    _NavItem(label: 'Accueil',  icon: Icons.home_outlined,        activeIcon: Icons.home_rounded,        route: RouteNames.home),
    _NavItem(label: 'Contenus', icon: Icons.store_outlined,       activeIcon: Icons.store_rounded,       route: RouteNames.marketplace),
    _NavItem(label: 'Apprendre',icon: Icons.menu_book_outlined,   activeIcon: Icons.menu_book_rounded,   route: RouteNames.learning),
    _NavItem(label: 'IA Tuteur',icon: Icons.psychology_outlined,  activeIcon: Icons.psychology_rounded,  route: RouteNames.aiTutor),
    _NavItem(label: 'Profil',   icon: Icons.person_outline_rounded,activeIcon: Icons.person_rounded,     route: RouteNames.gamification),
  ];

  // Teacher nav items
  static const List<_NavItem> _teacherNavItems = [
    _NavItem(label: 'Accueil',   icon: Icons.home_outlined,             activeIcon: Icons.home_rounded,          route: RouteNames.home),
    _NavItem(label: 'Classe',    icon: Icons.class_outlined,            activeIcon: Icons.class_rounded,         route: RouteNames.teacherDashboard),
    _NavItem(label: 'Contenus',  icon: Icons.store_outlined,            activeIcon: Icons.store_rounded,         route: RouteNames.marketplace),
    _NavItem(label: 'Wi-Fi',     icon: Icons.wifi_outlined,             activeIcon: Icons.wifi_rounded,          route: RouteNames.localClassroom),
    _NavItem(label: 'Profil',    icon: Icons.person_outline_rounded,    activeIcon: Icons.person_rounded,        route: RouteNames.gamification),
  ];

  // Parent nav items
  static const List<_NavItem> _parentNavItems = [
    _NavItem(label: 'Accueil',   icon: Icons.home_outlined,             activeIcon: Icons.home_rounded,          route: RouteNames.home),
    _NavItem(label: 'Enfants',   icon: Icons.child_care_outlined,       activeIcon: Icons.child_care_rounded,    route: RouteNames.home), // handled below
    _NavItem(label: 'Contenus',  icon: Icons.store_outlined,            activeIcon: Icons.store_rounded,         route: RouteNames.marketplace),
    _NavItem(label: 'IA Tuteur', icon: Icons.psychology_outlined,       activeIcon: Icons.psychology_rounded,    route: RouteNames.aiTutor),
    _NavItem(label: 'Profil',    icon: Icons.person_outline_rounded,    activeIcon: Icons.person_rounded,        route: RouteNames.gamification),
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
    // Parent "Enfants" tab goes to the parent dashboard (outside shell)
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

    final items = _itemsForRole(userRole);

    return Scaffold(
      body: Column(
        children: [
          if (isOffline) const OfflineBanner(),
          Expanded(child: widget.child),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => _onItemTapped(i, userRole),
        destinations: items.map((item) {
          final showBadge = item.route == RouteNames.home && syncPending > 0;
          return NavigationDestination(
            icon: showBadge
                ? Badge(
                    label: Text('$syncPending'),
                    backgroundColor: AppColors.warning,
                    child: Icon(item.icon),
                  )
                : Icon(item.icon),
            selectedIcon: Icon(item.activeIcon),
            label: item.label,
          );
        }).toList(),
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

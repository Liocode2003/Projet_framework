import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/offline_banner.dart';
import '../providers/shell_provider.dart';

/// App shell — persistent scaffold with bottom navigation bar.
/// Wraps all main routes via GoRouter ShellRoute.
class AppShell extends ConsumerStatefulWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  /// Maps route paths to bottom nav indices
  static const List<_NavItem> _navItems = [
    _NavItem(
      label: 'Accueil',
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      route: RouteNames.home,
    ),
    _NavItem(
      label: 'Contenus',
      icon: Icons.store_outlined,
      activeIcon: Icons.store_rounded,
      route: RouteNames.marketplace,
    ),
    _NavItem(
      label: 'Apprendre',
      icon: Icons.menu_book_outlined,
      activeIcon: Icons.menu_book_rounded,
      route: RouteNames.learning,
    ),
    _NavItem(
      label: 'IA Tuteur',
      icon: Icons.psychology_outlined,
      activeIcon: Icons.psychology_rounded,
      route: RouteNames.aiTutor,
    ),
    _NavItem(
      label: 'Profil',
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      route: RouteNames.gamification,
    ),
  ];

  int _currentIndex = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _currentIndex = _indexFromLocation(GoRouterState.of(context).matchedLocation);
  }

  int _indexFromLocation(String location) {
    for (int i = 0; i < _navItems.length; i++) {
      if (location.startsWith(_navItems[i].route)) return i;
    }
    return 0;
  }

  void _onItemTapped(int index) {
    if (index == _currentIndex) return;
    context.go(_navItems[index].route);
  }

  @override
  Widget build(BuildContext context) {
    final isOffline = ref.watch(offlineStatusProvider);
    final userRole = ref.watch(userRoleProvider);

    return Scaffold(
      body: Column(
        children: [
          // Offline indicator banner
          if (isOffline) const OfflineBanner(),

          // Main content
          Expanded(child: widget.child),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onItemTapped,
        destinations: _buildDestinations(userRole),
      ),
    );
  }

  List<NavigationDestination> _buildDestinations(String? role) {
    final items = role == 'teacher'
        ? _teacherNavItems
        : _navItems;

    return items.map((item) => NavigationDestination(
      icon: Icon(item.icon),
      selectedIcon: Icon(item.activeIcon),
      label: item.label,
    )).toList();
  }

  static const List<_NavItem> _teacherNavItems = [
    _NavItem(
      label: 'Accueil',
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      route: RouteNames.home,
    ),
    _NavItem(
      label: 'Classe',
      icon: Icons.class_outlined,
      activeIcon: Icons.class_rounded,
      route: RouteNames.teacherDashboard,
    ),
    _NavItem(
      label: 'Contenus',
      icon: Icons.store_outlined,
      activeIcon: Icons.store_rounded,
      route: RouteNames.marketplace,
    ),
    _NavItem(
      label: 'Wi-Fi Classe',
      icon: Icons.wifi_outlined,
      activeIcon: Icons.wifi_rounded,
      route: RouteNames.localClassroom,
    ),
    _NavItem(
      label: 'Profil',
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      route: RouteNames.gamification,
    ),
  ];
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

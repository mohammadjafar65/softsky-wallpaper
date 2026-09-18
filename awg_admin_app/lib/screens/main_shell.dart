import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/theme.dart';
import '../services/auth_service.dart';

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  static const _navItems = [
    _NavItem('/dashboard', Icons.dashboard_outlined, Icons.dashboard_rounded, 'Dashboard'),
    _NavItem('/wallpapers', Icons.wallpaper_outlined, Icons.wallpaper_rounded, 'Wallpapers'),
    _NavItem('/community', Icons.people_outline, Icons.people_rounded, 'Community'),
    _NavItem('/categories', Icons.category_outlined, Icons.category_rounded, 'Categories'),
    _NavItem('/packs', Icons.collections_outlined, Icons.collections_rounded, 'Packs'),
    _NavItem('/users', Icons.people_outline, Icons.people_rounded, 'Users'),
    _NavItem('/subscriptions', Icons.card_membership_outlined, Icons.card_membership_rounded, 'Subscriptions'),
    _NavItem('/notifications', Icons.notifications_outlined, Icons.notifications_rounded, 'Notifications'),
    _NavItem('/settings', Icons.settings_outlined, Icons.settings_rounded, 'Settings'),
  ];

  int _selectedIndex(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    final idx = _navItems.indexWhere((item) => loc.startsWith(item.path));
    return idx < 0 ? 0 : idx;
  }

  void _showMoreMenu(BuildContext context, String currentLoc) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final moreItems = _navItems.sublist(4);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.grid_view_rounded, size: 20, color: AppTheme.primary),
                    const SizedBox(width: 8),
                    const Text(
                      'More Modules',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const Divider(height: 16),
                ...moreItems.map((item) {
                  final isCurrent = currentLoc.startsWith(item.path);
                  return ListTile(
                    dense: true,
                    leading: Icon(
                      isCurrent ? item.activeIcon : item.icon,
                      color: isCurrent ? AppTheme.primary : AppTheme.textSecondary,
                    ),
                    title: Text(
                      item.label,
                      style: TextStyle(
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                        color: isCurrent ? AppTheme.primary : AppTheme.textPrimary,
                      ),
                    ),
                    trailing: isCurrent
                        ? Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppTheme.primary,
                              shape: BoxShape.circle,
                            ),
                          )
                        : null,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    tileColor: isCurrent ? const Color(0xFFEEF2FF) : null,
                    onTap: () {
                      Navigator.pop(ctx);
                      context.go(item.path);
                    },
                  );
                }),
                const Divider(height: 16),
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.logout_rounded, color: AppTheme.error),
                  title: const Text(
                    'Sign Out',
                    style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.w600),
                  ),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await AuthService.logout();
                    if (context.mounted) context.go('/login');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _selectedIndex(context);
    final loc = GoRouterState.of(context).matchedLocation;
    final isWide = MediaQuery.of(context).size.width >= 720;
    final isMoreSelected = selectedIndex >= 4;
    final mobileIndex = isMoreSelected ? 4 : selectedIndex;

    return Scaffold(
      backgroundColor: AppTheme.surfaceVariant,
      body: Row(
        children: [
          if (isWide)
            _SideNav(
              items: _navItems,
              selectedIndex: selectedIndex,
              onTap: (i) => context.go(_navItems[i].path),
            ),
          Expanded(child: child),
        ],
      ),
      bottomNavigationBar: isWide
          ? null
          : NavigationBar(
              selectedIndex: mobileIndex,
              onDestinationSelected: (i) {
                if (i < 4) {
                  context.go(_navItems[i].path);
                } else {
                  _showMoreMenu(context, loc);
                }
              },
              backgroundColor: AppTheme.surface,
              elevation: 0,
              surfaceTintColor: Colors.transparent,
              destinations: [
                ..._navItems.take(4).map(
                      (item) => NavigationDestination(
                        icon: Icon(item.icon, size: 22),
                        selectedIcon: Icon(item.activeIcon, size: 22),
                        label: item.label,
                      ),
                    ),
                NavigationDestination(
                  icon: const Icon(Icons.grid_view_outlined, size: 22),
                  selectedIcon: const Icon(Icons.grid_view_rounded, size: 22),
                  label: isMoreSelected ? _navItems[selectedIndex].label : 'More',
                ),
              ],
            ),
    );
  }
}

class _NavItem {
  final String path;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem(this.path, this.icon, this.activeIcon, this.label);
}

class _SideNav extends StatelessWidget {
  final List<_NavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onTap;
  const _SideNav({
    required this.items,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(right: BorderSide(color: AppTheme.border)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'SoftSky Admin',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppTheme.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: items.length,
              itemBuilder: (context, i) {
                final item = items[i];
                final isSelected = selectedIndex == i;
                return Container(
                  margin: const EdgeInsets.only(bottom: 2),
                  child: ListTile(
                    dense: true,
                    leading: Icon(
                      isSelected ? item.activeIcon : item.icon,
                      size: 20,
                      color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                    ),
                    title: Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                      ),
                    ),
                    selected: isSelected,
                    selectedTileColor: const Color(0xFFEEF2FF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    onTap: () => onTap(i),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    minLeadingWidth: 20,
                  ),
                );
              },
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(12),
            child: ListTile(
              dense: true,
              leading: CircleAvatar(
                radius: 14,
                backgroundColor: AppTheme.primary,
                child: Text(
                  _userInitial(AuthService.currentUser?.displayName),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              title: Text(
                AuthService.currentUser?.displayName ?? 'Admin',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                AuthService.currentUser?.email ?? '',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              trailing: IconButton(
                icon: const Icon(
                  Icons.logout_rounded,
                  size: 18,
                  color: AppTheme.textSecondary,
                ),
                onPressed: () async {
                  await AuthService.logout();
                  if (context.mounted) context.go('/login');
                },
                tooltip: 'Sign out',
              ),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }
}

String _userInitial(String? name) {
  final trimmed = name?.trim() ?? '';
  return trimmed.isNotEmpty ? trimmed[0].toUpperCase() : 'A';
}

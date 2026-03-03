import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/organization_provider.dart';
import '../providers/theme_provider.dart';

class WebSidebar extends StatelessWidget {
  final String currentRoute;

  const WebSidebar({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isAdmin = authProvider.isAdmin;

    return Drawer(
      elevation: 0,
      shape: const RoundedRectangleBorder(),
      child: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Column(
          children: [
            const SizedBox(height: 12),
            DrawerHeader(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.volunteer_activism_rounded,
                    size: 40,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Donation App',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    if (isAdmin) ...[
                      _SidebarTile(
                        title: 'Dashboard',
                        icon: Icons.grid_view_rounded,
                        route: '/admin',
                        isActive: currentRoute == '/admin',
                      ),
                      _SidebarTile(
                        title: 'Donors History',
                        icon: Icons.history_rounded,
                        route: '/donor-history',
                        isActive: currentRoute == '/donor-history',
                      ),
                      _SidebarTile(
                        title: 'Accounts',
                        icon: Icons.account_balance_rounded,
                        route: '/institution-accounts',
                        isActive: currentRoute == '/institution-accounts',
                      ),
                      _SidebarTile(
                        title: 'Expenses',
                        icon: Icons.receipt_long_rounded,
                        route: '/admin-expenses',
                        isActive: currentRoute == '/admin-expenses',
                      ),
                      _SidebarTile(
                        title: 'Manage Users',
                        icon: Icons.manage_accounts_rounded,
                        route: '/manage-users',
                        isActive: currentRoute == '/manage-users',
                      ),
                      _SidebarTile(
                        title: 'Settings',
                        icon: Icons.settings_rounded,
                        route: '/org-settings',
                        isActive: currentRoute == '/org-settings',
                      ),
                    ] else ...[
                      _SidebarTile(
                        title: 'Dashboard',
                        icon: Icons.grid_view_rounded,
                        route: '/collector',
                        isActive: currentRoute == '/collector',
                      ),
                      _SidebarTile(
                        title: 'Record Donation',
                        icon: Icons.add_circle_outline_rounded,
                        route: '/add-donation',
                        isActive: currentRoute == '/add-donation',
                      ),
                      _SidebarTile(
                        title: 'My Expenses',
                        icon: Icons.receipt_long_rounded,
                        route: '/add-expense',
                        isActive: currentRoute == '/add-expense',
                      ),
                      _SidebarTile(
                        title: 'My History',
                        icon: Icons.history_rounded,
                        route: '/donor-history',
                        isActive: currentRoute == '/donor-history',
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, _) => Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: ListTile(
                  onTap: () => themeProvider.toggleTheme(),
                  leading: Icon(
                    themeProvider.isDarkMode
                        ? Icons.dark_mode_rounded
                        : Icons.light_mode_rounded,
                    size: 18,
                  ),
                  title: const Text(
                    'Appearance',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  trailing: Transform.scale(
                    scale: 0.7,
                    child: Switch(
                      value: themeProvider.isDarkMode,
                      onChanged: (_) => themeProvider.toggleTheme(),
                    ),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            _SidebarTile(
              title: 'Logout',
              icon: Icons.logout_rounded,
              route: '/logout',
              isActive: false,
              onTap: () async {
                final authProvider = Provider.of<AuthProvider>(
                  context,
                  listen: false,
                );
                final orgProvider = Provider.of<OrganizationProvider>(
                  context,
                  listen: false,
                );
                await authProvider.logout();
                orgProvider.clear();
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/login',
                    (route) => false,
                  );
                }
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _SidebarTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final String route;
  final bool isActive;
  final VoidCallback? onTap;

  const _SidebarTile({
    required this.title,
    required this.icon,
    required this.route,
    required this.isActive,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: ListTile(
        onTap:
            onTap ??
            () {
              if (!isActive) {
                Navigator.pushReplacementNamed(context, route);
              }
            },
        leading: Icon(
          icon,
          color: isActive
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          size: 18,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isActive
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.85),
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        tileColor: isActive
            ? Theme.of(context).colorScheme.primary.withOpacity(0.05)
            : null,
        contentPadding: const EdgeInsets.only(left: 16),
        visualDensity: VisualDensity.compact,
        // Left Indicator
        minLeadingWidth: 20,
        trailing: isActive
            ? Container(
                width: 3,
                height: 20,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              )
            : null,
      ),
    );
  }
}

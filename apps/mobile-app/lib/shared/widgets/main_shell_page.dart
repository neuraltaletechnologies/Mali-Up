import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_colors.dart';
import '../../config/routing.dart';
import 'logo.dart';


class MainShellPage extends StatelessWidget {
  final Widget child;
  const MainShellPage({super.key, required this.child});

  static Future<void> _closeDrawerThenNavigate(BuildContext context, String route) async {
    Navigator.of(context).pop();
    await Future<void>.delayed(const Duration(milliseconds: 220));
    if (!context.mounted) return;
    context.go(route);
  }

  static int _calculateIndex(String location) {
    if (location.startsWith(AppRouter.salesPath)) return 1;
    if (location.startsWith(AppRouter.inventoryPath)) return 2;
    if (location.startsWith(AppRouter.crmPath)) return 3;
    return 0; // Dashboard
  }

  static String _pageTitle(String location) {
    if (location.startsWith(AppRouter.salesPath)) return 'Sales & Invoices';
    if (location.startsWith(AppRouter.inventoryPath)) return 'Inventory';
    if (location.startsWith(AppRouter.crmPath)) return 'Customers';
    if (location.startsWith(AppRouter.debtPath)) return 'Debt & Payables';
    if (location.startsWith(AppRouter.expensesPath)) return 'Expenses';
    if (location.startsWith(AppRouter.cashFlowPath)) return 'Cash Flow';
    if (location.startsWith(AppRouter.settingsPath)) return 'Settings';
    return 'Dashboard';
  }

  static bool _isSelected(String location, String route) {
    return location == route || location.startsWith('$route/');
  }

  static _DrawerProfileData _buildProfileData(User? user, Map<String, dynamic>? profile) {
    final accountTypesRaw = profile?['accountTypes'];
    final accountTypes = accountTypesRaw is List
        ? accountTypesRaw.whereType<String>().toList()
        : const <String>[];

    final accountType = (profile?['defaultAccountType'] as String?) ??
        (accountTypes.isNotEmpty ? accountTypes.first : 'personal');

    final accountTypeLabel = accountType.toLowerCase() == 'business'
        ? 'Akaunti ya Biashara'
        : 'Akaunti Binafsi';

    final fullName = ((profile?['displayName'] as String?)?.trim().isNotEmpty ?? false)
        ? (profile?['displayName'] as String).trim()
        : ((profile?['name'] as String?)?.trim().isNotEmpty ?? false)
            ? (profile?['name'] as String).trim()
            : ((user?.displayName?.trim().isNotEmpty ?? false)
                ? user!.displayName!.trim()
                : 'Mtumiaji wa Mali App');

    final authPhone = user?.phoneNumber?.trim();
    final profilePhone = (profile?['phone'] as String?)?.trim();
    final profileEmail = (profile?['email'] as String?)?.trim();
    final authEmail = user?.email?.trim();

    final contactLine = (authPhone != null && authPhone.isNotEmpty)
      ? authPhone
      : (profilePhone != null && profilePhone.isNotEmpty)
        ? profilePhone
        : (profileEmail != null && profileEmail.isNotEmpty)
          ? profileEmail
          : ((authEmail != null && authEmail.isNotEmpty)
            ? authEmail
            : 'Hakuna maelezo ya mawasiliano');

    final avatarUrl = ((profile?['avatarUrl'] as String?)?.trim().isNotEmpty ?? false)
        ? (profile?['avatarUrl'] as String).trim()
        : ((profile?['photoURL'] as String?)?.trim().isNotEmpty ?? false)
            ? (profile?['photoURL'] as String).trim()
            : user?.photoURL;

    return _DrawerProfileData(
      fullName: fullName,
      contactLine: contactLine,
      accountTypeLabel: accountTypeLabel,
      avatarUrl: avatarUrl,
    );
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = _calculateIndex(location);
    final title = _pageTitle(location);
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      drawerScrimColor: Colors.black.withValues(alpha: 0.45),
      appBar: AppBar(
        title: Row(
          children: [
            const MaliUpLogo(size: 28),
            const SizedBox(width: 12),
            Text(title),
          ],
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.go(AppRouter.settingsPath),
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: Drawer(
        width: MediaQuery.of(context).size.width * 0.80,
        backgroundColor: AppColors.secondary,
        elevation: 18,
        clipBehavior: Clip.antiAlias,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.secondary,
          ),
          child: Column(
            children: [
              SafeArea(
                bottom: false,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 26),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.secondaryLight.withValues(alpha: 0.95),
                        AppColors.secondary,
                      ],
                    ),
                  ),
                  child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    stream: currentUser == null
                        ? null
                        : FirebaseFirestore.instance
                            .collection('users')
                            .doc(currentUser.uid)
                            .snapshots(),
                    builder: (context, snapshot) {
                      final profileData = snapshot.data?.data();
                      final profile = _buildProfileData(currentUser, profileData);
                      final initials = profile.fullName.isNotEmpty ? profile.fullName.trim()[0].toUpperCase() : 'M';

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Semantics(
                            label: 'Picha ya wasifu wa mtumiaji',
                            child: CircleAvatar(
                              radius: 26,
                              backgroundColor: AppColors.primary,
                              backgroundImage: (profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty)
                                  ? NetworkImage(profile.avatarUrl!)
                                  : null,
                              child: (profile.avatarUrl == null || profile.avatarUrl!.isEmpty)
                                  ? Text(
                                      initials,
                                      style: const TextStyle(
                                        color: AppColors.secondary,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            profile.fullName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            profile.contactLine,
                            style: TextStyle(
                              color: AppColors.background.withValues(alpha: 0.75),
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              profile.accountTypeLabel,
                              style: const TextStyle(
                                color: AppColors.secondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              Container(
                height: 18,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.vertical(top: Radius.elliptical(260, 30)),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                  children: [
                    _DrawerItem(
                      icon: Icons.grid_view_rounded,
                      label: 'Dashboard',
                      semanticsLabel: 'Dashboard, sehemu kuu ya biashara',
                      selected: _isSelected(location, AppRouter.dashboardPath),
                      onTap: () => _closeDrawerThenNavigate(context, AppRouter.dashboardPath),
                    ),
                    const SizedBox(height: 8),
                    _DrawerItem(
                      icon: Icons.receipt_long_rounded,
                      label: 'Mauzo na Ankara',
                      semanticsLabel: 'Mauzo na Ankara, sales and invoices',
                      selected: _isSelected(location, AppRouter.salesPath),
                      onTap: () => _closeDrawerThenNavigate(context, AppRouter.salesPath),
                      trailingBadge: '3',
                    ),
                    const SizedBox(height: 8),
                    _DrawerItem(
                      icon: Icons.inventory_2_rounded,
                      label: 'Bidhaa / Inventory',
                      semanticsLabel: 'Bidhaa, inventory management',
                      selected: _isSelected(location, AppRouter.inventoryPath),
                      onTap: () => _closeDrawerThenNavigate(context, AppRouter.inventoryPath),
                    ),
                    const SizedBox(height: 8),
                    _DrawerItem(
                      icon: Icons.people_alt_rounded,
                      label: 'Wateja / Customers',
                      semanticsLabel: 'Wateja, customer relationship management',
                      selected: _isSelected(location, AppRouter.crmPath),
                      onTap: () => _closeDrawerThenNavigate(context, AppRouter.crmPath),
                    ),
                    const SizedBox(height: 10),
                    Divider(color: AppColors.background.withValues(alpha: 0.14), height: 1),
                    const SizedBox(height: 10),
                    _DrawerItem(
                      icon: Icons.account_balance_rounded,
                      label: 'Madeni / Debt Tracking',
                      semanticsLabel: 'Madeni, debt tracking',
                      selected: _isSelected(location, AppRouter.debtPath),
                      onTap: () => _closeDrawerThenNavigate(context, AppRouter.debtPath),
                    ),
                    const SizedBox(height: 8),
                    _DrawerItem(
                      icon: Icons.payments_outlined,
                      label: 'Matumizi / Expenses',
                      semanticsLabel: 'Matumizi, expense management',
                      selected: _isSelected(location, AppRouter.expensesPath),
                      onTap: () => _closeDrawerThenNavigate(context, AppRouter.expensesPath),
                    ),
                    const SizedBox(height: 8),
                    _DrawerItem(
                      icon: Icons.account_balance_wallet_outlined,
                      label: 'Mtiririko wa Fedha',
                      semanticsLabel: 'Mtiririko wa fedha, cash flow and accounts',
                      selected: _isSelected(location, AppRouter.cashFlowPath),
                      onTap: () => _closeDrawerThenNavigate(context, AppRouter.cashFlowPath),
                    ),
                    const SizedBox(height: 10),
                    Divider(color: AppColors.background.withValues(alpha: 0.14), height: 1),
                    const SizedBox(height: 10),
                    _DrawerItem(
                      icon: Icons.settings_rounded,
                      label: 'Mipangilio / Settings',
                      semanticsLabel: 'Mipangilio, app settings',
                      selected: _isSelected(location, AppRouter.settingsPath),
                      onTap: () => _closeDrawerThenNavigate(context, AppRouter.settingsPath),
                    ),
                    const SizedBox(height: 8),
                    _DrawerItem(
                      icon: Icons.headset_mic_rounded,
                      label: 'Msaada / Help & Support',
                      semanticsLabel: 'Msaada na support',
                      selected: false,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.background.withValues(alpha: 0.16))),
                ),
                child: Column(
                  children: [
                    Semantics(
                      button: true,
                      label: 'Toka, logout from Mali App',
                      child: SizedBox(
                        height: 56,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => _closeDrawerThenNavigate(context, AppRouter.loginPath),
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              children: [
                                Icon(Icons.logout_rounded, color: AppColors.primary, size: 20),
                                SizedBox(width: 12),
                                Text(
                                  'Toka',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Mali App v1.0.0',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          border: Border(
            top: BorderSide(color: AppColors.secondary.withValues(alpha: 0.08), width: 1.5),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (index) {
            switch (index) {
              case 0: context.go(AppRouter.dashboardPath); break;
              case 1: context.go(AppRouter.salesPath); break;
              case 2: context.go(AppRouter.inventoryPath); break;
              case 3: context.go(AppRouter.crmPath); break;
            }
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_outlined),
              activeIcon: Icon(Icons.grid_view_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_outlined),
              activeIcon: Icon(Icons.receipt_rounded),
              label: 'Sales',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_outlined),
              activeIcon: Icon(Icons.inventory_2_rounded),
              label: 'Stock',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline_rounded),
              activeIcon: Icon(Icons.people_rounded),
              label: 'Customers',
            ),
          ],
        ),
      ),
    );
  }
}


class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String semanticsLabel;
  final String? trailingBadge;
  final bool selected;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.semanticsLabel,
    this.trailingBadge,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final active = AppColors.primary;
    final labelColor = AppColors.background.withValues(alpha: 0.95);
    final chevronColor = AppColors.background.withValues(alpha: 0.62);

    return Semantics(
      button: true,
      label: semanticsLabel,
      child: SizedBox(
        height: 52,
        child: Material(
          color: selected ? active.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: AppColors.background.withValues(alpha: selected ? 0.18 : 0.10),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(icon, size: 16, color: selected ? active : Colors.white),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: selected ? active : labelColor,
                        fontSize: 14,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                  if (trailingBadge != null)
                    Container(
                      width: 18,
                      height: 18,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        trailingBadge!,
                        style: const TextStyle(
                          color: AppColors.secondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  else
                    Icon(Icons.chevron_right_rounded, color: chevronColor, size: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DrawerProfileData {
  final String fullName;
  final String contactLine;
  final String accountTypeLabel;
  final String? avatarUrl;

  const _DrawerProfileData({
    required this.fullName,
    required this.contactLine,
    required this.accountTypeLabel,
    required this.avatarUrl,
  });
}


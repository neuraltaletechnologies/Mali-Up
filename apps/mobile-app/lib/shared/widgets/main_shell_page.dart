import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/services/default_context_routing_service.dart';
import '../../core/services/localization_service.dart';
import '../../core/theme/app_colors.dart';
import '../../config/routing.dart';
import 'logo.dart';


class MainShellPage extends StatefulWidget {
  final Widget child;
  const MainShellPage({super.key, required this.child});

  @override
  State<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends State<MainShellPage> {
  User? _currentUser;
  late Future<Map<String, dynamic>?> _profileFuture;
  late final VoidCallback _languageListener;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    _profileFuture = _fetchUserProfile(_currentUser);
    _languageListener = () {
      if (mounted) {
        setState(() {});
      }
    };
    LocalizationService.languageNotifier.addListener(_languageListener);
  }

  @override
  void dispose() {
    LocalizationService.languageNotifier.removeListener(_languageListener);
    super.dispose();
  }

  bool get _isSwahili => LocalizationService.isSwahili;

  String _tr(String en, String sw) {
    return _isSwahili ? sw : en;
  }

  void _refreshProfile() {
    setState(() {
      _currentUser = FirebaseAuth.instance.currentUser;
      _profileFuture = _fetchUserProfile(_currentUser);
    });
  }

  String _defaultContextFromProfile(Map<String, dynamic>? profile) {
    final defaultContext = profile?['defaultContext'];
    if (defaultContext is String && defaultContext.isNotEmpty) {
      return defaultContext;
    }

    final defaultAccountType = (profile?['defaultAccountType'] as String?)?.toLowerCase();
    if (defaultAccountType == 'business') {
      final uid = _currentUser?.uid;
      return uid == null ? 'business' : 'business:$uid';
    }

    return 'personal';
  }

  bool _canSwitchFinanceContext(Map<String, dynamic>? profile) {
    final accountTypesRaw = profile?['accountTypes'];
    if (accountTypesRaw is! List) return false;

    final normalized = accountTypesRaw
        .whereType<String>()
        .map((e) => e.toLowerCase())
        .toSet();

    return normalized.contains('personal') && normalized.contains('business');
  }

  Future<void> _switchFinanceContext(String nextContext) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final nextType = nextContext.toLowerCase().startsWith('business')
        ? 'business'
        : 'personal';

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'defaultContext': nextContext,
      'defaultAccountType': nextType,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    _refreshProfile();

    if (!mounted) return;
    final route = DefaultContextRoutingService.routeFromContextValue(nextContext);
    context.go(route);
  }

  static Future<Map<String, dynamic>?> _fetchUserProfile(User? user) async {
    if (user == null) return null;
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get(const GetOptions(source: Source.serverAndCache));
    return snapshot.data();
  }

  static Future<void> _closeDrawerThenNavigate(BuildContext context, String route) async {
    Navigator.of(context).pop();
    await Future<void>.delayed(const Duration(milliseconds: 220));
    if (!context.mounted) return;
    context.go(route);
  }

  static int _calculateIndex(String location, List<_NavDestination> destinations) {
    final index = destinations.indexWhere((destination) => _isSelected(location, destination.route));
    return index >= 0 ? index : 0;
  }

  static List<_NavDestination> _businessNavDestinations() {
    return const [
      _NavDestination(
        route: AppRouter.dashboardPath,
        label: 'Home',
        icon: Icons.grid_view_outlined,
        activeIcon: Icons.grid_view_rounded,
      ),
      _NavDestination(
        route: AppRouter.salesPath,
        label: 'Sales',
        icon: Icons.receipt_outlined,
        activeIcon: Icons.receipt_rounded,
      ),
      _NavDestination(
        route: AppRouter.inventoryPath,
        label: 'Stock',
        icon: Icons.inventory_2_outlined,
        activeIcon: Icons.inventory_2_rounded,
      ),
      _NavDestination(
        route: AppRouter.crmPath,
        label: 'Customers',
        icon: Icons.people_outline_rounded,
        activeIcon: Icons.people_rounded,
      ),
    ];
  }

  static List<_NavDestination> _personalNavDestinations() {
    return const [
      _NavDestination(
        route: AppRouter.dashboardPath,
        label: 'Home',
        icon: Icons.grid_view_outlined,
        activeIcon: Icons.grid_view_rounded,
      ),
      _NavDestination(
        route: AppRouter.expensesPath,
        label: 'Expenses',
        icon: Icons.payments_outlined,
        activeIcon: Icons.payments_rounded,
      ),
      _NavDestination(
        route: AppRouter.debtPath,
        label: 'Debt',
        icon: Icons.account_balance_outlined,
        activeIcon: Icons.account_balance_rounded,
      ),
      _NavDestination(
        route: AppRouter.cashFlowPath,
        label: 'Cash Flow',
        icon: Icons.account_balance_wallet_outlined,
        activeIcon: Icons.account_balance_wallet_rounded,
      ),
    ];
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

  _DrawerProfileData _buildProfileData(User? user, Map<String, dynamic>? profile) {
    final accountTypesRaw = profile?['accountTypes'];
    final accountTypes = accountTypesRaw is List
        ? accountTypesRaw.whereType<String>().toList()
        : const <String>[];

    final contextValue = (profile?['defaultContext'] as String?)?.toLowerCase();
    final accountType = (contextValue != null && contextValue.isNotEmpty)
        ? (contextValue.startsWith('business') ? 'business' : 'personal')
        : (profile?['defaultAccountType'] as String?) ??
            (accountTypes.isNotEmpty ? accountTypes.first : 'personal');

    final accountTypeLabel = accountType.toLowerCase() == 'business'
      ? _tr('Business Account', 'Akaunti ya Biashara')
      : _tr('Personal Account', 'Akaunti Binafsi');

    final fullName = ((profile?['displayName'] as String?)?.trim().isNotEmpty ?? false)
        ? (profile?['displayName'] as String).trim()
        : ((profile?['name'] as String?)?.trim().isNotEmpty ?? false)
            ? (profile?['name'] as String).trim()
            : ((user?.displayName?.trim().isNotEmpty ?? false)
                ? user!.displayName!.trim()
                : _tr('Mali App User', 'Mtumiaji wa Mali App'));

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
            : _tr('No contact details available', 'Hakuna maelezo ya mawasiliano'));

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
    final title = _pageTitle(location);
    final currentUser = _currentUser;

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
          FutureBuilder<Map<String, dynamic>?>(
            future: _profileFuture,
            builder: (context, snapshot) {
              final profile = snapshot.data;
              final selectedContext = _defaultContextFromProfile(profile);
              final canSwitch = _canSwitchFinanceContext(profile);
              return _FinanceContextSwitcher(
                selectedContext: selectedContext,
                canSwitch: canSwitch,
                onChanged: _switchFinanceContext,
              );
            },
          ),
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
          child: FutureBuilder<Map<String, dynamic>?>(
            future: _profileFuture,
            builder: (context, snapshot) {
              final profileData = snapshot.data;
              final profile = _buildProfileData(currentUser, profileData);
              final initials = profile.fullName.isNotEmpty
                  ? profile.fullName.trim()[0].toUpperCase()
                  : 'M';
              final isBusinessContext =
                  _defaultContextFromProfile(profileData).toLowerCase().startsWith('business');

              return Column(
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Semantics(
                            label: _tr('User profile picture', 'Picha ya wasifu wa mtumiaji'),
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
                      ),
                    ),
                  ),
                  Container(
                    height: 18,
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.92),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.elliptical(260, 30),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                      children: [
                        _DrawerItem(
                          icon: Icons.grid_view_rounded,
                          label: 'Dashboard',
                          semanticsLabel: _tr(
                            'Dashboard, main app section',
                            'Dashboard, sehemu kuu ya biashara',
                          ),
                          selected: _isSelected(location, AppRouter.dashboardPath),
                          onTap: () => _closeDrawerThenNavigate(context, AppRouter.dashboardPath),
                        ),
                        const SizedBox(height: 8),
                        if (isBusinessContext) ...[
                          _DrawerItem(
                            icon: Icons.receipt_long_rounded,
                            label: _tr('Sales & Invoices', 'Mauzo na Ankara'),
                            semanticsLabel: _tr(
                              'Sales and invoices',
                              'Mauzo na Ankara, sales and invoices',
                            ),
                            selected: _isSelected(location, AppRouter.salesPath),
                            onTap: () => _closeDrawerThenNavigate(context, AppRouter.salesPath),
                            trailingBadge: '3',
                          ),
                          const SizedBox(height: 8),
                          _DrawerItem(
                            icon: Icons.inventory_2_rounded,
                            label: _tr('Inventory', 'Bidhaa / Inventory'),
                            semanticsLabel: _tr(
                              'Inventory management',
                              'Bidhaa, inventory management',
                            ),
                            selected: _isSelected(location, AppRouter.inventoryPath),
                            onTap: () => _closeDrawerThenNavigate(context, AppRouter.inventoryPath),
                          ),
                          const SizedBox(height: 8),
                          _DrawerItem(
                            icon: Icons.people_alt_rounded,
                            label: _tr('Customers', 'Wateja / Customers'),
                            semanticsLabel: _tr(
                              'Customer relationship management',
                              'Wateja, customer relationship management',
                            ),
                            selected: _isSelected(location, AppRouter.crmPath),
                            onTap: () => _closeDrawerThenNavigate(context, AppRouter.crmPath),
                          ),
                          const SizedBox(height: 10),
                          Divider(color: AppColors.background.withValues(alpha: 0.14), height: 1),
                          const SizedBox(height: 10),
                          _DrawerItem(
                            icon: Icons.account_balance_rounded,
                            label: _tr('Debt Tracking', 'Madeni / Debt Tracking'),
                            semanticsLabel: _tr('Debt tracking', 'Madeni, debt tracking'),
                            selected: _isSelected(location, AppRouter.debtPath),
                            onTap: () => _closeDrawerThenNavigate(context, AppRouter.debtPath),
                          ),
                          const SizedBox(height: 8),
                          _DrawerItem(
                            icon: Icons.payments_outlined,
                            label: _tr('Expenses', 'Matumizi / Expenses'),
                            semanticsLabel: _tr('Expense management', 'Matumizi, expense management'),
                            selected: _isSelected(location, AppRouter.expensesPath),
                            onTap: () => _closeDrawerThenNavigate(context, AppRouter.expensesPath),
                          ),
                          const SizedBox(height: 8),
                          _DrawerItem(
                            icon: Icons.account_balance_wallet_outlined,
                            label: _tr('Cash Flow', 'Mtiririko wa Fedha'),
                            semanticsLabel: _tr(
                              'Cash flow and accounts',
                              'Mtiririko wa fedha, cash flow and accounts',
                            ),
                            selected: _isSelected(location, AppRouter.cashFlowPath),
                            onTap: () => _closeDrawerThenNavigate(context, AppRouter.cashFlowPath),
                          ),
                        ] else ...[
                          _DrawerItem(
                            icon: Icons.payments_outlined,
                            label: _tr('Expenses', 'Matumizi / Expenses'),
                            semanticsLabel: _tr('Expense management', 'Matumizi, expense management'),
                            selected: _isSelected(location, AppRouter.expensesPath),
                            onTap: () => _closeDrawerThenNavigate(context, AppRouter.expensesPath),
                          ),
                          const SizedBox(height: 8),
                          _DrawerItem(
                            icon: Icons.account_balance_rounded,
                            label: _tr('Debt Tracking', 'Madeni / Debt Tracking'),
                            semanticsLabel: _tr('Debt tracking', 'Madeni, debt tracking'),
                            selected: _isSelected(location, AppRouter.debtPath),
                            onTap: () => _closeDrawerThenNavigate(context, AppRouter.debtPath),
                          ),
                          const SizedBox(height: 8),
                          _DrawerItem(
                            icon: Icons.account_balance_wallet_outlined,
                            label: _tr('Cash Flow', 'Mtiririko wa Fedha'),
                            semanticsLabel: _tr(
                              'Cash flow and accounts',
                              'Mtiririko wa fedha, cash flow and accounts',
                            ),
                            selected: _isSelected(location, AppRouter.cashFlowPath),
                            onTap: () => _closeDrawerThenNavigate(context, AppRouter.cashFlowPath),
                          ),
                        ],
                        const SizedBox(height: 10),
                        Divider(color: AppColors.background.withValues(alpha: 0.14), height: 1),
                        const SizedBox(height: 10),
                        _DrawerItem(
                          icon: Icons.settings_rounded,
                          label: _tr('Settings', 'Mipangilio / Settings'),
                          semanticsLabel: _tr('App settings', 'Mipangilio, app settings'),
                          selected: _isSelected(location, AppRouter.settingsPath),
                          onTap: () => _closeDrawerThenNavigate(context, AppRouter.settingsPath),
                        ),
                        const SizedBox(height: 8),
                        _DrawerItem(
                          icon: Icons.headset_mic_rounded,
                          label: _tr('Help & Support', 'Msaada / Help & Support'),
                          semanticsLabel: _tr('Help and support', 'Msaada na support'),
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
                      border: Border(
                        top: BorderSide(color: AppColors.background.withValues(alpha: 0.16)),
                      ),
                    ),
                    child: Column(
                      children: [
                        Semantics(
                          button: true,
                          label: _tr('Sign out from Mali App', 'Toka, logout from Mali App'),
                          child: SizedBox(
                            height: 56,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () => _closeDrawerThenNavigate(context, AppRouter.loginPath),
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                child: Row(
                                  children: [
                                    const Icon(Icons.logout_rounded, color: AppColors.primary, size: 20),
                                    const SizedBox(width: 12),
                                    Text(
                                      _tr('Sign Out', 'Toka'),
                                      style: const TextStyle(
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
              );
            },
          ),
        ),
      ),
      body: widget.child,
      bottomNavigationBar: FutureBuilder<Map<String, dynamic>?>(
        future: _profileFuture,
        builder: (context, snapshot) {
          final profile = snapshot.data;
          final contextValue = _defaultContextFromProfile(profile).toLowerCase();
          final isBusinessContext = contextValue.startsWith('business');
          final destinations = isBusinessContext
              ? _businessNavDestinations()
              : _personalNavDestinations();
          final currentIndex = _calculateIndex(location, destinations);

          return Container(
            decoration: BoxDecoration(
              color: AppColors.background,
              border: Border(
                top: BorderSide(color: AppColors.secondary.withValues(alpha: 0.08), width: 1.5),
              ),
            ),
            child: BottomNavigationBar(
              currentIndex: currentIndex,
              onTap: (index) {
                context.go(destinations[index].route);
              },
              items: destinations
                  .map(
                    (destination) => BottomNavigationBarItem(
                      icon: Icon(destination.icon),
                      activeIcon: Icon(destination.activeIcon),
                      label: destination.label,
                    ),
                  )
                  .toList(),
            ),
          );
        },
      ),
    );
  }
}


class _NavDestination {
  final String route;
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const _NavDestination({
    required this.route,
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
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

class _FinanceContextSwitcher extends StatelessWidget {
  final String selectedContext;
  final bool canSwitch;
  final ValueChanged<String> onChanged;

  const _FinanceContextSwitcher({
    required this.selectedContext,
    required this.canSwitch,
    required this.onChanged,
  });

  bool get _isBusiness => selectedContext.toLowerCase().startsWith('business');

  @override
  Widget build(BuildContext context) {
    final isSwahili = LocalizationService.isSwahili;
    String tr(String en, String sw) => isSwahili ? sw : en;
    final label = _isBusiness ? 'Business' : 'Personal';
    final icon = _isBusiness ? Icons.business_center_rounded : Icons.person_rounded;

    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: PopupMenuButton<String>(
        enabled: canSwitch,
        tooltip: canSwitch
          ? tr('Switch finance context', 'Badili muktadha wa fedha')
          : tr('Single account context', 'Muktadha mmoja wa akaunti'),
        onSelected: onChanged,
        itemBuilder: (context) {
          final uid = FirebaseAuth.instance.currentUser?.uid;
          final businessContext = uid == null ? 'business' : 'business:$uid';
          return [
            const PopupMenuItem<String>(
              value: 'personal',
              child: Row(
                children: [
                  Icon(Icons.person_rounded, size: 18),
                  SizedBox(width: 8),
                  Text('Personal Context'),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: businessContext,
              child: const Row(
                children: [
                  Icon(Icons.business_center_rounded, size: 18),
                  SizedBox(width: 8),
                  Text('Business Context'),
                ],
              ),
            ),
          ];
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: canSwitch
                ? AppColors.primary.withValues(alpha: 0.14)
                : AppColors.surface.withValues(alpha: 0.28),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: canSwitch
                  ? AppColors.primary.withValues(alpha: 0.30)
                  : AppColors.border.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: AppColors.secondary),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.secondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.unfold_more_rounded,
                size: 14,
                color: canSwitch
                    ? AppColors.secondary
                    : AppColors.textSecondary,
              ),
            ],
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


import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/services/default_context_routing_service.dart';
import '../../core/services/localization_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../config/routing.dart';
import 'mali_components.dart';


class MainShellPage extends StatefulWidget {
  final Widget child;
  const MainShellPage({super.key, required this.child});

  @override
  State<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends State<MainShellPage> with SingleTickerProviderStateMixin {
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

  List<Map<String, dynamic>> _businessesFromProfile(Map<String, dynamic>? profile) {
    final businessesRaw = profile?['businesses'];
    if (businessesRaw is! List) return const [];

    return businessesRaw
        .whereType<Map>()
        .map(
          (entry) => <String, dynamic>{
            'id': (entry['id'] as String?)?.trim() ?? '',
            'name': (entry['name'] as String?)?.trim() ?? '',
            'category': (entry['category'] as String?)?.trim() ?? '',
            'placeOfBusiness': (entry['placeOfBusiness'] as String?)?.trim() ?? '',
          },
        )
        .where((entry) => (entry['id'] as String).isNotEmpty)
        .toList();
  }

  String? _selectedBusinessId(Map<String, dynamic>? profile) {
    final value = profile?['selectedBusinessId'] as String?;
    return value == null || value.trim().isEmpty ? null : value.trim();
  }

  String _defaultContextFromProfile(Map<String, dynamic>? profile) {
    final defaultContext = profile?['defaultContext'];
    if (defaultContext is String && defaultContext.isNotEmpty) {
      return defaultContext;
    }

    final businesses = _businessesFromProfile(profile);
    final selectedBusinessId = _selectedBusinessId(profile);
    
    // Default to business context
    final businessId = selectedBusinessId ?? (businesses.isNotEmpty ? businesses.first['id'] as String : null);
    if (businessId != null && businessId.isNotEmpty) {
      return 'business:$businessId';
    }
    return 'business';
  }

  bool _canSwitchFinanceContext(Map<String, dynamic>? profile) {
    final businesses = _businessesFromProfile(profile);
    if (businesses.isNotEmpty) {
      return true;
    }

    final accountTypesRaw = profile?['accountTypes'];
    if (accountTypesRaw is List) {
      final normalized = accountTypesRaw
          .whereType<String>()
          .map((e) => e.toLowerCase())
          .toSet();
      if (normalized.contains('personal') && normalized.contains('business')) {
        return true;
      }
    }

    final usagePreference = (profile?['usagePreference'] as String?)?.toLowerCase();
    if (usagePreference == 'both' || usagePreference == 'personal_and_business') {
      return true;
    }

    return false;
  }

  Future<void> _switchFinanceContext(String nextContext) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final profile = await _profileFuture;
    final businesses = _businessesFromProfile(profile);
    final normalized = nextContext.toLowerCase();
    final resolvedNextContext = normalized.startsWith('business')
        ? () {
            final requestedBusinessId = normalized.contains(':')
                ? normalized.split(':').sublist(1).join(':').trim()
                : null;
            if (requestedBusinessId != null && requestedBusinessId.isNotEmpty) {
              return 'business:$requestedBusinessId';
            }
            final fallbackBusinessId = _selectedBusinessId(profile) ?? (businesses.isNotEmpty ? businesses.first['id'] as String : null);
            return fallbackBusinessId == null ? 'business' : 'business:$fallbackBusinessId';
          }()
        : 'personal';

    final nextType = normalized.startsWith('business')
        ? 'business'
        : 'personal';

    final currentContext = _defaultContextFromProfile(profile);
    if (currentContext == resolvedNextContext) {
      if (!mounted) return;
      final route = DefaultContextRoutingService.routeFromContextValue(resolvedNextContext);
      context.go(route);
      return;
    }

    final selectedBusinessId = resolvedNextContext.startsWith('business:')
        ? resolvedNextContext.split(':').sublist(1).join(':')
        : null;

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'defaultContext': resolvedNextContext,
      'defaultAccountType': nextType,
      'selectedBusinessId': selectedBusinessId,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    _refreshProfile();

    if (!mounted) return;
    final route = DefaultContextRoutingService.routeFromContextValue(resolvedNextContext);
    context.go(route);
  }

  static Future<Map<String, dynamic>?> _fetchUserProfile(User? user) async {
    if (user == null) return null;
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get(const GetOptions());
    return snapshot.data();
  }

  static Future<void> _closeNavigationPanelThenNavigate(
    BuildContext sheetContext,
    BuildContext rootContext,
    String route,
  ) async {
    Navigator.of(sheetContext).pop();
    await Future<void>.delayed(const Duration(milliseconds: 150));
    if (!rootContext.mounted) return;
    rootContext.go(route);
  }

  Future<void> _openNavigationPanel({
    required BuildContext context,
    required String location,
    required _DrawerProfileData profile,
    required bool isBusinessContext,
  }) async {
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: _tr('Close navigation menu', 'Funga menyu ya urambazaji'),
      barrierColor: AppColors.overlay,
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        final fade = Tween<double>(begin: 0, end: 1).animate(curved);
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10 * fade.value, sigmaY: 10 * fade.value),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(-1, 0),
              end: Offset.zero,
            ).animate(curved),
            child: FadeTransition(
              opacity: fade,
              child: child,
            ),
          ),
        );
      },
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        final isDashboard = _isSelected(location, AppRouter.dashboardPath);
        return Align(
          alignment: Alignment.centerLeft,
          child: SafeArea(
            child: Container(
              width: MediaQuery.of(dialogContext).size.width * 0.82,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
                boxShadow: AppTheme.modalShadow,
              ),
              child: Column(
                children: [
                  // Profile Header — navy gradient
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.navyPrimary, AppColors.navySecondary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.only(topRight: Radius.circular(24)),
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 16, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: AppColors.yellowBrand,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
                                  ),
                                  child: Center(
                                    child: Text(
                                      profile.fullName.isNotEmpty ? profile.fullName.trim()[0].toUpperCase() : 'M',
                                      style: const TextStyle(
                                        color: AppColors.navyPrimary,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        profile.fullName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        profile.contactLine,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.6),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => Navigator.of(dialogContext).pop(),
                                  icon: Icon(Icons.close_rounded, color: Colors.white.withValues(alpha: 0.7), size: 22),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.yellowBrand.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(color: AppColors.yellowBrand.withValues(alpha: 0.5)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.stars_rounded, size: 12, color: AppColors.yellowBrand),
                                      const SizedBox(width: 4),
                                      Text(
                                        _tr('Free', 'Bure'),
                                        style: const TextStyle(
                                          color: AppColors.yellowBrand,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isBusinessContext ? Icons.business_center_rounded : Icons.person_rounded,
                                        size: 12,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        isBusinessContext ? _tr('Business', 'Biashara') : _tr('Personal', 'Binafsi'),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Navigation Items
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                      children: [
                        _DrawerItemLight(
                          icon: Icons.grid_view_rounded,
                          label: _tr('Hali ya biashara', 'Hali ya biashara'),
                          semanticsLabel: _tr('Dashboard, business overview', 'Hali ya biashara, muhtasari wa biashara'),
                          selected: isDashboard,
                          onTap: () => _closeNavigationPanelThenNavigate(dialogContext, context, AppRouter.dashboardPath),
                        ),
                        if (isBusinessContext) ...[
                          _DrawerSectionLabel(label: _tr('BUSINESS', 'BIASHARA')),
                          _DrawerItemLight(
                            icon: Icons.receipt_long_rounded,
                            label: _tr('Tuma ankara', 'Tuma ankara'),
                            semanticsLabel: _tr('Sales and invoices', 'Tuma ankara, mauzo na ankara'),
                            selected: _isSelected(location, AppRouter.salesPath),
                            onTap: () => _closeNavigationPanelThenNavigate(dialogContext, context, AppRouter.salesPath),
                          ),
                          const SizedBox(height: 2),
                          _DrawerItemLight(
                            icon: Icons.inventory_2_rounded,
                            label: _tr('Hisa zangu', 'Hisa zangu'),
                            semanticsLabel: _tr('My stock and inventory', 'Hisa zangu, usimamizi wa bidhaa'),
                            selected: _isSelected(location, AppRouter.inventoryPath),
                            onTap: () => _closeNavigationPanelThenNavigate(dialogContext, context, AppRouter.inventoryPath),
                          ),
                          const SizedBox(height: 2),
                          _DrawerItemLight(
                            icon: Icons.people_alt_rounded,
                            label: _tr('Wateja wangu', 'Wateja wangu'),
                            semanticsLabel: _tr('My customers', 'Wateja wangu, usimamizi wa wateja'),
                            selected: _isSelected(location, AppRouter.crmPath),
                            onTap: () => _closeNavigationPanelThenNavigate(dialogContext, context, AppRouter.crmPath),
                          ),
                          _DrawerSectionLabel(label: _tr('FINANCE', 'FEDHA')),
                          _DrawerItemLight(
                            icon: Icons.account_balance_rounded,
                            label: _tr('Madeni', 'Madeni'),
                            semanticsLabel: _tr('Debt tracking', 'Madeni, ufuatiliaji wa madeni'),
                            selected: _isSelected(location, AppRouter.debtPath),
                            onTap: () => _closeNavigationPanelThenNavigate(dialogContext, context, AppRouter.debtPath),
                          ),
                          const SizedBox(height: 2),
                          _DrawerItemLight(
                            icon: Icons.payments_outlined,
                            label: _tr('Gharama zangu', 'Gharama zangu'),
                            semanticsLabel: _tr('My expenses', 'Gharama zangu, usimamizi wa matumizi'),
                            selected: _isSelected(location, AppRouter.expensesPath),
                            onTap: () => _closeNavigationPanelThenNavigate(dialogContext, context, AppRouter.expensesPath),
                          ),
                          const SizedBox(height: 2),
                          _DrawerItemLight(
                            icon: Icons.account_balance_wallet_outlined,
                            label: _tr('Mtiririko wa Fedha', 'Mtiririko wa Fedha'),
                            semanticsLabel: _tr('Cash flow and accounts', 'Mtiririko wa fedha na akaunti'),
                            selected: _isSelected(location, AppRouter.cashFlowPath),
                            onTap: () => _closeNavigationPanelThenNavigate(dialogContext, context, AppRouter.cashFlowPath),
                          ),
                        ],
                        _DrawerSectionLabel(label: _tr('SETTINGS', 'MIPANGILIO')),
                        _DrawerItemLight(
                          icon: Icons.storefront_rounded,
                          label: _tr('Simamia Biashara', 'Simamia Biashara'),
                          semanticsLabel: _tr('Add or switch businesses', 'Ongeza au badili biashara'),
                          selected: _isSelected(location, AppRouter.businessesPath),
                          onTap: () => _closeNavigationPanelThenNavigate(dialogContext, context, AppRouter.businessesPath),
                        ),
                        const SizedBox(height: 2),
                        _DrawerItemLight(
                          icon: Icons.settings_rounded,
                          label: _tr('Mipangilio', 'Mipangilio'),
                          semanticsLabel: _tr('App settings', 'Mipangilio ya programu'),
                          selected: _isSelected(location, AppRouter.settingsPath),
                          onTap: () => _closeNavigationPanelThenNavigate(dialogContext, context, AppRouter.settingsPath),
                        ),
                        const SizedBox(height: 2),
                      ],
                    ),
                  ),
                  // Sign Out Button
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.fromLTRB(12, 12, 12, MediaQuery.of(dialogContext).padding.bottom + 16),
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.only(
                        bottomRight: Radius.circular(24),
                      ),
                      border: Border(
                        top: BorderSide(color: AppColors.border),
                      ),
                    ),
                    child: Column(
                      children: [
                        Semantics(
                          button: true,
                          label: _tr('Sign out from Mali App', 'Toka, logout from Mali App'),
                          child: SizedBox(
                            height: 48,
                            child: Material(
                              type: MaterialType.transparency,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => _closeNavigationPanelThenNavigate(dialogContext, context, AppRouter.loginPath),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.error.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
                                      const SizedBox(width: 12),
                                      Text(
                                        _tr('Sign Out', 'Toka'),
                                        style: const TextStyle(
                                          color: AppColors.error,
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
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static int _calculateIndex(String location, List<_NavDestination> destinations) {
    final index = destinations.indexWhere((destination) => _isSelected(location, destination.route));
    return index >= 0 ? index : 0;
  }

  List<_NavDestination> _businessNavDestinations() {
    return [
      _NavDestination(
        route: AppRouter.dashboardPath,
        label: _tr('Home', 'Nyumbani'),
        icon: Icons.grid_view_outlined,
        activeIcon: Icons.grid_view_rounded,
      ),
      _NavDestination(
        route: AppRouter.salesPath,
        label: _tr('Invoices', 'Ankara'),
        icon: Icons.receipt_outlined,
        activeIcon: Icons.receipt_rounded,
      ),
      _NavDestination(
        route: AppRouter.inventoryPath,
        label: _tr('Stock', 'Hisa'),
        icon: Icons.inventory_2_outlined,
        activeIcon: Icons.inventory_2_rounded,
      ),
      _NavDestination(
        route: AppRouter.crmPath,
        label: _tr('Clients', 'Wateja'),
        icon: Icons.people_outline_rounded,
        activeIcon: Icons.people_rounded,
      ),
    ];
  }

  String _pageTitle(String location) {
    if (location.startsWith(AppRouter.salesPath)) return _tr('Tuma ankara', 'Tuma ankara');
    if (location.startsWith(AppRouter.inventoryPath)) return _tr('Hisa zangu', 'Hisa zangu');
    if (location.startsWith(AppRouter.crmPath)) return _tr('Wateja wangu', 'Wateja wangu');
    if (location.startsWith(AppRouter.debtPath)) return _tr('Madeni', 'Madeni');
    if (location.startsWith(AppRouter.expensesPath)) return _tr('Gharama zangu', 'Gharama zangu');
    if (location.startsWith(AppRouter.cashFlowPath)) return _tr('Mtiririko wa Fedha', 'Mtiririko wa Fedha');
    if (location.startsWith(AppRouter.settingsPath)) return _tr('Settings', 'Mipangilio');
    if (location.startsWith(AppRouter.businessesPath)) return _tr('Manage Businesses', 'Simamia Biashara');
    return _tr('Hali ya biashara', 'Hali ya biashara');
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

    return _DrawerProfileData(
      fullName: fullName,
      contactLine: contactLine,
      accountTypeLabel: accountTypeLabel,
    );
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final title = _pageTitle(location);
    final currentUser = _currentUser;
    final isDashboard = _isSelected(location, AppRouter.dashboardPath);

    return FutureBuilder<Map<String, dynamic>?>(
      future: _profileFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done && snapshot.data == null) {
          return const SkeletonScreen(hasHeader: false, listItems: 6);
        }

        final profileData = snapshot.data;
        final profile = _buildProfileData(currentUser, profileData);
        final businesses = _businessesFromProfile(profileData);
        final isBusinessContext =
            _defaultContextFromProfile(profileData).toLowerCase().startsWith('business');
        final selectedContext = _defaultContextFromProfile(profileData);
        final canSwitch = _canSwitchFinanceContext(profileData);
        final destinations = _businessNavDestinations();
        final currentIndex = _calculateIndex(location, destinations);

        return Scaffold(
          extendBodyBehindAppBar: true, // Allow body to flow under the glass app bar
          drawerScrimColor: Colors.transparent,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(kToolbarHeight + 16),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      height: kToolbarHeight,
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      decoration: BoxDecoration(
                        color: AppColors.background.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.15),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.menu_rounded, color: AppColors.secondary, size: 28),
                            tooltip: _tr('Open navigation menu', 'Fungua menyu ya urambazaji'),
                            onPressed: () => _openNavigationPanel(
                              context: context,
                              location: location,
                              profile: profile,
                              isBusinessContext: isBusinessContext,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: _FinanceContextSwitcher(
                              selectedContext: selectedContext,
                              canSwitch: canSwitch,
                              businesses: businesses,
                              onChanged: _switchFinanceContext,
                              onManageBusinesses: () => context.go(AppRouter.businessesPath),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          body: Padding(
            // We use padding so that the content isn't completely hidden behind the AppBar
            // However, scroll views inside the children will automatically adjust for extendBody: true.
            // If the child is not a scroll view, it will need padding.
            padding: EdgeInsets.only(top: isDashboard ? 0 : kToolbarHeight + 24 + MediaQuery.of(context).padding.top),
            child: Column(
              children: [
                if (!isDashboard)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      border: Border(
                        bottom: BorderSide(
                          color: AppColors.secondary.withValues(alpha: 0.06),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.secondary,
                                  letterSpacing: 0.2,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(child: widget.child),
              ],
            ),
          ),
          bottomNavigationBar: SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(context).padding.bottom + 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: List.generate(destinations.length, (index) {
                        final destination = destinations[index];
                        final isSelected = index == currentIndex;
                        return _buildBottomNavItem(context, destination, isSelected, index);
                      }),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomNavItem(BuildContext context, _NavDestination destination, bool isSelected, int index) {
    return GestureDetector(
      onTap: () {
        context.go(destination.route);
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 18 : 12,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              child: Icon(
                isSelected ? destination.activeIcon : destination.icon,
                key: ValueKey<bool>(isSelected),
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                size: 24,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                destination.label,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ],
        ),
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

class _FinanceContextSwitcher extends StatelessWidget {
  final String selectedContext;
  final bool canSwitch;
  final List<Map<String, dynamic>> businesses;
  final ValueChanged<String> onChanged;
  final VoidCallback onManageBusinesses;

  const _FinanceContextSwitcher({
    required this.selectedContext,
    required this.canSwitch,
    required this.businesses,
    required this.onChanged,
    required this.onManageBusinesses,
  });

  bool get _isBusiness => selectedContext.toLowerCase().startsWith('business');

  String? _selectedBusinessId() {
    if (!_isBusiness || !selectedContext.contains(':')) {
      return null;
    }
    return selectedContext.split(':').sublist(1).join(':');
  }

  @override
  Widget build(BuildContext context) {
    final isSwahili = LocalizationService.isSwahili;
    String tr(String en, String sw) => isSwahili ? sw : en;
    final selectedBusinessId = _selectedBusinessId();
    Map<String, dynamic>? selectedBusiness;
    if (selectedBusinessId != null) {
      for (final business in businesses) {
        if (business['id'] == selectedBusinessId) {
          selectedBusiness = business;
          break;
        }
      }
    }
    final label = (selectedBusiness?['name'] as String?)?.trim().isNotEmpty == true
        ? (selectedBusiness!['name'] as String).trim()
        : tr('Business', 'Biashara');
    const icon = Icons.business_center_rounded;

    return PopupMenuButton<String>(
      enabled: canSwitch,
      tooltip: canSwitch
        ? tr('Switch finance context', 'Badili muktadha wa fedha')
        : tr('Single account context', 'Muktadha mmoja wa akaunti'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 8,
      offset: const Offset(0, 48),
      onSelected: (value) {
        if (value == 'manage_businesses') {
          onManageBusinesses();
          return;
        }
        onChanged(value);
      },
      itemBuilder: (context) {
        return <PopupMenuEntry<String>>[
          if (businesses.isNotEmpty) const PopupMenuDivider(),
          ...businesses.map(
            (business) => PopupMenuItem<String>(
              value: 'business:${business['id']}',
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.business_center_rounded, size: 20, color: AppColors.secondary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      (business['name'] as String?)?.trim().isNotEmpty == true
                          ? (business['name'] as String).trim()
                          : tr('Business Context', 'Muktadha wa Biashara'),
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const PopupMenuDivider(),
          PopupMenuItem<String>(
            value: 'manage_businesses',
            child: Row(
              children: [
                const Icon(Icons.settings_rounded, size: 20, color: AppColors.textSecondary),
                const SizedBox(width: 12),
                Text(
                  tr('Manage businesses', 'Simamia biashara'),
                  style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ];
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: canSwitch
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.surface.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: canSwitch
                ? AppColors.primary.withValues(alpha: 0.2)
                : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: canSwitch ? AppColors.primary : AppColors.secondary),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: canSwitch ? AppColors.primary : AppColors.secondary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            if (canSwitch) ...[
              const SizedBox(width: 6),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 16,
                color: AppColors.primary,
              ),
            ]
          ],
        ),
      ),
    );
  }
}

class _DrawerProfileData {
  final String fullName;
  final String contactLine;
  final String accountTypeLabel;

  const _DrawerProfileData({
    required this.fullName,
    required this.contactLine,
    required this.accountTypeLabel,
  });
}

/// Light theme drawer item for premium fintech look
class _DrawerItemLight extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String semanticsLabel;
  final bool selected;

  const _DrawerItemLight({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.semanticsLabel,
    this.selected = false,
  });

  @override
  State<_DrawerItemLight> createState() => _DrawerItemLightState();
}

class _DrawerItemLightState extends State<_DrawerItemLight> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const active = AppColors.primary;

    return Semantics(
      button: true,
      label: widget.semanticsLabel,
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) {
          _controller.reverse();
          widget.onTap();
        },
        onTapCancel: () => _controller.reverse(),
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            height: 52,
            margin: const EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(
              color: widget.selected ? active.withValues(alpha: 0.08) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: widget.selected ? Border.all(color: active.withValues(alpha: 0.15)) : null,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: widget.selected ? active.withValues(alpha: 0.12) : AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(widget.icon, size: 18, color: widget.selected ? active : AppColors.textSecondary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    widget.label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: widget.selected ? active : AppColors.textPrimary,
                      fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: widget.selected ? active : AppColors.textMuted, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DrawerSectionLabel extends StatelessWidget {
  final String label;
  const _DrawerSectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 6),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/services/default_context_routing_service.dart';
import '../../core/services/live_activity_service.dart';
import '../../core/services/localization_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../config/routing.dart';
import '../../core/providers/sync_provider.dart';
import '../../core/sync/sync_service.dart';
import '../../features/rbac/data/rbac_providers.dart';
import '../../features/rbac/domain/permission_service.dart';
import '../../features/team/domain/models/team_member.dart';
import 'app_sheet.dart';
import 'nav_aware_fab.dart';

class MainShellPage extends ConsumerStatefulWidget {
  final Widget child;
  const MainShellPage({super.key, required this.child});

  @override
  ConsumerState<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends ConsumerState<MainShellPage>
    with SingleTickerProviderStateMixin {
  User? _currentUser;
  late Future<Map<String, dynamic>?> _profileFuture;
  late final VoidCallback _languageListener;
  final _liveActivity = LiveActivityService();
  String _currentBusinessName = '';

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    _profileFuture = _fetchUserProfile(_currentUser);
    _profileFuture.then((profile) {
      if (!mounted) return;
      final businesses = _businessesFromProfile(profile);
      final selectedId = _selectedBusinessId(profile);
      final biz = businesses.firstWhere(
        (b) => b['id'] == selectedId,
        orElse: () => businesses.isNotEmpty ? businesses.first : {},
      );
      _currentBusinessName = (biz['name'] as String?)?.trim() ?? '';
    });
    _languageListener = () {
      if (mounted) setState(() {});
    };
    LocalizationService.languageNotifier.addListener(_languageListener);
    _liveActivity.initialize();
  }

  @override
  void dispose() {
    LocalizationService.languageNotifier.removeListener(_languageListener);
    _liveActivity.dispose();
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

  List<Map<String, dynamic>> _businessesFromProfile(
    Map<String, dynamic>? profile,
  ) {
    final businessesRaw = profile?['businesses'];
    if (businessesRaw is! List) return const [];

    return businessesRaw
        .whereType<Map>()
        .map((entry) {
          // Support both old field names and new Firestore schema field names.
          final name =
              ((entry['businessName'] as String?)?.trim().isNotEmpty == true
                  ? entry['businessName'] as String
                  : (entry['name'] as String?)?.trim()) ??
              '';
          final category =
              ((entry['businessCategory'] as String?)?.trim().isNotEmpty == true
                  ? entry['businessCategory'] as String
                  : (entry['category'] as String?)?.trim()) ??
              '';
          final place =
              ((entry['city'] as String?)?.trim().isNotEmpty == true
                  ? entry['city'] as String
                  : (entry['placeOfBusiness'] as String?)?.trim()) ??
              '';
          return <String, dynamic>{
            'id': (entry['id'] as String?)?.trim() ?? '',
            'name': name,
            'category': category,
            'placeOfBusiness': place,
          };
        })
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
    final businessId =
        selectedBusinessId ??
        (businesses.isNotEmpty ? businesses.first['id'] as String : null);
    if (businessId != null && businessId.isNotEmpty) {
      return 'business:$businessId';
    }
    return 'business';
  }

  Future<void> _switchFinanceContext(String nextContext) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final profile = await _profileFuture;
    final businesses = _businessesFromProfile(profile);
    final normalized = nextContext.toLowerCase();

    final requestedBusinessId = normalized.contains(':')
        ? normalized.split(':').sublist(1).join(':').trim()
        : null;
    final fallbackBusinessId =
        _selectedBusinessId(profile) ??
        (businesses.isNotEmpty ? businesses.first['id'] as String : null);
    final resolvedNextContext =
        requestedBusinessId != null && requestedBusinessId.isNotEmpty
        ? 'business:$requestedBusinessId'
        : fallbackBusinessId != null
        ? 'business:$fallbackBusinessId'
        : 'business';

    final currentContext = _defaultContextFromProfile(profile);
    if (currentContext == resolvedNextContext) {
      if (!mounted) return;
      final route = DefaultContextRoutingService.routeFromContextValue(
        resolvedNextContext,
      );
      context.go(route);
      return;
    }

    final selectedBusinessId = resolvedNextContext.startsWith('business:')
        ? resolvedNextContext.split(':').sublist(1).join(':')
        : null;

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'defaultContext': resolvedNextContext,
      'defaultAccountType': 'business',
      'selectedBusinessId': selectedBusinessId,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    _refreshProfile();

    if (!mounted) return;
    final route = DefaultContextRoutingService.routeFromContextValue(
      resolvedNextContext,
    );
    context.go(route);
  }

  static Future<Map<String, dynamic>?> _fetchUserProfile(User? user) async {
    if (user == null) return null;
    final fs = FirebaseFirestore.instance;

    final userSnap = await fs
        .collection('users')
        .doc(user.uid)
        .get(const GetOptions());
    final profile = userSnap.data();
    if (profile == null) return null;

    final isTeamMember = profile['isTeamMember'] == true;

    if (isTeamMember) {
      // Team members belong to one business — load it directly.
      final bizId = (profile['businessId'] as String?)?.trim() ?? '';
      if (bizId.isNotEmpty) {
        final bizSnap = await fs
            .collection('businesses')
            .doc(bizId)
            .get(const GetOptions());
        if (bizSnap.exists) {
          profile['businesses'] = [
            {'id': bizId, ...?bizSnap.data()},
          ];
        }
      }
    } else {
      // Owners — load all their businesses from the businesses collection.
      final bizSnap = await fs
          .collection('businesses')
          .where('ownerUid', isEqualTo: user.uid)
          .get(const GetOptions());
      profile['businesses'] = bizSnap.docs
          .map((d) => {'id': d.id, ...d.data()})
          .toList();
    }

    return profile;
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
    required PermissionService ps,
    TeamMember? member,
  }) async {
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: _tr('Close navigation menu', 'Funga menyu ya urambazaji'),
      barrierColor: AppColors.overlay,
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        final fade = Tween<double>(begin: 0, end: 1).animate(curved);
        return BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 10 * fade.value,
            sigmaY: 10 * fade.value,
          ),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(-1, 0),
              end: Offset.zero,
            ).animate(curved),
            child: FadeTransition(opacity: fade, child: child),
          ),
        );
      },
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        final isDashboard = _isSelected(location, AppRouter.dashboardPath);
        return Align(
          alignment: Alignment.centerLeft,
          child: SafeArea(
            bottom: false,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                child: Container(
                  width: MediaQuery.of(dialogContext).size.width * 0.82,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.94),
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                    border: Border.all(
                      color: AppColors.secondary.withValues(alpha: 0.12),
                    ),
                    boxShadow: AppTheme.modalShadow,
                  ),
                  child: Column(
                    children: [
                      // Profile Header — blue and white
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          border: Border(
                            bottom: BorderSide(
                              color: AppColors.secondary.withValues(
                                alpha: 0.18,
                              ),
                            ),
                          ),
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(24),
                          ),
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
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white.withValues(
                                            alpha: 0.28,
                                          ),
                                          width: 2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.secondary
                                                .withValues(alpha: 0.25),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Text(
                                          profile.fullName.isNotEmpty
                                              ? profile.fullName
                                                    .trim()[0]
                                                    .toUpperCase()
                                              : 'M',
                                          style: GoogleFonts.dmSans(
                                            color: AppColors.secondary,
                                            fontSize: 22,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            profile.fullName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.dmSans(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          SizedBox(height: 2),
                                          Text(
                                            profile.contactLine,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.dmSans(
                                              color: Colors.white70,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () =>
                                          Navigator.of(dialogContext).pop(),
                                      icon: const Icon(
                                        Icons.close_rounded,
                                        color: AppColors.textMuted,
                                        size: 22,
                                      ),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                if (ps.isOwner)
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: 0.14,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                          border: Border.all(
                                            color: Colors.white.withValues(
                                              alpha: 0.28,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.stars_rounded,
                                              size: 12,
                                              color: Colors.white,
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              _tr('Free', 'Bure'),
                                              style: GoogleFonts.dmSans(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                          border: Border.all(
                                            color: Colors.white.withValues(
                                              alpha: 0.24,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.business_center_rounded,
                                              size: 12,
                                              color: AppColors.secondary,
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              _tr('Business', 'Biashara'),
                                              style: GoogleFonts.dmSans(
                                                color: AppColors.secondary,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  )
                                else if (member != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.18,
                                      ),
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color: Colors.white.withValues(
                                          alpha: 0.32,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.badge_outlined,
                                          size: 12,
                                          color: Colors.white,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          member.role.label,
                                          style: GoogleFonts.dmSans(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Navigation Items
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                          children: [
                            _DrawerItemLight(
                              icon: Icons.grid_view_rounded,
                              iconColor: AppColors.secondary,
                              label: _tr(
                                'Hali ya biashara',
                                'Hali ya biashara',
                              ),
                              semanticsLabel: _tr(
                                'Dashboard, business overview',
                                'Hali ya biashara, muhtasari wa biashara',
                              ),
                              selected: isDashboard,
                              onTap: () => _closeNavigationPanelThenNavigate(
                                dialogContext,
                                context,
                                AppRouter.dashboardPath,
                              ),
                            ),
                            if (ps.canViewSales ||
                                ps.canViewInventory ||
                                ps.canViewCustomers)
                              _DrawerSectionLabel(
                                label: _tr('BUSINESS', 'BIASHARA'),
                              ),
                            if (ps.canViewSales)
                              _DrawerItemLight(
                                icon: Icons.receipt_long_rounded,
                                iconColor: AppColors.secondary,
                                label: _tr('Tuma ankara', 'Tuma ankara'),
                                semanticsLabel: _tr(
                                  'Sales and invoices',
                                  'Tuma ankara, mauzo na ankara',
                                ),
                                selected: _isSelected(
                                  location,
                                  AppRouter.salesPath,
                                ),
                                onTap: () => _closeNavigationPanelThenNavigate(
                                  dialogContext,
                                  context,
                                  AppRouter.salesPath,
                                ),
                              ),
                            if (ps.canViewInventory)
                              _DrawerItemLight(
                                icon: Icons.inventory_2_rounded,
                                iconColor: AppColors.secondary,
                                label: _tr('Bidhaa zangu', 'Bidhaa zangu'),
                                semanticsLabel: _tr(
                                  'My stock and inventory',
                                  'Bidhaa zangu, usimamizi wa bidhaaa',
                                ),
                                selected: _isSelected(
                                  location,
                                  AppRouter.inventoryPath,
                                ),
                                onTap: () => _closeNavigationPanelThenNavigate(
                                  dialogContext,
                                  context,
                                  AppRouter.inventoryPath,
                                ),
                              ),
                            if (ps.canViewCustomers)
                              _DrawerItemLight(
                                icon: Icons.people_alt_rounded,
                                iconColor: AppColors.secondary,
                                label: _tr('Wateja wangu', 'Wateja wangu'),
                                semanticsLabel: _tr(
                                  'My customers',
                                  'Wateja wangu, usimamizi wa wateja',
                                ),
                                selected: _isSelected(
                                  location,
                                  AppRouter.crmPath,
                                ),
                                onTap: () => _closeNavigationPanelThenNavigate(
                                  dialogContext,
                                  context,
                                  AppRouter.crmPath,
                                ),
                              ),
                            if (ps.canViewDebt ||
                                ps.canManageExpenses ||
                                ps.canViewCashFlow ||
                                ps.canViewFinancialReports)
                              _DrawerSectionLabel(
                                label: _tr('FINANCE', 'FEDHA'),
                              ),
                            if (ps.canViewDebt)
                              _DrawerItemLight(
                                icon: Icons.account_balance_rounded,
                                iconColor: AppColors.secondary,
                                label: _tr('Madeni', 'Madeni'),
                                semanticsLabel: _tr(
                                  'Debt tracking',
                                  'Madeni, ufuatiliaji wa madeni',
                                ),
                                selected: _isSelected(
                                  location,
                                  AppRouter.debtPath,
                                ),
                                onTap: () => _closeNavigationPanelThenNavigate(
                                  dialogContext,
                                  context,
                                  AppRouter.debtPath,
                                ),
                              ),
                            if (ps.canManageExpenses)
                              _DrawerItemLight(
                                icon: Icons.payments_outlined,
                                iconColor: AppColors.secondary,
                                label: _tr('Gharama zangu', 'Gharama zangu'),
                                semanticsLabel: _tr(
                                  'My expenses',
                                  'Gharama zangu, usimamizi wa matumizi',
                                ),
                                selected: _isSelected(
                                  location,
                                  AppRouter.expensesPath,
                                ),
                                onTap: () => _closeNavigationPanelThenNavigate(
                                  dialogContext,
                                  context,
                                  AppRouter.expensesPath,
                                ),
                              ),
                            if (ps.canViewCashFlow)
                              _DrawerItemLight(
                                icon: Icons.account_balance_wallet_outlined,
                                iconColor: AppColors.secondary,
                                label: _tr(
                                  'Mtiririko wa Fedha',
                                  'Mtiririko wa Fedha',
                                ),
                                semanticsLabel: _tr(
                                  'Cash flow and accounts',
                                  'Mtiririko wa fedha na akaunti',
                                ),
                                selected: _isSelected(
                                  location,
                                  AppRouter.cashFlowPath,
                                ),
                                onTap: () => _closeNavigationPanelThenNavigate(
                                  dialogContext,
                                  context,
                                  AppRouter.cashFlowPath,
                                ),
                              ),
                            if (ps.canViewFinancialReports)
                              _DrawerItemLight(
                                icon: Icons.bar_chart_rounded,
                                iconColor: AppColors.secondary,
                                label: _tr(
                                  'Ripoti za Fedha',
                                  'Ripoti za Fedha',
                                ),
                                semanticsLabel: _tr(
                                  'Financial reports — P&L, Balance Sheet, VAT',
                                  'Ripoti za fedha — P&L, Mizania, VAT',
                                ),
                                selected: _isSelected(
                                  location,
                                  AppRouter.reportsPath,
                                ),
                                onTap: () => _closeNavigationPanelThenNavigate(
                                  dialogContext,
                                  context,
                                  AppRouter.reportsPath,
                                ),
                              ),
                            if (ps.canManageTeam) ...[
                              _DrawerSectionLabel(label: _tr('TEAM', 'TIMU')),
                              _DrawerItemLight(
                                icon: Icons.group_rounded,
                                iconColor: AppColors.secondary,
                                label: _tr('My Team', 'Timu yangu'),
                                semanticsLabel: _tr(
                                  'Team and role management',
                                  'Timu yangu, usimamizi wa majukumu',
                                ),
                                selected: _isSelected(
                                  location,
                                  AppRouter.teamPath,
                                ),
                                onTap: () => _closeNavigationPanelThenNavigate(
                                  dialogContext,
                                  context,
                                  AppRouter.teamPath,
                                ),
                              ),
                            ],
                            if (ps.isOwner) ...[
                              _DrawerSectionLabel(
                                label: _tr('SETTINGS', 'MIPANGILIO'),
                              ),
                              _DrawerItemLight(
                                icon: Icons.storefront_rounded,
                                iconColor: AppColors.secondary,
                                label: _tr(
                                  'Simamia Biashara',
                                  'Simamia Biashara',
                                ),
                                semanticsLabel: _tr(
                                  'Add or switch businesses',
                                  'Ongeza au badili biashara',
                                ),
                                selected: _isSelected(
                                  location,
                                  AppRouter.businessesPath,
                                ),
                                onTap: () => _closeNavigationPanelThenNavigate(
                                  dialogContext,
                                  context,
                                  AppRouter.businessesPath,
                                ),
                              ),
                              _DrawerItemLight(
                                icon: Icons.settings_rounded,
                                iconColor: AppColors.secondary,
                                label: _tr('Mipangilio', 'Mipangilio'),
                                semanticsLabel: _tr(
                                  'App settings',
                                  'Mipangilio ya programu',
                                ),
                                selected: _isSelected(
                                  location,
                                  AppRouter.settingsPath,
                                ),
                                onTap: () => _closeNavigationPanelThenNavigate(
                                  dialogContext,
                                  context,
                                  AppRouter.settingsPath,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static int _calculateIndex(
    String location,
    List<_NavDestination> destinations,
  ) {
    final index = destinations.indexWhere(
      (destination) => _isSelected(location, destination.route),
    );
    return index >= 0 ? index : 0;
  }

  List<_NavDestination> _buildNavDestinations(PermissionService ps) {
    return [
      _NavDestination(
        route: AppRouter.dashboardPath,
        label: _tr('Home', 'Nyumbani'),
        icon: Icons.grid_view_outlined,
        activeIcon: Icons.grid_view_rounded,
      ),
      if (ps.canViewSales)
        _NavDestination(
          route: AppRouter.salesPath,
          label: _tr('Invoices', 'Ankara'),
          icon: Icons.receipt_outlined,
          activeIcon: Icons.receipt_rounded,
        ),
      if (ps.canViewInventory)
        _NavDestination(
          route: AppRouter.inventoryPath,
          label: _tr('Stock', 'Bidhaa'),
          icon: Icons.inventory_2_outlined,
          activeIcon: Icons.inventory_2_rounded,
        ),
      if (ps.canViewCustomers)
        _NavDestination(
          route: AppRouter.crmPath,
          label: _tr('Clients', 'Wateja'),
          icon: Icons.people_outline_rounded,
          activeIcon: Icons.people_rounded,
        ),
    ];
  }

  static bool _isSelected(String location, String route) {
    return location == route || location.startsWith('$route/');
  }

  _DrawerProfileData _buildProfileData(
    User? user,
    Map<String, dynamic>? profile,
  ) {
    final fullName =
        ((profile?['displayName'] as String?)?.trim().isNotEmpty ?? false)
        ? (profile?['displayName'] as String).trim()
        : ((profile?['name'] as String?)?.trim().isNotEmpty ?? false)
        ? (profile?['name'] as String).trim()
        : ((user?.displayName?.trim().isNotEmpty ?? false)
              ? user!.displayName!.trim()
              : _tr('Mali Up User', 'Mtumiaji wa Mali Up'));

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
              : _tr(
                  'No contact details available',
                  'Hakuna maelezo ya mawasiliano',
                ));

    return _DrawerProfileData(fullName: fullName, contactLine: contactLine);
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final currentUser = _currentUser;
    ref.watch(
      syncServiceProvider,
    ); // starts SyncService (local→Firestore push) when uid + bizId are ready
    // Drive the Dynamic Island Live Activity whenever the sync state changes.
    ref.listen<SyncState>(syncStateProvider, (prev, next) {
      if (prev == next) return;
      final bizName = _currentBusinessName;
      _liveActivity.onSyncStateChanged(next, businessName: bizName);
    });
    // Select only the bool we need so the shell doesn't rebuild on every
    // intermediate SyncState transition (e.g. idle→syncing→idle).
    final isOnline = ref.watch(
      syncStateProvider.select(
        (s) => s == SyncState.idle || s == SyncState.syncing,
      ),
    );
    final permissionsLoaded = ref.watch(permissionsLoadedProvider);
    // Use owner-equivalent permissions while loading to avoid a flash of the
    // one-icon nav bar on first login (no role cache yet on the device).
    // The router already blocks navigation to restricted routes until
    // permissions are settled, so this optimistic grant is safe.
    final ps = permissionsLoaded
        ? ref.watch(permissionServiceProvider)
        : PermissionService.owner();
    if (kDebugMode) {
      debugPrint(
        '[Shell] build: permissionsLoaded=$permissionsLoaded '
        'isOwner=${ps.isOwner} '
        'canSales=${ps.canViewSales} '
        'canInventory=${ps.canViewInventory}',
      );
    }
    // Select valueOrNull so the shell only rebuilds when the member record
    // itself changes, not on every AsyncValue wrapper transition.
    final member = ref.watch(
      currentMemberProvider.select((a) => a.valueOrNull),
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Shell pages (dashboard, sales, reports…) have a white top background,
      // so keep dark status bar icons even when returning from navy screens.
      value: AppTheme.statusBarDarkIcons,
      child: FutureBuilder<Map<String, dynamic>?>(
        future: _profileFuture,
        builder: (context, snapshot) {
          final profileData = snapshot.data;
          final profile = _buildProfileData(currentUser, profileData);
          final businesses = _businessesFromProfile(profileData);
          final selectedContext = _defaultContextFromProfile(profileData);
          final canSwitch = businesses.length > 1;
          final destinations = _buildNavDestinations(ps);
          final currentIndex = _calculateIndex(location, destinations);

          return Scaffold(
            extendBodyBehindAppBar: true,
            extendBody: true,
            drawerScrimColor: Colors.transparent,
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(
                54 + MediaQuery.of(context).padding.top,
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 4.0,
                  ),
                  child: Container(
                    height: 46,
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.menu_rounded,
                            color: AppColors.secondary,
                            size: 28,
                          ),
                          tooltip: _tr(
                            'Open navigation menu',
                            'Fungua menyu ya urambazaji',
                          ),
                          onPressed: () => _openNavigationPanel(
                            context: context,
                            location: location,
                            profile: profile,
                            ps: ps,
                            member: member,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: _FinanceContextSwitcher(
                            selectedContext: selectedContext,
                            canSwitch: canSwitch,
                            businesses: businesses,
                            isOnline: isOnline,
                            onChanged: _switchFinanceContext,
                            onManageBusinesses: () async {
                              await context.push(AppRouter.businessesPath);
                              _refreshProfile();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            body: Builder(
              // With extendBody, Scaffold injects the bottom nav's height into
              // the body's MediaQuery padding — republish it as NavBarLift so
              // FABs (whose slot strips MediaQuery padding) can clear the nav.
              builder: (bodyContext) => NavBarLift(
                lift: MediaQuery.of(bodyContext).padding.bottom,
                child: widget.child,
              ),
            ),
            bottomNavigationBar: ValueListenableBuilder<int>(
              valueListenable: sheetOpenNotifier,
              builder: (_, sheetCount, child) => ClipRect(
                child: AnimatedAlign(
                  alignment: Alignment.topCenter,
                  heightFactor: sheetCount > 0 ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 280),
                  curve: sheetCount > 0 ? Curves.easeIn : Curves.easeOut,
                  child: child,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      24,
                      8,
                      24,
                      MediaQuery.of(context).padding.bottom > 0
                          ? MediaQuery.of(context).padding.bottom + 8
                          : 16.0,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.navyPrimary,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.28),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: List.generate(destinations.length, (index) {
                          final destination = destinations[index];
                          final isSelected = index == currentIndex;
                          return _buildBottomNavItem(
                            context,
                            destination,
                            isSelected,
                            index,
                          );
                        }),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomNavItem(
    BuildContext context,
    _NavDestination destination,
    bool isSelected,
    int index,
  ) {
    return GestureDetector(
      onTap: () => context.go(destination.route),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, animation) =>
                      ScaleTransition(scale: animation, child: child),
                  child: Icon(
                    isSelected ? destination.activeIcon : destination.icon,
                    key: ValueKey<bool>(isSelected),
                    color: isSelected ? AppColors.yellowBrand : Colors.white54,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 3),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: GoogleFonts.dmSans(
                    color: isSelected ? AppColors.yellowBrand : Colors.white54,
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                  child: Text(
                    destination.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            // Straddles the top edge of the navy card so it reads as a
            // notch/badge cresting the bar, sitting right above the icon.
            Positioned(
              top: -11,
              child: AnimatedOpacity(
                opacity: isSelected ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppColors.yellowBrand,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
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
  final bool isOnline;
  final List<Map<String, dynamic>> businesses;
  final ValueChanged<String> onChanged;
  final VoidCallback onManageBusinesses;

  const _FinanceContextSwitcher({
    required this.selectedContext,
    required this.canSwitch,
    required this.isOnline,
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

  String _businessLabel(Map<String, dynamic> business) {
    final name = (business['name'] as String?)?.trim();
    return name != null && name.isNotEmpty
        ? name
        : LocalizationService.isSwahili
        ? 'Muktadha wa Biashara'
        : 'Business Context';
  }

  /// Returns the first meaningful word for compact display in the navbar.
  /// e.g. "Neuraltale Electronics Ltd" → "Neuraltale"
  ///      "AB Shop" → "AB Shop" (first word is too short, keep two words)
  static String _shortName(String name) {
    final words = name.trim().split(RegExp(r'\s+'));
    if (words.isEmpty) return name;
    final first = words.first;
    if (first.length >= 4 || words.length == 1) return first;
    return words.take(2).join(' ');
  }

  Future<void> _openBusinessSwitcherSheet(
    BuildContext context,
    String? selectedBusinessId,
  ) async {
    if (!canSwitch || businesses.isEmpty) return;

    await showAppSheet<void>(
      context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      builder: (sheetContext) {
        final isSwahili = LocalizationService.isSwahili;
        String tr(String en, String sw) => isSwahili ? sw : en;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('Switch business', 'Badili biashara'),
                  style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tr('Tap a business to open it.', 'Gusa biashara kuifungua.'),
                  style: Theme.of(sheetContext).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 12),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: businesses.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (_, index) {
                      final business = businesses[index];
                      final isActive = business['id'] == selectedBusinessId;

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: AppColors.secondary.withValues(
                            alpha: 0.12,
                          ),
                          child: const Icon(
                            Icons.business_center_rounded,
                            color: AppColors.secondary,
                          ),
                        ),
                        title: Text(
                          _businessLabel(business),
                          style: GoogleFonts.dmSans(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          '${(business['category'] ?? '').toString()} • ${(business['placeOfBusiness'] ?? '').toString()}',
                        ),
                        trailing: isActive
                            ? const Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.success,
                              )
                            : null,
                        onTap: () async {
                          Navigator.of(sheetContext).pop();
                          onChanged('business:${business['id']}');
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      onManageBusinesses();
                    },
                    icon: const Icon(Icons.settings_rounded),
                    label: Text(tr('Manage businesses', 'Simamia biashara')),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _switchToNextBusiness() {
    if (!canSwitch || businesses.length < 2) return;
    final currentBusinessId = _selectedBusinessId();
    final currentIndex = businesses.indexWhere(
      (business) => business['id'] == currentBusinessId,
    );
    final nextIndex = currentIndex < 0
        ? 0
        : (currentIndex + 1) % businesses.length;
    onChanged('business:${businesses[nextIndex]['id']}');
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
    final rawName = (selectedBusiness?['name'] as String?)?.trim() ?? '';
    final label = rawName.isNotEmpty
        ? _shortName(rawName)
        : tr('Business', 'Biashara');

    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: canSwitch
              ? () => _openBusinessSwitcherSheet(context, selectedBusinessId)
              : null,
          onDoubleTap: canSwitch ? _switchToNextBusiness : null,
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
                const Icon(
                  Icons.business_center_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
                SizedBox(width: 8),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 130),
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.dmSans(
                      color: canSwitch
                          ? AppColors.primary
                          : AppColors.secondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                if (canSwitch) ...[
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ],
              ],
            ),
          ),
        ),
        Positioned(
          top: -3,
          right: -3,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            padding: isOnline
                ? EdgeInsets.zero
                : const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: isOnline ? AppColors.success : AppColors.error,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            child: isOnline
                ? const SizedBox(width: 6, height: 6)
                : Text(
                    tr('Offline', 'Offline'),
                    style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                      height: 1.2,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

class _DrawerProfileData {
  final String fullName;
  final String contactLine;

  const _DrawerProfileData({required this.fullName, required this.contactLine});
}

class _DrawerItemLight extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String semanticsLabel;
  final bool selected;
  final Color iconColor;

  const _DrawerItemLight({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.semanticsLabel,
    required this.iconColor,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    const activeColor = AppColors.secondary;

    return Semantics(
      button: true,
      label: semanticsLabel,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            splashColor: (selected ? activeColor : iconColor).withValues(
              alpha: 0.1,
            ),
            highlightColor: (selected ? activeColor : iconColor).withValues(
              alpha: 0.05,
            ),
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: selected ? activeColor : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: selected
                    ? Border(
                        left: BorderSide(
                          color: Colors.white.withValues(alpha: 0.7),
                          width: 3,
                        ),
                      )
                    : null,
              ),
              padding: EdgeInsets.only(left: selected ? 9 : 12, right: 16),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: selected
                          ? Colors.white.withValues(alpha: 0.16)
                          : AppColors.secondary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      size: 17,
                      color: selected ? Colors.white : AppColors.secondary,
                    ),
                  ),
                  SizedBox(width: 13),
                  Expanded(
                    child: Text(
                      label,
                      style: GoogleFonts.dmSans(
                        color: selected ? Colors.white : AppColors.secondary,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        fontSize: 14,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ),
                  if (selected)
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
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
      padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
      child: Row(
        children: [
          Expanded(child: Divider(height: 1, color: AppColors.border)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              label,
              style: GoogleFonts.dmSans(
                color: AppColors.secondary,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const Expanded(child: Divider(height: 1, color: AppColors.border)),
        ],
      ),
    );
  }
}

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/services/default_context_routing_service.dart';
import '../../core/services/live_activity_service.dart';
import '../../core/services/localization_service.dart';
import '../../core/services/plan_service.dart';
import '../../core/services/version_gate_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_motion.dart';
import '../../config/routing.dart';
import '../../core/providers/business_id_provider.dart';
import '../../core/providers/connectivity_provider.dart';
import '../../core/providers/push_notification_provider.dart';
import '../../core/providers/sync_provider.dart';
import '../../core/services/business_profile_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/sync/sync_service.dart';
import '../../features/notifications/data/notification_aggregator.dart';
import '../../features/rbac/data/rbac_providers.dart';
import '../../features/rbac/data/role_cache_service.dart';
import '../../features/rbac/domain/permission_service.dart';
import '../../features/team/domain/models/team_member.dart';
import 'app_sheet.dart';
import 'nav_aware_fab.dart';
import 'plan_activated_dialog.dart';

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
  final _planActivationWatcher = _PlanActivationWatcher();
  String _currentBusinessName = '';
  late final VoidCallback _versionGateListener;
  // Timestamp of the last back-press on the Home tab, used for the
  // double-back-to-exit confirmation.
  DateTime? _lastBackPressAt;
  // slotPosition (0..2) -> catalog key of the screen assigned to that nav
  // slot. Empty until loaded from SharedPreferences; missing entries fall
  // back to _defaultSlotOrder.
  Map<int, String> _navSlotOverrides = {};

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
    // A business was just added/edited elsewhere (Manage Businesses) — the
    // nav bar's business pill/switcher holds its own _profileFuture, so it
    // needs its own nudge to refetch or the new business won't appear (or
    // become selectable) until the shell itself is torn down and rebuilt.
    // Mirrors DashboardScreen's listener on the same notifier.
    BusinessProfileService.updatedNotifier.addListener(_onBusinessProfileUpdated);
    _loadNavSlotOverrides();
    _liveActivity.initialize();
    // The version-gate fetch kicked off in main.dart may still be in flight
    // when this shell first mounts, so listen for the result as well as
    // checking it once immediately in case it already resolved.
    _versionGateListener = () {
      if (mounted) _maybeShowUpdateBanner();
    };
    VersionGateService.statusNotifier.addListener(_versionGateListener);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _maybeShowUpdateBanner(),
    );
  }

  @override
  void dispose() {
    LocalizationService.languageNotifier.removeListener(_languageListener);
    BusinessProfileService.updatedNotifier.removeListener(
      _onBusinessProfileUpdated,
    );
    VersionGateService.statusNotifier.removeListener(_versionGateListener);
    _removeNavPickOverlay();
    _navPickHighlightIndex.dispose();
    _liveActivity.dispose();
    super.dispose();
  }

  static const _updateBannerDismissedKey = 'update_banner_dismissed_build';

  Future<void> _maybeShowUpdateBanner() async {
    final status = VersionGateService.statusNotifier.value;
    final build = status.recommendedBuildNumber;
    if (status.tier != VersionGateTier.softNag || build == null) return;

    final prefs = await SharedPreferences.getInstance();
    if (prefs.getInt(_updateBannerDismissedKey) == build) return;
    if (!mounted) return;
    _showUpdateBanner(status, build);
  }

  void _showUpdateBanner(VersionGateStatus status, int build) {
    final message = _isSwahili ? status.messageSw : status.messageEn;
    ScaffoldMessenger.of(context)
      ..clearMaterialBanners()
      ..showMaterialBanner(
        MaterialBanner(
          backgroundColor: AppColors.infoBg,
          leading: const Icon(
            Icons.system_update_rounded,
            color: AppColors.info,
          ),
          content: Text(
            message.isNotEmpty
                ? message
                : _tr(
                    'A new version of Mali Up is available.',
                    'Toleo jipya la Mali Up linapatikana.',
                  ),
            style: GoogleFonts.dmSans(
              color: AppColors.info,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => _dismissUpdateBanner(build),
              child: Text(_tr('Later', 'Baadaye')),
            ),
            TextButton(
              onPressed: () => _openUpdateUrl(status),
              child: Text(_tr('Update', 'Sasisha')),
            ),
          ],
        ),
      );
  }

  Future<void> _dismissUpdateBanner(int build) async {
    if (mounted) ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_updateBannerDismissedKey, build);
  }

  Future<void> _openUpdateUrl(VersionGateStatus status) async {
    final url = Platform.isIOS ? status.updateUrlIOS : status.updateUrlAndroid;
    if (url.isNotEmpty) {
      final uri = Uri.tryParse(url);
      if (uri != null) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
    if (mounted) ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
  }

  // ── Connectivity banners ────────────────────────────────────────────────
  // Cold-start case: the app can be opened while already offline, which
  // isOnlineProvider's transition listener in build() never sees (it only
  // fires on a genuine flip after this shell has mounted). Checked once,
  // after first frame, alongside the other post-frame checks in initState.

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

  /// A business was just added/edited elsewhere (e.g. Manage Businesses) —
  /// refetch so the nav bar's business pill/switcher list picks up the new
  /// business (and its just-persisted selectedBusinessId) right away.
  void _onBusinessProfileUpdated() {
    if (!mounted) return;
    _refreshProfile();
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
          final logoUrl = (entry['logoUrl'] as String?)?.trim() ?? '';
          return <String, dynamic>{
            'id': (entry['id'] as String?)?.trim() ?? '',
            'name': name,
            'category': category,
            'placeOfBusiness': place,
            'logoUrl': logoUrl,
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

    // Firestore document IDs are case-sensitive, so the business ID must be
    // extracted from the original-case string — never from a lowercased
    // copy, or a business like "r6vNvUx4..." gets written back as
    // "r6vnvux4...", a document that doesn't exist, and every subsequent
    // read/write for that account is denied by security rules. (Same bug
    // class as ContextFirestoreRepository.resolveContextFromData.)
    final requestedBusinessId = nextContext.contains(':')
        ? nextContext.split(':').sublist(1).join(':').trim()
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

    // Set the optimistic override synchronously, before anything else, so
    // currentBusinessIdProvider — and every repository/screen watching it —
    // re-scopes to the new business immediately. Drift is still the source
    // of truth for every screen: if this business has never synced to this
    // device before, its local tables are momentarily empty and screens show
    // their normal loading/skeleton state (the same as any cold start) while
    // the automatically-restarted syncServiceProvider pulls it in.
    if (selectedBusinessId != null && selectedBusinessId.isNotEmpty) {
      ref.read(pendingBusinessIdOverrideProvider.notifier).state =
          selectedBusinessId;
    }

    final targetName = selectedBusinessId == null
        ? null
        : _businessLabelForId(businesses, selectedBusinessId);
    _showSwitchingBusinessDialog(targetName);

    try {
      // Cache it too so a cold start (app fully closed and reopened) also
      // resolves it instantly, without waiting on Firestore.
      if (selectedBusinessId != null && selectedBusinessId.isNotEmpty) {
        await RoleCacheService.saveBusinessId(user.uid, selectedBusinessId);
      }

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'defaultContext': resolvedNextContext,
        'defaultAccountType': 'business',
        'selectedBusinessId': selectedBusinessId,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // DashboardScreen's Hero card (business name/logo/plan) is fetched
      // through its own 24h-TTL-cached profile fetch, not through
      // currentBusinessIdProvider — so without this it keeps showing the
      // previous business until the cache happens to expire. Both
      // DashboardScreen and this page already listen for this notifier (to
      // pick up edits made in Manage Businesses); reuse it here so a switch
      // forces the same immediate refetch.
      BusinessProfileService.notifyUpdated();

      // No manual pre-pull here anymore: syncServiceProvider already
      // watches currentBusinessIdProvider and auto-starts a fresh
      // SyncService (which itself calls syncNow() on start) the moment the
      // businessId changes — see core/providers/sync_provider.dart. Blocking
      // navigation on a *second*, redundant full pull (capped at 12s) was
      // why switching businesses felt as slow as it did; the destination
      // screens already render from Drift reactively and fill in as the
      // background sync lands, the same way they do on a normal cold start.
    } finally {
      _dismissSwitchingBusinessDialog();
    }

    if (!mounted) return;
    // Deferred one frame: popping the "switching…" dialog above schedules
    // element teardown that Flutter finishes at the end of this frame.
    // Navigating immediately (context.go tears down/rebuilds the whole page
    // subtree) can race that teardown and trip the framework's
    // '_dependents.isEmpty' assertion — the same class of bug documented in
    // ManageBusinessesScreen's save handler. Waiting a frame lets the
    // dialog's elements finish unmounting first.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _refreshProfile();
      final route = DefaultContextRoutingService.routeFromContextValue(
        resolvedNextContext,
      );
      context.go(route);
    });
  }

  String? _businessLabelForId(
    List<Map<String, dynamic>> businesses,
    String id,
  ) {
    for (final business in businesses) {
      if (business['id'] == id) {
        final name = (business['name'] as String?)?.trim();
        return name != null && name.isNotEmpty ? name : null;
      }
    }
    return null;
  }

  bool _switchingDialogOpen = false;
  // Captured from the dialog's own builder so it can be dismissed without
  // going through this State's `context`/`mounted`. If something elsewhere
  // in the switch (e.g. a router redirect reacting to the RBAC reload that
  // follows a business switch) unmounts MainShellPage while the Firestore
  // write is still in flight, `Navigator.of(context, ...)` would no longer
  // be safe to call and the old `if (!mounted) return;` guard silently
  // skipped the pop — leaving the "Switching to X…" dialog stuck on screen
  // forever, since it lives on the root Navigator, independent of this
  // page's own lifecycle. The dialog's NavigatorState stays valid as long
  // as the dialog itself is still mounted, so use that instead.
  NavigatorState? _switchingDialogNavigator;

  void _showSwitchingBusinessDialog(String? businessName) {
    if (!mounted) return;
    _switchingDialogOpen = true;
    final label = businessName == null
        ? _tr('Switching business…', 'Inabadilisha biashara…')
        : _tr(
            'Switching to $businessName…',
            'Inabadilisha kwenda $businessName…',
          );
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        _switchingDialogNavigator = Navigator.of(
          dialogContext,
          rootNavigator: true,
        );
        return PopScope(
          canPop: false,
          child: AlertDialog(
            content: Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 16),
                Expanded(child: Text(label)),
              ],
            ),
          ),
        );
      },
    );
  }

  void _dismissSwitchingBusinessDialog() {
    if (!_switchingDialogOpen) return;
    _switchingDialogOpen = false;
    _switchingDialogNavigator?.pop();
    _switchingDialogNavigator = null;
  }

  static Future<Map<String, dynamic>?> _fetchUserProfile(User? user) async {
    if (user == null) return null;
    try {
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

      await BusinessProfileService.cacheProfile(user.uid, profile);
      return profile;
    } catch (_) {
      return BusinessProfileService.loadCachedProfile(user.uid);
    }
  }

  static Future<void> _closeNavigationPanelThenNavigate(
    BuildContext sheetContext,
    BuildContext rootContext,
    String route,
  ) async {
    Navigator.of(sheetContext).pop();
    // Deferred one frame so the dialog's own teardown finishes first —
    // navigating in the same frame it starts popping can trip the
    // framework's element-lifecycle assertions.
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
    PlanStatus? planStatus,
  }) async {
    final reduceMotion = AppMotion.reduceMotion(context);
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: _tr('Close navigation menu', 'Funga menyu ya urambazaji'),
      // No scrim: the strip to the right of the panel needs to stay at full
      // brightness for the selected item's flush edge to read as fusing
      // into it, not into a dimmed backdrop.
      barrierColor: Colors.transparent,
      transitionDuration: reduceMotion ? Duration.zero : AppMotion.quick,
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        if (reduceMotion) return child;
        final curved = CurvedAnimation(
          parent: animation,
          curve: AppMotion.enterCurve,
          reverseCurve: AppMotion.exitCurve,
        );
        final fade = Tween<double>(begin: 0, end: 1).animate(curved);
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(-0.12, 0),
            end: Offset.zero,
          ).animate(curved),
          child: FadeTransition(opacity: fade, child: child),
        );
      },
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return Stack(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: SafeArea(
                bottom: false,
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                  child: RepaintBoundary(
                    child: Container(
                      width: MediaQuery.of(dialogContext).size.width * 0.72,
                      decoration: BoxDecoration(
                        // Same blue as the top header card on the invoice
                        // (sales) and customer list screens (DarkHeaderShell).
                        color: AppColors.navyPrimary,
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(24),
                          bottomRight: Radius.circular(24),
                        ),
                        // No border here on purpose: it used to trace the
                        // panel's entire outline, including its right edge —
                        // exactly where the active pill's flush run is
                        // trying to fuse into the content beside it. Right
                        // next to that stark white pill, even this faint
                        // white-alpha line read as a visible seam.
                        boxShadow: AppTheme.modalShadow,
                      ),
                      child: Column(
                        children: [
                          // Profile header — no fill of its own now; the panel's
                          // gradient flows underneath it continuously so header
                          // and nav list read as one seamless floating surface.
                          SafeArea(
                            bottom: false,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                20,
                                18,
                                16,
                                18,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: 0.08,
                                          ),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white.withValues(
                                              alpha: 0.16,
                                            ),
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            profile.fullName.isNotEmpty
                                                ? profile.fullName
                                                      .trim()[0]
                                                      .toUpperCase()
                                                : 'M',
                                            style: GoogleFonts.dmSans(
                                              color: Colors.white,
                                              fontSize: 17,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 13),
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
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                decoration: TextDecoration.none,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              profile.contactLine,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.dmSans(
                                                color: Colors.white.withValues(
                                                  alpha: 0.56,
                                                ),
                                                fontSize: 12,
                                                fontWeight: FontWeight.w400,
                                                decoration: TextDecoration.none,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () =>
                                            Navigator.of(dialogContext).pop(),
                                        icon: Icon(
                                          Icons.close_rounded,
                                          color: Colors.white.withValues(
                                            alpha: 0.5,
                                          ),
                                          size: 20,
                                        ),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  if (ps.isOwner)
                                    _HeaderTag(
                                      icon: Icons.stars_rounded,
                                      label: planStatus != null
                                          ? (_isSwahili
                                                ? planStatus.tierLabelSw
                                                : planStatus.tierLabel)
                                          : _tr('Starter', 'Bure'),
                                    )
                                  else if (member != null)
                                    _HeaderTag(
                                      icon: Icons.badge_outlined,
                                      label: member.role.label,
                                    ),
                                ],
                              ),
                            ),
                          ),
                          // Navigation items — full-bleed to the panel's own right
                          // edge; selected item's pill/notch are painted flush
                          // against it (see _DrawerItemLight).
                          Expanded(
                            child: ListView(
                              // No right padding: _DrawerItemLight owns its
                              // own trailing inset so the selected row's
                              // pill can animate flush to the panel's true
                              // right edge.
                              padding: const EdgeInsets.fromLTRB(12, 8, 0, 8),
                              children: [
                                _DrawerItemLight(
                                  icon: Icons.dashboard_rounded,
                                  iconColor: AppColors.secondary,
                                  label: _tr('Dashboard', 'Dashibodi'),
                                  semanticsLabel: _tr(
                                    'Dashboard',
                                    'Dashibodi, muhtasari wa biashara',
                                  ),
                                  selected: _isSelected(
                                    location,
                                    AppRouter.dashboardPath,
                                  ),
                                  onTap: () =>
                                      _closeNavigationPanelThenNavigate(
                                        dialogContext,
                                        context,
                                        AppRouter.dashboardPath,
                                      ),
                                ),
                                if (ps.canViewSales ||
                                    ps.canViewInventory ||
                                    ps.canViewCustomers)
                                  if (ps.canViewSales)
                                    _DrawerItemLight(
                                      icon: Icons.receipt_long_rounded,
                                      iconColor: AppColors.secondary,
                                      label: _tr('Sales', 'Tuma ankara'),
                                      semanticsLabel: _tr(
                                        'Sales and invoices',
                                        'Tuma ankara, mauzo na ankara',
                                      ),
                                      selected: _isSelected(
                                        location,
                                        AppRouter.salesPath,
                                      ),
                                      onTap: () =>
                                          _closeNavigationPanelThenNavigate(
                                            dialogContext,
                                            context,
                                            AppRouter.salesPath,
                                          ),
                                    ),
                                if (ps.canViewInventory)
                                  _DrawerItemLight(
                                    icon: Icons.inventory_2_rounded,
                                    iconColor: AppColors.secondary,
                                    label: _tr('My Stock', 'Bidhaa zangu'),
                                    semanticsLabel: _tr(
                                      'My stock and inventory',
                                      'Bidhaa zangu, usimamizi wa bidhaaa',
                                    ),
                                    selected: _isSelected(
                                      location,
                                      AppRouter.inventoryPath,
                                    ),
                                    onTap: () =>
                                        _closeNavigationPanelThenNavigate(
                                          dialogContext,
                                          context,
                                          AppRouter.inventoryPath,
                                        ),
                                  ),
                                if (ps.canViewCustomers)
                                  _DrawerItemLight(
                                    icon: Icons.people_alt_rounded,
                                    iconColor: AppColors.secondary,
                                    label: _tr('My Customers', 'Wateja wangu'),
                                    semanticsLabel: _tr(
                                      'My customers',
                                      'Wateja wangu, usimamizi wa wateja',
                                    ),
                                    selected: _isSelected(
                                      location,
                                      AppRouter.crmPath,
                                    ),
                                    onTap: () =>
                                        _closeNavigationPanelThenNavigate(
                                          dialogContext,
                                          context,
                                          AppRouter.crmPath,
                                        ),
                                  ),
                                ValueListenableBuilder<int>(
                                  valueListenable:
                                      NotificationService.unreadCountNotifier,
                                  builder: (context, unreadCount, _) =>
                                      _DrawerItemLight(
                                        icon: Icons.notifications_outlined,
                                        iconColor: AppColors.secondary,
                                        label: _tr('Notifications', 'Arifa'),
                                        semanticsLabel: unreadCount > 0
                                            ? _tr(
                                                'Notifications, $unreadCount unread',
                                                'Arifa, $unreadCount hazijasomwa',
                                              )
                                            : _tr('Notifications', 'Arifa'),
                                        trailingBadgeCount: unreadCount,
                                        selected: _isSelected(
                                          location,
                                          AppRouter.notificationsPath,
                                        ),
                                        onTap: () =>
                                            _closeNavigationPanelThenNavigate(
                                              dialogContext,
                                              context,
                                              AppRouter.notificationsPath,
                                            ),
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
                                    label: _tr('Debts', 'Madeni'),
                                    semanticsLabel: _tr(
                                      'Debt tracking',
                                      'Madeni, ufuatiliaji wa madeni',
                                    ),
                                    selected: _isSelected(
                                      location,
                                      AppRouter.debtPath,
                                    ),
                                    onTap: () =>
                                        _closeNavigationPanelThenNavigate(
                                          dialogContext,
                                          context,
                                          AppRouter.debtPath,
                                        ),
                                  ),
                                if (ps.canManageExpenses)
                                  _DrawerItemLight(
                                    icon: Icons.payments_outlined,
                                    iconColor: AppColors.secondary,
                                    label: _tr('My Expenses', 'Gharama zangu'),
                                    semanticsLabel: _tr(
                                      'My expenses',
                                      'Gharama zangu, usimamizi wa matumizi',
                                    ),
                                    selected: _isSelected(
                                      location,
                                      AppRouter.expensesPath,
                                    ),
                                    onTap: () =>
                                        _closeNavigationPanelThenNavigate(
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
                                      'Cash Flow',
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
                                    onTap: () =>
                                        _closeNavigationPanelThenNavigate(
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
                                      'Financial Reports',
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
                                    onTap: () =>
                                        _closeNavigationPanelThenNavigate(
                                          dialogContext,
                                          context,
                                          AppRouter.reportsPath,
                                        ),
                                  ),
                                if (ps.canManageTeam) ...[
                                  _DrawerSectionLabel(
                                    label: _tr('TEAM', 'TIMU'),
                                  ),
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
                                    onTap: () =>
                                        _closeNavigationPanelThenNavigate(
                                          dialogContext,
                                          context,
                                          AppRouter.teamPath,
                                        ),
                                  ),
                                ],
                                _DrawerSectionLabel(
                                  label: _tr('SETTINGS', 'MIPANGILIO'),
                                ),
                                if (ps.isOwner)
                                  _DrawerItemLight(
                                    icon: Icons.storefront_rounded,
                                    iconColor: AppColors.secondary,
                                    label: _tr(
                                      'Manage Businesses',
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
                                    onTap: () =>
                                        _closeNavigationPanelThenNavigate(
                                          dialogContext,
                                          context,
                                          AppRouter.businessesPath,
                                        ),
                                  ),
                                // Reachable by every role, owner and team
                                // member alike — SettingsScreen itself hides
                                // the owner-only sections (plan/subscription,
                                // data export, audit log) for team members,
                                // but everyone needs it to edit their own
                                // profile or sign out.
                                _DrawerItemLight(
                                  icon: Icons.settings_rounded,
                                  iconColor: AppColors.secondary,
                                  label: _tr('Settings', 'Mipangilio'),
                                  semanticsLabel: _tr(
                                    'App settings',
                                    'Mipangilio ya programu',
                                  ),
                                  selected: _isSelected(
                                    location,
                                    AppRouter.settingsPath,
                                  ),
                                  onTap: () =>
                                      _closeNavigationPanelThenNavigate(
                                        dialogContext,
                                        context,
                                        AppRouter.settingsPath,
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
              ),
            ),
          ],
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

  static const _homeKey = 'home';
  // Default occupants of the 3 customizable slots, in order, before the
  // user long-presses to swap any of them out.
  static const _defaultSlotOrder = ['sales', 'inventory', 'customers'];

  /// Every screen the current role is allowed to see, available to be
  /// assigned to a nav slot. Order here is the order shown in the picker.
  List<_NavDestination> _fullNavCatalog(PermissionService ps) {
    return [
      if (ps.canViewSales)
        _NavDestination(
          key: 'sales',
          route: AppRouter.salesPath,
          label: _tr('Invoices', 'Ankara'),
          icon: Icons.receipt_outlined,
          activeIcon: Icons.receipt_rounded,
        ),
      if (ps.canViewInventory)
        _NavDestination(
          key: 'inventory',
          route: AppRouter.inventoryPath,
          label: _tr('Stock', 'Bidhaa'),
          icon: Icons.inventory_2_outlined,
          activeIcon: Icons.inventory_2_rounded,
        ),
      if (ps.canViewCustomers)
        _NavDestination(
          key: 'customers',
          route: AppRouter.crmPath,
          label: _tr('Clients', 'Wateja'),
          icon: Icons.people_outline_rounded,
          activeIcon: Icons.people_rounded,
        ),
      if (ps.canViewDebt)
        _NavDestination(
          key: 'debt',
          route: AppRouter.debtPath,
          label: _tr('Debt', 'Madeni'),
          icon: Icons.account_balance_outlined,
          activeIcon: Icons.account_balance_rounded,
        ),
      if (ps.canManageExpenses)
        _NavDestination(
          key: 'expenses',
          route: AppRouter.expensesPath,
          label: _tr('Expenses', 'Gharama'),
          icon: Icons.payments_outlined,
          activeIcon: Icons.payments_rounded,
        ),
      if (ps.canViewCashFlow)
        _NavDestination(
          key: 'cashflow',
          route: AppRouter.cashFlowPath,
          label: _tr('Cash Flow', 'Mtiririko'),
          icon: Icons.account_balance_wallet_outlined,
          activeIcon: Icons.account_balance_wallet_rounded,
        ),
      if (ps.canViewFinancialReports)
        _NavDestination(
          key: 'reports',
          route: AppRouter.reportsPath,
          label: _tr('Reports', 'Ripoti'),
          icon: Icons.bar_chart_outlined,
          activeIcon: Icons.bar_chart_rounded,
        ),
    ];
  }

  List<_NavDestination> _buildNavDestinations(PermissionService ps) {
    final catalog = _fullNavCatalog(ps);
    final catalogByKey = {for (final d in catalog) d.key: d};

    final slots = <_NavDestination>[];
    for (var i = 0; i < _defaultSlotOrder.length; i++) {
      final overrideKey = _navSlotOverrides[i];
      final resolvedKey =
          (overrideKey != null && catalogByKey.containsKey(overrideKey))
          ? overrideKey
          : _defaultSlotOrder[i];
      final entry = catalogByKey[resolvedKey];
      // Skip if the resolved screen isn't permitted, or is already used by
      // an earlier slot (guards against a stale override colliding with a
      // freshly-granted default).
      if (entry == null || slots.any((s) => s.key == entry.key)) continue;
      slots.add(entry.withSlotPosition(i));
    }

    return [
      _NavDestination(
        key: _homeKey,
        route: AppRouter.dashboardPath,
        label: _tr('Home', 'Nyumbani'),
        icon: Icons.grid_view_outlined,
        activeIcon: Icons.grid_view_rounded,
      ),
      ...slots,
    ];
  }

  Future<void> _loadNavSlotOverrides() async {
    final prefs = await SharedPreferences.getInstance();
    final loaded = <int, String>{};
    for (var i = 0; i < _defaultSlotOrder.length; i++) {
      final value = prefs.getString('nav_slot_override_$i');
      if (value != null) loaded[i] = value;
    }
    if (!mounted) return;
    setState(() => _navSlotOverrides = loaded);
  }

  /// Assigns [newKey] to [slotPosition]. If [newKey] already occupies a
  /// different slot, the two slots swap so no icon is ever duplicated.
  Future<void> _assignNavSlot(int slotPosition, String newKey) async {
    final prefs = await SharedPreferences.getInstance();
    final updated = Map<int, String>.from(_navSlotOverrides);

    String keyAt(int i) =>
        updated[i] ??
        (i < _defaultSlotOrder.length ? _defaultSlotOrder[i] : '');
    final currentKeyAtSlot = keyAt(slotPosition);

    for (var i = 0; i < _defaultSlotOrder.length; i++) {
      if (i == slotPosition) continue;
      if (keyAt(i) == newKey) {
        updated[i] = currentKeyAtSlot;
        await prefs.setString('nav_slot_override_$i', currentKeyAtSlot);
      }
    }
    updated[slotPosition] = newKey;
    await prefs.setString('nav_slot_override_$slotPosition', newKey);

    if (!mounted) return;
    setState(() => _navSlotOverrides = updated);
  }

  // ── Hold-and-drag nav slot picker ───────────────────────────────────────
  // Long-press a customizable icon, then without lifting the finger drag
  // upward through a strip of alternate screens that fans up from it
  // (dragging sideways or releasing without moving up cancels — same idea
  // as a slide-to-cancel voice-note recorder). One continuous gesture, no
  // second tap, no sheet.
  static const double _navPickItemHeight = 46;
  static const double _navPickStripWidth = 76;
  static const double _navPickCancelDx = 56;
  static const double _navPickCircleSize = 28;
  static const double _navPickCircleSizeSelected = 34;
  // How far the finger must drag up past the origin before the nearest
  // (index 0) option starts highlighting, so the strip clears the held
  // icon and its label first.
  static const double _navPickOriginClearance = 20;
  // One per customizable slot — pins the picker overlay to that exact
  // icon's on-screen position via CompositedTransformFollower, which is
  // immune to the manual-coordinate-math bugs an absolute Y calculation
  // is prone to (SafeArea, extendBody, status bar, etc.).
  final List<LayerLink> _navSlotLayerLinks = List.generate(
    3,
    (_) => LayerLink(),
  );

  List<_NavDestination> _navPickCatalog = [];
  int? _navPickSlotPosition;
  String? _navPickCurrentKey;
  double _navPickOriginX = 0;
  double _navPickOriginY = 0;
  OverlayEntry? _navPickOverlayEntry;
  bool _navPickWasCancelled = false;
  final ValueNotifier<int> _navPickHighlightIndex = ValueNotifier<int>(-1);

  void _startNavPick(
    BuildContext context,
    PermissionService ps,
    _NavDestination destination,
    Offset globalPosition,
  ) {
    final slotPosition = destination.slotPosition;
    if (slotPosition == null) return;
    // Only offer screens that are not already visible in the bottom bar.
    // This keeps the picker short and prevents the current/other slot icons
    // from being presented as if they were new choices.
    final occupiedKeys = _buildNavDestinations(ps).map((d) => d.key).toSet();
    final catalog = _fullNavCatalog(
      ps,
    ).where((candidate) => !occupiedKeys.contains(candidate.key)).toList();
    if (catalog.isEmpty) return;
    HapticFeedback.mediumImpact();

    _navPickCatalog = catalog;
    _navPickSlotPosition = slotPosition;
    _navPickCurrentKey = destination.key;
    _navPickOriginX = globalPosition.dx;
    _navPickOriginY = globalPosition.dy;
    _navPickWasCancelled = false;
    _navPickHighlightIndex.value = -1;

    _navPickOverlayEntry = OverlayEntry(builder: _buildNavPickOverlay);
    Overlay.of(context, rootOverlay: true).insert(_navPickOverlayEntry!);
  }

  void _updateNavPick(Offset globalPosition) {
    if (_navPickOverlayEntry == null || _navPickSlotPosition == null) return;
    final dx = (globalPosition.dx - _navPickOriginX).abs();
    // How far up the finger has dragged relative to where the long-press
    // started — self-contained, so it can't be thrown off by whatever
    // coordinate space globalPosition happens to be reported in.
    final draggedUp = _navPickOriginY - globalPosition.dy;
    // Crossing the horizontal threshold cancels the whole gesture. Moving
    // back over the strip must not accidentally assign a destination.
    if (dx > _navPickCancelDx) {
      _navPickWasCancelled = true;
    }
    var nextIndex = -1;
    if (!_navPickWasCancelled && draggedUp > _navPickOriginClearance) {
      final distanceIntoStrip = draggedUp - _navPickOriginClearance;
      nextIndex = (distanceIntoStrip / _navPickItemHeight).floor().clamp(
        0,
        _navPickCatalog.length - 1,
      );
    }
    if (nextIndex != _navPickHighlightIndex.value) {
      // Entering an option gets a tick; cancelling or returning to the dead
      // zone stays quiet.
      if (nextIndex >= 0) HapticFeedback.selectionClick();
      _navPickHighlightIndex.value = nextIndex;
    }
  }

  void _endNavPick() {
    final slotPosition = _navPickSlotPosition;
    final index = _navPickHighlightIndex.value;
    final catalog = _navPickCatalog;
    final currentKey = _navPickCurrentKey;
    final wasCancelled = _navPickWasCancelled;
    _removeNavPickOverlay();
    if (wasCancelled ||
        slotPosition == null ||
        index < 0 ||
        index >= catalog.length) {
      return;
    }
    final chosen = catalog[index];
    if (chosen.key == currentKey) return;
    _assignNavSlot(slotPosition, chosen.key);
  }

  void _cancelNavPick() => _removeNavPickOverlay();

  void _removeNavPickOverlay() {
    _navPickOverlayEntry?.remove();
    _navPickOverlayEntry = null;
    _navPickSlotPosition = null;
    _navPickCatalog = [];
    _navPickWasCancelled = false;
  }

  // Transparent overlay: only the floating destination icons and labels are
  // painted above the held navbar slot; there is no strip or page scrim.
  Widget _buildNavPickOverlay(BuildContext overlayContext) {
    final slotPosition = _navPickSlotPosition;
    if (slotPosition == null) return const SizedBox.shrink();
    return IgnorePointer(
      child: Align(
        alignment: Alignment.topLeft,
        child: CompositedTransformFollower(
          link: _navSlotLayerLinks[slotPosition],
          targetAnchor: Alignment.topCenter,
          followerAnchor: Alignment.bottomCenter,
          offset: const Offset(0, -14),
          showWhenUnlinked: false,
          child: SizedBox(
            width: _navPickStripWidth,
            child: ValueListenableBuilder<int>(
              valueListenable: _navPickHighlightIndex,
              builder: (_, highlighted, _) => Column(
                mainAxisSize: MainAxisSize.min,
                // Rendered top-to-bottom in the strip, but index 0 (the
                // catalog entry nearest the held icon) is the *last* child so
                // it sits at the bottom, nearest the finger's starting point.
                children: List.generate(_navPickCatalog.length, (i) {
                  final catalogIndex = _navPickCatalog.length - 1 - i;
                  final destination = _navPickCatalog[catalogIndex];
                  final isSelected = catalogIndex == highlighted;
                  final isCurrent = destination.key == _navPickCurrentKey;
                  final circleSize = isSelected
                      ? _navPickCircleSizeSelected
                      : _navPickCircleSize;
                  return SizedBox(
                    height: _navPickItemHeight,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 140),
                          curve: Curves.easeOut,
                          width: circleSize,
                          height: circleSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? AppColors.yellowBrand
                                : AppColors.navyPrimary,
                            border: isCurrent
                                ? Border.all(color: Colors.white, width: 2)
                                : null,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.28),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Icon(
                            destination.activeIcon,
                            size: isSelected ? 18 : 14,
                            color: isSelected
                                ? AppColors.navyPrimary
                                : Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 140),
                          style: GoogleFonts.dmSans(
                            fontSize: 9,
                            height: 1,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected
                                ? AppColors.tealAccent
                                : Colors.white,
                            shadows: const [
                              Shadow(color: Colors.black54, blurRadius: 6),
                            ],
                          ),
                          child: Text(
                            destination.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
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
    ref.watch(
      notificationAggregatorActivatorProvider,
    ); // starts alert detection (low stock, overdue debt/invoice, sync issues)
    ref.watch(
      pushTokenRegistrarProvider,
    ); // registers this device's FCM token for admin-broadcast push notifications
    // Open the relevant screen when the user taps an admin-broadcast push
    // notification that carries a deep link.
    ref.listen<AsyncValue<String>>(pushNotificationRouteProvider, (prev, next) {
      final route = next.valueOrNull;
      if (route != null && route.isNotEmpty) context.go(route);
    });
    // Drive the Dynamic Island Live Activity whenever the sync state changes.
    ref.listen<SyncState>(syncStateProvider, (prev, next) {
      if (prev == next) return;
      final bizName = _currentBusinessName;
      _liveActivity.onSyncStateChanged(next, businessName: bizName);
    });
    // The header pill reflects actual device connectivity, not the last
    // Firestore sync outcome — a transient sync error (SyncState.error)
    // otherwise left this stuck showing "Offline" even with a live
    // connection, since nothing retries a failed sync until the next real
    // connectivity change event. Sync-specific issues surface separately
    // via SyncStatusBanner.
    final isOnline = ref.watch(isOnlineProvider);
    // Reassure the user the moment connectivity flips either way — the
    // header pill's red/green dot is easy to miss, so a real message says
    // it plainly: nothing is lost offline, and reconnecting kicks off a
    // real sync rather than leaving them guessing.
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

    // Live plan status — drives the sidebar plan tag and the congrats popup
    // below when an admin activates an upgrade.
    final planStatus = ref.watch(
      planStatusProvider.select((a) => a.valueOrNull),
    );
    ref.listen<AsyncValue<PlanStatus>>(planStatusProvider, (prev, next) {
      final status = next.valueOrNull;
      if (status == null) return;
      _planActivationWatcher.checkAndUpdate(status.tier).then((previousTier) {
        if (!context.mounted) return;
        // No baseline yet (first load on this device) — just seed it.
        if (previousTier == null) return;
        // Only celebrate genuine upgrades, not no-ops or expiry downgrades.
        if (_planTierRank(status.tier) <= _planTierRank(previousTier)) return;
        PlanActivatedDialog.show(
          context,
          tier: status.tier,
          defs: status.definitions,
        );
      });
    });

    return PopScope(
      // Tab routes (dashboard, sales, inventory, …) are top-level siblings
      // navigated between via context.go(), which replaces the current
      // location instead of pushing — so there's never a previous route for
      // the system back button to pop to. Without this, back on any
      // non-Home tab fell straight through to closing the app. We intercept
      // it ourselves: first hop back to Home, then require a second press
      // to actually exit (mirrors the double-back-to-exit pattern most
      // Android apps use).
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (location != AppRoutes.dashboard) {
          context.go(AppRoutes.dashboard);
          return;
        }
        final now = DateTime.now();
        final last = _lastBackPressAt;
        if (last != null && now.difference(last) < const Duration(seconds: 2)) {
          SystemNavigator.pop();
          return;
        }
        _lastBackPressAt = now;
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              content: Text(
                _tr('Press back again to exit', 'Bonyeza nyuma tena kutoka'),
              ),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
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
                          // Notifications moved into the nav panel itself (see
                          // _openNavigationPanel) — this small pulsing dot is
                          // the only thing left in the top bar, just enough to
                          // say "there's something waiting for you in there".
                          _MenuToggleButton(
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
                              planStatus: planStatus,
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: _FinanceContextSwitcher(
                                  selectedContext: selectedContext,
                                  canSwitch: canSwitch,
                                  businesses: businesses,
                                  isOnline: isOnline,
                                  onChanged: _switchFinanceContext,
                                  onManageBusinesses: () async {
                                    await context.push(
                                      AppRouter.businessesPath,
                                    );
                                    _refreshProfile();
                                  },
                                ),
                              ),
                            ],
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
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: List.generate(destinations.length, (index) {
                            final destination = destinations[index];
                            final isSelected = index == currentIndex;
                            final isCustomizable =
                                destination.slotPosition != null;
                            return _buildBottomNavItem(
                              context,
                              destination,
                              isSelected,
                              index,
                              onLongPressStart: !isCustomizable
                                  ? null
                                  : (details) => _startNavPick(
                                      context,
                                      ps,
                                      destination,
                                      details.globalPosition,
                                    ),
                              onLongPressMoveUpdate: !isCustomizable
                                  ? null
                                  : (details) =>
                                        _updateNavPick(details.globalPosition),
                              onLongPressEnd: !isCustomizable
                                  ? null
                                  : (_) => _endNavPick(),
                              onLongPressCancel: !isCustomizable
                                  ? null
                                  : _cancelNavPick,
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
      ),
    );
  }

  Widget _buildBottomNavItem(
    BuildContext context,
    _NavDestination destination,
    bool isSelected,
    int index, {
    GestureLongPressStartCallback? onLongPressStart,
    GestureLongPressMoveUpdateCallback? onLongPressMoveUpdate,
    GestureLongPressEndCallback? onLongPressEnd,
    VoidCallback? onLongPressCancel,
  }) {
    final reduceMotion = AppMotion.reduceMotion(context);
    final navItem = GestureDetector(
      onTap: () => context.go(destination.route),
      onLongPressStart: onLongPressStart,
      onLongPressMoveUpdate: onLongPressMoveUpdate,
      onLongPressEnd: onLongPressEnd,
      onLongPressCancel: onLongPressCancel,
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
                  duration: reduceMotion ? Duration.zero : AppMotion.quick,
                  transitionBuilder: (child, animation) => reduceMotion
                      ? child
                      : ScaleTransition(scale: animation, child: child),
                  child: Icon(
                    isSelected ? destination.activeIcon : destination.icon,
                    key: ValueKey<bool>(isSelected),
                    color: isSelected ? AppColors.yellowBrand : Colors.white54,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 3),
                AnimatedDefaultTextStyle(
                  duration: reduceMotion ? Duration.zero : AppMotion.quick,
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

    final slotPosition = destination.slotPosition;
    if (slotPosition == null) return navItem;
    return CompositedTransformTarget(
      link: _navSlotLayerLinks[slotPosition],
      child: navItem,
    );
  }
}

/// Orders tiers so an upgrade (rank increases) can be told apart from a
/// no-op or an expiry-driven revert to Starter (rank decreases/unchanged).
int _planTierRank(PlanTier tier) {
  switch (tier) {
    case PlanTier.starter:
      return 0;
    case PlanTier.growth:
      return 1;
    case PlanTier.business:
      return 2;
    case PlanTier.enterprise:
      return 3;
    case PlanTier.lifetime:
      return 4;
  }
}

/// Remembers, per device, the last plan tier the user has been shown —
/// so the congrats popup only fires once per activation and never on a
/// fresh install where the account may already be on a paid tier.
class _PlanActivationWatcher {
  static const _prefsKey = 'last_seen_plan_tier';

  PlanTier? _cached;
  bool _loaded = false;

  /// Compares [tier] against the last recorded tier and persists [tier] as
  /// the new baseline. Returns the previous tier, or null if this device
  /// has no baseline yet (the caller should not celebrate in that case).
  Future<PlanTier?> checkAndUpdate(PlanTier tier) async {
    if (!_loaded) {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_prefsKey);
      _cached = stored != null ? PlanTierX.fromString(stored) : null;
      _loaded = true;
    }
    final previous = _cached;
    if (previous != tier) {
      _cached = tier;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, tier.name);
    }
    return previous;
  }
}

class _NavDestination {
  final String key;
  final String route;
  final String label;
  final IconData icon;
  final IconData activeIcon;
  // Which of the 3 customizable nav slots this occupies; null for Home,
  // which is fixed and not long-press-editable.
  final int? slotPosition;

  const _NavDestination({
    required this.key,
    required this.route,
    required this.label,
    required this.icon,
    required this.activeIcon,
    this.slotPosition,
  });

  _NavDestination withSlotPosition(int position) => _NavDestination(
    key: key,
    route: route,
    label: label,
    icon: icon,
    activeIcon: activeIcon,
    slotPosition: position,
  );
}

/// The hamburger menu toggle, with a small pulsing dot at its top-right
/// corner whenever there's an unread notification waiting in the nav panel.
class _MenuToggleButton extends StatelessWidget {
  final String tooltip;
  final VoidCallback onPressed;

  const _MenuToggleButton({required this.tooltip, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: NotificationService.unreadCountNotifier,
      builder: (context, unreadCount, _) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: const Icon(
                Icons.menu_rounded,
                color: AppColors.secondary,
                size: 28,
              ),
              tooltip: tooltip,
              onPressed: onPressed,
            ),
            if (unreadCount > 0)
              const Positioned(top: 2, right: 2, child: _PulsingBellIcon()),
          ],
        );
      },
    );
  }
}

/// Small floating bell icon that gently breathes (scale + fade) in a loop —
/// just enough to say "there's a notification waiting for you in there"
/// without duplicating the full Notifications entry point, which lives
/// inside the nav panel this button opens.
class _PulsingBellIcon extends StatefulWidget {
  const _PulsingBellIcon();

  @override
  State<_PulsingBellIcon> createState() => _PulsingBellIconState();
}

class _PulsingBellIconState extends State<_PulsingBellIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = AppMotion.reduceMotion(context);
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) {
          final t = reduceMotion ? 1.0 : _ctrl.value;
          return Opacity(opacity: 0.55 + t * 0.45, child: child);
        },
        child: Icon(
          Icons.notifications_rounded,
          size: 14,
          color: AppColors.yellowBrand,
          shadows: [
            Shadow(
              color: AppColors.yellowBrand.withValues(alpha: 0.5),
              blurRadius: 4,
            ),
          ],
        ),
      ),
    );
  }
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

    // The sheet returns the tapped business id (or '__manage__') instead of
    // acting immediately inside the tap handler. Calling onChanged (which
    // writes to Firestore and can pop up the "switching…" dialog) or
    // onManageBusinesses while this sheet is still mid-pop races its own
    // element teardown against that new work — the same '_dependents.isEmpty'
    // class of crash documented elsewhere in this file. Waiting for
    // showAppSheet's Future to resolve guarantees the sheet is fully gone
    // first.
    final selection = await showAppSheet<String>(
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
                const SizedBox(height: 12),
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
                        onTap: () => Navigator.of(
                          sheetContext,
                        ).pop(business['id'] as String),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        Navigator.of(sheetContext).pop(_manageBusinessesTag),
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

    if (selection == null || selection.isEmpty) return;
    if (selection == _manageBusinessesTag) {
      onManageBusinesses();
    } else {
      onChanged('business:$selection');
    }
  }

  static const _manageBusinessesTag = '__manage_businesses__';

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
    // Fall back to the first business on file so the pill always shows a
    // real business name instead of the generic "Business"/"Biashara"
    // placeholder while the selection is still resolving.
    final displayBusiness =
        selectedBusiness ?? (businesses.isNotEmpty ? businesses.first : null);
    final rawName = (displayBusiness?['name'] as String?)?.trim() ?? '';
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
            // No logo/avatar, no chevron — just the business name, always in
            // the same navy the menu toggle button on the left uses.
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 130),
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.dmSans(
                  color: AppColors.secondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ),
        // Online is the default, unremarkable state — nothing to show.
        // Offline is the one worth flagging, so only it gets a badge.
        if (!isOnline)
          Positioned(
            top: -3,
            right: -3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Text(
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

class _HeaderTag extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeaderTag({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white.withValues(alpha: 0.85)),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.dmSans(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
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
  final int trailingBadgeCount;

  const _DrawerItemLight({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.semanticsLabel,
    required this.iconColor,
    this.selected = false,
    this.trailingBadgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticsLabel,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 2),
        // Implicit animation driven purely by `selected`: whenever this
        // rebuilds with a different value (e.g. the panel reopening on a
        // new route), the pill/notch and icon+text colors glide to their
        // new state instead of snapping.
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: selected ? 1 : 0),
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          builder: (context, t, _) {
            // Dark-navy-on-white when selected (same navy as the Mali Up
            // card), white-on-transparent-navy otherwise.
            final fg = Color.lerp(Colors.white, AppColors.navyPrimary, t)!;
            // The pill bleeds from a normal 12px inset out to flush (0) with
            // the notch below, is what "grows" the tab into place. Padding
            // can't go negative (RenderPadding asserts on that), so the 1px
            // overshoot past the panel's edge lives in _PillNotchPainter's
            // own geometry instead — see its `overshoot` constant.
            final rightInset = 12 - 12 * t;
            // Selected row also nudges right off the sidebar's own left
            // edge a touch, on top of the ListView's shared 12px inset —
            // it grows toward the panel edge on both sides at once, not
            // just the flush side. This is on the same outer Padding as
            // rightInset, so it moves the pill shape, the icon, and the
            // text together as one unit — none of them shift on their own.
            final leftShift = 10 * t;

            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(25),
                splashColor: (selected ? iconColor : Colors.white).withValues(
                  alpha: 0.12,
                ),
                highlightColor: (selected ? iconColor : Colors.white)
                    .withValues(alpha: 0.06),
                child: Padding(
                  padding: EdgeInsets.only(left: leftShift, right: rightInset),
                  child: SizedBox(
                    // Shorter than before on purpose: capRadius/notchRadius
                    // stay fixed, so a shorter row makes both curves — the
                    // left stadium cap and the concave fillets — a bigger
                    // fraction of the shape, reading as more pronounced.
                    height: 40,
                    // _PillNotchPainter deliberately paints past this box's
                    // own top/bottom (the fillets bleed into the rows
                    // above/below to form the navy pockets) — nothing in
                    // this chain (Material/InkWell/Padding/SizedBox) clips,
                    // and CustomPaint doesn't clip to its own Size by
                    // default, so that overflow renders correctly. It never
                    // affects layout, though: this SizedBox's own height
                    // stays a fixed 40, so neighboring rows never move.
                    child: CustomPaint(
                      painter: _PillNotchPainter(t: t),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 12, right: 16),
                        child: Row(
                          children: [
                            Icon(icon, size: 19, color: fg),
                            const SizedBox(width: 13),
                            Expanded(
                              child: Text(
                                label,
                                style: GoogleFonts.dmSans(
                                  color: fg,
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  fontSize: 14,
                                  letterSpacing: -0.1,
                                ),
                              ),
                            ),
                            if (trailingBadgeCount > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.yellowBrand,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  trailingBadgeCount > 99
                                      ? '99+'
                                      : '$trailingBadgeCount',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.navyPrimary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Paints the selected row as an asymmetric shape: a fully-rounded stadium
/// cap on the free (left) end, and on the panel (right) side, the white
/// rises past its own row — bleeding `notchRadius` above and below it,
/// into the navy that belongs to the rows above/below — before curving
/// back in to meet the row's own top/bottom edges. That's what forms the
/// two navy pockets directly above and below the flush run: the white is
/// taller than the row there, and only recedes back down to the row's own
/// bounds via the fillets, rather than the navy ever being pushed into by
/// a fillet that stays within the row's own height. Fillet size is its own
/// `notchRadius`, independent of the cap's `capRadius`.
///
/// This paints outside the row's own 50px box on purpose — see the note on
/// `_DrawerItemLight` confirming nothing clips it. kappa ≈ 0.5523×radius
/// for the control-point offset, same approximation as the cap.
class _PillNotchPainter extends CustomPainter {
  final double t;
  final double capRadius;
  final double notchRadius;
  static const double _kappa = 0.5522847498;
  // How far past its own laid-out width the flush run/fillets are painted,
  // so they land a hair past the panel's edge rather than exactly on it.
  // CustomPaint doesn't clip to its own Size by default, so this just
  // paints outside the box — no negative Padding involved (RenderPadding
  // asserts against that).
  static const double _overshoot = 1;

  const _PillNotchPainter({
    required this.t,
    // Half the 40px row height exactly — the two-quarter-circle cap
    // construction below only traces a true, fully-rounded semicircle
    // when capRadius == height / 2; anything else leaves it slightly
    // egg-shaped rather than a clean full curve.
    this.capRadius = 20,
    this.notchRadius = 22,
  });

  Path _tabPath(Size size) {
    final w = size.width + _overshoot;
    final h = size.height;
    final cr = capRadius;
    final ck = cr * _kappa;
    final fr = math.min(notchRadius, h * 0.9);
    final fk = fr * _kappa;
    return Path()
      ..moveTo(cr, 0)
      ..lineTo(w - fr, 0) // top edge
      // Concave top-right: the white curves UP into the row above (a navy
      // pocket forms there) rather than rounding out to a point at (w,0).
      ..cubicTo(w - fr + fk, 0, w, -fr + fk, w, -fr)
      ..lineTo(w, h + fr) // flush run, bleeding past both edges
      // Concave bottom-right: the white curves DOWN into the row below.
      ..cubicTo(w, h + fr - fk, w - fr + fk, h, w - fr, h)
      ..lineTo(cr, h) // bottom edge
      ..cubicTo(cr - ck, h, 0, h - cr + ck, 0, h - cr) // bottom-left cap
      ..cubicTo(0, cr - ck, cr - ck, 0, cr, 0) // top-left cap
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0.001) return;
    final path = _tabPath(size);
    canvas.drawShadow(path, Colors.black, 8 * t, false);
    canvas.drawPath(path, Paint()..color = Colors.white.withValues(alpha: t));
  }

  @override
  bool shouldRepaint(covariant _PillNotchPainter oldDelegate) =>
      oldDelegate.t != t ||
      oldDelegate.capRadius != capRadius ||
      oldDelegate.notchRadius != notchRadius;
}

class _DrawerSectionLabel extends StatelessWidget {
  final String label;
  const _DrawerSectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    // Right padding is 4+12 here (not just 4) because the ListView no
    // longer supplies a right inset itself — see _DrawerItemLight, which
    // owns its own animated trailing inset instead.
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 18, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              height: 1,
              color: Colors.white.withValues(alpha: 0.14),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              label,
              style: GoogleFonts.dmSans(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ),
          Expanded(
            child: Divider(
              height: 1,
              color: Colors.white.withValues(alpha: 0.14),
            ),
          ),
        ],
      ),
    );
  }
}

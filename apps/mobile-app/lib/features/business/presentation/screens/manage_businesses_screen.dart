import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../config/routing.dart';
import '../../../../core/services/localization_service.dart';
import '../../../../core/services/lookup_service.dart';
import '../../../../core/services/plan_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_sheet.dart';
import '../../../../shared/widgets/mali_components.dart';
import '../../../../shared/widgets/nav_aware_fab.dart';
import '../../../../shared/widgets/skeleton_widgets.dart';
import '../../../../shared/widgets/smart_skeleton.dart';
import '../../../../shared/widgets/upgrade_sheet.dart';

String _tr(String en, String sw) => LocalizationService.tr(en: en, sw: sw);

class ManageBusinessesScreen extends StatefulWidget {
  const ManageBusinessesScreen({super.key});

  @override
  State<ManageBusinessesScreen> createState() => _ManageBusinessesScreenState();
}

class _ManageBusinessesScreenState extends State<ManageBusinessesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Future<Map<String, dynamic>?> _profileFuture;
  final _searchCtrl = TextEditingController();
  bool _searchExpanded = false;

  List<Map<String, dynamic>> _businessTypes = LookupService.defaultBusinessTypes;
  List<Map<String, String>> _tanzaniaCities = LookupService.defaultTanzaniaCities;
  Map<String, List<String>> _districts = LookupService.defaultDistricts;

  @override
  void initState() {
    super.initState();
    _profileFuture = _loadProfile();
    _loadLookups();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadLookups() async {
    try {
      final results = await Future.wait([
        LookupService.fetchBusinessTypes(),
        LookupService.fetchCities(),
        LookupService.fetchDistricts(),
      ]);
      if (mounted) {
        setState(() {
          _businessTypes = results[0] as List<Map<String, dynamic>>;
          _tanzaniaCities = results[1] as List<Map<String, String>>;
          _districts = results[2] as Map<String, List<String>>;
        });
      }
    } catch (_) {}
  }

  bool _isStarterPlan(Map<String, dynamic>? profile) {
    final tier = PlanTierX.fromString(profile?['plan'] as String?);
    if (tier == PlanTier.starter) return true;
    final expiresRaw = profile?['planExpiresAt'] ?? profile?['premiumExpiresAt'];
    if (expiresRaw is Timestamp) {
      return expiresRaw.toDate().isBefore(DateTime.now());
    }
    return false;
  }

  /// Add-business entry point (FAB): starter-plan users with an existing
  /// business are gated behind the shared slide-up upgrade sheet instead of
  /// the old blocking dialog, matching the rest of the app's paywall UX.
  Future<void> _handleAddBusinessTap(Map<String, dynamic>? profile) async {
    if (_isStarterPlan(profile) && _businessesFromProfile(profile).isNotEmpty) {
      await showUpgradeSheet(
        context,
        featureKey: PlanFeatureKey.multiBusiness,
        triggerReason: _tr(
          'Managing multiple businesses is available on Growth, Business, and Enterprise plans.',
          'Usimamizi wa biashara nyingi unapatikana kwenye mipango ya Growth, Business, na Enterprise.',
        ),
      );
      return;
    }
    await _openBusinessFormSheet(profile);
  }

  // ─── Storage helpers ─────────────────────────────────────────────────────────

  String _fileExtension(String path) {
    final dot = path.lastIndexOf('.');
    if (dot <= -1 || dot >= path.length - 1) return '.jpg';
    final ext = path.substring(dot).toLowerCase();
    if (ext == '.jpg' || ext == '.jpeg' || ext == '.png' || ext == '.webp') return ext;
    return '.jpg';
  }

  String _contentTypeFromExtension(String ext) {
    switch (ext) {
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  String _normalizeBucketName(String name) {
    var value = name.trim();
    if (value.isEmpty) return '';
    if (value.startsWith('gs://')) value = value.substring(5);
    if (value.endsWith('/')) value = value.substring(0, value.length - 1);
    return value;
  }

  String? _normalizeOptionalUrl(String? url) {
    if (url == null) return null;
    var value = url.trim();
    if (value.isEmpty) return null;
    if (!value.startsWith('http://') && !value.startsWith('https://')) {
      value = 'https://$value';
    }
    return value;
  }

  bool _isBucketResolutionError(FirebaseException e) {
    return e.code == 'object-not-found' ||
        e.code == 'bucket-not-found' ||
        e.code == 'unknown';
  }

  Future<String> _uploadBusinessLogo({
    required String userId,
    required String businessId,
    required File file,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final ext = _fileExtension(file.path);
    final objectPath = 'businesses/$userId/$businessId/logo_$now$ext';
    final metadata = SettableMetadata(
      contentType: _contentTypeFromExtension(ext),
      cacheControl: 'public,max-age=3600',
    );

    final attempts = <MapEntry<String, FirebaseStorage>>[
      MapEntry('default', FirebaseStorage.instance),
    ];

    final configuredBucket = _normalizeBucketName(
      Firebase.app().options.storageBucket ?? '',
    );
    final projectId = Firebase.app().options.projectId.trim();
    final fallbackBuckets = <String>{
      if (configuredBucket.isNotEmpty) configuredBucket,
      if (projectId.isNotEmpty) '$projectId.appspot.com',
      if (projectId.isNotEmpty) '$projectId.firebasestorage.app',
    };
    for (final bucket in fallbackBuckets) {
      attempts.add(MapEntry(bucket, FirebaseStorage.instanceFor(bucket: 'gs://$bucket')));
    }

    FirebaseException? lastFirebaseError;
    for (final attempt in attempts) {
      try {
        debugPrint('Attempting upload using bucket: ${attempt.key}');
        final ref = attempt.value.ref().child(objectPath);
        final snapshot = await ref.putFile(file, metadata).whenComplete(() {});
        if (snapshot.state == TaskState.success) {
          return await snapshot.ref.getDownloadURL();
        } else {
          throw FirebaseException(
            plugin: 'firebase_storage',
            code: 'upload-failed',
            message: 'Upload did not complete successfully (state: ${snapshot.state})',
          );
        }
      } on FirebaseException catch (e) {
        lastFirebaseError = e;
        debugPrint('Logo upload failed on ${attempt.key}: code=${e.code}, message=${e.message}');
        if (!_isBucketResolutionError(e)) rethrow;
      } catch (e, st) {
        debugPrint('Unexpected upload error on ${attempt.key}: $e\n$st');
        lastFirebaseError = FirebaseException(
          plugin: 'firebase_storage',
          code: 'unknown',
          message: e.toString(),
        );
      }
    }

    throw lastFirebaseError ??
        FirebaseException(
          plugin: 'firebase_storage',
          code: 'unknown',
          message: 'Logo upload failed for all configured storage buckets.',
        );
  }

  // ─── Data helpers ─────────────────────────────────────────────────────────────

  /// Loads the user profile + all owned businesses from the `businesses` collection.
  /// Returns a combined map with a synthetic `businesses` key for downstream helpers.
  Future<Map<String, dynamic>?> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    try {
      final results = await Future.wait([
        _firestore.collection('users').doc(user.uid).get(const GetOptions()),
        _firestore
            .collection('businesses')
            .where('ownerUid', isEqualTo: user.uid)
            .get(const GetOptions()),
      ]);
      final userSnap = results[0] as DocumentSnapshot<Map<String, dynamic>>;
      final bizSnap  = results[1] as QuerySnapshot<Map<String, dynamic>>;

      final profile  = userSnap.data() ?? {};
      profile['businesses'] = bizSnap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
      return profile;
    } catch (_) {
      try {
        final userSnap = await _firestore
            .collection('users')
            .doc(user.uid)
            .get(const GetOptions(source: Source.cache));
        final bizSnap = await _firestore
            .collection('businesses')
            .where('ownerUid', isEqualTo: user.uid)
            .get(const GetOptions(source: Source.cache));
        final profile = userSnap.data() ?? {};
        profile['businesses'] = bizSnap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
        return profile;
      } catch (_) {
        return null;
      }
    }
  }

  List<Map<String, dynamic>> _businessesFromProfile(Map<String, dynamic>? profile) {
    final raw = profile?['businesses'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((entry) => <String, dynamic>{
              'id': (entry['id'] as String?)?.trim() ?? '',
              'name': ((entry['businessName'] as String?)?.trim().isNotEmpty == true
                  ? entry['businessName'] as String
                  : (entry['name'] as String?)?.trim()) ?? '',
              'category': ((entry['businessCategory'] as String?)?.trim().isNotEmpty == true
                  ? entry['businessCategory'] as String
                  : (entry['category'] as String?)?.trim()) ?? '',
              'placeOfBusiness': (entry['city'] as String?)?.trim() ??
                  (entry['placeOfBusiness'] as String?)?.trim() ?? '',
              'district': (entry['district'] as String?)?.trim() ?? '',
              'phone': (entry['phone'] as String?)?.trim() ?? '',
              'logoUrl': (entry['logoUrl'] as String?)?.trim() ?? '',
              'workingHours': (entry['workingHours'] as String?)?.trim() ?? '',
              'facebook': (entry['facebook'] as String?)?.trim() ?? '',
              'instagram': (entry['instagram'] as String?)?.trim() ?? '',
              'tiktok': (entry['tiktok'] as String?)?.trim() ?? '',
              'websiteUrl': ((entry['websiteUrl'] as String?)?.trim().isNotEmpty == true
                  ? entry['websiteUrl'] as String
                  : (entry['website'] as String?)?.trim()) ?? '',
              'hasWebsite': (entry['hasWebsite'] as bool?) ?? false,
              'websiteInterest': (entry['websiteInterest'] as bool?) ?? false,
              'website': (entry['website'] as String?)?.trim() ?? '',
              'x': (entry['x'] as String?)?.trim() ?? '',
              'linkedin': (entry['linkedin'] as String?)?.trim() ?? '',
            })
        .where((entry) => (entry['id'] as String).isNotEmpty)
        .toList();
  }

  String? _selectedBusinessId(Map<String, dynamic>? profile) {
    final value = profile?['selectedBusinessId'] as String?;
    return value == null || value.trim().isEmpty ? null : value.trim();
  }

  /// Updates only `selectedBusinessId` on the user profile — no more businesses array.
  Future<void> _persistSelectedBusiness({
    required String userId,
    required String? selectedBusinessId,
  }) async {
    if (selectedBusinessId == null || selectedBusinessId.isEmpty) return;
    await _firestore.collection('users').doc(userId).set({
      'selectedBusinessId': selectedBusinessId,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ─── Delete ──────────────────────────────────────────────────────────────────

  Future<void> _deleteBusiness(
    Map<String, dynamic>? profile,
    Map<String, dynamic> business,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final businessId = business['id'] as String;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(_tr('Delete business?', 'Futa biashara?')),
        content: Text(_tr(
          'This will remove the business from your profile. Any data stored under it will remain in Firestore unless cleaned up separately.',
          'Hii itaiondoa biashara kwenye wasifu wako. Taarifa zake zitaendelea kuwepo Firestore hadi zisafishwe tofauti.',
        )),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(false),
            child: Text(_tr('Cancel', 'Ghairi')),
          ),
          TextButton(
            onPressed: () => Navigator.of(c).pop(true),
            child: Text(
              _tr('Delete', 'Futa'),
              style: GoogleFonts.dmSans(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final existing = _businessesFromProfile(profile);
    final remaining = existing.where((e) => e['id'] != businessId).toList();
    final activeId = _selectedBusinessId(profile);
    final newActiveId = remaining.isNotEmpty
        ? (activeId == businessId ? remaining.first['id'] as String : activeId)
        : null;

    await Future.wait([
      _firestore.collection('businesses').doc(businessId).delete(),
      _persistSelectedBusiness(userId: user.uid, selectedBusinessId: newActiveId),
    ]);

    if (!mounted) return;
    setState(() {
      _profileFuture = _loadProfile();
    });

    if (remaining.isEmpty) {
      if (!mounted) return;
      GoRouter.of(context).go(AppRouter.dashboardPath);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_tr('Business deleted.', 'Biashara imefutwa.'))),
    );
  }

  // ─── Form sheet ───────────────────────────────────────────────────────────────

  Future<void> _openBusinessFormSheet(
    Map<String, dynamic>? profile, {
    Map<String, dynamic>? business,
  }) async {
    final isEditing = business != null;
    final businessId = business?['id'] as String?;

    final nameCtrl    = TextEditingController(text: (business?['name'] as String?) ?? '');
    final websiteCtrl = TextEditingController(text: (business?['websiteUrl'] as String?) ?? '');

    String selectedType = () {
      final stored = (business?['category'] as String?) ?? '';
      return _businessTypes.any((t) => t['value'] == stored) ? stored : (_businessTypes.isNotEmpty ? _businessTypes.first['value'] as String : 'retail');
    }();
    String? selectedCity = (business?['placeOfBusiness'] as String?)?.trim();
    if (selectedCity != null && !_tanzaniaCities.any((c) => c['en'] == selectedCity)) {
      selectedCity = null;
    }
    String? selectedDistrict = (business?['district'] as String?)?.trim();
    if (selectedDistrict != null && (selectedCity == null || !(_districts[selectedCity] ?? []).contains(selectedDistrict))) {
      selectedDistrict = null;
    }

    File?  pickedLogoFile;
    final  existingLogoUrl = (business?['logoUrl'] as String?)?.trim();

    final result = await showAppSheet<bool>(
      context,
      builder: (sheetCtx) {
        bool   localSaving     = false;
        bool   websiteInterest = (business?['websiteInterest'] as bool?) ?? false;

        return StatefulBuilder(
          builder: (dlgCtx, setS) {
            final currentName = nameCtrl.text.trim();
            final initial     = currentName.isNotEmpty ? currentName[0].toUpperCase() : 'B';

            InputDecoration fieldDeco({required String label, String? hint, required IconData icon}) =>
                InputDecoration(
                  labelText: label,
                  hintText: hint,
                  prefixIcon: Icon(icon, size: 18, color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: AppColors.navyPrimary.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                  ),
                  labelStyle: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textMuted),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                );

            return Container(
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -4)),
                ],
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    24, 20, 24,
                    MediaQuery.viewInsetsOf(dlgCtx).bottom + 24,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Handle ─────────────────────────────────────────────
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 4),
                          decoration: BoxDecoration(
                            color: AppColors.border,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                          // ── Header ────────────────────────────────────────
                          Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.navyPrimary,
                                  borderRadius: BorderRadius.circular(13),
                                ),
                                child: Icon(
                                  isEditing ? Icons.edit_rounded : Icons.add_business_rounded,
                                  color: AppColors.yellowBrand,
                                  size: 22,
                                ),
                              ),
                              SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isEditing
                                          ? _tr('Edit business', 'Hariri biashara')
                                          : _tr('Add new business', 'Ongeza biashara mpya'),
                                      style: GoogleFonts.dmSans(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.navyPrimary,
                                        letterSpacing: -0.3,
                                        height: 1.2,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      isEditing
                                          ? _tr('Update your business profile.', 'Sasisha wasifu wa biashara yako.')
                                          : _tr('Fill in the details below to get started.', 'Jaza maelezo hapa chini kuanza.'),
                                      style: GoogleFonts.dmSans(
                                        fontSize: 12,
                                        color: AppColors.textMuted,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),

                          // ── Logo picker ───────────────────────────────────
                          Center(
                            child: GestureDetector(
                              onTap: () async {
                                final picker = ImagePicker();
                                final picked = await picker.pickImage(
                                  source: ImageSource.gallery,
                                  maxWidth: 512,
                                  maxHeight: 512,
                                  imageQuality: 85,
                                );
                                if (picked != null && dlgCtx.mounted) {
                                  setS(() => pickedLogoFile = File(picked.path));
                                }
                              },
                              child: Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                                  Container(
                                    width: 90,
                                    height: 90,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.yellowBrand,
                                      border: Border.all(color: AppColors.border, width: 2.5),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: pickedLogoFile != null
                                        ? Image.file(pickedLogoFile!, fit: BoxFit.cover)
                                        : (existingLogoUrl != null && existingLogoUrl.isNotEmpty
                                            ? Image.network(
                                                existingLogoUrl,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, _, _) => _LogoInitial(initial: initial),
                                              )
                                            : _LogoInitial(initial: initial)),
                                  ),
                                  Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: AppColors.navyPrimary,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                    child: const Icon(Icons.camera_alt_rounded, size: 14, color: AppColors.yellowBrand),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Business name
                          TextField(
                            controller: nameCtrl,
                            onChanged: (_) => setS(() {}),
                            style: GoogleFonts.dmSans(fontSize: 15, color: AppColors.navyPrimary),
                            decoration: fieldDeco(
                              label: _tr('Business name *', 'Jina la biashara *'),
                              hint: _tr("e.g. Mama Lucy's Shop", 'mfano Duka la Mama Lucy'),
                              icon: Icons.storefront_outlined,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // ── Business type ─────────────────────────────────
                          _FormSectionLabel(label: _tr('Business type', 'Aina ya biashara')),
                          const SizedBox(height: 8),
                          _FormTapSelector(
                            icon: () {
                              final t = _businessTypes.firstWhere(
                                (t) => t['value'] == selectedType,
                                orElse: () => _businessTypes.isNotEmpty ? _businessTypes.first : {'icon': Icons.category},
                              );
                              final raw = t['icon'];
                              if (raw is IconData) return raw;
                              if (raw is String) return LookupService.iconFromName(raw);
                              return Icons.category_rounded;
                            }(),
                            value: () {
                              final t = _businessTypes.firstWhere(
                                (t) => t['value'] == selectedType,
                                orElse: () => _businessTypes.isNotEmpty ? _businessTypes.first : {'en': '', 'sw': ''},
                              );
                              return _tr(t['en'] as String, t['sw'] as String);
                            }(),
                            placeholder: _tr('Select business type', 'Chagua aina ya biashara'),
                            hasValue: true,
                            onTap: () async {
                              final picked = await showAppSheet<String>(
                                dlgCtx,
                                builder: (_) => _BizTypePickerSheet(
                                  types: _businessTypes,
                                  selectedValue: selectedType,
                                  tr: _tr,
                                ),
                              );
                              if (picked != null && dlgCtx.mounted) {
                                setS(() => selectedType = picked);
                              }
                            },
                          ),
                          const SizedBox(height: 24),

                          // ── Business location ─────────────────────────────
                          _FormSectionLabel(label: _tr('Business location', 'Mahali pa biashara')),
                          SizedBox(height: 4),
                          Text(
                            _tr(
                              'Helps customers and reports stay accurate.',
                              'Husaidia wateja na ripoti kuwa sahihi.',
                            ),
                            style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textMuted),
                          ),
                          const SizedBox(height: 12),
                          _FormTapSelector(
                            icon: Icons.location_on_outlined,
                            value: selectedCity == null ? null : () {
                              final city = _tanzaniaCities.firstWhere(
                                (c) => c['en'] == selectedCity,
                                orElse: () => _tanzaniaCities.isNotEmpty ? _tanzaniaCities.first : {'en': '', 'sw': ''},
                              );
                              return _tr(city['en']!, city['sw']!);
                            }(),
                            placeholder: _tr('Select city / region *', 'Chagua mji / mkoa *'),
                            hasValue: selectedCity != null,
                            onTap: () async {
                              final picked = await showAppSheet<String>(
                                dlgCtx,
                                builder: (_) => _CityPickerSheet(
                                  cities: _tanzaniaCities,
                                  selectedValue: selectedCity,
                                  tr: _tr,
                                ),
                              );
                              if (picked != null && dlgCtx.mounted) {
                                setS(() {
                                  selectedCity = picked;
                                  selectedDistrict = null;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 12),
                          _FormTapSelector(
                            icon: Icons.location_city_outlined,
                            value: selectedDistrict,
                            placeholder: selectedCity == null
                                ? _tr('Select city first', 'Chagua mji kwanza')
                                : _tr('Select district (optional)', 'Chagua wilaya (hiari)'),
                            hasValue: selectedDistrict != null,
                            onTap: selectedCity == null
                                ? () {}
                                : () async {
                                    final districts = _districts[selectedCity] ?? [];
                                    if (districts.isEmpty) return;
                                    final picked = await showAppSheet<String>(
                                      dlgCtx,
                                      builder: (_) => _DistrictPickerSheet(
                                        districts: districts,
                                        selectedValue: selectedDistrict,
                                        tr: _tr,
                                      ),
                                    );
                                    if (picked != null && dlgCtx.mounted) {
                                      setS(() => selectedDistrict = picked);
                                    }
                                  },
                            disabled: selectedCity == null,
                          ),
                          const SizedBox(height: 24),

                          // ── Online presence ───────────────────────────────
                          _FormSectionLabel(label: _tr('Online presence', 'Uwepo wa mtandao')),
                          SizedBox(height: 4),
                          Text(
                            _tr(
                              'Add your website if you have one (optional).',
                              'Ongeza tovuti yako kama una moja (si lazima).',
                            ),
                            style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textMuted),
                          ),
                          SizedBox(height: 12),
                          TextField(
                            controller: websiteCtrl,
                            keyboardType: TextInputType.url,
                            autocorrect: false,
                            style: GoogleFonts.dmSans(fontSize: 15, color: AppColors.navyPrimary),
                            decoration: fieldDeco(
                              label: _tr('Business website (optional)', 'Tovuti ya biashara (hiari)'),
                              hint: 'https://mybusiness.com',
                              icon: Icons.language_rounded,
                            ),
                          ),
                          const SizedBox(height: 10),

                          // "Build me my website" checkbox
                          GestureDetector(
                            onTap: () => setS(() => websiteInterest = !websiteInterest),
                            behavior: HitTestBehavior.opaque,
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: Checkbox(
                                    value: websiteInterest,
                                    onChanged: (v) => setS(() => websiteInterest = v ?? false),
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    activeColor: AppColors.navyPrimary,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                    side: const BorderSide(color: AppColors.border, width: 1.5),
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  _tr('Build me my website', 'Nitengeneze Tovuti Yangu'),
                                  style: GoogleFonts.dmSans(
                                    fontSize: 13,
                                    color: AppColors.textMuted,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),

                          // ── Delete (edit mode only) ────────────────────────
                          if (isEditing) ...[
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.error,
                                  side: BorderSide(color: AppColors.error.withValues(alpha: 0.3)),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () async {
                                  final nameConfirmCtrl = TextEditingController();
                                  final bizName = (business['name'] as String?)?.trim() ?? '';
                                  final confirmed = await showDialog<bool>(
                                    context: dlgCtx,
                                    barrierDismissible: false,
                                    builder: (c) => StatefulBuilder(
                                      builder: (sc, ss) => AlertDialog(
                                        title: Text(_tr('Confirm deletion', 'Thibitisha kufuta')),
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(_tr(
                                              'Type the business name to confirm permanent deletion.',
                                              'Andika jina la biashara kuthibitisha ufutaji.',
                                            )),
                                            const SizedBox(height: 12),
                                            TextField(
                                              controller: nameConfirmCtrl,
                                              decoration: InputDecoration(hintText: bizName),
                                              onChanged: (_) => ss(() {}),
                                            ),
                                          ],
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.of(c).pop(false),
                                            child: Text(_tr('Cancel', 'Ghairi')),
                                          ),
                                          TextButton(
                                            onPressed: nameConfirmCtrl.text.trim() == bizName
                                                ? () => Navigator.of(c).pop(true)
                                                : null,
                                            child: Text(
                                              _tr('Delete permanently', 'Futa kudumu'),
                                              style: GoogleFonts.dmSans(color: Colors.redAccent),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                  if (confirmed == true) {
                                    if (dlgCtx.mounted) Navigator.of(dlgCtx).pop(false);
                                    await _deleteBusiness(profile, business);
                                  }
                                },
                                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                                label: Text(_tr('Delete business', 'Futa biashara')),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],

                          // ── Cancel / Save ─────────────────────────────────
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    foregroundColor: AppColors.navyPrimary,
                                    side: const BorderSide(color: AppColors.border),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  onPressed: localSaving ? null : () => Navigator.of(dlgCtx).pop(false),
                                  child: Text(_tr('Cancel', 'Ghairi')),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: AppColors.navyPrimary,
                                    elevation: 3,
                                    shadowColor: AppColors.primary.withValues(alpha: 0.35),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  onPressed: localSaving
                                      ? null
                                      : () async {
                                          setS(() => localSaving = true);
                                          final saved = await _saveBusinessForm(
                                            profile: profile,
                                            businessId: businessId,
                                            name: nameCtrl.text.trim(),
                                            category: selectedType,
                                            place: selectedCity ?? '',
                                            district: selectedDistrict ?? '',
                                            phone: (business?['phone'] as String?) ?? '',
                                            workingHours: (business?['workingHours'] as String?) ?? '',
                                            websiteUrl: websiteCtrl.text.trim(),
                                            websiteInterest: websiteInterest,
                                            facebook: (business?['facebook'] as String?) ?? '',
                                            instagram: (business?['instagram'] as String?) ?? '',
                                            tiktok: (business?['tiktok'] as String?) ?? '',
                                            existingBusiness: business,
                                            pickedLogoFile: pickedLogoFile,
                                            existingLogoUrl: existingLogoUrl,
                                          );
                                          if (!mounted) return;
                                          // Delay the pop by one post-frame callback.
                                          // The Firestore write triggers a Riverpod
                                          // provider cascade (currentBusinessIdProvider
                                          // → syncServiceProvider → MainShellPage)
                                          // that schedules widget rebuilds. If the pop
                                          // starts in the same frame those rebuilds are
                                          // processed, an InheritedElement is deactivated
                                          // while the sheet's elements are still
                                          // registered as dependents → _dependents.isEmpty
                                          // assertion. Deferring to the next frame lets
                                          // those rebuilds flush cleanly first.
                                          if (saved) {
                                            WidgetsBinding.instance.addPostFrameCallback((_) {
                                              if (dlgCtx.mounted) Navigator.of(dlgCtx).pop(true);
                                            });
                                          } else if (dlgCtx.mounted) {
                                            setS(() => localSaving = false);
                                          }
                                        },
                                  child: localSaving
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppColors.navyPrimary,
                                          ),
                                        )
                                      : Text(
                                          isEditing
                                              ? _tr('Save changes', 'Hifadhi mabadiliko')
                                              : _tr('Add business', 'Ongeza biashara'),
                                          style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 15),
                                        ),
                                ),
                              ),
                            ],
                          ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    nameCtrl.dispose();
    websiteCtrl.dispose();

    if (result == true && mounted) {
      setState(() => _profileFuture = _loadProfile());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditing
                ? _tr('Business updated.', 'Biashara imesasishwa.')
                : _tr('Business added.', 'Biashara imeongezwa.'),
          ),
          backgroundColor: AppColors.navyPrimary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  // ─── Save ─────────────────────────────────────────────────────────────────────

  Future<bool> _saveBusinessForm({
    required Map<String, dynamic>? profile,
    required String? businessId,
    required String name,
    required String category,
    required String place,
    required String district,
    required String phone,
    required String workingHours,
    required String websiteUrl,
    required bool websiteInterest,
    required String facebook,
    required String instagram,
    required String tiktok,
    Map<String, dynamic>? existingBusiness,
    File? pickedLogoFile,
    String? existingLogoUrl,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    if (name.isEmpty || place.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_tr(
            'Business name and city are required.',
            'Jina la biashara na mji vinahitajika.',
          )),
        ),
      );
      return false;
    }

    try {
      final resolvedId = businessId ?? _firestore.collection('businesses').doc().id;

      final phoneVal = phone.trim().isEmpty ? null : phone.trim();
      final hoursVal = workingHours.trim();
      final fbVal = _normalizeOptionalUrl(facebook);
      final igVal = _normalizeOptionalUrl(instagram);
      final ttVal = _normalizeOptionalUrl(tiktok);

      // Preserve x / linkedin (not surfaced in form)
      String? xVal, linkedinVal;
      if (existingBusiness != null) {
        final x  = (existingBusiness['x']       as String?)?.trim();
        final li = (existingBusiness['linkedin'] as String?)?.trim();
        if (x  != null && x.isNotEmpty)  xVal       = x;
        if (li != null && li.isNotEmpty) linkedinVal = li;
      }

      String? newLogoUrl = existingLogoUrl;
      if (pickedLogoFile != null) {
        final messenger = ScaffoldMessenger.of(context);
        try {
          newLogoUrl = await _uploadBusinessLogo(
            userId: user.uid,
            businessId: resolvedId,
            file: pickedLogoFile,
          );
        } on FirebaseException catch (e) {
          debugPrint('Logo upload failed: ${e.code} ${e.message}');
          if (mounted) {
            messenger.showSnackBar(SnackBar(
              content: Text(_tr(
                'Logo upload failed. Business saved without logo change.',
                'Kupakia nembo kumeshindikana. Biashara imehifadhiwa bila kubadilisha nembo.',
              )),
            ));
          }
        }
      }

      // Single write — businesses collection is the source of truth.
      await _firestore.collection('businesses').doc(resolvedId).set({
        'ownerUid': user.uid,
        'ownerName': profile?['displayName'] ?? profile?['name'] ?? user.displayName,
        'businessName': name,
        'businessCategory': category,
        'city': place,
        if (district.isNotEmpty) 'district': district,
        'phone': ?phoneVal,
        'workingHours': hoursVal,
        'websiteUrl': websiteUrl,
        'hasWebsite': websiteUrl.isNotEmpty,
        'websiteInterest': websiteInterest,
        'website': websiteUrl.isEmpty ? null : websiteUrl,
        'facebook': ?fbVal,
        'instagram': ?igVal,
        'tiktok': ?ttVal,
        'x': ?xVal,
        'linkedin': ?linkedinVal,
        if (newLogoUrl != null && newLogoUrl.isNotEmpty) 'logoUrl': newLogoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
        if (businessId == null) 'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Keep selectedBusinessId current on the user profile.
      final currentSelected = _selectedBusinessId(profile);
      if (currentSelected == null || currentSelected.isEmpty || businessId == null) {
        await _persistSelectedBusiness(
          userId: user.uid,
          selectedBusinessId: resolvedId,
        );
      }

      return true;
    } on FirebaseException catch (e) {
      debugPrint('Business save failed: ${e.code} ${e.message}');
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_tr(
          'Could not save business right now. Please try again.',
          'Imeshindikana kuhifadhi biashara kwa sasa. Tafadhali jaribu tena.',
        )),
      ));
      return false;
    } catch (e) {
      debugPrint('Business save failed: $e');
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_tr(
          'Could not save business right now. Please try again.',
          'Imeshindikana kuhifadhi biashara kwa sasa. Tafadhali jaribu tena.',
        )),
      ));
      return false;
    }
  }

  // ─── UI builders ──────────────────────────────────────────────────────────────

  Future<void> _openBusinessActionsSheet(
    Map<String, dynamic>? profile,
    Map<String, dynamic> business,
  ) async {
    final name = (business['name'] as String?)?.trim() ?? '';
    final category = (business['category'] as String?)?.trim() ?? '';
    final logoUrl = (business['logoUrl'] as String?)?.trim();
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'B';

    await showAppSheet<void>(
      context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Business identity header
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: const BoxDecoration(
                        color: AppColors.yellowBrand,
                        shape: BoxShape.circle,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: (logoUrl != null && logoUrl.isNotEmpty)
                          ? Image.network(
                              logoUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) =>
                                  _LogoInitial(initial: initial),
                            )
                          : _LogoInitial(initial: initial),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.dmSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (category.isNotEmpty)
                            Text(
                              category,
                              style: GoogleFonts.dmSans(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 8),
                // Edit option
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.edit_outlined,
                        color: AppColors.primary, size: 20),
                  ),
                  title: Text(
                    _tr('Edit business', 'Hariri biashara'),
                    style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  subtitle: Text(
                    _tr('Update details, logo and contacts',
                        'Sasisha maelezo, nembo na mawasiliano'),
                    style: GoogleFonts.dmSans(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded,
                      color: AppColors.textMuted, size: 18),
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    await _openBusinessFormSheet(profile, business: business);
                  },
                ),
                const Divider(height: 1, indent: 52, color: AppColors.border),
                // Delete option
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.delete_outline_rounded,
                        color: AppColors.error, size: 20),
                  ),
                  title: Text(
                    _tr('Delete business', 'Futa biashara'),
                    style: GoogleFonts.dmSans(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.error,
                    ),
                  ),
                  subtitle: Text(
                    _tr('Permanently remove this business',
                        'Futa biashara hii kudumu'),
                    style: GoogleFonts.dmSans(fontSize: 12),
                  ),
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    await _deleteBusiness(profile, business);
                  },
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _profileFuture,
      builder: (context, snapshot) {
        final profile = snapshot.data;
        final businesses = _businessesFromProfile(profile);
        final selectedBusinessId = _selectedBusinessId(profile);
        final isLoading =
            snapshot.connectionState != ConnectionState.done && profile == null;
        final tier = PlanTierX.fromString(profile?['plan'] as String?);

        return Scaffold(
          backgroundColor: AppColors.background,
          floatingActionButton: NavAwareFab(
            child: FloatingActionButton.extended(
              onPressed: () => _handleAddBusinessTap(profile),
              backgroundColor: AppColors.yellowBrand,
              foregroundColor: AppColors.navyPrimary,
              elevation: 3,
              icon: const Icon(Icons.add_business_rounded, size: 20),
              label: Text(
                _tr('Add Business', 'Ongeza Biashara'),
                style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          body: SmartSkeleton(
            isLoading: isLoading,
            hasExistingData: profile != null,
            skeleton: const SkeletonBusinessList(),
            child: isLoading
                ? const SizedBox.shrink()
                : Column(
                    children: [
                      _BusinessDarkHeader(
                        businessCount: businesses.length,
                        tier: tier,
                        searchCtrl: _searchCtrl,
                        searchExpanded: _searchExpanded,
                        onToggleSearch: () => setState(() {
                          _searchExpanded = !_searchExpanded;
                          if (!_searchExpanded) {
                            _searchCtrl.clear();
                          }
                        }),
                      ),
                      const SizedBox(height: _BusinessDarkHeader._pillHalf + 8),
                      Expanded(
                        child: businesses.isEmpty
                            ? const _BusinessEmptyState()
                            : ListView.builder(
                                padding: const EdgeInsets.only(bottom: 120),
                                itemCount: businesses.length,
                                itemBuilder: (_, i) => _BusinessRow(
                                  business: businesses[i],
                                  isActive:
                                      businesses[i]['id'] == selectedBusinessId,
                                  isLast: i == businesses.length - 1,
                                  onTap: () => _openBusinessActionsSheet(
                                      profile, businesses[i]),
                                ),
                              ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

// ─── Dark header + status pill (mirrors CustomerListScreen's header) ─────────

class _BusinessDarkHeader extends StatelessWidget {
  final int businessCount;
  final PlanTier tier;
  final TextEditingController searchCtrl;
  final bool searchExpanded;
  final VoidCallback onToggleSearch;

  const _BusinessDarkHeader({
    required this.businessCount,
    required this.tier,
    required this.searchCtrl,
    required this.searchExpanded,
    required this.onToggleSearch,
  });

  static const double _pillHalf = 22.0;

  String get _tierLabel {
    switch (tier) {
      case PlanTier.starter:
        return _tr('Starter', 'Bure');
      case PlanTier.growth:
        return 'Growth';
      case PlanTier.business:
        return 'Business';
      case PlanTier.enterprise:
        return 'Enterprise';
      case PlanTier.lifetime:
        return 'Lifetime';
    }
  }

  Widget _buildPill() {
    final isStarter = tier == PlanTier.starter;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PillStat(
            label: _tr('Businesses', 'Biashara'),
            value: '$businessCount',
            color: AppColors.tealAccent,
          ),
          const _PillDivider(),
          _PillStat(
            label: _tr('Plan', 'Mpango'),
            value: _tierLabel,
            color: isStarter ? AppColors.textMuted : AppColors.navyPrimary,
          ),
          const _PillDivider(),
          _PillStat(
            label: _tr('Limit', 'Kikomo'),
            value: isStarter ? '1' : '∞',
            color: isStarter ? AppColors.warning : AppColors.success,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: const BoxDecoration(
            color: AppColors.navyPrimary,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
          padding: EdgeInsets.fromLTRB(20, top + AppTheme.headerTopPadding, 20, _pillHalf + 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _tr('Businesses', 'Biashara'),
                      style: GoogleFonts.dmSans(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: onToggleSearch,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: searchExpanded
                            ? AppColors.yellowBrand.withValues(alpha: 0.18)
                            : Colors.white12,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: searchExpanded ? AppColors.yellowBrand : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        searchExpanded ? Icons.close_rounded : Icons.search_rounded,
                        color: searchExpanded ? AppColors.yellowBrand : Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                child: searchExpanded
                    ? Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: SizedBox(
                          height: 44,
                          child: TextField(
                            controller: searchCtrl,
                            autofocus: true,
                            style: GoogleFonts.dmSans(
                                fontSize: 14, color: Colors.white),
                            decoration: InputDecoration(
                              hintText: _tr(
                                'Search by name or category…',
                                'Tafuta kwa jina au kategoria…',
                              ),
                              hintStyle: GoogleFonts.dmSans(
                                  fontSize: 14, color: Colors.white38),
                              prefixIcon: const Icon(Icons.search_rounded,
                                  size: 18, color: Colors.white54),
                              filled: true,
                              fillColor: Colors.white12,
                              contentPadding: EdgeInsets.zero,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    const BorderSide(color: Colors.white24),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: AppColors.yellowBrand, width: 1.5),
                              ),
                            ),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
        Positioned(
          bottom: -_pillHalf,
          left: 0,
          right: 0,
          child: Center(child: _buildPill()),
        ),
      ],
    );
  }
}

class _PillStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _PillStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: GoogleFonts.dmSans(
              fontSize: 13, fontWeight: FontWeight.w800, color: color),
        ),
        SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.dmSans(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppColors.textMuted),
        ),
      ],
    );
  }
}

class _PillDivider extends StatelessWidget {
  const _PillDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        width: 1,
        height: 28,
        color: AppColors.border,
      ),
    );
  }
}

// ─── Business row (flat list-card style, mirrors CustomerListScreen) ─────────

class _BusinessRow extends StatelessWidget {
  final Map<String, dynamic> business;
  final bool isActive;
  final bool isLast;
  final VoidCallback onTap;

  const _BusinessRow({
    required this.business,
    required this.isActive,
    required this.isLast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = (business['name'] as String?)?.trim() ?? '';
    final category = (business['category'] as String?)?.trim() ?? '';
    final place = (business['placeOfBusiness'] as String?)?.trim() ?? '';
    final logoUrl = (business['logoUrl'] as String?)?.trim();
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'B';
    final hasLogo = logoUrl != null && logoUrl.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: hasLogo
                        ? Colors.transparent
                        : (isActive ? AppColors.navyPrimary : AppColors.yellowBrand),
                    shape: BoxShape.circle,
                    border: hasLogo
                        ? Border.all(
                            color: AppColors.border,
                            width: 1,
                          )
                        : null,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: hasLogo
                      ? Image.network(
                          logoUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (_, child, progress) =>
                              progress == null
                                  ? child
                                  : Center(
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          value: progress.expectedTotalBytes != null
                                              ? progress.cumulativeBytesLoaded /
                                                  progress.expectedTotalBytes!
                                              : null,
                                        ),
                                      ),
                                    ),
                          errorBuilder: (_, __, ___) =>
                              _LogoInitial(initial: initial),
                        )
                      : Center(
                          child: _LogoInitial(initial: initial),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.dmSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: isActive
                                    ? AppColors.navyPrimary
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ),
                          if (isActive) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.navyPrimary,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                _tr('Active', 'Hai'),
                                style: GoogleFonts.dmSans(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (category.isNotEmpty || place.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          [
                            if (category.isNotEmpty) category,
                            if (place.isNotEmpty) place,
                          ].join(' • '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.dmSans(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.textMuted, size: 18),
              ],
            ),
            if (!isLast)
              const Padding(
                padding: EdgeInsets.only(top: 13, left: 54),
                child: Divider(
                    height: 1, color: AppColors.border, thickness: 0.8),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty state ───────────────────────────────────────────────────────────

class _BusinessEmptyState extends StatelessWidget {
  const _BusinessEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(
                Icons.storefront_outlined,
                size: 36,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              _tr('No businesses yet', 'Bado hakuna biashara'),
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              _tr(
                'Tap "Add Business" below to add your first business.',
                'Bonyeza "Ongeza Biashara" hapa chini kuongeza biashara yako ya kwanza.',
              ),
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Supporting widgets ───────────────────────────────────────────────────────

class _FormSectionLabel extends StatelessWidget {
  final String label;
  const _FormSectionLabel({required this.label});

  @override
  Widget build(BuildContext context) => Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.navyPrimary,
          letterSpacing: 0.1,
        ),
      );
}

// ── Tap-to-open selector (matches onboarding _TapSelector style) ──────────────

class _FormTapSelector extends StatelessWidget {
  const _FormTapSelector({
    required this.icon,
    required this.placeholder,
    required this.onTap,
    this.value,
    this.hasValue = false,
    this.disabled = false,
  });

  final IconData  icon;
  final String    placeholder;
  final String?   value;
  final bool      hasValue;
  final bool      disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: disabled ? AppColors.surface.withValues(alpha: 0.5) : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasValue
                ? AppColors.navyPrimary.withValues(alpha: 0.35)
                : AppColors.border,
            width: hasValue ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18,
                color: disabled ? AppColors.textDisabled : (hasValue ? AppColors.navyPrimary : AppColors.textMuted)),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                value ?? placeholder,
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: hasValue ? FontWeight.w600 : FontWeight.w400,
                  color: disabled ? AppColors.textDisabled : (hasValue ? AppColors.navyPrimary : AppColors.textDisabled),
                ),
              ),
            ),
            Icon(
              hasValue
                  ? Icons.check_circle_rounded
                  : Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: hasValue ? AppColors.success : AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Business-type picker sheet (mirrors onboarding _BizTypePickerSheet) ────────

class _BizTypePickerSheet extends StatefulWidget {
  const _BizTypePickerSheet({
    required this.types,
    required this.selectedValue,
    required this.tr,
  });

  final List<Map<String, dynamic>> types;
  final String  selectedValue;
  final String Function(String, String) tr;

  @override
  State<_BizTypePickerSheet> createState() => _BizTypePickerSheetState();
}

class _BizTypePickerSheetState extends State<_BizTypePickerSheet> {
  final _searchCtrl = TextEditingController();
  late List<Map<String, dynamic>> _filtered;

  @override
  void initState() {
    super.initState();
    _filtered = widget.types;
    _searchCtrl.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearch);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch() {
    final q = _searchCtrl.text.toLowerCase().trim();
    setState(() {
      _filtered = q.isEmpty
          ? widget.types
          : widget.types.where((t) {
              final en = (t['en'] as String? ?? '').toLowerCase();
              final sw = (t['sw'] as String? ?? '').toLowerCase();
              return en.contains(q) || sw.contains(q);
            }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SheetHandle(),
          SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              widget.tr('Business Type', 'Aina ya Biashara'),
              style: GoogleFonts.dmSans(
                fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.navyPrimary,
              ),
            ),
          ),
          SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                controller: _searchCtrl,
                style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.navyPrimary),
                decoration: InputDecoration(
                  hintText: widget.tr('Search business type…', 'Tafuta aina ya biashara…'),
                  hintStyle: GoogleFonts.dmSans(fontSize: 14, color: AppColors.textDisabled),
                  prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.textMuted),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 32),
              itemCount: _filtered.length,
              itemBuilder: (_, i) {
                final t        = _filtered[i];
                final val      = t['value'] as String? ?? '';
                final selected = val == widget.selectedValue;
                final label    = widget.tr(t['en'] as String? ?? '', t['sw'] as String? ?? '');
                final rawIcon  = t['icon'];
                final icon     = rawIcon is IconData
                    ? rawIcon
                    : (rawIcon is String ? LookupService.iconFromName(rawIcon) : Icons.category_rounded);

                return InkWell(
                  onTap: () => Navigator.of(context).pop(val),
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.navyPrimary.withValues(alpha: 0.06)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: selected ? AppColors.navyPrimary : AppColors.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: selected ? AppColors.navyPrimary : AppColors.border,
                            ),
                          ),
                          child: Icon(icon, size: 18,
                              color: selected ? AppColors.yellowBrand : AppColors.textMuted),
                        ),
                        SizedBox(width: 14),
                        Expanded(
                          child: Text(label,
                              style: GoogleFonts.dmSans(
                                fontSize: 14,
                                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                color: AppColors.navyPrimary,
                              )),
                        ),
                        if (selected)
                          const Icon(Icons.check_rounded, size: 18, color: AppColors.success),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── City / Region picker sheet (mirrors onboarding _SearchPickerSheet) ─────────

class _CityPickerSheet extends StatefulWidget {
  const _CityPickerSheet({
    required this.cities,
    required this.selectedValue,
    required this.tr,
  });

  final List<Map<String, String>> cities;
  final String? selectedValue;
  final String Function(String, String) tr;

  @override
  State<_CityPickerSheet> createState() => _CityPickerSheetState();
}

class _CityPickerSheetState extends State<_CityPickerSheet> {
  final _searchCtrl = TextEditingController();
  late List<Map<String, String>> _filtered;

  @override
  void initState() {
    super.initState();
    _filtered = widget.cities;
    _searchCtrl.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearch);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch() {
    final q = _searchCtrl.text.toLowerCase().trim();
    setState(() {
      _filtered = q.isEmpty
          ? widget.cities
          : widget.cities.where((c) {
              final en = (c['en'] ?? '').toLowerCase();
              final sw = (c['sw'] ?? '').toLowerCase();
              return en.contains(q) || sw.contains(q);
            }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SheetHandle(),
          SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              widget.tr('City / Region', 'Mji / Mkoa'),
              style: GoogleFonts.dmSans(
                fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.navyPrimary,
              ),
            ),
          ),
          SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                controller: _searchCtrl,
                style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.navyPrimary),
                decoration: InputDecoration(
                  hintText: widget.tr('Search…', 'Tafuta…'),
                  hintStyle: GoogleFonts.dmSans(fontSize: 14, color: AppColors.textDisabled),
                  prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.textMuted),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ),
          ),
          SizedBox(height: 8),
          Flexible(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 32),
              itemCount: _filtered.length,
              itemBuilder: (_, i) {
                final city     = _filtered[i];
                final en       = city['en'] ?? '';
                final selected = en == widget.selectedValue;
                final label    = widget.tr(en, city['sw'] ?? en);

                return InkWell(
                  onTap: () => Navigator.of(context).pop(en),
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(label,
                              style: GoogleFonts.dmSans(
                                fontSize: 14,
                                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                color: AppColors.navyPrimary,
                              )),
                        ),
                        if (selected)
                          const Icon(Icons.check_rounded, size: 17, color: AppColors.success),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DistrictPickerSheet extends StatefulWidget {
  const _DistrictPickerSheet({
    required this.districts,
    required this.selectedValue,
    required this.tr,
  });

  final List<String> districts;
  final String? selectedValue;
  final String Function(String, String) tr;

  @override
  State<_DistrictPickerSheet> createState() => _DistrictPickerSheetState();
}

class _DistrictPickerSheetState extends State<_DistrictPickerSheet> {
  final _searchCtrl = TextEditingController();
  late List<String> _filtered;

  @override
  void initState() {
    super.initState();
    _filtered = widget.districts;
    _searchCtrl.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearch);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch() {
    final q = _searchCtrl.text.toLowerCase().trim();
    setState(() {
      _filtered = q.isEmpty
          ? widget.districts
          : widget.districts.where((d) => d.toLowerCase().contains(q)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.70),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SheetHandle(),
          SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              widget.tr('District', 'Wilaya'),
              style: GoogleFonts.dmSans(
                fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.navyPrimary,
              ),
            ),
          ),
          SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                controller: _searchCtrl,
                style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.navyPrimary),
                decoration: InputDecoration(
                  hintText: widget.tr('Search…', 'Tafuta…'),
                  hintStyle: GoogleFonts.dmSans(fontSize: 14, color: AppColors.textDisabled),
                  prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.textMuted),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ),
          ),
          SizedBox(height: 8),
          Flexible(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 32),
              itemCount: _filtered.length,
              itemBuilder: (_, i) {
                final district = _filtered[i];
                final selected = district == widget.selectedValue;
                return InkWell(
                  onTap: () => Navigator.of(context).pop(district),
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(district,
                              style: GoogleFonts.dmSans(
                                fontSize: 14,
                                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                color: AppColors.navyPrimary,
                              )),
                        ),
                        if (selected)
                          const Icon(Icons.check_rounded, size: 17, color: AppColors.success),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoInitial extends StatelessWidget {
  final String initial;
  const _LogoInitial({required this.initial});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initial,
        style: GoogleFonts.dmSans(
          color: AppColors.navyPrimary,
          fontSize: 32,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}


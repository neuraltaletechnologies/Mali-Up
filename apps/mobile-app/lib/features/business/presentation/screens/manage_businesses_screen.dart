import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../config/routing.dart';
import '../../../../core/services/localization_service.dart';
import '../../../../core/services/lookup_service.dart';
import '../../../../core/theme/app_colors.dart';

class ManageBusinessesScreen extends StatefulWidget {
  const ManageBusinessesScreen({super.key});

  @override
  State<ManageBusinessesScreen> createState() => _ManageBusinessesScreenState();
}

class _ManageBusinessesScreenState extends State<ManageBusinessesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Future<Map<String, dynamic>?> _profileFuture;

  List<Map<String, dynamic>> _businessTypes = LookupService.defaultBusinessTypes;
  List<Map<String, String>> _tanzaniaCities = LookupService.defaultTanzaniaCities;

  @override
  void initState() {
    super.initState();
    _profileFuture = _loadProfile();
    _loadLookups();
  }

  Future<void> _loadLookups() async {
    try {
      final types = await LookupService.fetchBusinessTypes();
      final cities = await LookupService.fetchCities();
      if (mounted) {
        setState(() {
          _businessTypes = types;
          _tanzaniaCities = cities;
        });
      }
    } catch (_) {}
  }

  String _tr(String en, String sw) => LocalizationService.tr(en: en, sw: sw);

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

  Future<Map<String, dynamic>?> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .get(const GetOptions());
      return snapshot.data();
    } catch (_) {
      try {
        final cached = await _firestore
            .collection('users')
            .doc(user.uid)
            .get(const GetOptions(source: Source.cache));
        return cached.data();
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
              'name': (entry['name'] as String?)?.trim() ?? '',
              'category': (entry['category'] as String?)?.trim() ?? '',
              'placeOfBusiness': (entry['placeOfBusiness'] as String?)?.trim() ?? '',
              'phone': (entry['phone'] as String?)?.trim() ?? '',
              'logoUrl': (entry['logoUrl'] as String?)?.trim() ?? '',
              'workingHours': (entry['workingHours'] as String?)?.trim() ?? '',
              'facebook': (entry['facebook'] as String?)?.trim() ?? '',
              'instagram': (entry['instagram'] as String?)?.trim() ?? '',
              'tiktok': (entry['tiktok'] as String?)?.trim() ?? '',
              // website fields — now editable
              'websiteUrl': ((entry['websiteUrl'] as String?)?.trim().isNotEmpty == true
                  ? entry['websiteUrl'] as String
                  : (entry['website'] as String?)?.trim()) ?? '',
              'hasWebsite': (entry['hasWebsite'] as bool?) ?? false,
              'websiteInterest': (entry['websiteInterest'] as bool?) ?? false,
              // kept for data preservation
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

  Future<void> _persistBusinesses({
    required String userId,
    required List<Map<String, dynamic>> businesses,
    String? selectedBusinessId,
  }) async {
    final data = <String, dynamic>{
      'businesses': businesses,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (selectedBusinessId != null && selectedBusinessId.isNotEmpty) {
      data.addAll({
        'defaultContext': 'business:$selectedBusinessId',
        'defaultAccountType': 'business',
        'selectedBusinessId': selectedBusinessId,
      });
    }
    await _firestore.collection('users').doc(userId).set(data, SetOptions(merge: true));
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
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final existing = _businessesFromProfile(profile);
    final remaining = existing.where((e) => e['id'] != businessId).toList();
    final activeId = _selectedBusinessId(profile);

    await _persistBusinesses(
      userId: user.uid,
      businesses: remaining,
      selectedBusinessId: remaining.isNotEmpty
          ? (activeId == businessId
              ? remaining.first['id'] as String
              : activeId)
          : null,
    );

    await _firestore
        .collection('tenants')
        .doc(user.uid)
        .collection('businesses')
        .doc(businessId)
        .delete();

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

    File?  pickedLogoFile;
    final  existingLogoUrl = (business?['logoUrl'] as String?)?.trim();

    final result = await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        bool   localSaving     = false;
        bool   websiteInterest = (business?['websiteInterest'] as bool?) ?? false;

        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetCtx).height * 0.90,
          ),
          child: StatefulBuilder(
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
                  labelStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
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
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isEditing
                                          ? _tr('Edit business', 'Hariri biashara')
                                          : _tr('Add new business', 'Ongeza biashara mpya'),
                                      style: const TextStyle(
                                        fontSize: 19,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.navyPrimary,
                                        letterSpacing: -0.3,
                                        height: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      isEditing
                                          ? _tr('Update your business profile.', 'Sasisha wasifu wa biashara yako.')
                                          : _tr('Fill in the details below to get started.', 'Jaza maelezo hapa chini kuanza.'),
                                      style: const TextStyle(
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
                            style: const TextStyle(fontSize: 15, color: AppColors.navyPrimary),
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
                              final picked = await showModalBottomSheet<String>(
                                context: dlgCtx,
                                useRootNavigator: true,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
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
                          const SizedBox(height: 4),
                          Text(
                            _tr(
                              'Helps customers and reports stay accurate.',
                              'Husaidia wateja na ripoti kuwa sahihi.',
                            ),
                            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
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
                              final picked = await showModalBottomSheet<String>(
                                context: dlgCtx,
                                useRootNavigator: true,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (_) => _CityPickerSheet(
                                  cities: _tanzaniaCities,
                                  selectedValue: selectedCity,
                                  tr: _tr,
                                ),
                              );
                              if (picked != null && dlgCtx.mounted) {
                                setS(() => selectedCity = picked);
                              }
                            },
                          ),
                          const SizedBox(height: 24),

                          // ── Online presence ───────────────────────────────
                          _FormSectionLabel(label: _tr('Online presence', 'Uwepo wa mtandao')),
                          const SizedBox(height: 4),
                          Text(
                            _tr(
                              'Add your website if you have one (optional).',
                              'Ongeza tovuti yako kama una moja (si lazima).',
                            ),
                            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: websiteCtrl,
                            keyboardType: TextInputType.url,
                            autocorrect: false,
                            style: const TextStyle(fontSize: 15, color: AppColors.navyPrimary),
                            decoration: fieldDeco(
                              label: _tr('Business website (optional)', 'Tovuti ya biashara (hiari)'),
                              hint: 'https://mybusiness.com',
                              icon: Icons.language_rounded,
                            ),
                          ),
                          const SizedBox(height: 10),

                          // "Build me one" checkbox
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
                                const SizedBox(width: 8),
                                Text(
                                  _tr('Build me one', 'Nifanyie tovuti'),
                                  style: const TextStyle(
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
                                              style: const TextStyle(color: Colors.redAccent),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                  if (confirmed == true) {
                                    if (mounted) Navigator.of(context).pop();
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
                                          setS(() => localSaving = false);
                                          if (saved && dlgCtx.mounted) {
                                            Navigator.of(dlgCtx).pop(true);
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
                                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
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
        ),
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
      final resolvedId = businessId ??
          _firestore
              .collection('tenants')
              .doc(user.uid)
              .collection('businesses')
              .doc()
              .id;

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

      Map<String, dynamic> buildEntry(Map<String, dynamic>? base) => {
            if (base != null) ...base,
            'id': resolvedId,
            'name': name,
            'category': category,
            'placeOfBusiness': place,
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
            if (businessId == null) 'createdAt': DateTime.now().toIso8601String(),
          };

      final existingList = _businessesFromProfile(profile);
      final updated = businessId == null
          ? [...existingList, buildEntry(null)]
          : existingList.map((e) {
              if (e['id'] != resolvedId) return e;
              return buildEntry(e);
            }).toList();

      await _persistBusinesses(
        userId: user.uid,
        businesses: updated,
        selectedBusinessId: _selectedBusinessId(profile) ?? resolvedId,
      );

      await _firestore
          .collection('tenants')
          .doc(user.uid)
          .collection('businesses')
          .doc(resolvedId)
          .set({
        'id': resolvedId,
        'businessName': name,
        'businessCategory': category,
        'placeOfBusiness': place,
        'ownerUid': user.uid,
        'ownerName':
            profile?['displayName'] ?? profile?['name'] ?? user.displayName,
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

    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
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
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (category.isNotEmpty)
                            Text(
                              category,
                              style: const TextStyle(
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
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  subtitle: Text(
                    _tr('Update details, logo and contacts',
                        'Sasisha maelezo, nembo na mawasiliano'),
                    style: const TextStyle(fontSize: 12),
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
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.error,
                    ),
                  ),
                  subtitle: Text(
                    _tr('Permanently remove this business',
                        'Futa biashara hii kudumu'),
                    style: const TextStyle(fontSize: 12),
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

  Widget _buildAddHero(Map<String, dynamic>? profile) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: () => _openBusinessFormSheet(profile),
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF003153), Color(0xFF003153)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF003153).withValues(alpha: 0.45),
                blurRadius: 24,
                offset: const Offset(0, 10),
                spreadRadius: -4,
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -36,
                top: -36,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.04),
                  ),
                ),
              ),
              Positioned(
                right: 20,
                bottom: -24,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.yellowBrand.withValues(alpha: 0.06),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: AppColors.yellowBrand.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: AppColors.yellowBrand.withValues(alpha: 0.3),
                            ),
                          ),
                          child: const Icon(
                            Icons.add_business_rounded,
                            color: AppColors.yellowBrand,
                            size: 26,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.add_rounded,
                                  size: 13, color: Colors.white),
                              const SizedBox(width: 4),
                              Text(
                                _tr('New', 'Mpya'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      _tr('Add a new business', 'Ongeza biashara mpya'),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.2,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _tr(
                        'Set up a separate profile for each business and track everything in one place.',
                        'Tengeneza wasifu tofauti kwa kila biashara na ufuatilie kila kitu mahali pamoja.',
                      ),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 13),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.add_rounded,
                              color: AppColors.navyPrimary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            _tr('Add New Business', 'Ongeza Biashara Mpya'),
                            style: const TextStyle(
                              color: AppColors.navyPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ],
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
  }

  Widget _buildBusinessCard(
    Map<String, dynamic>? profile,
    Map<String, dynamic> business,
    String? selectedBusinessId,
  ) {
    final name = (business['name'] as String?)?.trim() ?? '';
    final category = (business['category'] as String?)?.trim() ?? '';
    final place = (business['placeOfBusiness'] as String?)?.trim() ?? '';
    final logoUrl = (business['logoUrl'] as String?)?.trim();
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'B';
    final isActive = selectedBusinessId == business['id'];

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _openBusinessActionsSheet(profile, business),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isActive
                    ? AppColors.primary.withValues(alpha: 0.35)
                    : AppColors.border,
                width: isActive ? 1.5 : 1,
              ),
            ),
            child: Row(
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
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          if (isActive) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                _tr('Active', 'Hai'),
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (category.isNotEmpty || place.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          [
                            if (category.isNotEmpty) category,
                            if (place.isNotEmpty) place,
                          ].join(' • '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.more_vert_rounded,
                    color: AppColors.textMuted, size: 20),
              ],
            ),
          ),
        ),
      ),
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

        return Scaffold(
          backgroundColor: AppColors.background,
          body: isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 62, 20, 40),
                  children: [
                    _buildAddHero(profile),
                    if (businesses.isNotEmpty) ...[
                      const SizedBox(height: 28),
                      Row(
                        children: [
                          Text(
                            _tr('Your businesses', 'Biashara zako'),
                            style:
                                Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary,
                                    ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '${businesses.length}',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...businesses.map(
                        (b) =>
                            _buildBusinessCard(profile, b, selectedBusinessId),
                      ),
                    ] else if (snapshot.connectionState ==
                        ConnectionState.done) ...[
                      const SizedBox(height: 40),
                      Center(
                        child: Column(
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
                                'Tap the button above to add your first business.',
                                'Bonyeza kitufe hapo juu kuongeza biashara yako ya kwanza.',
                              ),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
        );
      },
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
        style: const TextStyle(
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
  });

  final IconData  icon;
  final String    placeholder;
  final String?   value;
  final bool      hasValue;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
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
                color: hasValue ? AppColors.navyPrimary : AppColors.textMuted),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value ?? placeholder,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: hasValue ? FontWeight.w600 : FontWeight.w400,
                  color: hasValue ? AppColors.navyPrimary : AppColors.textDisabled,
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
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.88),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              widget.tr('Business Type', 'Aina ya Biashara'),
              style: const TextStyle(
                fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.navyPrimary,
              ),
            ),
          ),
          const SizedBox(height: 12),
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
                style: const TextStyle(fontSize: 14, color: AppColors.navyPrimary),
                decoration: InputDecoration(
                  hintText: widget.tr('Search business type…', 'Tafuta aina ya biashara…'),
                  hintStyle: const TextStyle(fontSize: 14, color: AppColors.textDisabled),
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
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(label,
                              style: TextStyle(
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
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.82),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              widget.tr('City / Region', 'Mji / Mkoa'),
              style: const TextStyle(
                fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.navyPrimary,
              ),
            ),
          ),
          const SizedBox(height: 12),
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
                style: const TextStyle(fontSize: 14, color: AppColors.navyPrimary),
                decoration: InputDecoration(
                  hintText: widget.tr('Search…', 'Tafuta…'),
                  hintStyle: const TextStyle(fontSize: 14, color: AppColors.textDisabled),
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
                              style: TextStyle(
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
        style: const TextStyle(
          color: AppColors.navyPrimary,
          fontSize: 32,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}


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
import '../../../../shared/widgets/mali_components.dart';

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
    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .get(const GetOptions());
    return snapshot.data();
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
              // kept read-only for data preservation — not shown in form
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

    final nameController =
        TextEditingController(text: (business?['name'] as String?) ?? '');
    final phoneController =
        TextEditingController(text: (business?['phone'] as String?) ?? '');
    final workingHoursController =
        TextEditingController(text: (business?['workingHours'] as String?) ?? '');
    final facebookController =
        TextEditingController(text: (business?['facebook'] as String?) ?? '');
    final instagramController =
        TextEditingController(text: (business?['instagram'] as String?) ?? '');
    final tiktokController =
        TextEditingController(text: (business?['tiktok'] as String?) ?? '');

    String selectedBusinessType = () {
      final stored = (business?['category'] as String?) ?? 'Retail';
      return _businessTypes.any((t) => t['value'] == stored) ? stored : 'Retail';
    }();
    String? selectedCity = (business?['placeOfBusiness'] as String?)?.trim();
    if (selectedCity != null &&
        !_tanzaniaCities.any((c) => c['en'] == selectedCity)) {
      selectedCity = null;
    }

    File? pickedLogoFile;
    final existingLogoUrl = (business?['logoUrl'] as String?)?.trim();

    final result = await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        bool localSaving = false;
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            final currentName = nameController.text.trim();
            final initial =
                currentName.isNotEmpty ? currentName[0].toUpperCase() : 'B';

            return Container(
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 14,
                    bottom: MediaQuery.of(dialogContext).viewInsets.bottom + 18,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 44,
                            height: 5,
                            decoration: BoxDecoration(
                              color: AppColors.border,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Header — no gradient
                        Text(
                          isEditing
                              ? _tr('Edit business', 'Hariri biashara')
                              : _tr('Add new business', 'Ongeza biashara mpya'),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isEditing
                              ? _tr(
                                  'Update your business profile.',
                                  'Sasisha wasifu wa biashara yako.',
                                )
                              : _tr(
                                  'Fill in your business details to get started.',
                                  'Jaza taarifa za biashara yako kuanza.',
                                ),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Logo picker
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
                              if (picked != null && dialogContext.mounted) {
                                setDialogState(() => pickedLogoFile = File(picked.path));
                              }
                            },
                            child: Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                Container(
                                  width: 88,
                                  height: 88,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.yellowBrand,
                                    border: Border.all(color: AppColors.border, width: 2),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: pickedLogoFile != null
                                      ? Image.file(pickedLogoFile!, fit: BoxFit.cover)
                                      : (existingLogoUrl != null && existingLogoUrl.isNotEmpty
                                          ? Image.network(
                                              existingLogoUrl,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, _, _) =>
                                                  _LogoInitial(initial: initial),
                                            )
                                          : _LogoInitial(initial: initial)),
                                ),
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                  child: const Icon(Icons.camera_alt_rounded,
                                      size: 14, color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ── Section: Basic info ──────────────────────────────
                        _FormSectionLabel(
                            label: _tr('BASIC INFO', 'TAARIFA ZA MSINGI')),
                        const SizedBox(height: 10),
                        TextField(
                          controller: nameController,
                          onChanged: (_) => setDialogState(() {}),
                          decoration: InputDecoration(
                            labelText: _tr('Business name *', 'Jina la biashara *'),
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.business_rounded),
                          ),
                        ),
                        const SizedBox(height: 12),
                        MaliSelectField(
                          placeholder: _tr('Business Type', 'Aina ya Biashara'),
                          displayValue: () {
                            final type = _businessTypes.firstWhere(
                              (t) => t['value'] == selectedBusinessType,
                              orElse: () => _businessTypes.first,
                            );
                            return _tr(type['en'] as String, type['sw'] as String);
                          }(),
                          hasValue: true,
                          onTap: () async {
                            final selected = await showModalBottomSheet<String>(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => MaliSelectSheet<String>(
                                title: _tr('Business Type', 'Aina ya Biashara'),
                                items: _businessTypes
                                    .map((t) => t['value'] as String)
                                    .toList(),
                                selectedValue: selectedBusinessType,
                                labelBuilder: (value) {
                                  final type = _businessTypes.firstWhere(
                                    (t) => t['value'] == value,
                                    orElse: () => _businessTypes.first,
                                  );
                                  return _tr(type['en'] as String, type['sw'] as String);
                                },
                                iconBuilder: (value) {
                                  final type = _businessTypes.firstWhere(
                                    (t) => t['value'] == value,
                                    orElse: () => _businessTypes.first,
                                  );
                                  final iconRaw = type['icon'];
                                  if (iconRaw is IconData) return iconRaw;
                                  if (iconRaw is String) {
                                    return LookupService.iconFromName(iconRaw);
                                  }
                                  return Icons.category;
                                },
                              ),
                            );
                            if (selected != null && dialogContext.mounted) {
                              setDialogState(() => selectedBusinessType = selected);
                            }
                          },
                          icon: Icons.category_rounded,
                        ),
                        const SizedBox(height: 12),
                        MaliSelectField(
                          placeholder: _tr('City / Region *', 'Mji / Mkoa *'),
                          displayValue: () {
                            if (selectedCity == null) return '';
                            final city = _tanzaniaCities.firstWhere(
                              (c) => c['en'] == selectedCity,
                              orElse: () => _tanzaniaCities.first,
                            );
                            return _tr(city['en']!, city['sw']!);
                          }(),
                          hasValue: selectedCity != null,
                          onTap: () async {
                            final selected = await showModalBottomSheet<String>(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => MaliSelectSheet<String>(
                                title: _tr('City / Region', 'Mji / Mkoa'),
                                items: _tanzaniaCities.map((c) => c['en']!).toList(),
                                selectedValue: selectedCity,
                                labelBuilder: (value) {
                                  final city = _tanzaniaCities.firstWhere(
                                    (c) => c['en'] == value,
                                    orElse: () => _tanzaniaCities.first,
                                  );
                                  return _tr(city['en']!, city['sw']!);
                                },
                              ),
                            );
                            if (selected != null && dialogContext.mounted) {
                              setDialogState(() => selectedCity = selected);
                            }
                          },
                          icon: Icons.location_on_outlined,
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: _tr(
                              'Phone number (optional)',
                              'Nambari ya simu (hiari)',
                            ),
                            hintText: '+255 700 000 000',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.phone_outlined),
                          ),
                        ),

                        // ── Section: Presence ────────────────────────────────
                        _FormSectionLabel(
                            label: _tr('PRESENCE', 'UWEPO WA BIASHARA')),
                        const SizedBox(height: 10),
                        TextField(
                          controller: workingHoursController,
                          decoration: InputDecoration(
                            labelText: _tr(
                              'Working hours (optional)',
                              'Muda wa kazi (hiari)',
                            ),
                            hintText: _tr(
                              'Mon – Sat: 8:00 AM – 6:00 PM',
                              'Jumatatu – Jumamosi: 8:00 – 18:00',
                            ),
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.access_time_rounded),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _WebsitePromoCard(tr: _tr),

                        // ── Section: Social media ────────────────────────────
                        _FormSectionLabel(
                            label: _tr('SOCIAL MEDIA', 'MITANDAO YA KIJAMII')),
                        const SizedBox(height: 10),
                        TextField(
                          controller: facebookController,
                          keyboardType: TextInputType.url,
                          decoration: const InputDecoration(
                            labelText: 'Facebook',
                            hintText: 'facebook.com/yourbusiness',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.facebook_rounded),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: instagramController,
                          keyboardType: TextInputType.url,
                          decoration: const InputDecoration(
                            labelText: 'Instagram',
                            hintText: '@yourbusiness',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.camera_alt_outlined),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: tiktokController,
                          keyboardType: TextInputType.url,
                          decoration: const InputDecoration(
                            labelText: 'TikTok',
                            hintText: '@yourbusiness',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.music_note_rounded),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Delete button — edit mode only
                        if (isEditing) ...[
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.error,
                                side: BorderSide(
                                    color: AppColors.error.withValues(alpha: 0.25)),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () async {
                                final nameConfirmCtrl = TextEditingController();
                                final businessName =
                                    (business['name'] as String?)?.trim() ?? '';
                                final confirmed = await showDialog<bool>(
                                  context: dialogContext,
                                  barrierDismissible: false,
                                  builder: (c) => StatefulBuilder(
                                    builder: (sc, ss) => AlertDialog(
                                      title: Text(_tr(
                                          'Confirm deletion',
                                          'Thibitisha kufuta')),
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
                                            decoration: InputDecoration(
                                                hintText: businessName),
                                            onChanged: (_) => ss(() {}),
                                          ),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(c).pop(false),
                                          child: Text(_tr('Cancel', 'Ghairi')),
                                        ),
                                        TextButton(
                                          onPressed:
                                              nameConfirmCtrl.text.trim() ==
                                                      businessName
                                                  ? () => Navigator.of(c)
                                                      .pop(true)
                                                  : null,
                                          child: Text(
                                            _tr('Delete permanently',
                                                'Futa kudumu'),
                                            style: const TextStyle(
                                                color: Colors.redAccent),
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
                              icon: const Icon(Icons.delete_outline_rounded,
                                  size: 18),
                              label: Text(
                                  _tr('Delete business', 'Futa biashara')),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Cancel / Save
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: localSaving
                                    ? null
                                    : () =>
                                        Navigator.of(dialogContext).pop(false),
                                child: Text(_tr('Cancel', 'Ghairi')),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                                icon: localSaving
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white),
                                      )
                                    : Icon(
                                        isEditing
                                            ? Icons.save_rounded
                                            : Icons.add_business_rounded,
                                        size: 18),
                                onPressed: localSaving
                                    ? null
                                    : () async {
                                        setDialogState(() => localSaving = true);
                                        final saved = await _saveBusinessForm(
                                          profile: profile,
                                          businessId: businessId,
                                          name: nameController.text.trim(),
                                          category: selectedBusinessType,
                                          place: selectedCity ?? '',
                                          phone: phoneController.text.trim(),
                                          workingHours:
                                              workingHoursController.text,
                                          facebook: facebookController.text,
                                          instagram: instagramController.text,
                                          tiktok: tiktokController.text,
                                          existingBusiness: business,
                                          pickedLogoFile: pickedLogoFile,
                                          existingLogoUrl: existingLogoUrl,
                                        );
                                        if (!mounted) return;
                                        setDialogState(
                                            () => localSaving = false);
                                        if (saved && dialogContext.mounted) {
                                          Navigator.of(dialogContext).pop(true);
                                        }
                                      },
                                label: Text(
                                  localSaving
                                      ? _tr('Saving…', 'Inahifadhi…')
                                      : isEditing
                                          ? _tr('Save changes',
                                              'Hifadhi mabadiliko')
                                          : _tr('Add business',
                                              'Ongeza biashara'),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    nameController.dispose();
    phoneController.dispose();
    workingHoursController.dispose();
    facebookController.dispose();
    instagramController.dispose();
    tiktokController.dispose();

    if (result == true && mounted) {
      setState(() {
        _profileFuture = _loadProfile();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditing
                ? _tr('Business updated.', 'Biashara imesasishwa.')
                : _tr('Business added.', 'Biashara imeongezwa.'),
          ),
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

      // Pass through fields removed from the form — preserves existing data
      String? websiteVal, xVal, linkedinVal;
      if (existingBusiness != null) {
        final w = (existingBusiness['website'] as String?)?.trim();
        if (w != null && w.isNotEmpty) websiteVal = w;
        final x = (existingBusiness['x'] as String?)?.trim();
        if (x != null && x.isNotEmpty) xVal = x;
        final li = (existingBusiness['linkedin'] as String?)?.trim();
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
            'facebook': ?fbVal,
            'instagram': ?igVal,
            'tiktok': ?ttVal,
            'website': ?websiteVal,
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
        'facebook': ?fbVal,
        'instagram': ?igVal,
        'tiktok': ?ttVal,
        'website': ?websiteVal,
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
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 2),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 14,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _WebsitePromoCard extends StatelessWidget {
  final String Function(String, String) tr;
  const _WebsitePromoCard({required this.tr});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF6366F1).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF6366F1).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.language_rounded,
                color: Color(0xFF6366F1), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr("Don't have a website?", 'Huna tovuti bado?'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tr(
                    'We build professional websites for businesses like yours — fast and affordable.',
                    'Tunajenga tovuti za kitaalamu kwa biashara kama yako — haraka na bei nafuu.',
                  ),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () {
                    showDialog<void>(
                      context: context,
                      builder: (c) => AlertDialog(
                        title: Text(tr('Get in touch', 'Wasiliana nasi')),
                        content: Text(tr(
                          'Contact us and we will build a professional website for your business.',
                          'Wasiliana nasi na tutakutengenezea tovuti ya kitaalamu kwa biashara yako.',
                        )),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(c).pop(),
                            child: Text(tr('Close', 'Funga')),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        tr('Contact us to get started', 'Wasiliana nasi kuanza'),
                        style: const TextStyle(
                          color: Color(0xFF6366F1),
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_rounded,
                          size: 14, color: Color(0xFF6366F1)),
                    ],
                  ),
                ),
              ],
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


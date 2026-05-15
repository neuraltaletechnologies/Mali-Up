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
  final TextEditingController _businessNameController = TextEditingController();
  late Future<Map<String, dynamic>?> _profileFuture;
  bool _isSaving = false;

  

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

  @override
  void dispose() {
    _businessNameController.dispose();
    super.dispose();
  }
  String _tr(String en, String sw) => LocalizationService.tr(en: en, sw: sw);
  

  String _fileExtension(String path) {
    final dot = path.lastIndexOf('.');
    if (dot <= -1 || dot >= path.length - 1) return '.jpg';
    final ext = path.substring(dot).toLowerCase();
    if (ext == '.jpg' || ext == '.jpeg' || ext == '.png' || ext == '.webp') {
      return ext;
    }
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
      attempts.add(
        MapEntry(
          bucket,
          FirebaseStorage.instanceFor(bucket: 'gs://$bucket'),
        ),
      );
    }

    FirebaseException? lastFirebaseError;

    for (final attempt in attempts) {
      try {
        debugPrint('Attempting upload using bucket: ${attempt.key}');
        debugPrint('Configured storageBucket: ${Firebase.app().options.storageBucket}');
        final ref = attempt.value.ref().child(objectPath);

        final uploadTask = ref.putFile(file, metadata);

        // Await task completion and get the snapshot to ensure the server accepted it
        final snapshot = await uploadTask.whenComplete(() {});

        if (snapshot.state == TaskState.success) {
          final url = await snapshot.ref.getDownloadURL();
          return url;
        } else {
          throw FirebaseException(
            plugin: 'firebase_storage',
            code: 'upload-failed',
            message: 'Upload did not complete successfully (state: ${snapshot.state})',
          );
        }
      } on FirebaseException catch (e) {
        lastFirebaseError = e;
        debugPrint(
          'Logo upload failed on ${attempt.key}: code=${e.code}, message=${e.message}',
        );
        if (!_isBucketResolutionError(e)) rethrow;
      } catch (e, st) {
        debugPrint('Unexpected upload error on ${attempt.key}: $e');
        debugPrint('$st');
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
        .map(
          (entry) => <String, dynamic>{
            'id': (entry['id'] as String?)?.trim() ?? '',
            'name': (entry['name'] as String?)?.trim() ?? '',
            'category': (entry['category'] as String?)?.trim() ?? '',
            'placeOfBusiness': (entry['placeOfBusiness'] as String?)?.trim() ?? '',
            'logoUrl': (entry['logoUrl'] as String?)?.trim() ?? '',
            'website': (entry['website'] as String?)?.trim() ?? '',
            'workingHours': (entry['workingHours'] as String?)?.trim() ?? '',
            'facebook': (entry['facebook'] as String?)?.trim() ?? '',
            'instagram': (entry['instagram'] as String?)?.trim() ?? '',
            'tiktok': (entry['tiktok'] as String?)?.trim() ?? '',
            'x': (entry['x'] as String?)?.trim() ?? '',
            'linkedin': (entry['linkedin'] as String?)?.trim() ?? '',
          },
        )
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

  Future<void> _switchToBusiness(Map<String, dynamic> business) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final businessId = business['id'] as String;
    await _firestore.collection('users').doc(user.uid).set({
      'defaultContext': 'business:$businessId',
      'defaultAccountType': 'business',
      'selectedBusinessId': businessId,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (!mounted) return;
    context.go(AppRouter.salesPath);
  }

  Future<void> _editBusiness(Map<String, dynamic>? profile, Map<String, dynamic> business) async {
    await _openBusinessFormSheet(profile, business: business);
  }
 

  Future<void> _deleteBusiness(Map<String, dynamic>? profile, Map<String, dynamic> business) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final businessId = business['id'] as String;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_tr('Delete business?', 'Futa biashara?')),
        content: Text(_tr(
          'This will remove the business from your profile. Any business data stored under it will remain in Firestore unless cleaned up separately.',
          'Hii itaiondoa biashara kwenye wasifu wako. Taarifa zake zitaendelea kuwepo Firestore hadi zisafishwe tofauti.',
        )),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(_tr('Cancel', 'Ghairi')),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(_tr('Delete', 'Futa')),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final existingBusinesses = _businessesFromProfile(profile);
    final remainingBusinesses =
        existingBusinesses.where((entry) => entry['id'] != businessId).toList();
    final activeBusinessId = _selectedBusinessId(profile);
    final shouldFallbackToPersonal = remainingBusinesses.isEmpty;

    await _persistBusinesses(
      userId: user.uid,
      businesses: remainingBusinesses,
      selectedBusinessId: remainingBusinesses.isNotEmpty
          ? (activeBusinessId == businessId
              ? remainingBusinesses.first['id'] as String
              : activeBusinessId)
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

    if (shouldFallbackToPersonal) {
      if (!mounted) return;
      GoRouter.of(context).go(AppRouter.dashboardPath);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_tr('Business deleted.', 'Biashara imefutwa.'))),
    );
  }

  

  Future<void> _openAddBusinessSheet(Map<String, dynamic>? profile) async {
    await _openBusinessFormSheet(profile);
  }

  Future<void> _openBusinessFormSheet(
    Map<String, dynamic>? profile, {
    Map<String, dynamic>? business,
  }) async {
    final isEditing = business != null;
    final businessId = business?['id'] as String?;
    final nameController = TextEditingController(text: (business?['name'] as String?) ?? '');
    final websiteController = TextEditingController(text: (business?['website'] as String?) ?? '');
    final workingHoursController = TextEditingController(
      text: (business?['workingHours'] as String?) ?? '',
    );
    final facebookController = TextEditingController(text: (business?['facebook'] as String?) ?? '');
    final instagramController = TextEditingController(
      text: (business?['instagram'] as String?) ?? '',
    );
    final tiktokController = TextEditingController(text: (business?['tiktok'] as String?) ?? '');
    final xController = TextEditingController(text: (business?['x'] as String?) ?? '');
    final linkedinController = TextEditingController(
      text: (business?['linkedin'] as String?) ?? '',
    );

    String selectedBusinessType = () {
      final stored = (business?['category'] as String?) ?? 'Retail';
      return _businessTypes.any((type) => type['value'] == stored) ? stored : 'Retail';
    }();
    String? selectedCity = (business?['placeOfBusiness'] as String?)?.trim();
    if (selectedCity != null && !_tanzaniaCities.any((city) => city['en'] == selectedCity)) {
      selectedCity = null;
    }

    File? pickedLogoFile;
    final existingLogoUrl = (business?['logoUrl'] as String?)?.trim();
    const bool isSaving = false;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            final currentName = nameController.text.trim();
            final initial = currentName.isNotEmpty ? currentName[0].toUpperCase() : 'B';
            final title = isEditing
              ? _tr('Edit business', 'Hariri biashara')
              : _tr('Add new business', 'Ongeza biashara mpya');
            final subtitle = isEditing
              ? _tr('Update the profile and keep everything in sync.', 'Sasisha wasifu na uendelee kusawazisha kila kitu.')
              : _tr('Create a full business profile in one place.', 'Tengeneza wasifu kamili wa biashara hapa hapa.');

            final headerGradient = isEditing
              ? const LinearGradient(
                colors: [AppColors.secondary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                )
              : const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                );

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
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: headerGradient,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                subtitle,
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        Center(
                          child: GestureDetector(
                            onTap: isSaving
                                ? null
                                : () async {
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
                                  width: 92,
                                  height: 92,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.yellowBrand,
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
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt_rounded,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        TextField(
                          controller: nameController,
                          decoration: InputDecoration(
                            labelText: _tr('Business name', 'Jina la biashara'),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        MaliSelectField(
                          placeholder: _tr('Business Type', 'Aina ya Biashara'),
                          displayValue: () {
                            final type = _businessTypes.firstWhere(
                              (type) => type['value'] == selectedBusinessType,
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
                                items: _businessTypes.map((type) => type['value'] as String).toList(),
                                selectedValue: selectedBusinessType,
                                labelBuilder: (value) {
                                  final type = _businessTypes.firstWhere(
                                    (type) => type['value'] == value,
                                    orElse: () => _businessTypes.first,
                                  );
                                  return _tr(type['en'] as String, type['sw'] as String);
                                },
                                iconBuilder: (value) {
                                  final type = _businessTypes.firstWhere(
                                    (type) => type['value'] == value,
                                    orElse: () => _businessTypes.first,
                                  );
                                  final iconRaw = type['icon'];
                                  if (iconRaw is IconData) return iconRaw;
                                  if (iconRaw is String) return LookupService.iconFromName(iconRaw);
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
                          placeholder: _tr('City / Region', 'Mji / Mkoa'),
                          displayValue: () {
                            if (selectedCity == null) return '';
                            final city = _tanzaniaCities.firstWhere(
                              (city) => city['en'] == selectedCity,
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
                                items: _tanzaniaCities.map((city) => city['en']!).toList(),
                                selectedValue: selectedCity,
                                labelBuilder: (value) {
                                  final city = _tanzaniaCities.firstWhere(
                                    (city) => city['en'] == value,
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
                          controller: websiteController,
                          keyboardType: TextInputType.url,
                          decoration: InputDecoration(
                            labelText: _tr('Website (optional)', 'Tovuti (hiari)'),
                            hintText: 'https://example.com',
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: workingHoursController,
                          decoration: InputDecoration(
                            labelText: _tr('Working hours (optional)', 'Muda wa kazi (hiari)'),
                            hintText: _tr(
                              'Mon - Sat: 8:00 AM - 6:00 PM',
                              'Jtatu - Jumamosi: 2:00 Asubuhi - 12:00 Jioni',
                            ),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _tr('Social media links (optional)', 'Viungo vya mitandao ya kijamii (hiari)'),
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: facebookController,
                          keyboardType: TextInputType.url,
                          decoration: const InputDecoration(
                            labelText: 'Facebook',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: instagramController,
                          keyboardType: TextInputType.url,
                          decoration: const InputDecoration(
                            labelText: 'Instagram',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: tiktokController,
                          keyboardType: TextInputType.url,
                          decoration: const InputDecoration(
                            labelText: 'TikTok',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: xController,
                          keyboardType: TextInputType.url,
                          decoration: const InputDecoration(
                            labelText: 'X (Twitter)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: linkedinController,
                          keyboardType: TextInputType.url,
                          decoration: const InputDecoration(
                            labelText: 'LinkedIn',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 18),
                        if (isEditing) ...[
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.error,
                                side: BorderSide(color: AppColors.error.withValues(alpha: 0.12)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                                onPressed: () async {
                                final nameConfirmController = TextEditingController();
                                final businessName = (business['name'] as String?)?.trim() ?? '';
                                final confirmed = await showDialog<bool>(
                                  context: dialogContext,
                                  barrierDismissible: false,
                                  builder: (c) => StatefulBuilder(
                                    builder: (sc, setState) {
                                      return AlertDialog(
                                        title: Text(_tr('Confirm deletion', 'Thibitisha kufuta')),
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(_tr(
                                              'Type the business name below to confirm permanent deletion. This action cannot be undone.',
                                              'Andika jina la biashara hapa chini kuthibitisha ufutaji wa kudumu. Hatua hii haitarudishwa.',
                                            )),
                                            const SizedBox(height: 12),
                                            TextField(
                                              controller: nameConfirmController,
                                              decoration: InputDecoration(
                                                hintText: businessName,
                                              ),
                                              onChanged: (_) => setState(() {}),
                                            ),
                                          ],
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.of(c).pop(false),
                                            child: Text(_tr('Cancel', 'Ghairi')),
                                          ),
                                          TextButton(
                                            onPressed: nameConfirmController.text.trim() == businessName
                                                ? () => Navigator.of(c).pop(true)
                                                : null,
                                            child: Text(
                                              _tr('Delete permanently', 'Futa kudumu'),
                                              style: const TextStyle(color: Colors.redAccent),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                );
                                if (confirmed == true) {
                                  if (mounted) Navigator.of(context).pop();
                                  await _deleteBusiness(profile, business);
                                }
                              },
                              icon: const Icon(Icons.delete_outline_rounded),
                              label: Text(_tr('Delete business', 'Futa biashara')),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: isSaving
                                    ? null
                                    : () => Navigator.of(dialogContext).pop(false),
                                child: Text(_tr('Cancel', 'Ghairi')),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isEditing ? AppColors.primaryDark : null,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                icon: Icon(isEditing ? Icons.save_rounded : Icons.add_business_rounded),
                                onPressed: isSaving
                                    ? null
                                    : () async {
                                        final saved = await _saveBusinessForm(
                                          profile: profile,
                                          businessId: businessId,
                                          name: nameController.text.trim(),
                                          category: selectedBusinessType,
                                          place: selectedCity ?? '',
                                          website: websiteController.text,
                                          workingHours: workingHoursController.text,
                                          facebook: facebookController.text,
                                          instagram: instagramController.text,
                                          tiktok: tiktokController.text,
                                          x: xController.text,
                                          linkedin: linkedinController.text,
                                          pickedLogoFile: pickedLogoFile,
                                          existingLogoUrl: existingLogoUrl,
                                        );

                                        if (saved && mounted && dialogContext.mounted) {
                                          Navigator.of(dialogContext).pop(true);
                                        }
                                      },
                                label: Text(
                                  isSaving
                                      ? _tr('Saving...', 'Inahifadhi...')
                                      : isEditing
                                          ? _tr('Save changes', 'Hifadhi mabadiliko')
                                          : _tr('Add business', 'Ongeza biashara'),
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
    websiteController.dispose();
    workingHoursController.dispose();
    facebookController.dispose();
    instagramController.dispose();
    tiktokController.dispose();
    xController.dispose();
    linkedinController.dispose();

    if (result == true && mounted) {
      setState(() {
        _profileFuture = _loadProfile();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditing ? _tr('Business updated.', 'Biashara imesasishwa.') : _tr('Business added.', 'Biashara imeongezwa.'),
          ),
        ),
      );
    }
  }

  Future<bool> _saveBusinessForm({
    required Map<String, dynamic>? profile,
    required String? businessId,
    required String name,
    required String category,
    required String place,
    required String website,
    required String workingHours,
    required String facebook,
    required String instagram,
    required String tiktok,
    required String x,
    required String linkedin,
    File? pickedLogoFile,
    String? existingLogoUrl,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    if (name.isEmpty || place.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_tr(
            'Business name and place are required.',
            'Jina la biashara na mahali vinahitajika.')),
        ),
      );
      return false;
    }

    setState(() => _isSaving = true);
    try {
      final resolvedBusinessId = businessId ?? _firestore
          .collection('tenants')
          .doc(user.uid)
          .collection('businesses')
          .doc()
          .id;
      final websiteValue = _normalizeOptionalUrl(website);
      final workingHoursValue = workingHours.trim();
      final facebookValue = _normalizeOptionalUrl(facebook);
      final instagramValue = _normalizeOptionalUrl(instagram);
      final tiktokValue = _normalizeOptionalUrl(tiktok);
      final xValue = _normalizeOptionalUrl(x);
      final linkedinValue = _normalizeOptionalUrl(linkedin);

      String? newLogoUrl = existingLogoUrl;
      if (pickedLogoFile != null) {
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        try {
          newLogoUrl = await _uploadBusinessLogo(
            userId: user.uid,
            businessId: resolvedBusinessId,
            file: pickedLogoFile,
          );
        } on FirebaseException catch (e) {
          debugPrint('Logo upload failed: ${e.code} ${e.message}');
          if (mounted) {
            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Text(
                  _tr(
                    'Logo upload failed. Business details were saved without changing logo.',
                    'Kupakia nembo kumeshindikana. Taarifa za biashara zimehifadhiwa bila kubadilisha nembo.',
                  ),
                ),
              ),
            );
          }
        }
      }

      final existingBusinesses = _businessesFromProfile(profile);
      final updatedBusinesses = businessId == null
          ? [
              ...existingBusinesses,
              {
                'id': resolvedBusinessId,
                'name': name,
                'category': category,
                'placeOfBusiness': place,
                'website': websiteValue,
                'workingHours': workingHoursValue,
                'facebook': facebookValue,
                'instagram': instagramValue,
                'tiktok': tiktokValue,
                'x': xValue,
                'linkedin': linkedinValue,
                if (newLogoUrl != null && newLogoUrl.isNotEmpty) 'logoUrl': newLogoUrl,
                'createdAt': DateTime.now().toIso8601String(),
              },
            ]
          : existingBusinesses.map((entry) {
              if (entry['id'] != resolvedBusinessId) return entry;
              return <String, dynamic>{
                ...entry,
                'name': name,
                'category': category,
                'placeOfBusiness': place,
                'website': websiteValue,
                'workingHours': workingHoursValue,
                'facebook': facebookValue,
                'instagram': instagramValue,
                'tiktok': tiktokValue,
                'x': xValue,
                'linkedin': linkedinValue,
                if (newLogoUrl != null && newLogoUrl.isNotEmpty) 'logoUrl': newLogoUrl,
              };
            }).toList();

      await _persistBusinesses(
        userId: user.uid,
        businesses: updatedBusinesses,
        selectedBusinessId: _selectedBusinessId(profile) ?? resolvedBusinessId,
      );

      await _firestore
          .collection('tenants')
          .doc(user.uid)
          .collection('businesses')
          .doc(resolvedBusinessId)
          .set({
        'id': resolvedBusinessId,
        'businessName': name,
        'businessCategory': category,
        'placeOfBusiness': place,
        'ownerUid': user.uid,
        'ownerName': profile?['displayName'] ?? profile?['name'] ?? user.displayName,
        'website': websiteValue,
        'workingHours': workingHoursValue,
        'facebook': facebookValue,
        'instagram': instagramValue,
        'tiktok': tiktokValue,
        'x': xValue,
        'linkedin': linkedinValue,
        if (newLogoUrl != null && newLogoUrl.isNotEmpty) 'logoUrl': newLogoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
        if (businessId == null) 'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return true;
    } on FirebaseException catch (e) {
      debugPrint('Business save failed: ${e.code} ${e.message}');
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _tr(
              'Could not save business right now. Please try again.',
              'Imeshindikana kuhifadhi biashara kwa sasa. Tafadhali jaribu tena.',
            ),
          ),
        ),
      );
      return false;
    } catch (e) {
      debugPrint('Business save failed: $e');
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _tr(
              'Could not save business right now. Please try again.',
              'Imeshindikana kuhifadhi biashara kwa sasa. Tafadhali jaribu tena.',
            ),
          ),
        ),
      );
      return false;
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _openBusinessActionsSheet(
    Map<String, dynamic>? profile,
    Map<String, dynamic> business,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
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
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.secondary, AppColors.primaryDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (business['name'] ?? '').toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _tr('Manage, edit, or remove this business.', 'Simamia, hariri, au futa biashara hii.'),
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _ActionSheetButton(
                    icon: Icons.edit_rounded,
                    title: _tr('Edit business info', 'Hariri taarifa za biashara'),
                    subtitle: _tr('Open the business form.', 'Fungua fomu ya biashara.'),
                    color: AppColors.primary,
                    onTap: () async {
                      Navigator.of(sheetContext).pop();
                      await _editBusiness(profile, business);
                    },
                  ),
                  const SizedBox(height: 10),
                  _ActionSheetButton(
                    icon: Icons.delete_outline_rounded,
                    title: _tr('Delete business', 'Futa biashara'),
                    subtitle: _tr('Remove it from your profile.', 'Ondoa kwenye wasifu wako.'),
                    color: AppColors.error,
                    onTap: () async {
                      Navigator.of(sheetContext).pop();
                      await _deleteBusiness(profile, business);
                    },
                    destructive: true,
                  ),
                ],
              ),
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

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text(_tr('Manage businesses', 'Simamia biashara')),
            actions: [
              if (businesses.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.business_center_rounded, size: 16, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          (() {
                            for (final b in businesses) {
                              if (b['id'] == selectedBusinessId) {
                                return (b['name'] ?? '').toString();
                              }
                            }
                            return (businesses.first['name'] ?? '').toString();
                          })(),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, AppColors.primaryDark],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _tr('Start here', 'Anza hapa'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _tr(
                        'Add a new business first',
                        'Ongeza biashara mpya kwanza',
                      ),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _tr(
                        'Create a separate profile for every business and keep each one organized.',
                        'Tengeneza wasifu tofauti kwa kila biashara na uitunze kila moja ikiwa imepangwa vizuri.',
                      ),
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                        child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primaryDark,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: _isSaving ? null : () => _openAddBusinessSheet(profile),
                        icon: const Icon(Icons.add_business_rounded),
                        label: Text(
                          _isSaving
                              ? _tr('Saving...', 'Inahifadhi...')
                              : _tr('Add New Business', 'Ongeza Biashara Mpya'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _tr('Your businesses', 'Biashara zako'),
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              if (businesses.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(_tr(
                      'No businesses added yet.',
                      'Bado hakuna biashara zilizoongezwa.')),
                )
              else
                ...businesses.map(
                  (business) {
                    final name = business['name'] as String;
                    final logoUrl = (business['logoUrl'] as String?)?.trim();
                    final initial =
                        name.isNotEmpty ? name[0].toUpperCase() : 'B';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => _switchToBusiness(business),
                        child: ListTile(
                          tileColor: AppColors.surface,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          leading: CircleAvatar(
                            backgroundColor: AppColors.yellowBrand,
                            backgroundImage: (logoUrl != null && logoUrl.isNotEmpty)
                                ? NetworkImage(logoUrl)
                                : null,
                            child: (logoUrl == null || logoUrl.isEmpty)
                                ? Text(
                                    initial,
                                    style: const TextStyle(
                                      color: AppColors.navyPrimary,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  )
                                : null,
                          ),
                          title: Text(name),
                          subtitle: Text(
                              '${business['category']} • ${business['placeOfBusiness']}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (selectedBusinessId == business['id'])
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Text(
                                    _tr('Active', 'Hai'),
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                constraints: const BoxConstraints.tightFor(width: 36, height: 36),
                                padding: EdgeInsets.zero,
                                onPressed: () => _openBusinessActionsSheet(profile, business),
                                icon: const Icon(Icons.more_vert_rounded),
                                color: AppColors.textSecondary,
                                tooltip: _tr('Business actions', 'Vitendo vya biashara'),
                              ),
                            ],
                          ),
                          onTap: () => _openBusinessActionsSheet(profile, business),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
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

class _ActionSheetButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final bool destructive;

  const _ActionSheetButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: destructive ? color.withValues(alpha: 0.08) : color.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: destructive ? color.withValues(alpha: 0.18) : color.withValues(alpha: 0.12),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: destructive ? AppColors.error : AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: destructive ? AppColors.error : color,
              ),
            ],
          ),
        ),
      ),
    );
  }
}


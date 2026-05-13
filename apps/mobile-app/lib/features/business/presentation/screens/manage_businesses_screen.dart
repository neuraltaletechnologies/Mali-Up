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

  String _selectedBusinessType = 'Retail';
  String? _selectedCity;

  static const List<Map<String, dynamic>> _businessTypes = [
    {'value': 'Retail', 'en': 'Retail', 'sw': 'Uuzaji', 'icon': Icons.store},
    {'value': 'Wholesale', 'en': 'Wholesale', 'sw': 'Uuzaji wa Jumla', 'icon': Icons.store_mall_directory},
    {'value': 'Service', 'en': 'Service', 'sw': 'Huduma', 'icon': Icons.room_service},
    {'value': 'Manufacturing', 'en': 'Manufacturing', 'sw': 'Uzalishaji', 'icon': Icons.build},
    {'value': 'Food & Beverage', 'en': 'Food & Beverage', 'sw': 'Chakula na Vinywaji', 'icon': Icons.restaurant},
    {'value': 'Agriculture', 'en': 'Agriculture', 'sw': 'Kilimo', 'icon': Icons.agriculture},
    {'value': 'Transport', 'en': 'Transport', 'sw': 'Usafiri', 'icon': Icons.local_shipping},
    {'value': 'Construction', 'en': 'Construction', 'sw': 'Ujenzi', 'icon': Icons.construction},
    {'value': 'Healthcare', 'en': 'Healthcare', 'sw': 'Afya', 'icon': Icons.local_hospital},
    {'value': 'Education', 'en': 'Education', 'sw': 'Elimu', 'icon': Icons.school},
    {'value': 'Technology', 'en': 'Technology', 'sw': 'Teknolojia', 'icon': Icons.computer},
    {'value': 'Hospitality', 'en': 'Hospitality', 'sw': 'Ukarimu', 'icon': Icons.hotel},
    {'value': 'Beauty & Wellness', 'en': 'Beauty & Wellness', 'sw': 'Uzuri na Afya', 'icon': Icons.spa},
    {'value': 'Entertainment', 'en': 'Entertainment', 'sw': 'Burudani', 'icon': Icons.theater_comedy},
    {'value': 'Real Estate', 'en': 'Real Estate', 'sw': 'Mali Isiyohamishika', 'icon': Icons.apartment},
    {'value': 'Financial Services', 'en': 'Financial Services', 'sw': 'Huduma za Kifedha', 'icon': Icons.account_balance},
    {'value': 'Professional Services', 'en': 'Professional Services', 'sw': 'Huduma za Kitaalam', 'icon': Icons.business_center},
    {'value': 'Other', 'en': 'Other', 'sw': 'Nyingine', 'icon': Icons.category},
  ];

  static const List<Map<String, String>> _tanzaniaCities = [
    {'en': 'Dar es Salaam', 'sw': 'Dar es Salaam'},
    {'en': 'Dodoma', 'sw': 'Dodoma'},
    {'en': 'Mwanza', 'sw': 'Mwanza'},
    {'en': 'Arusha', 'sw': 'Arusha'},
    {'en': 'Mbeya', 'sw': 'Mbeya'},
    {'en': 'Morogoro', 'sw': 'Morogoro'},
    {'en': 'Tanga', 'sw': 'Tanga'},
    {'en': 'Zanzibar', 'sw': 'Zanzibar'},
    {'en': 'Kigoma', 'sw': 'Kigoma'},
    {'en': 'Mtwara', 'sw': 'Mtwara'},
    {'en': 'Tabora', 'sw': 'Tabora'},
    {'en': 'Iringa', 'sw': 'Iringa'},
    {'en': 'Singida', 'sw': 'Singida'},
    {'en': 'Shinyanga', 'sw': 'Shinyanga'},
    {'en': 'Musoma', 'sw': 'Musoma'},
    {'en': 'Bukoba', 'sw': 'Bukoba'},
    {'en': 'Sumbawanga', 'sw': 'Sumbawanga'},
    {'en': 'Njombe', 'sw': 'Njombe'},
    {'en': 'Other', 'sw': 'Nyingine'},
  ];

  @override
  void initState() {
    super.initState();
    _profileFuture = _loadProfile();
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    super.dispose();
  }

  Future<void> _showAddBusinessTypeSheet() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MaliSelectSheet<String>(
        title: _tr('Business Type', 'Aina ya Biashara'),
        items: _businessTypes.map((t) => t['value'] as String).toList(),
        selectedValue: _selectedBusinessType,
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
          return type['icon'] as IconData;
        },
      ),
    );
    if (selected != null && mounted) {
      setState(() => _selectedBusinessType = selected);
    }
  }

  Future<void> _showAddCitySheet() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MaliSelectSheet<String>(
        title: _tr('City / Region', 'Mji / Mkoa'),
        items: _tanzaniaCities.map((c) => c['en']!).toList(),
        selectedValue: _selectedCity,
        labelBuilder: (value) {
          final city = _tanzaniaCities.firstWhere(
            (c) => c['en'] == value,
            orElse: () => _tanzaniaCities.first,
          );
          return _tr(city['en']!, city['sw']!);
        },
      ),
    );
    if (selected != null && mounted) {
      setState(() => _selectedCity = selected);
    }
  }

  String _tr(String en, String sw) => LocalizationService.tr(en: en, sw: sw);

  String _normalizeBucketName(String bucket) {
    var value = bucket.trim();
    if (value.startsWith('gs://')) {
      value = value.substring(5);
    }
    if (value.endsWith('/')) {
      value = value.substring(0, value.length - 1);
    }
    return value;
  }

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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final businessId = business['id'] as String;
    final nameController = TextEditingController(text: (business['name'] as String?) ?? '');
    String editBusinessType = () {
      final stored = (business['category'] as String?) ?? '';
      return _businessTypes.any((t) => t['value'] == stored) ? stored : 'Retail';
    }();
    String? editCity = (business['placeOfBusiness'] as String?)?.trim();
    if (editCity != null && !_tanzaniaCities.any((c) => c['en'] == editCity)) {
      editCity = null;
    }
    bool isSaving = false;
    File? pickedLogoFile;
    final existingLogoUrl = (business['logoUrl'] as String?)?.trim();

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final currentName = nameController.text.trim();
            final initial = currentName.isNotEmpty ? currentName[0].toUpperCase() : 'B';

            return AlertDialog(
              title: Text(_tr('Edit business', 'Hariri biashara')),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo picker
                    GestureDetector(
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
                              if (picked == null) return;
                              if (!dialogContext.mounted) return;
                              setDialogState(() => pickedLogoFile = File(picked.path));
                            },
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
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
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
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
                          (t) => t['value'] == editBusinessType,
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
                            items: _businessTypes.map((t) => t['value'] as String).toList(),
                            selectedValue: editBusinessType,
                            labelBuilder: (v) {
                              final t = _businessTypes.firstWhere(
                                (t) => t['value'] == v,
                                orElse: () => _businessTypes.first,
                              );
                              return _tr(t['en'] as String, t['sw'] as String);
                            },
                            iconBuilder: (v) {
                              final t = _businessTypes.firstWhere(
                                (t) => t['value'] == v,
                                orElse: () => _businessTypes.first,
                              );
                              return t['icon'] as IconData;
                            },
                          ),
                        );
                        if (selected != null) {
                          setDialogState(() => editBusinessType = selected);
                        }
                      },
                      icon: Icons.category_rounded,
                    ),
                    const SizedBox(height: 12),
                    MaliSelectField(
                      placeholder: _tr('City / Region', 'Mji / Mkoa'),
                      displayValue: () {
                        if (editCity == null) return '';
                        final city = _tanzaniaCities.firstWhere(
                          (c) => c['en'] == editCity,
                          orElse: () => _tanzaniaCities.first,
                        );
                        return _tr(city['en']!, city['sw']!);
                      }(),
                      hasValue: editCity != null,
                      onTap: () async {
                        final selected = await showModalBottomSheet<String>(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => MaliSelectSheet<String>(
                            title: _tr('City / Region', 'Mji / Mkoa'),
                            items: _tanzaniaCities.map((c) => c['en']!).toList(),
                            selectedValue: editCity,
                            labelBuilder: (v) {
                              final c = _tanzaniaCities.firstWhere(
                                (c) => c['en'] == v,
                                orElse: () => _tanzaniaCities.first,
                              );
                              return _tr(c['en']!, c['sw']!);
                            },
                          ),
                        );
                        if (selected != null) {
                          setDialogState(() => editCity = selected);
                        }
                      },
                      icon: Icons.location_on_outlined,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.of(dialogContext).pop(false),
                  child: Text(_tr('Cancel', 'Ghairi')),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final name = nameController.text.trim();
                          final place = editCity ?? '';
                          final category = editBusinessType;
                          if (name.isEmpty || place.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(_tr(
                                  'Business name and place are required.',
                                  'Jina la biashara na mahali vinahitajika.',
                                )),
                              ),
                            );
                            return;
                          }

                          setDialogState(() => isSaving = true);

                          // Upload logo if a new one was picked
                          String? newLogoUrl = existingLogoUrl;
                          if (pickedLogoFile != null) {
                            try {
                              newLogoUrl = await _uploadBusinessLogo(
                                userId: user.uid,
                                businessId: businessId,
                                file: pickedLogoFile!,
                              );
                            } on FirebaseException catch (e) {
                              debugPrint('Logo upload failed: ${e.code} ${e.message}');
                              if (mounted) {
                                ScaffoldMessenger.of(this.context).showSnackBar(
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

                          final updatedBusinesses = _businessesFromProfile(profile)
                              .map((entry) {
                                if (entry['id'] != businessId) return entry;
                                return <String, dynamic>{
                                  ...entry,
                                  'name': name,
                                  'category': category,
                                  'placeOfBusiness': place,
                                  if (newLogoUrl != null && newLogoUrl.isNotEmpty)
                                    'logoUrl': newLogoUrl,
                                };
                              })
                              .toList();

                          await _persistBusinesses(
                            userId: user.uid,
                            businesses: updatedBusinesses,
                            selectedBusinessId: _selectedBusinessId(profile) ?? businessId,
                          );

                          await _firestore
                              .collection('tenants')
                              .doc(user.uid)
                              .collection('businesses')
                              .doc(businessId)
                              .set({
                            'id': businessId,
                            'businessName': name,
                            'businessCategory': category,
                            'placeOfBusiness': place,
                            'ownerUid': user.uid,
                            'ownerName': profile?['displayName'] ??
                                profile?['name'] ??
                                user.displayName,
                            if (newLogoUrl != null && newLogoUrl.isNotEmpty)
                              'logoUrl': newLogoUrl,
                            'updatedAt': FieldValue.serverTimestamp(),
                          }, SetOptions(merge: true));

                          if (!mounted) return;
                          Navigator.of(this.context, rootNavigator: true).pop(true);
                        },
                  child: Text(
                    isSaving
                        ? _tr('Saving...', 'Inahifadhi...')
                        : _tr('Save', 'Hifadhi'),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    placeController.dispose();
    categoryController.dispose();

    if (result == true && mounted) {
      setState(() {
        _profileFuture = _loadProfile();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_tr('Business updated.', 'Biashara imesasishwa.'))),
      );
    }
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

  Future<void> _addBusiness(Map<String, dynamic>? profile) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final businessName = _businessNameController.text.trim();
    final placeOfBusiness = _selectedCity ?? '';

    if (businessName.isEmpty || placeOfBusiness.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_tr(
            'Please fill business name and select a location.',
            'Tafadhali jaza jina la biashara na chagua mahali.',
          )),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    final businessId = _firestore
        .collection('tenants')
        .doc(user.uid)
        .collection('businesses')
        .doc()
        .id;
    final existingBusinesses = _businessesFromProfile(profile);
    final newBusinesses = [
      ...existingBusinesses,
      {
        'id': businessId,
        'name': businessName,
        'category': _selectedBusinessType,
        'placeOfBusiness': placeOfBusiness,
        'createdAt': FieldValue.serverTimestamp(),
      },
    ];

    await _firestore.collection('users').doc(user.uid).set({
      'businesses': newBusinesses,
      'selectedBusinessId': businessId,
      'defaultContext': 'business:$businessId',
      'defaultAccountType': 'business',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _firestore
        .collection('tenants')
        .doc(user.uid)
        .collection('businesses')
        .doc(businessId)
        .set({
      'id': businessId,
      'businessName': businessName,
      'businessCategory': _selectedBusinessType,
      'placeOfBusiness': placeOfBusiness,
      'ownerUid': user.uid,
      'ownerName': profile?['displayName'] ?? profile?['name'] ?? user.displayName,
      'createdAt': FieldValue.serverTimestamp(),
      'plan': 'Trial',
    }, SetOptions(merge: true));

    if (!mounted) return;
    setState(() {
      _isSaving = false;
      _profileFuture = _loadProfile();
      _businessNameController.clear();
      _selectedBusinessType = 'Retail';
      _selectedCity = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_tr(
          'Business added and set active.',
          'Biashara imeongezwa na kuwekwa hai.',
        )),
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

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text(_tr('Manage businesses', 'Simamia biashara')),
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                _tr(
                  'Add a new business you want to monitor.',
                  'Ongeza biashara mpya unayotaka kufuatilia.',
                ),
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _businessNameController,
                      decoration: InputDecoration(
                        labelText: _tr('Business name', 'Jina la biashara'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: AppColors.background,
                      ),
                    ),
                    const SizedBox(height: 12),
                    MaliSelectField(
                      placeholder: _tr('Business Type', 'Aina ya Biashara'),
                      displayValue: () {
                        final type = _businessTypes.firstWhere(
                          (t) => t['value'] == _selectedBusinessType,
                          orElse: () => _businessTypes.first,
                        );
                        return _tr(
                          type['en'] as String,
                          type['sw'] as String,
                        );
                      }(),
                      hasValue: true,
                      onTap: _showAddBusinessTypeSheet,
                      icon: Icons.category_rounded,
                    ),
                    const SizedBox(height: 12),
                    MaliSelectField(
                      placeholder: _tr('City / Region', 'Mji / Mkoa'),
                      displayValue: () {
                        if (_selectedCity == null) return '';
                        final city = _tanzaniaCities.firstWhere(
                          (c) => c['en'] == _selectedCity,
                          orElse: () => _tanzaniaCities.first,
                        );
                        return _tr(city['en']!, city['sw']!);
                      }(),
                      hasValue: _selectedCity != null,
                      onTap: _showAddCitySheet,
                      icon: Icons.location_on_outlined,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed:
                            _isSaving ? null : () => _addBusiness(profile),
                        child: Text(
                          _isSaving
                              ? _tr('Saving...', 'Inahifadhi...')
                              : _tr('Add business', 'Ongeza biashara'),
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
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') {
                                _editBusiness(profile, business);
                              }
                              if (value == 'delete') {
                                _deleteBusiness(profile, business);
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem<String>(
                                value: 'edit',
                                child: Text(_tr('Edit', 'Hariri')),
                              ),
                              PopupMenuItem<String>(
                                value: 'delete',
                                child: Text(_tr('Delete', 'Futa')),
                              ),
                            ],
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (selectedBusinessId == business['id'])
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: Text(_tr('Active', 'Hai')),
                                  ),
                                const Icon(Icons.more_vert_rounded),
                              ],
                            ),
                          ),
                          onTap: () => _switchToBusiness(business),
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

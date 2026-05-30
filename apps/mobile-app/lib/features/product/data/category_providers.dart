import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/repositories/context_firestore_repository.dart';
import '../../customer/data/customer_providers.dart';
import '../domain/models/product_category.dart';

const List<String> _retailCategories = [
  'Groceries',
  'Beverages',
  'Snacks',
  'Household Items',
  'Personal Care',
  'Stationery',
  'Cleaning Supplies',
  'Other',
];

const List<String> _foodCategories = [
  'Ingredients',
  'Fresh Produce',
  'Prepared Food',
  'Beverages',
  'Snacks',
  'Bakery',
  'Condiments',
  'Other',
];

const List<String> _fashionCategories = [
  'Men Wear',
  'Women Wear',
  'Kids Wear',
  'Shoes',
  'Bags & Accessories',
  'Fabrics',
  'Other',
];

const List<String> _beautyCategories = [
  'Cosmetics',
  'Hair Care',
  'Skin Care',
  'Nails',
  'Barber Supplies',
  'Wigs & Extensions',
  'Other',
];

const List<String> _electronicsCategories = [
  'Phones',
  'Phone Accessories',
  'Computers',
  'TV & Audio',
  'Chargers & Cables',
  'Home Appliances',
  'Other',
];

const List<String> _pharmacyCategories = [
  'Prescription Medicine',
  'OTC Medicine',
  'Medical Supplies',
  'Vitamins & Supplements',
  'Baby Care',
  'Personal Care',
  'Other',
];

const List<String> _agricultureCategories = [
  'Seeds',
  'Fertilizers',
  'Pesticides',
  'Feeds',
  'Tools & Equipment',
  'Produce',
  'Other',
];

const List<String> _hardwareCategories = [
  'Cement',
  'Sand & Aggregate',
  'Steel',
  'Timber',
  'Plumbing',
  'Electrical',
  'Tools',
  'Other',
];

const List<String> _transportCategories = [
  'Fuel',
  'Engine Oil',
  'Tyres',
  'Spare Parts',
  'Accessories',
  'Maintenance Supplies',
  'Other',
];

const List<String> _serviceCategories = [
  'Consumables',
  'Office Supplies',
  'Equipment',
  'Digital Products',
  'Other',
];

String _normalizeBusinessType(String businessType) {
  final normalized = businessType.trim().toLowerCase();
  switch (normalized) {
    case 'retail shop':
    case 'retail':
      return 'retail';
    case 'wholesale':
      return 'wholesale';
    case 'supermarket':
      return 'supermarket';
    case 'grocery & convenience':
    case 'grocery_convenience':
      return 'grocery_convenience';
    case 'electronics & mobile phones':
    case 'electronics':
      return 'electronics';
    case 'fashion & boutique':
      return 'fashion';
    case 'tailoring & textiles':
    case 'tailoring':
      return 'tailoring';
    case 'beauty & cosmetics':
    case 'beauty':
      return 'beauty';
    case 'salon & barber':
    case 'salon':
      return 'salon';
    case 'restaurant':
    case 'restaurant / café':
      return 'restaurant';
    case 'cafe & bakery':
      return 'cafe_bakery';
    case 'street food':
      return 'street_food';
    case 'catering':
      return 'catering';
    case 'agriculture':
    case 'agriculture & farming':
      return 'agriculture';
    case 'agribusiness':
      return 'agribusiness';
    case 'livestock & poultry':
      return 'livestock_poultry';
    case 'fishing':
      return 'fishing';
    case 'manufacturing':
      return 'manufacturing';
    case 'construction':
      return 'construction';
    case 'hardware & building materials':
    case 'hardware':
      return 'hardware';
    case 'transportation & logistics':
    case 'transport':
      return 'transport';
    case 'travel & tours':
    case 'travel':
      return 'travel';
    case 'hotel & accommodation':
    case 'hotel':
      return 'hotel';
    case 'pharmacy & healthcare':
    case 'pharmacy':
      return 'pharmacy';
    case 'clinic & laboratory':
    case 'clinic':
      return 'clinic';
    case 'education & training':
    case 'education':
      return 'education';
    case 'real estate':
    case 'real_estate':
      return 'real_estate';
    case 'financial services':
      return 'financial_services';
    case 'ict & software':
      return 'ict';
    case 'printing & stationery':
    case 'printing':
      return 'printing';
    case 'automotive & spare parts':
      return 'automotive';
    case 'fuel & lubricants':
      return 'fuel';
    case 'e-commerce':
    case 'ecommerce':
      return 'ecommerce';
    case 'entertainment & events':
      return 'entertainment';
    case 'cleaning services':
    case 'cleaning':
      return 'cleaning';
    case 'security services':
    case 'security_guard':
      return 'security';
    case 'ngo & community services':
      return 'ngo';
    case 'export & import':
      return 'export_import';
    case 'agricultural inputs':
      return 'agricultural_inputs';
    case 'media & communications':
    case 'media':
      return 'media';
    case 'jewelry & crafts':
      return 'jewelry';
    case 'furniture & carpentry':
      return 'furniture';
    case 'water & beverages':
      return 'water';
    case 'auto repair':
      return 'auto_repair';
    default:
      return normalized.replaceAll(RegExp(r'[^a-z0-9]+'), '_').replaceAll(RegExp(r'_+'), '_').replaceAll(RegExp(r'^_|_$'), '');
  }
}

String _categoryDocumentId(String name) {
  return name
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
}

String _businessTypeFromProfile(Map<String, dynamic>? profile, String businessId) {
  final businessesRaw = profile?['businesses'];
  if (businessesRaw is List) {
    for (final entry in businessesRaw.whereType<Map>()) {
      final entryId = (entry['id'] as String?)?.trim() ?? '';
      if (businessId.isNotEmpty && entryId != businessId) continue;
      final rawType = (entry['type'] as String?) ??
          (entry['businessType'] as String?) ??
          (entry['category'] as String?) ??
          '';
      final normalized = _normalizeBusinessType(rawType);
      if (normalized.isNotEmpty) return normalized;
    }
    if (businessesRaw.isNotEmpty) {
      final first = businessesRaw.whereType<Map>().first;
      final rawType = (first['type'] as String?) ??
          (first['businessType'] as String?) ??
          (first['category'] as String?) ??
          '';
      final normalized = _normalizeBusinessType(rawType);
      if (normalized.isNotEmpty) return normalized;
    }
  }

  final rawFallback = (profile?['businessType'] as String?) ??
      (profile?['businessCategory'] as String?) ??
      '';
  return _normalizeBusinessType(rawFallback);
}

List<String> defaultCategoriesForBusinessType(String businessType) {
  switch (_normalizeBusinessType(businessType)) {
    case 'wholesale':
    case 'supermarket':
    case 'grocery_convenience':
      return _retailCategories;
    case 'electronics':
      return _electronicsCategories;
    case 'fashion':
    case 'tailoring':
      return _fashionCategories;
    case 'beauty':
    case 'salon':
      return _beautyCategories;
    case 'restaurant':
    case 'cafe_bakery':
    case 'street_food':
    case 'catering':
      return _foodCategories;
    case 'agriculture':
    case 'agribusiness':
    case 'livestock_poultry':
    case 'fishing':
    case 'agricultural_inputs':
      return _agricultureCategories;
    case 'manufacturing':
    case 'construction':
    case 'hardware':
      return _hardwareCategories;
    case 'transport':
    case 'automotive':
    case 'fuel':
    case 'auto_repair':
      return _transportCategories;
    case 'pharmacy':
    case 'clinic':
    case 'education':
    case 'real_estate':
    case 'financial_services':
    case 'ict':
    case 'printing':
    case 'ecommerce':
    case 'entertainment':
    case 'cleaning':
    case 'security':
    case 'ngo':
    case 'export_import':
    case 'media':
    case 'jewelry':
    case 'furniture':
    case 'water':
    case 'travel':
    case 'hotel':
      return _serviceCategories;
    case 'retail':
    default:
      return _retailCategories;
  }
}

Future<void> _seedDefaultCategoriesIfNeeded({
  required ContextFirestoreRepository repo,
  required String uid,
  required String bizId,
  required String businessType,
}) async {
  final col = repo.scopeCollection(
    uid: uid,
    context: ResolvedFinanceContext.business(bizId),
    childCollection: 'categories',
  );
  final snapshot = await col.get();
  final existingNames = snapshot.docs
      .map((doc) => (doc.data()['name'] as String?)?.trim().toLowerCase() ?? '')
      .where((name) => name.isNotEmpty)
      .toSet();

  final defaults = defaultCategoriesForBusinessType(businessType);
  final missingDefaults = defaults
      .where((name) => !existingNames.contains(name.trim().toLowerCase()))
      .toList();

  if (missingDefaults.isEmpty) return;

  final batch = FirebaseFirestore.instance.batch();
  for (final name in missingDefaults) {
    final docId = _categoryDocumentId(name);
    batch.set(
      col.doc(docId),
      {
        'name': name,
        'businessType': _normalizeBusinessType(businessType),
        'isDefault': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
  await batch.commit();
}

/// Streams the categories for the currently active business.
/// Path: tenants/{uid}/businesses/{bizId}/categories
final categoryListProvider = StreamProvider<List<ProductCategory>>((ref) async* {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    yield const <ProductCategory>[];
    return;
  }
  final businessAsync = ref.watch(currentBusinessIdProvider);
  if (businessAsync.isLoading) return;
  final bizId = businessAsync.valueOrNull;
  if (bizId == null || bizId.isEmpty) {
    yield const <ProductCategory>[];
    return;
  }
  final businessType = ref.watch(currentBusinessTypeProvider).valueOrNull ?? '';
  final repo = ref.read(contextFirestoreRepositoryProvider);
  final col = repo.scopeCollection(
    uid: user.uid,
    context: ResolvedFinanceContext.business(bizId),
    childCollection: 'categories',
  );
  await _seedDefaultCategoriesIfNeeded(
    repo: repo,
    uid: user.uid,
    bizId: bizId,
    businessType: businessType,
  );
  yield* col
      .orderBy('name')
      .snapshots()
      .map((snap) => snap.docs
          .map((d) => ProductCategory.fromFirestore(d.data(), d.id))
          .toList());
});

/// Streams the businessType string of the user's currently active business.
/// Reads from the active business entry in users/{uid}.businesses.
final currentBusinessTypeProvider = StreamProvider<String>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value('');
  final businessAsync = ref.watch(currentBusinessIdProvider);
  if (businessAsync.isLoading) return Stream.value('');
  final activeBusinessId = businessAsync.valueOrNull ?? '';
  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .snapshots()
      .map((snap) => _businessTypeFromProfile(snap.data(), activeBusinessId));
});

/// Adds a new category and returns its generated document ID.
Future<String> addCategory({
  required String uid,
  required String bizId,
  required String businessType,
  required String name,
  required ContextFirestoreRepository repo,
}) async {
  final resolvedBizId = bizId.isNotEmpty
      ? bizId
      : (await repo.resolveContextForUser(uid)).businessId ?? '';
  if (resolvedBizId.isEmpty) {
    throw StateError('No active business found for category creation.');
  }

  final categoryName = name.trim();
  if (categoryName.isEmpty) {
    throw ArgumentError.value(name, 'name', 'Category name cannot be empty');
  }

  final col = repo.scopeCollection(
    uid: uid,
    context: ResolvedFinanceContext.business(resolvedBizId),
    childCollection: 'categories',
  );
  final docId = _categoryDocumentId(categoryName);
  await col.doc(docId).set({
    'name': categoryName,
    'businessType': _normalizeBusinessType(businessType),
    'isDefault': false,
    'createdAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));
  return docId;
}

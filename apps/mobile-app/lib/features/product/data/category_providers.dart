import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/repositories/context_firestore_repository.dart';
import '../../customer/data/customer_providers.dart';
// ─────────────────────────────────────────────────────────────────────────────
// Normalise business type key to a canonical token
// Handles all keys in onboarding_strings.dart + legacy variants
// ─────────────────────────────────────────────────────────────────────────────

String _normalizeBusinessType(String businessType) {
  final s = businessType.trim().toLowerCase();
  switch (s) {
    // ── Retail / Wholesale ─────────────────────────────────────────────────
    case 'retail':
    case 'retail shop':
      return 'retail';
    case 'wholesale':
      return 'wholesale';
    case 'supermarket':
    case 'grocery_convenience':
    case 'grocery & convenience':
      return 'wholesale';

    // ── Food / Beverage ────────────────────────────────────────────────────
    case 'food_beverages':
    case 'food & beverages':
    case 'restaurant':
    case 'restaurant / café':
    case 'restaurant / cafe':
    case 'cafe_bakery':
    case 'cafe & bakery':
    case 'street_food':
    case 'street food':
    case 'catering':
      return 'restaurant';

    // ── Electronics ────────────────────────────────────────────────────────
    case 'electronics':
    case 'electronics & mobile phones':
      return 'electronics';

    // ── Fashion / Boutique ─────────────────────────────────────────────────
    case 'tailoring':
    case 'tailoring & fashion':
    case 'tailoring & textiles':
      return 'tailoring';

    // ── Beauty / Salon ─────────────────────────────────────────────────────
    case 'salon':
    case 'salon & beauty':
    case 'salon & barber':
    case 'beauty':
    case 'beauty & cosmetics':
      return 'salon';

    // ── Hardware / Construction ────────────────────────────────────────────
    case 'hardware':
    case 'hardware & building':
    case 'hardware & building materials':
      return 'hardware';
    case 'construction':
      return 'construction';

    // ── Pharmacy / Health ──────────────────────────────────────────────────
    case 'pharmacy':
    case 'pharmacy & healthcare':
    case 'health':
    case 'health & wellness':
    case 'clinic':
    case 'clinic & laboratory':
      return 'pharmacy';

    // ── Agriculture ────────────────────────────────────────────────────────
    case 'agriculture':
    case 'agriculture & farming':
    case 'agribusiness':
    case 'livestock_poultry':
    case 'livestock & poultry':
    case 'fishing':
    case 'agricultural_inputs':
    case 'agricultural inputs':
      return 'agriculture';

    // ── Transport / Automotive ─────────────────────────────────────────────
    case 'transport':
    case 'transport & logistics':
    case 'transportation & logistics':
    case 'automotive':
    case 'automotive & spare parts':
    case 'fuel':
    case 'fuel & lubricants':
    case 'auto_repair':
    case 'auto repair':
      return 'transport';

    // ── Services (generic) ─────────────────────────────────────────────────
    case 'education':
    case 'education & training':
    case 'real_estate':
    case 'real estate':
    case 'printing':
    case 'printing & branding':
    case 'printing & stationery':
    case 'cleaning':
    case 'cleaning services':
    case 'tech_services':
    case 'it & tech services':
    case 'ict & software':
    case 'events':
    case 'events & entertainment':
    case 'entertainment & events':
    case 'freelance':
    case 'freelancing':
    case 'consultancy':
    case 'banking_finance':
    case 'banking & finance':
    case 'financial services':
    case 'insurance':
    case 'mobile_money':
    case 'mobile money agent':
    case 'photography':
    case 'photography & video':
    case 'media':
    case 'media & marketing':
    case 'media & communications':
    case 'legal':
    case 'legal services':
    case 'security_guard':
    case 'security services':
    case 'travel':
    case 'travel & tourism':
    case 'travel & tours':
    case 'hotel':
    case 'hotel & accommodation':
    case 'ngo':
    case 'ngo & community services':
    case 'export_import':
    case 'export & import':
    case 'jewelry':
    case 'jewelry & crafts':
    case 'furniture':
    case 'furniture & carpentry':
    case 'water':
    case 'water & beverages':
    case 'manufacturing':
    case 'ecommerce':
    case 'e-commerce':
      return 'service';

    case 'other':
    default:
      return 'retail';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Internal helpers
// ─────────────────────────────────────────────────────────────────────────────

String _businessTypeFromProfile(
    Map<String, dynamic>? profile, String businessId) {
  final businessesRaw = profile?['businesses'];
  if (businessesRaw is List) {
    for (final entry in businessesRaw.whereType<Map>()) {
      final entryId = (entry['id'] as String?)?.trim() ?? '';
      if (businessId.isNotEmpty && entryId != businessId) continue;
      final raw = (entry['type'] as String?) ??
          (entry['businessType'] as String?) ??
          (entry['category'] as String?) ??
          '';
      final normalized = _normalizeBusinessType(raw);
      if (normalized.isNotEmpty) return normalized;
    }
    if (businessesRaw.isNotEmpty) {
      final first = businessesRaw.whereType<Map>().first;
      final raw = (first['type'] as String?) ??
          (first['businessType'] as String?) ??
          (first['category'] as String?) ??
          '';
      return _normalizeBusinessType(raw);
    }
  }
  final raw = (profile?['businessType'] as String?) ??
      (profile?['businessCategory'] as String?) ??
      '';
  return _normalizeBusinessType(raw);
}

// ─────────────────────────────────────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────────────────────────────────────

/// Streams the normalised business type key of the active business.
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

// ─────────────────────────────────────────────────────────────────────────────
// Mutation helpers
// ─────────────────────────────────────────────────────────────────────────────

/// Creates a custom category in the business's own Firestore subcollection
/// and returns the generated document ID.
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

  final docId = categoryName
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');

  final col = repo.scopeCollection(
    uid: uid,
    context: ResolvedFinanceContext.business(resolvedBizId),
    childCollection: 'categories',
  );
  await col.doc(docId).set(
    {
      'name': categoryName,
      'businessType': _normalizeBusinessType(businessType),
      'isDefault': false,
      'createdAt': FieldValue.serverTimestamp(),
    },
    SetOptions(merge: true),
  );
  return docId;
}

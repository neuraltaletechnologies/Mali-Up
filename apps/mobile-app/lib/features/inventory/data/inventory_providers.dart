import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../customer/data/customer_providers.dart';
import '../../sales/data/sales_providers.dart';

final inventoryItemListProvider = StreamProvider<List<Map<String, dynamic>>>((ref) async* {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    yield const <Map<String, dynamic>>[];
    return;
  }

  final repository = ref.watch(contextFirestoreRepositoryProvider);
  final context = await repository.resolveContextForUser(user.uid);
  final collection = repository.scopeCollection(
    uid: user.uid,
    context: context,
    childCollection: 'inventory_items',
  );

  yield* collection
      .orderBy('updatedAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
});

int parseStock(Object? value) {
  if (value == null) return 0;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}

double parseUnitPrice(Object? value) {
  return parseNumericAmount(value);
}

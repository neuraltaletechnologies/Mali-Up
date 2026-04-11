import '../domain/models/customer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/data/repositories/context_firestore_repository.dart';

final contextFirestoreRepositoryProvider = Provider<ContextFirestoreRepository>((ref) {
  return ContextFirestoreRepository();
});

final customerListProvider = StreamProvider<List<Customer>>((ref) async* {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    yield const <Customer>[];
    return;
  }

  final repository = ref.watch(contextFirestoreRepositoryProvider);
  final context = await repository.resolveContextForUser(user.uid);

  yield* repository.watchCustomers(uid: user.uid, context: context);
});


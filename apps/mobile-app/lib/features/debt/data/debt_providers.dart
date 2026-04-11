import '../domain/models/debt.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../customer/data/customer_providers.dart';

final debtListProvider = StreamProvider<List<Debt>>((ref) async* {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    yield const <Debt>[];
    return;
  }

  final repository = ref.watch(contextFirestoreRepositoryProvider);
  final context = await repository.resolveContextForUser(user.uid);

  yield* repository.watchDebts(uid: user.uid, context: context);
});


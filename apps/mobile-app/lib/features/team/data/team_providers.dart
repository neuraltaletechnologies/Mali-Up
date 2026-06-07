import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/repositories/context_firestore_repository.dart';
import '../../customer/data/customer_providers.dart';
import '../domain/models/team_member.dart';

final teamMembersProvider = StreamProvider<List<TeamMember>>((ref) async* {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    yield const [];
    return;
  }
  final bizId = ref.watch(currentBusinessIdProvider).valueOrNull;
  if (bizId == null || bizId.isEmpty) {
    yield const [];
    return;
  }
  final repo = ref.read(contextFirestoreRepositoryProvider);
  yield* repo.watchTeamMembers(
    uid: user.uid,
    context: ResolvedFinanceContext.business(bizId),
  );
});

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../customer/data/customer_providers.dart';
import '../domain/models/team_member.dart';

final teamMembersProvider = StreamProvider<List<TeamMember>>((ref) async* {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    yield [];
    return;
  }
  final repo = ref.read(contextFirestoreRepositoryProvider);
  final ctx = await repo.resolveContextForUser(user.uid);
  yield* repo.watchTeamMembers(uid: user.uid, context: ctx);
});

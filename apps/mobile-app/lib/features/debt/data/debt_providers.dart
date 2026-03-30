import '../domain/models/debt.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

final debtListProvider = StreamProvider<List<Debt>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return const Stream.empty();

  final query = FirebaseFirestore.instance
      .collection('tenants')
      .doc(user.uid)
      .collection('debts')
      .orderBy('dueDate');

  return query.snapshots().map((snapshot) {
    return snapshot.docs.map((doc) {
      return Debt.fromFirestore(doc.data(), doc.id);
    }).toList();
  });
});


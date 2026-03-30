import '../domain/models/customer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

final customerListProvider = StreamProvider<List<Customer>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  
  // If not logged in, return an empty list or redirect logic (usually handled at app level)
  if (user == null) return const Stream.empty();

  final query = FirebaseFirestore.instance
      .collection('tenants')
      .doc(user.uid)
      .collection('customers')
      .orderBy('name');

  return query.snapshots().map((snapshot) {
    return snapshot.docs.map((doc) {
      return Customer.fromFirestore(doc.data(), doc.id);
    }).toList();
  });
});


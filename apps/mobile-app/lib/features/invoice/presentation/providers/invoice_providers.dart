import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/business_id_provider.dart';
import '../../../../core/providers/sync_provider.dart';
import '../../data/repositories/sync_invoice_repository.dart';
import '../../domain/models/invoice.dart';

/// The app's single invoice repository. Rebuilt automatically when
/// uid or businessId changes (sign-out, business switch).
final invoiceRepositoryProvider = Provider<SyncInvoiceRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  final bizId = ref.watch(currentBusinessIdProvider).valueOrNull ?? '';
  final policy = ref.watch(offlinePolicyProvider);
  return SyncInvoiceRepository(db: db, uid: uid, businessId: bizId, policy: policy);
});

/// Live stream of all non-deleted invoices for the active business.
/// Backed by Drift — works fully offline.
final invoicesProvider = StreamProvider<List<Invoice>>((ref) {
  return ref.watch(invoiceRepositoryProvider).watchAll();
});

final pendingInvoicesProvider = StreamProvider<List<Invoice>>((ref) {
  return ref.watch(invoiceRepositoryProvider).watchByStatus('pending');
});

final paidInvoicesProvider = StreamProvider<List<Invoice>>((ref) {
  return ref.watch(invoiceRepositoryProvider).watchByStatus('paid');
});

final overdueInvoicesProvider = StreamProvider<List<Invoice>>((ref) {
  return ref.watch(invoiceRepositoryProvider).watchOverdue();
});

final totalOutstandingProvider = FutureProvider<double>((ref) {
  return ref.watch(invoiceRepositoryProvider).getTotalOutstanding();
});

final monthlySalesProvider =
    FutureProvider.family<Map<String, double>, int>((ref, year) {
  return ref.watch(invoiceRepositoryProvider).getMonthlySales(year);
});

final customerInvoicesProvider =
    FutureProvider.family<List<Invoice>, String>((ref, customerId) {
  return ref.watch(invoiceRepositoryProvider).getByCustomer(customerId);
});

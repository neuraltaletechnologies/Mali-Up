import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/sync_provider.dart';
import '../../customer/data/customer_providers.dart';
import '../../debt/data/debt_providers.dart';
import '../../debt/domain/models/debt.dart';
import '../../rbac/data/audit_log_service.dart';
import 'sales_providers.dart';

/// Outcome of [settleInvoicePayment], used by callers to update local UI state.
class InvoicePaymentResult {
  final double received;
  final double newAmountPaid;
  final String newStatus;

  const InvoicePaymentResult({
    required this.received,
    required this.newAmountPaid,
    required this.newStatus,
  });

  bool get fullySettled => newStatus == 'paid';
}

/// Settles [amount] against [invoice] as one money movement. This is the only
/// path that may move payment money — "Mark as Paid" is a full-outstanding
/// payment through here, so every side effect stays consistent:
///
/// - payment record, invoice balance/status, customer balance and the
///   receivable mirror commit in a single Firestore batch;
/// - the Drift customer balance and the offline debt ledger (receivable
///   created on the credit sale, matched by invoiceRef) are mirrored
///   immediately so offline screens don't keep showing the money as owed.
///
/// Returns null when no sales scope could be resolved (caller shows nothing
/// happened); throws on Firestore failures so callers can surface them.
Future<InvoicePaymentResult?> settleInvoicePayment(
  WidgetRef ref, {
  required Map<String, dynamic> invoice,
  required double amount,
  required String method,
  String reference = '',
  String? auditDetails,
}) async {
  final scope = await resolveSalesScope(ref);
  if (scope == null) return null;
  final repo = ref.read(contextFirestoreRepositoryProvider);

  final invoiceId = (invoice['id'] ?? '').toString();
  final invoiceNumber = (invoice['invoiceNumber'] ?? invoiceId).toString();
  final total = readInvoiceTotal(invoice);
  final amountPaid = parseNumericAmount(invoice['amountPaid']);
  final outstanding = (total - amountPaid).clamp(0.0, total);
  final customerId = (invoice['customerId'] ?? '').toString();

  // A payment can never exceed what is still owed.
  final received = amount > outstanding ? outstanding : amount;
  final newAmountPaid = amountPaid + received;
  final fullySettled = newAmountPaid >= total - 0.005;
  final newStatus = fullySettled ? 'paid' : 'partial';

  // Look up the receivable mirror created on the credit sale before building
  // the batch, so its settlement commits atomically with everything else.
  // Best-effort: older sales have no receivable doc.
  DocumentReference<Map<String, dynamic>>? receivableRef;
  double receivableOutstanding = 0;
  if (received > 0) {
    try {
      final recCol = repo.scopeCollection(
          uid: scope.ownerUid,
          context: scope.context,
          childCollection: 'receivables');
      final snap =
          await recCol.where('invoiceId', isEqualTo: invoiceId).limit(1).get();
      if (snap.docs.isNotEmpty) {
        receivableRef = snap.docs.first.reference;
        receivableOutstanding =
            parseNumericAmount(snap.docs.first.data()['outstanding']);
      }
    } catch (_) {}
  }

  // Atomic: payment record + invoice balance + customer balance + receivable.
  final batch = FirebaseFirestore.instance.batch();

  if (received > 0) {
    final paymentsCol = repo.scopeCollection(
        uid: scope.ownerUid,
        context: scope.context,
        childCollection: 'invoice_payments');
    batch.set(paymentsCol.doc(), {
      'invoiceId': invoiceId,
      'invoiceNumber': invoiceNumber,
      'businessId': scope.businessId,
      if (customerId.isNotEmpty) 'customerId': customerId,
      'amount': received,
      'method': method,
      if (reference.isNotEmpty) 'reference': reference,
      'recordedBy': scope.userUid,
      'recordedAt': FieldValue.serverTimestamp(),
    });
  }

  final invoicesCol = repo.scopeCollection(
      uid: scope.ownerUid,
      context: scope.context,
      childCollection: 'sales_invoices');
  batch.update(invoicesCol.doc(invoiceId), {
    'amountPaid': FieldValue.increment(received),
    'status': newStatus,
    'paymentMethod': method,
    'updatedAt': FieldValue.serverTimestamp(),
    if (fullySettled) 'paidAt': FieldValue.serverTimestamp(),
  });

  if (customerId.isNotEmpty && received > 0) {
    final customersCol = repo.scopeCollection(
        uid: scope.ownerUid,
        context: scope.context,
        childCollection: 'customers');
    batch.set(
        customersCol.doc(customerId),
        {
          'balance': FieldValue.increment(-received),
          'lastTransactionDate': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true));
  }

  if (receivableRef != null) {
    final newOutstanding =
        (receivableOutstanding - received).clamp(0.0, double.maxFinite);
    batch.update(receivableRef, {
      'outstanding': newOutstanding,
      'status': newOutstanding <= 0.005 ? 'settled' : 'open',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  await batch.commit();

  // Mirror the customer balance into Drift immediately so credit-limit checks
  // in this session don't wait for a sync pull.
  if (customerId.isNotEmpty && received > 0) {
    try {
      final db = ref.read(appDatabaseProvider);
      final row = await db.customerDao.getById(customerId);
      if (row != null) {
        final newBalance =
            (row.balance - received).clamp(0.0, double.maxFinite);
        await db.customerDao.updateBalance(customerId, newBalance);
      }
    } catch (_) {}
  }

  await _settleLedgerReceivable(
    ref,
    invoiceNumber: invoiceNumber,
    received: received,
    method: method,
    recordedBy: scope.userUid,
  );

  unawaited(AuditLogService().logSaleAction(
    ownerUid: scope.ownerUid,
    businessId: scope.businessId,
    performedByUid: scope.userUid,
    performedByRole: ref.read(currentUserRoleProvider),
    action: AuditLogService.paymentReceived,
    invoiceId: invoiceId,
    invoiceNumber: invoiceNumber,
    amount: received,
    details: auditDetails ?? method,
  ));
  unawaited(ref.read(syncServiceProvider).syncNow());

  return InvoicePaymentResult(
    received: received,
    newAmountPaid: newAmountPaid,
    newStatus: newStatus,
  );
}

/// Applies the payment to the offline debt ledger: finds the open receivable
/// created for this invoice and records the payment against it, so the Debts
/// screen stops counting the settled money as owed. Best-effort — the ledger
/// entry may not exist (cash sales, manually deleted debts).
Future<void> _settleLedgerReceivable(
  WidgetRef ref, {
  required String invoiceNumber,
  required double received,
  required String method,
  required String recordedBy,
}) async {
  if (received <= 0 || invoiceNumber.isEmpty) return;
  try {
    final debtRepo = ref.read(debtRepositoryProvider);
    final debts = await debtRepo.watchAll().first;
    Debt? match;
    for (final d in debts) {
      if (d.type == 'receivable' &&
          !d.isWrittenOff &&
          !d.isFullyPaid &&
          d.invoiceRef == invoiceNumber) {
        match = d;
        break;
      }
    }
    if (match == null) return;

    final applied = received.clamp(0.0, match.remainingAmount);
    if (applied <= 0) return;
    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    await debtRepo.addPayment(
      match.id,
      DebtPayment(
        id: '',
        amount: applied,
        date: dateStr,
        method: method,
        note: 'Invoice $invoiceNumber',
        recordedBy: recordedBy,
      ),
    );
    // Denormalize paidAmount on the debt so reports stay accurate offline —
    // same pattern as the manual repayment flow in debt_detail_screen.
    final newPaid = match.paidAmount + applied;
    await debtRepo.save(match.copyWith(
      paidAmount: newPaid,
      status: newPaid >= match.originalAmount ? 'paid' : match.status,
    ));
  } catch (_) {}
}

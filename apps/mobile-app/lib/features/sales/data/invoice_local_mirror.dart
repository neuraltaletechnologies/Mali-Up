import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../../../core/providers/sync_provider.dart';
import '../../customer/data/customer_providers.dart';
import '../../invoice/data/mappers/invoice_mapper.dart';
import '../../invoice/domain/models/invoice.dart';

/// Mirrors an invoice that was just written directly to Firestore into the
/// local Drift database, so Drift-backed screens (sales list, dashboard
/// revenue/profit) update immediately instead of waiting for the next sync
/// pull — which can also miss the write entirely when the device clock runs
/// ahead of the Firestore server clock.
///
/// Stored with syncStatus 'synced' and no sync-queue entry: nothing gets
/// pushed back, and the next pull simply overwrites this row with the server
/// copy. Rows with local pending changes are left alone — the push/conflict
/// flow owns them.
///
/// Best-effort: failures go to Sentry, never to the user — the Firestore
/// write already succeeded and sync remains the fallback.
Future<void> mirrorInvoiceToDrift(WidgetRef ref, Invoice invoice) async {
  try {
    final db = ref.read(appDatabaseProvider);
    final bizId = ref.read(currentBusinessIdProvider).valueOrNull ?? '';
    if (bizId.isEmpty || invoice.id.isEmpty) return;

    final existing = await db.invoiceDao.getById(invoice.id);
    if (existing != null &&
        existing.syncStatus != 'synced' &&
        existing.syncStatus != 'conflict') {
      return;
    }

    await db.invoiceDao.upsert(
      InvoiceMapper.toCompanion(
        invoice,
        businessId: bizId,
        syncStatus: 'synced',
        localVersion: existing?.localVersion ?? 1,
        createdAtMs:
            existing?.createdAt ?? DateTime.now().millisecondsSinceEpoch,
        serverUpdatedAt: existing?.serverUpdatedAt,
      ),
    );
    await db.invoiceDao.replaceItems(
      invoice.id,
      InvoiceMapper.toItemCompanions(invoice.items, invoice.id),
    );
  } catch (e, st) {
    unawaited(Sentry.captureException(e, stackTrace: st));
  }
}

/// Partial mirror for flows that only change a few fields on an existing
/// invoice (payment received, status change, quotation conversion). No-op
/// when the invoice isn't in Drift yet — the sync pull will bring the full
/// document. Line items are untouched.
Future<void> mirrorInvoiceFieldsToDrift(
  WidgetRef ref,
  String invoiceId, {
  String? status,
  double? amountPaid,
  String? paymentMethod,
  String? paymentAccountId,
  String? type,
}) async {
  try {
    final db = ref.read(appDatabaseProvider);
    final bizId = ref.read(currentBusinessIdProvider).valueOrNull ?? '';
    if (bizId.isEmpty || invoiceId.isEmpty) return;

    final existing = await db.invoiceDao.getById(invoiceId);
    if (existing == null ||
        (existing.syncStatus != 'synced' &&
            existing.syncStatus != 'conflict')) {
      return;
    }

    final items = await db.invoiceDao.getItemsForInvoice(invoiceId);
    final current = InvoiceMapper.fromRow(existing, items);
    final updated = current.copyWith(
      status: status,
      amountPaid: amountPaid,
      paymentMethod: paymentMethod,
      paymentAccountId: paymentAccountId,
      type: type,
      updatedAt: DateTime.now().toIso8601String(),
    );

    await db.invoiceDao.upsert(
      InvoiceMapper.toCompanion(
        updated,
        businessId: bizId,
        syncStatus: 'synced',
        localVersion: existing.localVersion,
        createdAtMs: existing.createdAt,
        serverUpdatedAt: existing.serverUpdatedAt,
      ),
    );
  } catch (e, st) {
    unawaited(Sentry.captureException(e, stackTrace: st));
  }
}

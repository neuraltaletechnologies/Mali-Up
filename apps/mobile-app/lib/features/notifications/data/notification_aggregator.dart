import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/daos/notification_log_dao.dart';
import '../../../core/providers/sync_provider.dart';
import '../../../core/services/localization_service.dart';
import '../../../core/services/notification_prefs.dart';
import '../../../core/services/notification_service.dart';
import '../../debt/data/debt_providers.dart';
import '../../debt/domain/models/debt.dart';
import '../../invoice/domain/models/invoice.dart';
import '../../invoice/presentation/providers/invoice_providers.dart';
import '../../inventory/domain/models/inventory_item.dart';
import '../../inventory/presentation/providers/inventory_providers.dart';
import 'notification_prefs_provider.dart';
import 'notification_providers.dart';

/// Reactive alert generation — the core of the notifications feature.
///
/// There is no background execution in this app, so alerts are only ever
/// (re-)detected while the app is open, by combining the existing
/// offline-first data providers (low stock, overdue debts, overdue
/// invoices, sync problems) and reconciling them against the local
/// [NotificationLogDao]: a still-true condition is refreshed in place
/// without re-firing the system notification; a resolved condition is
/// deleted so it can alert again if it recurs later.
class _AlertCandidates {
  final List<InventoryItem> lowStock;
  final List<Debt> overdueDebts;
  final List<Invoice> overdueInvoices;
  final bool syncProblem;

  const _AlertCandidates({
    required this.lowStock,
    required this.overdueDebts,
    required this.overdueInvoices,
    required this.syncProblem,
  });
}

/// Pure derivation of "what should currently be alerting" — no side
/// effects. Gated per-category by [NotificationPrefs].
final _notificationCandidatesProvider = Provider<_AlertCandidates>((ref) {
  final prefs =
      ref.watch(notificationPrefsProvider).valueOrNull ?? const NotificationPrefs();

  final lowStock = prefs.masterEnabled && prefs.lowStockEnabled
      ? ref.watch(lowStockItemsProvider).valueOrNull ?? const <InventoryItem>[]
      : const <InventoryItem>[];

  final overdueDebts = <Debt>[];
  if (prefs.masterEnabled && prefs.overdueDebtEnabled) {
    overdueDebts.addAll(
      ref.watch(receivablesProvider).where((d) => d.daysOverdue > 0),
    );
    overdueDebts.addAll(
      ref.watch(payablesProvider).where((d) => d.daysOverdue > 0),
    );
  }

  final overdueInvoices = prefs.masterEnabled && prefs.overdueInvoiceEnabled
      ? ref.watch(overdueInvoicesProvider).valueOrNull ?? const <Invoice>[]
      : const <Invoice>[];

  final syncProblem = prefs.masterEnabled && prefs.syncFailureEnabled
      ? ref.watch(syncHasProblemsProvider)
      : false;

  return _AlertCandidates(
    lowStock: lowStock,
    overdueDebts: overdueDebts,
    overdueInvoices: overdueInvoices,
    syncProblem: syncProblem,
  );
});

/// Side-effecting reconciliation. Never watched for its return value —
/// only activated via [notificationAggregatorActivatorProvider] below, so
/// it runs exactly once per session regardless of how many widgets are on
/// screen.
final _notificationReconcilerProvider = Provider<void>((ref) {
  final businessId = ref.watch(currentBusinessIdProvider).valueOrNull ?? '';
  if (businessId.isEmpty) return;
  final candidates = ref.watch(_notificationCandidatesProvider);
  final dao = ref.watch(appDatabaseProvider).notificationLogDao;
  unawaited(_reconcile(dao: dao, businessId: businessId, candidates: candidates));
});

/// Public activation hook. Watch this exactly once, high in the widget
/// tree (the authenticated app shell), to turn on alert generation for the
/// session and keep [NotificationService.unreadCountNotifier] in sync with
/// the unread count for the bell badge.
final notificationAggregatorActivatorProvider = Provider<void>((ref) {
  ref.watch(_notificationReconcilerProvider);

  final businessId = ref.watch(currentBusinessIdProvider).valueOrNull ?? '';
  if (businessId.isEmpty) {
    NotificationService.unreadCountNotifier.value = 0;
    return;
  }

  // Housekeeping: drop already-read alerts older than 30 days so the log
  // doesn't grow unbounded. Cheap enough to run on every activation.
  unawaited(
    ref.read(appDatabaseProvider).notificationLogDao.pruneOldRead(
          businessId,
          DateTime.now().subtract(const Duration(days: 30)),
        ),
  );

  ref.listen<AsyncValue<int>>(
    unreadNotificationCountProvider,
    (previous, next) {
      NotificationService.unreadCountNotifier.value = next.valueOrNull ?? 0;
    },
    fireImmediately: true,
  );
});

Future<void> _reconcile({
  required NotificationLogDao dao,
  required String businessId,
  required _AlertCandidates candidates,
}) async {
  // ── Low stock ──────────────────────────────────────────────────────────
  final lowStockIds = <String>{};
  for (final item in candidates.lowStock) {
    lowStockIds.add(item.id);
    final title = item.isOutOfStock
        ? LocalizationService.tr(
            en: 'Out of stock: ${item.name}',
            sw: 'Bidhaa ${item.name} imeisha',
          )
        : LocalizationService.tr(
            en: 'Low stock: ${item.name}',
            sw: 'Bidhaa ${item.name} inaisha',
          );
    final body = LocalizationService.tr(
      en: 'Only ${_fmtQty(item.currentStock)} ${item.unit} left — restock soon',
      sw: 'Zimebaki ${_fmtQty(item.currentStock)} ${item.unit} tu — jaza upya hivi karibuni',
    );
    final isNew = await dao.upsertByKey(
      businessId: businessId,
      type: 'low_stock',
      entityId: item.id,
      title: title,
      body: body,
    );
    if (isNew) {
      await NotificationService.showLocalNotification(
        id: NotificationService.idForKey(businessId, 'low_stock', item.id),
        title: title,
        body: body,
        payload: 'low_stock:${item.id}',
      );
    }
  }
  await dao.pruneStaleForType(businessId, 'low_stock', lowStockIds);

  // ── Overdue debts (receivable + payable) ─────────────────────────────────
  final debtIds = <String>{};
  for (final d in candidates.overdueDebts) {
    debtIds.add(d.id);
    final isReceivable = d.type == 'receivable';
    final title = isReceivable
        ? LocalizationService.tr(
            en: '${d.partyName} owes you ${_fmtAmount(d.remainingAmount)}',
            sw: '${d.partyName} anadaiwa ${_fmtAmount(d.remainingAmount)}',
          )
        : LocalizationService.tr(
            en: 'You owe ${d.partyName} ${_fmtAmount(d.remainingAmount)}',
            sw: 'Unadaiwa ${d.partyName} ${_fmtAmount(d.remainingAmount)}',
          );
    final body = LocalizationService.tr(
      en: 'Overdue by ${d.daysOverdue} days',
      sw: 'Imechelewa kwa siku ${d.daysOverdue}',
    );
    final isNew = await dao.upsertByKey(
      businessId: businessId,
      type: 'overdue_debt',
      entityId: d.id,
      title: title,
      body: body,
    );
    if (isNew) {
      await NotificationService.showLocalNotification(
        id: NotificationService.idForKey(businessId, 'overdue_debt', d.id),
        title: title,
        body: body,
        payload: 'overdue_debt:${d.id}',
      );
    }
  }
  await dao.pruneStaleForType(businessId, 'overdue_debt', debtIds);

  // ── Overdue invoices ──────────────────────────────────────────────────────
  final invoiceIds = <String>{};
  for (final inv in candidates.overdueInvoices) {
    invoiceIds.add(inv.id);
    final title = LocalizationService.tr(
      en: 'Invoice ${inv.invoiceNumber} overdue',
      sw: 'Ankara ${inv.invoiceNumber} imechelewa',
    );
    final body = LocalizationService.tr(
      en: '${inv.customerName} — ${_fmtAmount(inv.outstanding)} due',
      sw: '${inv.customerName} — ${_fmtAmount(inv.outstanding)} inadaiwa',
    );
    final isNew = await dao.upsertByKey(
      businessId: businessId,
      type: 'overdue_invoice',
      entityId: inv.id,
      title: title,
      body: body,
    );
    if (isNew) {
      await NotificationService.showLocalNotification(
        id: NotificationService.idForKey(businessId, 'overdue_invoice', inv.id),
        title: title,
        body: body,
        payload: 'overdue_invoice:${inv.id}',
      );
    }
  }
  await dao.pruneStaleForType(businessId, 'overdue_invoice', invoiceIds);

  // ── Sync failures — one consolidated row per business ─────────────────────
  if (candidates.syncProblem) {
    final title = LocalizationService.tr(
      en: 'Sync problem detected',
      sw: 'Tatizo la usawazishaji limegunduliwa',
    );
    final body = LocalizationService.tr(
      en: "Some changes couldn't be synced. Tap to review",
      sw: 'Baadhi ya mabadiliko hayakuweza kusawazishwa. Gusa kuangalia',
    );
    final isNew = await dao.upsertByKey(
      businessId: businessId,
      type: 'sync_failure',
      title: title,
      body: body,
    );
    if (isNew) {
      await NotificationService.showLocalNotification(
        id: NotificationService.idForKey(businessId, 'sync_failure', null),
        title: title,
        body: body,
        payload: 'sync_failure',
      );
    }
  } else {
    await dao.deleteByKey(businessId, 'sync_failure', null);
  }
}

String _fmtQty(double v) {
  return v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
}

String _fmtAmount(double v) {
  if (v >= 1000000) return 'TZS ${(v / 1000000).toStringAsFixed(1)}M';
  if (v >= 1000) return 'TZS ${(v / 1000).toStringAsFixed(0)}K';
  return 'TZS ${v.toStringAsFixed(0)}';
}

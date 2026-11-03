import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/daos/notification_log_dao.dart';
import '../../../core/providers/sync_provider.dart';
import '../../../core/services/localization_service.dart';
import '../../../core/services/notification_prefs.dart';
import '../../../core/services/notification_service.dart';
import '../../customer/data/customer_providers.dart';
import '../../customer/domain/models/customer.dart';
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
  final List<InventoryItem>? lowStock;
  final List<Debt>? overdueDebts;
  final List<Invoice>? overdueInvoices;
  final bool syncProblem;

  /// Current customer names by id. A debt stores a snapshot of the party's
  /// name taken when it was recorded, which goes stale if the customer is
  /// renamed afterwards — alerts prefer the live name when the debt is
  /// linked to a customer.
  final Map<String, String> customerNames;

  const _AlertCandidates({
    required this.lowStock,
    required this.overdueDebts,
    required this.overdueInvoices,
    required this.syncProblem,
    required this.customerNames,
  });
}

/// Pure derivation of "what should currently be alerting" — no side
/// effects. Gated per-category by [NotificationPrefs].
final _notificationCandidatesProvider = Provider<_AlertCandidates>((ref) {
  final prefs =
      ref.watch(notificationPrefsProvider).valueOrNull ??
      const NotificationPrefs();

  // A null list means "not loaded yet" — the reconciler leaves that category
  // untouched. Treating a loading/reloading stream as an empty list would
  // prune every alert and re-insert (and re-notify) them on the next pass.
  // A disabled category is an empty list, so its alerts are cleared.
  final lowStock = prefs.masterEnabled && prefs.lowStockEnabled
      ? ref.watch(lowStockItemsProvider).valueOrNull
      : const <InventoryItem>[];

  // Read the raw stream (valueOrNull keeps the previous data while it
  // reloads) rather than receivables/payablesProvider, which fall back to
  // an empty list during a reload.
  List<Debt>? overdueDebts = const <Debt>[];
  if (prefs.masterEnabled && prefs.overdueDebtEnabled) {
    overdueDebts = ref
        .watch(debtListProvider)
        .valueOrNull
        ?.where(
          (d) =>
              (d.type == 'receivable' || d.type == 'payable') &&
              !d.isWrittenOff &&
              !d.isFullyPaid &&
              d.daysOverdue > 0,
        )
        .toList();
  }

  final overdueInvoices = prefs.masterEnabled && prefs.overdueInvoiceEnabled
      ? ref.watch(overdueInvoicesProvider).valueOrNull
      : const <Invoice>[];

  final syncProblem = prefs.masterEnabled && prefs.syncFailureEnabled
      ? ref.watch(syncHasProblemsProvider)
      : false;

  final customerNames = <String, String>{};
  if (overdueDebts != null && overdueDebts.isNotEmpty) {
    for (final c
        in ref.watch(customerListProvider).valueOrNull ?? const <Customer>[]) {
      final name = c.name.trim();
      if (name.isNotEmpty) customerNames[c.id] = name;
    }
  }

  return _AlertCandidates(
    lowStock: lowStock,
    overdueDebts: overdueDebts,
    overdueInvoices: overdueInvoices,
    syncProblem: syncProblem,
    customerNames: customerNames,
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
  // Run passes one at a time: overlapping passes could both see "no row"
  // for the same key and each insert + notify.
  _reconcileQueue = _reconcileQueue
      .then(
        (_) => _reconcile(
          dao: dao,
          businessId: businessId,
          candidates: candidates,
        ),
      )
      .catchError(
        (Object e) => debugPrint('[Notifications] reconcile failed: $e'),
      );
});

Future<void> _reconcileQueue = Future.value();

/// When each alert key last fired a system notification this session. A
/// safety net on top of the log row: even if a row is deleted and
/// re-inserted (data reload, resolve-then-recur in quick succession), the
/// same alert never pops up on the phone more than once a day.
final Map<String, DateTime> _lastFired = {};
const _refireAfter = Duration(hours: 24);

Future<void> _notifyOnce({
  required String businessId,
  required String type,
  String? entityId,
  required String title,
  required String body,
  required String payload,
}) async {
  final key = '$businessId|$type|${entityId ?? ''}';
  final last = _lastFired[key];
  final now = DateTime.now();
  if (last != null && now.difference(last) < _refireAfter) return;
  _lastFired[key] = now;
  await NotificationService.showLocalNotification(
    id: NotificationService.idForKey(businessId, type, entityId),
    title: title,
    body: body,
    payload: payload,
  );
}

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
    ref
        .read(appDatabaseProvider)
        .notificationLogDao
        .pruneOldRead(
          businessId,
          DateTime.now().subtract(const Duration(days: 30)),
        ),
  );

  ref.listen<AsyncValue<int>>(unreadNotificationCountProvider, (
    previous,
    next,
  ) {
    NotificationService.unreadCountNotifier.value = next.valueOrNull ?? 0;
  }, fireImmediately: true);
});

Future<void> _reconcile({
  required NotificationLogDao dao,
  required String businessId,
  required _AlertCandidates candidates,
}) async {
  // ── Low stock ──────────────────────────────────────────────────────────
  final lowStock = candidates.lowStock;
  if (lowStock != null) {
    final lowStockIds = <String>{};
    for (final item in lowStock) {
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
        await _notifyOnce(
          businessId: businessId,
          type: 'low_stock',
          entityId: item.id,
          title: title,
          body: body,
          payload: 'low_stock:${item.id}',
        );
      }
    }
    await dao.pruneStaleForType(businessId, 'low_stock', lowStockIds);
  }

  // ── Overdue debts (receivable + payable) ─────────────────────────────────
  final overdueDebts = candidates.overdueDebts;
  if (overdueDebts != null) {
    final debtIds = <String>{};
    for (final d in overdueDebts) {
      debtIds.add(d.id);
      final isReceivable = d.type == 'receivable';
      final party = _debtPartyName(d, candidates.customerNames);
      final title = isReceivable
          ? LocalizationService.tr(
              en: '$party owes you ${_fmtAmount(d.remainingAmount)}',
              sw: '$party anadaiwa ${_fmtAmount(d.remainingAmount)}',
            )
          : LocalizationService.tr(
              en: 'You owe $party ${_fmtAmount(d.remainingAmount)}',
              sw: 'Unadaiwa na $party ${_fmtAmount(d.remainingAmount)}',
            );
      final overdue = LocalizationService.tr(
        en: 'Overdue by ${d.daysOverdue} days',
        sw: 'Imechelewa kwa siku ${d.daysOverdue}',
      );
      final detail = d.invoiceRef.trim().isNotEmpty
          ? d.invoiceRef.trim()
          : d.note.trim();
      final body = detail.isEmpty ? overdue : '$detail — $overdue';
      final isNew = await dao.upsertByKey(
        businessId: businessId,
        type: 'overdue_debt',
        entityId: d.id,
        title: title,
        body: body,
      );
      if (isNew) {
        await _notifyOnce(
          businessId: businessId,
          type: 'overdue_debt',
          entityId: d.id,
          title: title,
          body: body,
          payload: 'overdue_debt:${d.id}',
        );
      }
    }
    await dao.pruneStaleForType(businessId, 'overdue_debt', debtIds);
  }

  // ── Overdue invoices ──────────────────────────────────────────────────────
  final overdueInvoices = candidates.overdueInvoices;
  if (overdueInvoices != null) {
    final invoiceIds = <String>{};
    for (final inv in overdueInvoices) {
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
        await _notifyOnce(
          businessId: businessId,
          type: 'overdue_invoice',
          entityId: inv.id,
          title: title,
          body: body,
          payload: 'overdue_invoice:${inv.id}',
        );
      }
    }
    await dao.pruneStaleForType(businessId, 'overdue_invoice', invoiceIds);
  }

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
      await _notifyOnce(
        businessId: businessId,
        type: 'sync_failure',
        title: title,
        body: body,
        payload: 'sync_failure',
      );
    }
  } else {
    await dao.deleteByKey(businessId, 'sync_failure', null);
  }
}

/// Live customer name when the debt is linked to one, else the name stored
/// on the debt, else the phone number.
String _debtPartyName(Debt d, Map<String, String> customerNames) {
  final live = customerNames[d.partyId];
  if (live != null) return live;
  if (d.partyName.trim().isNotEmpty) return d.partyName.trim();
  if (d.partyPhone.trim().isNotEmpty) return d.partyPhone.trim();
  return LocalizationService.tr(en: 'A customer', sw: 'Mteja');
}

String _fmtQty(double v) {
  return v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
}

String _fmtAmount(double v) {
  if (v >= 1000000) return 'TZS ${(v / 1000000).toStringAsFixed(1)}M';
  if (v >= 1000) return 'TZS ${(v / 1000).toStringAsFixed(0)}K';
  return 'TZS ${v.toStringAsFixed(0)}';
}

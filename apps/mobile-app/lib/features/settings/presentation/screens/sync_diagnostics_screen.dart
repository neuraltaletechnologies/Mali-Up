import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/providers/sync_provider.dart';
import '../../../../core/services/localization_service.dart';
import '../../../../core/sync/offline_policy_notifier.dart';
import '../../../../core/sync/sync_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/skeleton_widgets.dart';
import '../../../../shared/widgets/smart_skeleton.dart';

String _tr(String en, String sw) => LocalizationService.tr(en: en, sw: sw);

// ── Providers ─────────────────────────────────────────────────────────────────

final _pendingEntriesProvider = FutureProvider<List<SyncQueueTableData>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.syncQueueDao.fetchPending(limit: 100);
});

final _failedEntriesProvider = FutureProvider<List<SyncQueueTableData>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.syncQueueDao.getFailedEntries();
});

final _conflictEntriesProvider = FutureProvider<List<SyncQueueTableData>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.syncQueueDao.getConflictEntries();
});

// ── Screen ────────────────────────────────────────────────────────────────────

class SyncDiagnosticsScreen extends ConsumerWidget {
  const SyncDiagnosticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncStateProvider);
    final pendingCount = ref.watch(pendingSyncCountProvider).valueOrNull ?? 0;
    final policy = ref.watch(offlinePolicyProvider);
    final service = ref.watch(syncServiceProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.navyPrimary,
        foregroundColor: Colors.white,
        title: Text(
          _tr('Sync Diagnostics', 'Uchunguzi wa Usawazishaji'),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip: _tr('Sync now', 'Sawazisha sasa'),
            onPressed: syncState == SyncState.syncing
                ? null
                : () => service.syncNow(),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.yellowBrand,
        onRefresh: () async {
          ref.invalidate(_pendingEntriesProvider);
          ref.invalidate(_failedEntriesProvider);
          ref.invalidate(_conflictEntriesProvider);
          await service.syncNow();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SyncHealthCard(
              syncState: syncState,
              pendingCount: pendingCount,
              policy: policy,
              lastSyncAt: service.lastSyncAt,
            ),
            const SizedBox(height: 16),
            _QueueSection(
              title: _tr('Pending Operations', 'Mabadiliko Yanayongoja'),
              icon: Icons.cloud_upload_outlined,
              color: AppColors.warning,
              provider: _pendingEntriesProvider,
              emptyLabel: _tr('No pending operations', 'Hakuna mabadiliko yanayongoja'),
            ),
            const SizedBox(height: 12),
            _QueueSection(
              title: _tr('Failed Operations', 'Mabadiliko Yaliyoshindwa'),
              icon: Icons.error_outline_rounded,
              color: AppColors.error,
              provider: _failedEntriesProvider,
              emptyLabel: _tr('No failed operations', 'Hakuna mabadiliko yaliyoshindwa'),
            ),
            const SizedBox(height: 12),
            _QueueSection(
              title: _tr('Conflicts', 'Migogoro'),
              icon: Icons.merge_type_rounded,
              color: AppColors.purpleAccent,
              provider: _conflictEntriesProvider,
              emptyLabel: _tr('No conflicts', 'Hakuna migogoro'),
            ),
            const SizedBox(height: 24),
            _ActionButtons(
              onClearCompleted: () async {
                final db = ref.read(appDatabaseProvider);
                await db.syncQueueDao.deleteCompleted();
                ref.invalidate(_pendingEntriesProvider);
              },
              onForceSync: () => service.syncNow(),
              syncing: syncState == SyncState.syncing,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ── Health Card ───────────────────────────────────────────────────────────────

class _SyncHealthCard extends StatelessWidget {
  final SyncState syncState;
  final int pendingCount;
  final OfflinePolicyNotifier policy;
  final DateTime? lastSyncAt;

  const _SyncHealthCard({
    required this.syncState,
    required this.pendingCount,
    required this.policy,
    required this.lastSyncAt,
  });

  @override
  Widget build(BuildContext context) {
    final (statusLabel, statusColor) = switch (syncState) {
      SyncState.syncing => (_tr('Syncing', 'Inasawazisha'), AppColors.info),
      SyncState.offline => _offlineLabel(policy),
      SyncState.error   => (_tr('Error', 'Hitilafu'), AppColors.error),
      SyncState.idle    => (_tr('Online', 'Mtandaoni'), AppColors.success),
    };

    final fmt = DateFormat('dd MMM yyyy, HH:mm');
    final lastSync = lastSyncAt != null
        ? fmt.format(lastSyncAt!)
        : _tr('Never', 'Haijawahi');

    final offlineFor = policy.isOffline
        ? _formatDuration(policy.offlineDuration)
        : '—';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                statusLabel,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _Row(
            label: _tr('Queue size', 'Idadi ya foleni'),
            value: '$pendingCount ${_tr('operation(s)', 'operesheni')}',
          ),
          _Row(
            label: _tr('Last sync', 'Usawazishaji wa mwisho'),
            value: lastSync,
          ),
          _Row(
            label: _tr('Offline for', 'Bila mtandao kwa'),
            value: offlineFor,
          ),
          _Row(
            label: _tr('Offline level', 'Kiwango cha kutokuwa na mtandao'),
            value: _levelLabel(policy.level),
          ),
        ],
      ),
    );
  }

  (String, Color) _offlineLabel(OfflinePolicyNotifier policy) {
    return switch (policy.level) {
      OfflineLevel.restricted => (
          _tr('Offline — Restricted', 'Bila Mtandao — Imezuiwa'),
          AppColors.error,
        ),
      OfflineLevel.warning => (
          _tr('Offline — Warning', 'Bila Mtandao — Onyo'),
          AppColors.warning,
        ),
      OfflineLevel.normal => (
          _tr('Offline', 'Bila Mtandao'),
          AppColors.warning,
        ),
    };
  }

  String _levelLabel(OfflineLevel level) {
    return switch (level) {
      OfflineLevel.normal     => _tr('Normal', 'Kawaida'),
      OfflineLevel.warning    => _tr('Warning (24–48 h)', 'Onyo (masaa 24–48)'),
      OfflineLevel.restricted => _tr('Restricted (48 h+)', 'Imezuiwa (zaidi ya saa 48)'),
    };
  }

  String _formatDuration(Duration d) {
    if (d.inHours >= 1) return '${d.inHours} h ${d.inMinutes.remainder(60)} min';
    return '${d.inMinutes} min';
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textMuted)),
          ),
          Expanded(
            flex: 3,
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }
}

// ── Queue Section ─────────────────────────────────────────────────────────────

class _QueueSection extends ConsumerWidget {
  final String title;
  final IconData icon;
  final Color color;
  final ProviderBase<AsyncValue<List<SyncQueueTableData>>> provider;
  final String emptyLabel;

  const _QueueSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.provider,
    required this.emptyLabel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(provider);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: color,
                  ),
                ),
                const Spacer(),
                async.whenData((list) => Text(
                      '${list.length}',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: color),
                    )).valueOrNull ??
                    const SizedBox.shrink(),
              ],
            ),
          ),
          const Divider(height: 1),
          async.smartWhen(
            skeleton: () => const Column(
              children: [
                SkeletonSyncEntry(),
                SkeletonSyncEntry(),
                SkeletonSyncEntry(),
              ],
            ),
            onError: (e, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Error: $e',
                  style: const TextStyle(color: AppColors.error)),
            ),
            data: (entries) => entries.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(emptyLabel,
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 13)),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: entries.length,
                    separatorBuilder: (_, _) =>
                        const Divider(height: 1, indent: 16),
                    itemBuilder: (_, i) => _QueueEntryTile(entry: entries[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _QueueEntryTile extends StatelessWidget {
  final SyncQueueTableData entry;
  const _QueueEntryTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final created = DateFormat('dd MMM, HH:mm').format(
      DateTime.fromMillisecondsSinceEpoch(entry.createdAt),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _EntityIcon(type: entry.entityType),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${entry.entityType} · ${entry.operation}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    _StatusChip(status: entry.status),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  entry.entityId,
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                      fontFamily: 'monospace'),
                  overflow: TextOverflow.ellipsis,
                ),
                if (entry.errorMessage.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    entry.errorMessage,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.error),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 2),
                Text(
                  '${_tr('Created', 'Iliundwa')} $created · '
                  '${_tr('Attempts', 'Majaribio')} ${entry.attempts}/${entry.maxAttempts}',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textDisabled),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EntityIcon extends StatelessWidget {
  final String type;
  const _EntityIcon({required this.type});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (type) {
      'invoice'          => (Icons.receipt_long_rounded, AppColors.info),
      'customer'         => (Icons.person_rounded, AppColors.success),
      'expense'          => (Icons.payments_rounded, AppColors.error),
      'inventory_item'   => (Icons.inventory_2_rounded, AppColors.warning),
      'debt'             => (Icons.account_balance_wallet_rounded, AppColors.purpleAccent),
      'debt_payment'     => (Icons.price_check_rounded, AppColors.success),
      'team_member'      => (Icons.group_rounded, AppColors.info),
      'cash_account'     => (Icons.account_balance_rounded, AppColors.tealAccent),
      'cash_transaction' => (Icons.swap_horiz_rounded, AppColors.tealAccent),
      'reconciliation'   => (Icons.fact_check_rounded, AppColors.success),
      _                  => (Icons.sync_alt_rounded, AppColors.textMuted),
    };
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
            color.withValues(alpha: 0.12), Colors.white),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 16, color: color),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (status) {
      'pending'    => (_tr('Pending', 'Inasubiri'), AppColors.warningBg, AppColors.warning),
      'processing' => (_tr('Processing', 'Inafanyika'), AppColors.infoBg, AppColors.info),
      'completed'  => (_tr('Synced', 'Imesawazishwa'), AppColors.successBg, AppColors.success),
      'failed'     => (_tr('Failed', 'Imeshindwa'), AppColors.errorBg, AppColors.error),
      'conflict'   => (_tr('Conflict', 'Mgogoro'), const Color(0xFFEDE9FE), AppColors.purpleAccent),
      'cancelled'  => (_tr('Cancelled', 'Imefutwa'), AppColors.surfaceVariant, AppColors.textMuted),
      _            => (status, AppColors.surfaceVariant, AppColors.textMuted),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w700, color: fg)),
    );
  }
}

// ── Action Buttons ────────────────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  final VoidCallback onClearCompleted;
  final VoidCallback onForceSync;
  final bool syncing;

  const _ActionButtons({
    required this.onClearCompleted,
    required this.onForceSync,
    required this.syncing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onClearCompleted,
            icon: const Icon(Icons.delete_sweep_rounded, size: 16),
            label: Text(_tr('Clear completed', 'Futa zilizomalizika'),
                style: const TextStyle(fontSize: 13)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              side: const BorderSide(color: AppColors.border),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            onPressed: syncing ? null : onForceSync,
            icon: syncing
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.sync_rounded, size: 16),
            label: Text(
              syncing
                  ? _tr('Syncing...', 'Inasawazisha...')
                  : _tr('Sync now', 'Sawazisha sasa'),
              style: const TextStyle(fontSize: 13),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.navyPrimary,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ],
    );
  }
}

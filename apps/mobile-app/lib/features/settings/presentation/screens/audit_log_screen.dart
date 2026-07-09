import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/business_id_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/localization_service.dart';
import '../../../rbac/data/audit_log_service.dart';

/// Streams the most recent audit-log entries for the active business.
///
/// Reads are restricted to the business owner by firestore.rules, so
/// non-owner staff will hit permission-denied here — that's treated as
/// "nothing to show" rather than surfaced as an error.
final auditLogsProvider = StreamProvider.autoDispose<List<AuditLogEvent>>((ref) {
  final businessId = ref.watch(currentBusinessIdProvider).valueOrNull ?? '';
  if (businessId.isEmpty) return Stream.value(const []);
  return _watchAuditLogs(businessId);
});

Stream<List<AuditLogEvent>> _watchAuditLogs(String businessId) async* {
  try {
    yield* FirebaseFirestore.instance
        .collection('businesses')
        .doc(businessId)
        .collection('audit_logs')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => AuditLogEvent.fromFirestore(doc.id, doc.data()))
            .toList());
  } catch (_) {
    yield const [];
  }
}

class AuditLogScreen extends ConsumerWidget {
  const AuditLogScreen({super.key});

  String _tr(String en, String sw) => LocalizationService.tr(en: en, sw: sw);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auditLogsAsync = ref.watch(auditLogsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Custom AppBar ────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.background,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded),
              color: AppColors.navyPrimary,
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              _tr('Audit Log', 'Kumbukumbu ya Matukio'),
              style: GoogleFonts.dmSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.navyPrimary,
              ),
            ),
          ),

          if (auditLogsAsync.isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if ((auditLogsAsync.valueOrNull ?? const []).isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.surfaceVariant,
                      ),
                      child: Icon(
                        Icons.history_rounded,
                        size: 40,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _tr('Nothing to see yet', 'Hakuna matukio'),
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navyPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _tr(
                        'Your account activity will appear here',
                        'Shughuli za akaunti zitaonekana hapa'
                      ),
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final auditLogs = auditLogsAsync.valueOrNull ?? const [];
                  final event = auditLogs[index];
                  final isLast = index == auditLogs.length - 1;
                  return _AuditLogItem(
                    event: event,
                    tr: _tr,
                    isLast: isLast,
                  );
                },
                childCount: (auditLogsAsync.valueOrNull ?? const []).length,
              ),
            ),
        ],
      ),
    );
  }
}

class AuditLogEvent {
  final String id;
  final String action;
  final DateTime timestamp;
  final String status;
  final String? details;

  AuditLogEvent({
    required this.id,
    required this.action,
    required this.timestamp,
    required this.status,
    this.details,
  });

  factory AuditLogEvent.fromFirestore(String id, Map<String, dynamic> data) {
    final ts = data['timestamp'];
    final timestamp = ts is Timestamp ? ts.toDate() : DateTime.now();

    final name = (data['entityName'] as String?) ?? (data['targetName'] as String?);
    final actorName = data['performedByName'] as String?;
    final amount = data['amount'];
    final freeformDetails = data['details'];
    final previousValue = data['previousValue'];
    final newValue = data['newValue'];

    final parts = <String>[];
    if (name != null && name.isNotEmpty) parts.add(name);
    if (previousValue != null && newValue != null) {
      parts.add('$previousValue → $newValue');
    }
    if (amount != null) parts.add('TZS $amount');
    if (freeformDetails != null && freeformDetails.toString().isNotEmpty) {
      parts.add(freeformDetails.toString());
    }
    if (actorName != null && actorName.isNotEmpty) parts.add('by $actorName');

    return AuditLogEvent(
      id: id,
      action: (data['action'] as String?) ?? 'unknown',
      timestamp: timestamp,
      status: 'success',
      details: parts.isEmpty ? null : parts.join(' · '),
    );
  }
}

class _AuditLogItem extends StatelessWidget {
  final AuditLogEvent event;
  final String Function(String en, String sw) tr;
  final bool isLast;

  const _AuditLogItem({
    required this.event,
    required this.tr,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final iconData = _getActionIconData(event.action);
    final color = _getActionColor(event.action);
    final actionLabel = _getActionLabel(event.action);
    final timestamp = _formatTimestamp(event.timestamp);
    final isSuccess = event.status == 'success';

    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {},
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Icon ─────────────────────────────────────────
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withValues(alpha: 0.15),
                    ),
                    child: Icon(
                      iconData,
                      color: color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),

                  // ── Content ──────────────────────────────────────
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                actionLabel,
                                style: GoogleFonts.dmSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.navyPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (isSuccess)
                              Icon(
                                Icons.check_circle_rounded,
                                size: 16,
                                color: AppColors.success,
                              )
                            else
                              Icon(
                                Icons.error_rounded,
                                size: 16,
                                color: AppColors.error,
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          timestamp,
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                        if (event.details != null) ...[
                          const SizedBox(height: 3),
                          Text(
                            event.details!,
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (!isLast)
          Padding(
            padding: const EdgeInsets.only(left: 74),
            child: Divider(
              height: 1,
              color: AppColors.border,
              thickness: 0.5,
            ),
          ),
      ],
    );
  }

  IconData _getActionIconData(String action) {
    switch (action) {
      case AuditLogService.memberInvited:
        return Icons.person_add_rounded;
      case AuditLogService.memberRemoved:
        return Icons.person_remove_rounded;
      case AuditLogService.memberSuspended:
        return Icons.pause_circle_rounded;
      case AuditLogService.memberActivated:
        return Icons.play_circle_rounded;
      case AuditLogService.roleChanged:
      case AuditLogService.permissionsChanged:
        return Icons.admin_panel_settings_rounded;
      case AuditLogService.customerCreated:
        return Icons.person_add_alt_1_rounded;
      case AuditLogService.customerUpdated:
        return Icons.edit_rounded;
      case AuditLogService.customerDeleted:
        return Icons.delete_rounded;
      case AuditLogService.creditLimitChanged:
        return Icons.credit_score_rounded;
      case AuditLogService.tagAdded:
      case AuditLogService.tagRemoved:
        return Icons.label_rounded;
      case AuditLogService.reminderSent:
        return Icons.notifications_active_rounded;
      case AuditLogService.saleCreated:
        return Icons.point_of_sale_rounded;
      case AuditLogService.invoiceEdited:
        return Icons.receipt_long_rounded;
      case AuditLogService.paymentReceived:
        return Icons.payments_rounded;
      case AuditLogService.returnProcessed:
        return Icons.assignment_return_rounded;
      case AuditLogService.invoiceCancelled:
      case AuditLogService.invoiceDeleted:
        return Icons.cancel_rounded;
      case AuditLogService.quotationConverted:
        return Icons.swap_horiz_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  Color _getActionColor(String action) {
    switch (action) {
      case AuditLogService.memberInvited:
      case AuditLogService.memberActivated:
      case AuditLogService.customerCreated:
      case AuditLogService.saleCreated:
      case AuditLogService.paymentReceived:
      case AuditLogService.tagAdded:
        return AppColors.success;
      case AuditLogService.memberRemoved:
      case AuditLogService.memberSuspended:
      case AuditLogService.customerDeleted:
      case AuditLogService.invoiceCancelled:
      case AuditLogService.invoiceDeleted:
      case AuditLogService.tagRemoved:
        return AppColors.error;
      case AuditLogService.roleChanged:
      case AuditLogService.permissionsChanged:
      case AuditLogService.creditLimitChanged:
      case AuditLogService.returnProcessed:
      case AuditLogService.reminderSent:
        return AppColors.warning;
      case AuditLogService.customerUpdated:
      case AuditLogService.invoiceEdited:
      case AuditLogService.quotationConverted:
        return AppColors.tealAccent;
      default:
        return AppColors.textMuted;
    }
  }

  String _getActionLabel(String action) {
    switch (action) {
      case AuditLogService.memberInvited:
        return tr('Team Member Invited', 'Mwanachama Alialikwa');
      case AuditLogService.memberRemoved:
        return tr('Team Member Removed', 'Mwanachama Aliondolewa');
      case AuditLogService.memberSuspended:
        return tr('Team Member Suspended', 'Mwanachama Alisimamishwa');
      case AuditLogService.memberActivated:
        return tr('Team Member Activated', 'Mwanachama Aliwezeshwa');
      case AuditLogService.roleChanged:
        return tr('Role Changed', 'Jukumu Limebadilishwa');
      case AuditLogService.permissionsChanged:
        return tr('Permissions Changed', 'Ruhusa Zimebadilishwa');
      case AuditLogService.customerCreated:
        return tr('Customer Added', 'Mteja Aliongezwa');
      case AuditLogService.customerUpdated:
        return tr('Customer Updated', 'Mteja Alisasishwa');
      case AuditLogService.customerDeleted:
        return tr('Customer Deleted', 'Mteja Alifutwa');
      case AuditLogService.creditLimitChanged:
        return tr('Credit Limit Changed', 'Kikomo cha Mkopo Kimebadilishwa');
      case AuditLogService.tagAdded:
        return tr('Tag Added', 'Lebo Imeongezwa');
      case AuditLogService.tagRemoved:
        return tr('Tag Removed', 'Lebo Imeondolewa');
      case AuditLogService.reminderSent:
        return tr('Reminder Sent', 'Kikumbusho Kilitumwa');
      case AuditLogService.saleCreated:
        return tr('Sale Recorded', 'Mauzo Yalirekodiwa');
      case AuditLogService.invoiceEdited:
        return tr('Invoice Edited', 'Ankara Ilihaririwa');
      case AuditLogService.paymentReceived:
        return tr('Payment Received', 'Malipo Yalipokelewa');
      case AuditLogService.returnProcessed:
        return tr('Return Processed', 'Kurejeshwa Kulishughulikiwa');
      case AuditLogService.invoiceCancelled:
        return tr('Invoice Cancelled', 'Ankara Ilighairiwa');
      case AuditLogService.invoiceDeleted:
        return tr('Invoice Deleted', 'Ankara Ilifutwa');
      case AuditLogService.quotationConverted:
        return tr('Quotation Converted', 'Nukuu Ilibadilishwa');
      default:
        return action;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d, yyyy').format(timestamp);
    }
  }
}


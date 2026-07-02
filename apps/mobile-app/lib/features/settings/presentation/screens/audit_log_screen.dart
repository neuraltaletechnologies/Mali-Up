import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/localization_service.dart';

class AuditLogScreen extends ConsumerWidget {
  const AuditLogScreen({super.key});

  String _tr(String en, String sw) => LocalizationService.tr(en: en, sw: sw);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auditLogs = _getMockAuditLogs();

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

          if (auditLogs.isEmpty)
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
                  final event = auditLogs[index];
                  final isLast = index == auditLogs.length - 1;
                  return _AuditLogItem(
                    event: event,
                    tr: _tr,
                    isLast: isLast,
                  );
                },
                childCount: auditLogs.length,
              ),
            ),
        ],
      ),
    );
  }

  List<AuditLogEvent> _getMockAuditLogs() {
    return [
      AuditLogEvent(
        id: '1',
        action: 'LOGIN',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        status: 'success',
        details: 'Mobile app · Dar es Salaam',
      ),
      AuditLogEvent(
        id: '2',
        action: 'DATA_EXPORT',
        timestamp: DateTime.now().subtract(const Duration(hours: 8)),
        status: 'success',
        details: 'JSON format, 2.3 MB',
      ),
      AuditLogEvent(
        id: '3',
        action: 'PIN_SET',
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
        status: 'success',
        details: 'PIN code changed',
      ),
      AuditLogEvent(
        id: '4',
        action: 'BIOMETRIC_ENABLED',
        timestamp: DateTime.now().subtract(const Duration(days: 3)),
        status: 'success',
        details: 'Fingerprint registered',
      ),
      AuditLogEvent(
        id: '5',
        action: 'LOGIN',
        timestamp: DateTime.now().subtract(const Duration(days: 4)),
        status: 'success',
        details: 'Mobile app · Dar es Salaam',
      ),
      AuditLogEvent(
        id: '6',
        action: 'LOGOUT',
        timestamp: DateTime.now().subtract(const Duration(days: 5)),
        status: 'success',
        details: 'Manual sign out',
      ),
      AuditLogEvent(
        id: '7',
        action: 'CONSENT_ACCEPTED',
        timestamp: DateTime.now().subtract(const Duration(days: 8)),
        status: 'success',
        details: 'Privacy policy v2.0',
      ),
      AuditLogEvent(
        id: '8',
        action: 'BIOMETRIC_DISABLED',
        timestamp: DateTime.now().subtract(const Duration(days: 12)),
        status: 'success',
        details: null,
      ),
      AuditLogEvent(
        id: '9',
        action: 'LOGIN',
        timestamp: DateTime.now().subtract(const Duration(days: 15)),
        status: 'success',
        details: 'Mobile app · Dar es Salaam',
      ),
      AuditLogEvent(
        id: '10',
        action: 'CONSENT_WITHDRAWN',
        timestamp: DateTime.now().subtract(const Duration(days: 20)),
        status: 'success',
        details: 'Marketing consent withdrawn',
      ),
      AuditLogEvent(
        id: '11',
        action: 'PIN_SET',
        timestamp: DateTime.now().subtract(const Duration(days: 25)),
        status: 'success',
        details: 'PIN code updated',
      ),
      AuditLogEvent(
        id: '12',
        action: 'ACCOUNT_CREATED',
        timestamp: DateTime.now().subtract(const Duration(days: 45)),
        status: 'success',
        details: 'Phone number verified',
      ),
    ];
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
      case 'DATA_EXPORT':
        return Icons.download_rounded;
      case 'DATA_DELETE':
        return Icons.delete_rounded;
      case 'LOGIN':
        return Icons.login_rounded;
      case 'LOGOUT':
        return Icons.logout_rounded;
      case 'ACCOUNT_CREATED':
        return Icons.person_add_rounded;
      case 'ACCOUNT_DELETED':
        return Icons.person_remove_rounded;
      case 'CONSENT_ACCEPTED':
        return Icons.check_circle_rounded;
      case 'CONSENT_WITHDRAWN':
        return Icons.cancel_rounded;
      case 'PIN_SET':
        return Icons.lock_rounded;
      case 'BIOMETRIC_ENABLED':
        return Icons.fingerprint_rounded;
      case 'BIOMETRIC_DISABLED':
        return Icons.fingerprint_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  Color _getActionColor(String action) {
    switch (action) {
      case 'DATA_EXPORT':
        return AppColors.tealAccent;
      case 'DATA_DELETE':
        return AppColors.error;
      case 'LOGIN':
        return AppColors.success;
      case 'LOGOUT':
        return AppColors.warning;
      case 'ACCOUNT_CREATED':
        return AppColors.success;
      case 'ACCOUNT_DELETED':
        return AppColors.error;
      case 'CONSENT_ACCEPTED':
        return AppColors.success;
      case 'CONSENT_WITHDRAWN':
        return AppColors.warning;
      case 'PIN_SET':
        return AppColors.tealAccent;
      case 'BIOMETRIC_ENABLED':
        return AppColors.success;
      case 'BIOMETRIC_DISABLED':
        return AppColors.warning;
      default:
        return AppColors.textMuted;
    }
  }

  String _getActionLabel(String action) {
    switch (action) {
      case 'DATA_EXPORT':
        return tr('Data Exported', 'Data Ilihamishibwa');
      case 'DATA_DELETE':
        return tr('Account Deletion Started', 'Kufuta Akaunti Kulianza');
      case 'LOGIN':
        return tr('Logged In', 'Ingia');
      case 'LOGOUT':
        return tr('Logged Out', 'Toka');
      case 'ACCOUNT_CREATED':
        return tr('Account Created', 'Akaunti Imeundwa');
      case 'ACCOUNT_DELETED':
        return tr('Account Deleted', 'Akaunti Ifutwa');
      case 'CONSENT_ACCEPTED':
        return tr('Privacy Policy Accepted', 'Sera ya Faragha Kujazakubali');
      case 'CONSENT_WITHDRAWN':
        return tr('Consent Withdrawn', 'Ridhaa Ilitorolewa');
      case 'PIN_SET':
        return tr('PIN Set', 'PIN Imewekwa');
      case 'BIOMETRIC_ENABLED':
        return tr('Biometric Lock Enabled', 'Kufuli cha Vidole Kuzengawa');
      case 'BIOMETRIC_DISABLED':
        return tr('Biometric Lock Disabled', 'Kufuli cha Vidole Kuzimwa');
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


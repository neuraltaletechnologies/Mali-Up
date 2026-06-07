import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/mali_components.dart';

/// Audit Log Screen - Activity Log
/// Shows all compliance-critical events (logins, exports, deletions, etc)
/// Helps users understand what actions have been taken on their account
/// Complies with PDPA transparency requirements

class AuditLogScreen extends ConsumerWidget {
  const AuditLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // In real implementation:
    // final auditLogs = ref.watch(auditLogsProvider);

    // Mock data for now
    final auditLogs = _getMockAuditLogs();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity Log'),
      ),
      body: auditLogs.isEmpty
          ? const EmptyState(
              icon: Icons.timeline_rounded,
              title: 'Nothing to see here yet',
              subtitle:
                  'Actions and changes on your account will be logged here.',
            )
          : ListView.builder(
              itemCount: auditLogs.length,
              itemBuilder: (context, index) {
                final event = auditLogs[index];
                return _AuditLogItem(event: event);
              },
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
        details: 'Mobile app',
      ),
      AuditLogEvent(
        id: '2',
        action: 'DATA_EXPORT',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        status: 'success',
        details: 'JSON format, 2.3 MB',
      ),
      AuditLogEvent(
        id: '3',
        action: 'CONSENT_ACCEPTED',
        timestamp: DateTime.now().subtract(const Duration(days: 5)),
        status: 'success',
        details: 'Privacy policy v1.0',
      ),
      AuditLogEvent(
        id: '4',
        action: 'BIOMETRIC_ENABLED',
        timestamp: DateTime.now().subtract(const Duration(days: 7)),
        status: 'success',
        details: 'Fingerprint',
      ),
      AuditLogEvent(
        id: '5',
        action: 'ACCOUNT_CREATED',
        timestamp: DateTime.now().subtract(const Duration(days: 30)),
        status: 'success',
        details: 'Email verified',
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

  const _AuditLogItem({
    required this.event,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: _getActionIcon(event.action),
      title: Text(_getActionLabel(event.action)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            DateFormat('MMM d, yyyy h:mm a').format(event.timestamp),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          if (event.details != null) ...[
            const SizedBox(height: 4),
            Text(
              event.details!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[700],
              ),
            ),
          ],
        ],
      ),
      trailing: event.status == 'success'
          ? Icon(Icons.check_circle, color: Colors.green[600])
          : Icon(Icons.error, color: Colors.red[600]),
      isThreeLine: event.details != null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  Widget _getActionIcon(String action) {
    final iconData = _getActionIconData(action);
    final color = _getActionColor(action);

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withAlpha(100),
      ),
      child: Icon(iconData, color: color, size: 20),
    );
  }

  IconData _getActionIconData(String action) {
    switch (action) {
      case 'DATA_EXPORT':
        return Icons.download;
      case 'DATA_DELETE':
        return Icons.delete;
      case 'LOGIN':
        return Icons.login;
      case 'LOGOUT':
        return Icons.logout;
      case 'ACCOUNT_CREATED':
        return Icons.person_add;
      case 'ACCOUNT_DELETED':
        return Icons.person_remove;
      case 'CONSENT_ACCEPTED':
        return Icons.check_circle;
      case 'CONSENT_WITHDRAWN':
        return Icons.cancel;
      case 'PIN_SET':
        return Icons.vpn_key;
      case 'BIOMETRIC_ENABLED':
        return Icons.fingerprint;
      case 'BIOMETRIC_DISABLED':
        return Icons.remove_circle;
      default:
        return Icons.info;
    }
  }

  Color _getActionColor(String action) {
    switch (action) {
      case 'DATA_EXPORT':
        return AppColors.navyPrimary;
      case 'DATA_DELETE':
        return Colors.red;
      case 'LOGIN':
        return Colors.green;
      case 'LOGOUT':
        return Colors.orange;
      case 'ACCOUNT_CREATED':
        return Colors.green;
      case 'ACCOUNT_DELETED':
        return Colors.red;
      case 'CONSENT_ACCEPTED':
        return Colors.green;
      case 'BIOMETRIC_ENABLED':
        return Colors.green;
      case 'BIOMETRIC_DISABLED':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getActionLabel(String action) {
    switch (action) {
      case 'DATA_EXPORT':
        return 'Data Exported';
      case 'DATA_DELETE':
        return 'Account Deletion Initiated';
      case 'LOGIN':
        return 'Logged In';
      case 'LOGOUT':
        return 'Logged Out';
      case 'ACCOUNT_CREATED':
        return 'Account Created';
      case 'ACCOUNT_DELETED':
        return 'Account Deleted';
      case 'CONSENT_ACCEPTED':
        return 'Privacy Policy Accepted';
      case 'CONSENT_WITHDRAWN':
        return 'Consent Withdrawn';
      case 'PIN_SET':
        return 'PIN Code Set';
      case 'BIOMETRIC_ENABLED':
        return 'Biometric Lock Enabled';
      case 'BIOMETRIC_DISABLED':
        return 'Biometric Lock Disabled';
      default:
        return action;
    }
  }
}


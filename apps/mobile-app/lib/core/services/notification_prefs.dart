import 'dart:convert';

/// Per-category notification toggle preferences.
///
/// Persisted as a JSON blob in `UserSettingsTable.notificationSettings`
/// (already declared, previously unused) via [SettingsDao], rather than a
/// new table/column.
class NotificationPrefs {
  final bool masterEnabled;
  final bool lowStockEnabled;
  final bool overdueDebtEnabled;
  final bool overdueInvoiceEnabled;
  final bool syncFailureEnabled;

  const NotificationPrefs({
    this.masterEnabled = true,
    this.lowStockEnabled = true,
    this.overdueDebtEnabled = true,
    this.overdueInvoiceEnabled = true,
    this.syncFailureEnabled = true,
  });

  factory NotificationPrefs.fromJson(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const NotificationPrefs();
      final map = decoded;
      return NotificationPrefs(
        masterEnabled: map['masterEnabled'] as bool? ?? true,
        lowStockEnabled: map['lowStockEnabled'] as bool? ?? true,
        overdueDebtEnabled: map['overdueDebtEnabled'] as bool? ?? true,
        overdueInvoiceEnabled: map['overdueInvoiceEnabled'] as bool? ?? true,
        syncFailureEnabled: map['syncFailureEnabled'] as bool? ?? true,
      );
    } catch (_) {
      return const NotificationPrefs();
    }
  }

  String toJson() => jsonEncode({
        'masterEnabled': masterEnabled,
        'lowStockEnabled': lowStockEnabled,
        'overdueDebtEnabled': overdueDebtEnabled,
        'overdueInvoiceEnabled': overdueInvoiceEnabled,
        'syncFailureEnabled': syncFailureEnabled,
      });

  NotificationPrefs copyWith({
    bool? masterEnabled,
    bool? lowStockEnabled,
    bool? overdueDebtEnabled,
    bool? overdueInvoiceEnabled,
    bool? syncFailureEnabled,
  }) {
    return NotificationPrefs(
      masterEnabled: masterEnabled ?? this.masterEnabled,
      lowStockEnabled: lowStockEnabled ?? this.lowStockEnabled,
      overdueDebtEnabled: overdueDebtEnabled ?? this.overdueDebtEnabled,
      overdueInvoiceEnabled:
          overdueInvoiceEnabled ?? this.overdueInvoiceEnabled,
      syncFailureEnabled: syncFailureEnabled ?? this.syncFailureEnabled,
    );
  }
}

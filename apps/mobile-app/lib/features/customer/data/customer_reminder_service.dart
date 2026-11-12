import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/data/repositories/context_firestore_repository.dart';
import '../../../core/services/localization_service.dart';
import '../../../shared/widgets/app_notification.dart';
import '../../debt/data/debt_providers.dart';
import '../../debt/domain/models/debt.dart';
import '../../rbac/data/audit_log_service.dart';
import '../../rbac/data/rbac_providers.dart';
import '../../sales/data/sales_providers.dart';
import '../../sales/domain/debt_reminder_text.dart';
import '../../sales/services/receipt_pdf_service.dart';
import '../domain/models/customer.dart';
import 'customer_providers.dart';

String _t(String en, String sw) => LocalizationService.tr(en: en, sw: sw);

/// Sends a customer-level debt reminder (WhatsApp PDF share / SMS text /
/// PDF preview) — the one place this logic lives, since it's needed from
/// three separate sheets: the customer detail screen's Balance card, the
/// Record-Debt-Payment sheet (opened from there and from the customer
/// list), and the customer list's own quick info sheet. Duplicating this
/// per-sheet is exactly what let one of them drift out of sync last time
/// (a plain-text-only reminder survived in the customer list's info sheet
/// after the other two were upgraded to send the actual PDF).
///
/// A customer can owe across several invoices — unlike a single Debt record
/// there's no one invoice to build a receipt from, so the reminder combines
/// line items from the customer's open invoices (capped at 5, same as the
/// text reminder) under the customer's own balance.
abstract final class CustomerReminderService {
  /// Balance and phone checks shared by all three send methods below.
  static bool canSend(BuildContext context, Customer customer, double balance) {
    if (balance <= 0) {
      AppNotification.warning(
        context,
        _t('No outstanding balance', 'Hakuna deni linalodaiwa'),
      );
      return false;
    }
    if (customer.phone.isEmpty) {
      AppNotification.warning(
        context,
        _t('No phone number on file.', 'Hakuna namba ya simu iliyohifadhiwa.'),
      );
      return false;
    }
    return true;
  }

  /// Everything this customer still owes, one entry per bill: each open
  /// invoice plus each receivable added by hand on the Debt page (those
  /// count toward the balance but have no invoice). Paid/owed figures come
  /// from the linked Debt when there is one — a payment recorded on the Debt
  /// page never updates the invoice's own amountPaid, so the debt is the
  /// authoritative figure, same as DebtDetailScreen's reminder.
  static List<_Bill> _bills(WidgetRef ref, String customerId) {
    final invoices = ref
        .read(customerInvoicesProvider(customerId))
        .maybeWhen(data: (d) => d, orElse: () => <Map<String, dynamic>>[]);
    final debts = ref
        .read(debtListProvider)
        .maybeWhen(data: (d) => d, orElse: () => <Debt>[])
        .where((d) => d.type == 'receivable' && d.partyId == customerId)
        .toList();
    final debtByRef = {
      for (final d in debts)
        if (d.invoiceRef.isNotEmpty) d.invoiceRef: d,
    };
    final invoiceNumbers = <String>{};
    final bills = <_Bill>[];

    for (final inv in invoices) {
      final invNum = (inv['invoiceNumber'] ?? '').toString();
      if (invNum.isNotEmpty) invoiceNumbers.add(invNum);
      final s = (inv['status'] ?? '').toString().toLowerCase();
      if (s == 'paid' || s == 'cancelled' || s == 'draft') continue;
      final linked = debtByRef[invNum];
      if (linked != null && linked.isWrittenOff) continue;
      final total = linked?.totalOwedWithInterest ?? readInvoiceTotal(inv);
      final paid = linked?.paidAmount ?? parseNumericAmount(inv['amountPaid']);
      final owed = linked?.remainingAmount ??
          (total - paid).clamp(0, double.infinity).toDouble();
      if (owed <= 0) continue;
      final raw = inv['lineItems'] ?? inv['items'];
      bills.add(
        _Bill(
          label: invNum.isNotEmpty
              ? '${_t('Invoice', 'Ankara')} $invNum'
              : _t('Invoice', 'Ankara'),
          date: readSaleDate(inv),
          dueDate: DateTime.tryParse(
            (linked?.dueDate ?? inv['dueDate'] ?? '').toString(),
          ),
          items: raw is List
              ? raw.whereType<Map>().map(Map<String, dynamic>.from).toList()
              : const [],
          total: total,
          paid: paid,
          owed: owed,
        ),
      );
    }

    for (final d in debts) {
      if (d.isWrittenOff || d.remainingAmount <= 0) continue;
      if (invoiceNumbers.contains(d.invoiceRef)) continue;
      final line = DebtReminderText.manualLineItem(d);
      bills.add(
        _Bill(
          label: d.invoiceRef.isNotEmpty
              ? '${_t('Debt', 'Deni')} ${d.invoiceRef}'
              : _t('Debt', 'Deni'),
          date: DateTime.tryParse(d.createdAt),
          dueDate: DateTime.tryParse(d.dueDate),
          items: line != null ? [line] : const [],
          total: d.totalOwedWithInterest,
          paid: d.paidAmount,
          owed: d.remainingAmount,
        ),
      );
    }
    return bills;
  }

  /// Same layout as the Debt page's reminder (DebtReminderText), repeated
  /// per bill: every item with qty, unit price and line total, then what
  /// the bill came to, what's been paid and what's still owed.
  static String _buildReminderText(
    Customer c,
    double balance,
    List<_Bill> bills,
  ) {
    final buf = StringBuffer();
    buf.writeln(_t('Dear *${c.name}*,', 'Ndugu *${c.name}*,'));
    buf.writeln();
    buf.writeln(
      _t(
        'This is a friendly reminder of your outstanding balance with us.',
        'Hii ni ukumbusho wa kirafiki wa salio lako linalodaiwa kwetu.',
      ),
    );
    buf.writeln();
    for (final b in bills.take(_maxBills)) {
      final datePart = b.date != null ? ' (${_fmtDate(b.date!)})' : '';
      buf.writeln('*${b.label}*$datePart');
      if (b.items.isNotEmpty) {
        buf.writeln('━━━━━━━━━━━━━━━━━━━━━');
        for (final item in b.items) {
          final line = DebtReminderText.itemLine(item);
          if (line.isNotEmpty) buf.writeln('• $line');
        }
        buf.writeln('━━━━━━━━━━━━━━━━━━━━━');
      }
      buf.writeln('${_t('Total:', 'Jumla:')} TZS ${_fmtNum(b.total)}');
      if (b.paid > 0) {
        buf.writeln(
          '${_t('Already paid:', 'Tayari umelipa:')} TZS ${_fmtNum(b.paid)}',
        );
      }
      buf.writeln(
        '*${_t('Amount Owed:', 'Kiasi Kinachodaiwa:')} TZS ${_fmtNum(b.owed)}*',
      );
      buf.writeln();
    }
    if (bills.length > _maxBills) {
      final extra = bills.length - _maxBills;
      buf.writeln(
        _t(
          '+ $extra more bill${extra == 1 ? '' : 's'}',
          '+ madeni mengine $extra',
        ),
      );
      buf.writeln();
    }
    buf.writeln(
      '*${_t('Total Outstanding: TZS ${_fmtNum(balance)}', 'Jumla Inayodaiwa: TZS ${_fmtNum(balance)}')}*',
    );
    buf.writeln();
    buf.writeln(
      _t(
        'Please arrange payment at your earliest convenience.',
        'Tafadhali panga malipo haraka iwezekanavyo.',
      ),
    );
    buf.writeln(_t('Thank you!', 'Asante!'));
    return buf.toString();
  }

  /// Sale map for the reminder PDF. `type: 'debt'` tells
  /// [ReceiptPdfService] to title the document a debt receipt rather than
  /// a sale receipt — this is a reminder of money owed, not proof of a
  /// completed sale.
  ///
  /// Total = what's been paid on the listed bills + the customer's balance,
  /// so the PDF's Total / Paid / Balance agree with each other and with the
  /// listed items (e.g. items 8,000 → Paid 2,100 → Balance 5,900).
  static Map<String, dynamic> _buildStatementSale(
    Customer c,
    double balance,
    List<_Bill> bills,
  ) {
    final listed = bills.take(_maxBills).toList();
    final items = <Map<String, dynamic>>[
      for (final b in listed) ...b.items,
    ];
    final paid = listed.fold<double>(0, (acc, b) => acc + b.paid);
    DateTime? earliestDue;
    for (final b in bills) {
      final d = b.dueDate;
      if (d != null && (earliestDue == null || d.isBefore(earliestDue))) {
        earliestDue = d;
      }
    }
    final singleRef = bills.length == 1 ? bills.first.label : '';
    return {
      'type': 'debt',
      'invoiceNumber':
          singleRef.isNotEmpty ? singleRef : _t('Statement', 'Taarifa ya Malipo'),
      'customerName': c.name,
      'customerPhone': c.phone,
      'totalAmount': paid + balance,
      'amount': paid + balance,
      'amountPaid': paid,
      if (earliestDue != null) 'dueDate': earliestDue.toIso8601String(),
      'items': items,
    };
  }

  static const _maxBills = 5;

  /// Notes-tab entry + audit-log line recording that a reminder went out.
  static Future<void> _markSent(
    WidgetRef ref, {
    required String customerId,
    required String customerName,
    required String channel,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final ownerUid = ref.read(tenantOwnerUidProvider) ?? user.uid;
      final bizId = ref.read(currentBusinessIdProvider).valueOrNull ?? '';
      if (bizId.isNotEmpty) {
        final repo = ref.read(contextFirestoreRepositoryProvider);
        final customersCol = repo.scopeCollection(
          uid: ownerUid,
          context: ResolvedFinanceContext.business(bizId),
          childCollection: 'customers',
        );
        // Best-effort, non-blocking: notes have no offline store and this
        // write never completes while offline (persistence is disabled —
        // see main.dart); Firestore flushes the queued write on reconnect.
        customersCol.doc(customerId).collection('notes').add({
          'type': 'reminder',
          'text': _t(
            'Payment reminder sent via $channel',
            'Kumbusho la malipo kilitumwa kupitia $channel',
          ),
          'addedAt': FieldValue.serverTimestamp(),
          'addedBy': user.uid,
          'reminderSent': false,
        }).ignore();
      }
      await ref
          .read(customerAuditLoggerProvider)
          .log(
            AuditLogService.reminderSent,
            customerId: customerId,
            customerName: customerName,
            newValue: channel,
          );
    } catch (_) {}
  }

  /// `wa.me` can only pre-fill text, not attach a file, so sending the
  /// actual PDF goes through the OS share sheet instead (the user picks
  /// WhatsApp there) — same mechanism as the debt sheet's WhatsApp Reminder.
  static Future<void> sendWhatsApp(
    WidgetRef ref,
    BuildContext context,
    Customer customer,
    double balance,
  ) async {
    if (!canSend(context, customer, balance)) return;
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final bizId = ref.read(currentBusinessIdProvider).valueOrNull;
      final sale = _buildStatementSale(
        customer,
        balance,
        _bills(ref, customer.id),
      );
      final meta = await ReceiptPdfService.loadMeta(uid: uid, businessId: bizId);
      final shared = await ReceiptPdfService.share(
        sale: sale,
        businessName: meta['businessName'] ?? 'Business',
        printedBy: meta['printedBy'] ?? _t('User', 'Mtumiaji'),
        isSwahili: LocalizationService.isSwahili,
        businessPhone: meta['businessPhone'] ?? '',
        businessEmail: meta['businessEmail'] ?? '',
        businessAddress: meta['businessAddress'] ?? '',
        businessLogoUrl: meta['businessLogoUrl'] ?? '',
        subject: '${_t('Debt Reminder', 'Ukumbusho wa Deni')} ${customer.name}',
      );
      if (!shared) return;
      await _markSent(
        ref,
        customerId: customer.id,
        customerName: customer.name,
        channel: 'whatsapp',
      );
    } catch (_) {
      if (context.mounted) {
        AppNotification.error(
          context,
          _t('Could not open WhatsApp.', 'Imeshindwa kufungua WhatsApp.'),
        );
      }
    }
  }

  static Future<void> sendSms(
    WidgetRef ref,
    BuildContext context,
    Customer customer,
    double balance,
  ) async {
    if (!canSend(context, customer, balance)) return;
    // SMS is plain text — strip the WhatsApp-style markdown (*bold*) from
    // the shared reminder copy.
    final msg = _buildReminderText(
      customer,
      balance,
      _bills(ref, customer.id),
    ).replaceAll('*', '');
    final uri = Uri.parse(
      'sms:${customer.phone}?body=${Uri.encodeComponent(msg)}',
    );
    try {
      final opened = await launchUrl(uri);
      if (!opened) throw Exception('No SMS handler');
      await _markSent(
        ref,
        customerId: customer.id,
        customerName: customer.name,
        channel: 'sms',
      );
    } catch (_) {
      if (context.mounted) {
        AppNotification.error(
          context,
          _t('Could not open the SMS app.', 'Imeshindwa kufungua programu ya SMS.'),
        );
      }
    }
  }

  /// Opens the reminder PDF in the OS "Open with" viewer for a quick
  /// on-device preview/print — distinct from [sendWhatsApp], which hands
  /// the same PDF to the share sheet instead.
  static Future<void> sendPdf(
    WidgetRef ref,
    BuildContext context,
    Customer customer,
    double balance,
  ) async {
    if (!canSend(context, customer, balance)) return;
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final bizId = ref.read(currentBusinessIdProvider).valueOrNull;
      final sale = _buildStatementSale(
        customer,
        balance,
        _bills(ref, customer.id),
      );
      final meta = await ReceiptPdfService.loadMeta(uid: uid, businessId: bizId);
      await ReceiptPdfService.open(
        sale: sale,
        businessName: meta['businessName'] ?? 'Business',
        printedBy: meta['printedBy'] ?? _t('User', 'Mtumiaji'),
        isSwahili: LocalizationService.isSwahili,
        businessPhone: meta['businessPhone'] ?? '',
        businessEmail: meta['businessEmail'] ?? '',
        businessAddress: meta['businessAddress'] ?? '',
        businessLogoUrl: meta['businessLogoUrl'] ?? '',
      );
      await _markSent(
        ref,
        customerId: customer.id,
        customerName: customer.name,
        channel: 'pdf',
      );
    } catch (_) {
      if (context.mounted) {
        AppNotification.error(
          context,
          _t(
            'Could not create the reminder PDF. Please try again.',
            'Imeshindwa kutengeneza PDF ya ukumbusho. Jaribu tena.',
          ),
        );
      }
    }
  }

  static String _fmtNum(double v) {
    if (v == 0) return '0';
    final s = v.toStringAsFixed(0);
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static String _fmtDate(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';
}

/// One open bill in a customer reminder — an invoice or a hand-added debt.
class _Bill {
  final String label;
  final DateTime? date;
  final DateTime? dueDate;
  final List<Map<String, dynamic>> items;
  final double total;
  final double paid;
  final double owed;

  const _Bill({
    required this.label,
    required this.date,
    required this.dueDate,
    required this.items,
    required this.total,
    required this.paid,
    required this.owed,
  });
}

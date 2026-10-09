import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/data/repositories/context_firestore_repository.dart';
import '../../../core/services/localization_service.dart';
import '../../../shared/widgets/app_notification.dart';
import '../../rbac/data/audit_log_service.dart';
import '../../rbac/data/rbac_providers.dart';
import '../../sales/data/sales_providers.dart';
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

  static List<Map<String, dynamic>> _overdueInvoices(
    WidgetRef ref,
    String customerId,
  ) {
    final invoices = ref
        .read(customerInvoicesProvider(customerId))
        .maybeWhen(data: (d) => d, orElse: () => <Map<String, dynamic>>[]);
    return invoices.where((inv) {
      final s = (inv['status'] ?? '').toString().toLowerCase();
      return s != 'paid' && s != 'cancelled' && s != 'draft';
    }).toList();
  }

  static String _buildReminderText(
    Customer c,
    double balance,
    List<Map<String, dynamic>> overdue,
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
    if (overdue.isNotEmpty) {
      buf.writeln(_t('Unpaid invoices:', 'Ankara ambazo hazijalipwa:'));
      for (final inv in overdue.take(5)) {
        final invNum =
            inv['invoiceNumber']?.toString() ?? inv['id']?.toString() ?? '';
        final amt = readInvoiceTotal(inv);
        final date = readSaleDate(inv);
        final datePart = date != null ? ' (${_fmtDate(date)})' : '';
        buf.writeln(
          '• ${_t('Invoice', 'Ankara')} $invNum$datePart — TZS ${_fmtNum(amt)}',
        );

        final rawItems = inv['lineItems'] ?? inv['items'];
        if (rawItems is List && rawItems.isNotEmpty) {
          for (final item in rawItems.take(3)) {
            final name = (item['name'] ?? item['productName'] ?? '').toString();
            if (name.isEmpty) continue;
            final rawQty = item['quantity'] ?? item['qty'] ?? 1;
            final qtyVal = rawQty is num ? rawQty.toDouble() : 1.0;
            final qtyStr = qtyVal % 1 == 0
                ? qtyVal.toInt().toString()
                : qtyVal.toStringAsFixed(1);
            buf.writeln('   › $name × $qtyStr');
          }
          if (rawItems.length > 3) {
            final extra = rawItems.length - 3;
            buf.writeln(
              '   ${_t('+ $extra more item${extra == 1 ? '' : 's'}', '+ vitu $extra zaidi')}',
            );
          }
          buf.writeln();
        }
      }
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
  static Map<String, dynamic> _buildStatementSale(
    Customer c,
    double balance,
    List<Map<String, dynamic>> overdue,
  ) {
    final items = <Map<String, dynamic>>[];
    for (final inv in overdue.take(5)) {
      final raw = inv['lineItems'] ?? inv['items'];
      if (raw is List) {
        items.addAll(
          raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)),
        );
      }
    }
    DateTime? earliestDue;
    for (final inv in overdue) {
      final d = DateTime.tryParse((inv['dueDate'] ?? '').toString());
      if (d != null && (earliestDue == null || d.isBefore(earliestDue))) {
        earliestDue = d;
      }
    }
    final singleInvoiceNumber = overdue.length == 1
        ? (overdue.first['invoiceNumber'] ?? '').toString()
        : '';
    return {
      'type': 'debt',
      'invoiceNumber': singleInvoiceNumber.isNotEmpty
          ? singleInvoiceNumber
          : _t('Statement', 'Taarifa ya Malipo'),
      'customerName': c.name,
      'customerPhone': c.phone,
      'totalAmount': balance,
      'amount': balance,
      'amountPaid': 0,
      if (earliestDue != null) 'dueDate': earliestDue.toIso8601String(),
      'items': items,
    };
  }

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
        _overdueInvoices(ref, customer.id),
      );
      final meta = await ReceiptPdfService.loadMeta(uid: uid, businessId: bizId);
      final shared = await ReceiptPdfService.share(
        sale: sale,
        businessName: meta['businessName'] ?? 'Business',
        printedBy: meta['printedBy'] ?? 'User',
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
      _overdueInvoices(ref, customer.id),
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
        _overdueInvoices(ref, customer.id),
      );
      final meta = await ReceiptPdfService.loadMeta(uid: uid, businessId: bizId);
      await ReceiptPdfService.open(
        sale: sale,
        businessName: meta['businessName'] ?? 'Business',
        printedBy: meta['printedBy'] ?? 'User',
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

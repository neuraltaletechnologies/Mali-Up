import 'package:cloud_firestore/cloud_firestore.dart';

/// Everything a customer receipt shows, parsed once from a sale map so the
/// PDF ([ReceiptPdfService]) and the thermal-printer ticket
/// ([EscPosReceiptBuilder]) always agree on totals, lines and titles.
class ReceiptData {
  final bool isSwahili;
  final String invoiceNumber;
  final bool isQuotation;
  final bool isDebtReceipt;
  final String documentTitle;
  final String customer;
  final String customerPhone;
  final DateTime? createdAt;
  final DateTime? dueDate;
  final double amount;
  final double amountPaid;
  final double balance;

  /// Line items as stored on the sale; may be empty.
  final List<ReceiptLine> lines;
  final double subtotal;
  final double discount;
  final double vat;
  final String paymentMethod;
  final String paymentReference;
  final String notes;

  const ReceiptData._({
    required this.isSwahili,
    required this.invoiceNumber,
    required this.isQuotation,
    required this.isDebtReceipt,
    required this.documentTitle,
    required this.customer,
    required this.customerPhone,
    required this.createdAt,
    required this.dueDate,
    required this.amount,
    required this.amountPaid,
    required this.balance,
    required this.lines,
    required this.subtotal,
    required this.discount,
    required this.vat,
    required this.paymentMethod,
    required this.paymentReference,
    required this.notes,
  });

  String t(String en, String sw) => isSwahili ? sw : en;

  /// [lines], or a single "Sale item" line for the total when the sale has
  /// no itemised lines (quick sale, manual debt).
  List<ReceiptLine> get printableLines => lines.isNotEmpty
      ? lines
      : [
          ReceiptLine(
            name: t('Sale item', 'Bidhaa ya mauzo'),
            quantity: 1,
            unitPrice: amount,
            total: amount,
          ),
        ];

  factory ReceiptData.fromSale(
    Map<String, dynamic> sale, {
    required bool isSwahili,
  }) {
    String t(String en, String sw) => isSwahili ? sw : en;
    const amountOf = ReceiptFormat.amountOf;

    final invoiceNumber = (sale['invoiceNumber'] ?? sale['id'] ?? '-')
        .toString();
    final saleType = (sale['type'] ?? '').toString().toLowerCase();
    final isQuotation = saleType == 'quotation';
    // A debt reminder isn't proof of a completed sale — it's a receipt of
    // what's still owed, so it gets its own title rather than "SALE RECEIPT".
    final isDebtReceipt = saleType == 'debt';
    final documentTitle = isQuotation
        ? t('QUOTATION', 'NUKUU')
        : isDebtReceipt
        ? t('DEBT RECEIPT', 'RISITI YA DENI')
        : t('SALE RECEIPT', 'RISITI YA MAUZO');
    final customerName = (sale['customerName'] ?? '').toString().trim();
    // The sale's actual date, not when the record was written — a backdated
    // sale must print the date the user picked, not today's date.
    final createdAt = ReceiptFormat.asDate(
      sale['date'] ?? sale['invoiceDate'] ?? sale['createdAt'],
    );
    final amount = amountOf(sale['totalAmount'] ?? sale['amount']);
    final amountPaid = amountOf(sale['amountPaid']);
    final rawItems = sale['lineItems'] ?? sale['items'];
    final items = rawItems is List
        ? rawItems.whereType<Map>().toList()
        : const <Map>[];

    var itemDiscount = 0.0;
    final lines = <ReceiptLine>[];
    for (final item in items) {
      final quantity = amountOf(item['qty'] ?? item['quantity'] ?? 1);
      final chargedUnitPrice = amountOf(item['unitPrice']);
      final basePrice = amountOf(item['basePrice']);
      final displayUnitPrice =
          basePrice > chargedUnitPrice && chargedUnitPrice > 0
          ? basePrice
          : chargedUnitPrice;
      if (displayUnitPrice > chargedUnitPrice && quantity > 0) {
        itemDiscount += (displayUnitPrice - chargedUnitPrice) * quantity;
      }
      final storedTotal = amountOf(item['lineTotal'] ?? item['total']);
      final displayTotal = displayUnitPrice > chargedUnitPrice && quantity > 0
          ? displayUnitPrice * quantity
          : storedTotal > 0
          ? storedTotal
          : displayUnitPrice * quantity;
      final name = (item['productName'] ?? item['name'] ?? '-')
          .toString()
          .trim();
      lines.add(
        ReceiptLine(
          name: name.isEmpty ? '-' : name,
          quantity: quantity,
          unitPrice: displayUnitPrice,
          total: displayTotal,
        ),
      );
    }

    final storedSubtotal = amountOf(sale['subtotal']);
    return ReceiptData._(
      isSwahili: isSwahili,
      invoiceNumber: invoiceNumber,
      isQuotation: isQuotation,
      isDebtReceipt: isDebtReceipt,
      documentTitle: documentTitle,
      customer: customerName.isEmpty
          ? t('Walk-in customer', 'Mteja wa kawaida')
          : customerName,
      customerPhone: (sale['customerPhone'] ?? '').toString().trim(),
      createdAt: createdAt,
      dueDate: ReceiptFormat.asDate(sale['dueDate']),
      amount: amount,
      amountPaid: amountPaid,
      balance: (amount - amountPaid).clamp(0, amount).toDouble(),
      lines: lines,
      subtotal: (storedSubtotal > 0 ? storedSubtotal : amount) + itemDiscount,
      discount: amountOf(sale['discountAmount']) + itemDiscount,
      vat: amountOf(sale['vatAmount']),
      paymentMethod: ReceiptFormat.paymentMethod(
        (sale['paymentMethod'] ?? '').toString(),
        isSwahili: isSwahili,
      ),
      paymentReference: (sale['mpesaRef'] ?? '').toString().trim(),
      notes: (sale['notes'] ?? '').toString().trim(),
    );
  }
}

class ReceiptLine {
  final String name;
  final double quantity;
  final double unitPrice;
  final double total;

  const ReceiptLine({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.total,
  });
}

/// Shared number/date formatting for receipts.
abstract final class ReceiptFormat {
  static double amountOf(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(
          (value ?? '').toString().replaceAll(RegExp(r'[^0-9.-]'), ''),
        ) ??
        0;
  }

  static DateTime? asDate(dynamic value) {
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static String date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

  static String dateTime(DateTime value) =>
      '${date(value)} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

  static String quantity(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(2);

  /// `12,500` — grouped whole shillings, no currency.
  static String number(double value) {
    final sign = value < 0 ? '-' : '';
    final raw = value.abs().toStringAsFixed(0);
    final grouped = raw.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'),
      (match) => '${match[1]},',
    );
    return '$sign$grouped';
  }

  /// `TZS 12,500` (negative: `-TZS 12,500`).
  static String money(double value) {
    final n = number(value);
    return n.startsWith('-') ? '-TZS ${n.substring(1)}' : 'TZS $n';
  }

  static String paymentMethod(String value, {required bool isSwahili}) {
    String t(String en, String sw) => isSwahili ? sw : en;
    return switch (value.trim().toLowerCase()) {
      'mpesa' => 'M-Pesa',
      'bank_transfer' => t('Bank transfer', 'Uhamisho wa benki'),
      'card' => t('Card', 'Kadi'),
      'credit' => t('Credit (pay later)', 'Mkopo'),
      'cash' => t('Cash', 'Taslimu'),
      final other => other,
    };
  }
}

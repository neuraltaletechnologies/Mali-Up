import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../core/services/business_profile_service.dart';
import '../../../core/utils/online_guard.dart';

/// Builds and shares customer-facing sale receipts as real PDF attachments.
///
/// The caller continues to own channel selection. WhatsApp and email use
/// [share], printing uses [print], while SMS can keep using the compact text
/// receipt already built by the sales screens.
abstract final class ReceiptPdfService {
  static const _navy = PdfColor.fromInt(0xFF0D1B3E);
  static const _teal = PdfColor.fromInt(0xFF1A6E8A);
  static const _yellow = PdfColor.fromInt(0xFFFFC107);
  static const _muted = PdfColor.fromInt(0xFF667085);
  static const _line = PdfColor.fromInt(0xFFE4E7EC);

  static Future<Map<String, String>> loadMeta({
    required String uid,
    required String? businessId,
  }) async {
    final firestore = FirebaseFirestore.instance;
    var businessName = 'Business';
    var printedBy = 'User';
    final cachedProfile = await BusinessProfileService.loadCachedProfile(uid);
    final cachedBusinesses = cachedProfile?['businesses'];
    if (cachedBusinesses is List && businessId != null) {
      for (final business in cachedBusinesses) {
        if (business is! Map || business['id']?.toString() != businessId) {
          continue;
        }
        final name = (business['businessName'] ?? business['name'])
            ?.toString()
            .trim();
        if (name != null && name.isNotEmpty) businessName = name;
        break;
      }
    }
    try {
      if (!await OnlineGuard.isDeviceOnline()) {
        return {'businessName': businessName, 'printedBy': printedBy};
      }
    } catch (_) {
      // If connectivity cannot be determined, use the bounded reads below.
    }
    try {
      final userDoc = await firestore
          .collection('users')
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 3));
      final data = userDoc.data();
      printedBy =
          ((data?['displayName'] ?? data?['name']) as String?)?.trim() ??
          'User';
      final businesses = data?['businesses'];
      if (businesses is List && businessId != null) {
        for (final business in businesses) {
          final name =
              (business is Map
                      ? business['businessName'] ?? business['name']
                      : null)
                  ?.toString()
                  .trim();
          if (business is Map &&
              business['id']?.toString() == businessId &&
              name != null &&
              name.isNotEmpty) {
            businessName = name;
            break;
          }
        }
      }
    } catch (_) {
      // The business document fallback below can still supply the receipt name.
    }
    if (businessName == 'Business' &&
        businessId != null &&
        businessId.isNotEmpty) {
      try {
        final businessDoc = await firestore
            .collection('businesses')
            .doc(businessId)
            .get()
            .timeout(const Duration(seconds: 3));
        final name = (businessDoc.data()?['businessName'] as String?)?.trim();
        if (name != null && name.isNotEmpty) businessName = name;
      } catch (_) {
        // A generic label is preferable to blocking an offline PDF receipt.
      }
    }
    return {'businessName': businessName, 'printedBy': printedBy};
  }

  static Future<Uint8List> build({
    required Map<String, dynamic> sale,
    required String businessName,
    required String printedBy,
    required bool isSwahili,
  }) async {
    String t(String en, String sw) => isSwahili ? sw : en;

    final invoiceNumber = (sale['invoiceNumber'] ?? sale['id'] ?? '-')
        .toString();
    final isQuotation =
        (sale['type'] ?? '').toString().toLowerCase() == 'quotation';
    final documentTitle = isQuotation
        ? t('QUOTATION', 'NUKUU')
        : t('SALE RECEIPT', 'RISITI YA MAUZO');
    final customerName = (sale['customerName'] ?? '').toString().trim();
    final customer = customerName.isEmpty
        ? t('Walk-in customer', 'Mteja wa kawaida')
        : customerName;
    final customerPhone = (sale['customerPhone'] ?? '').toString().trim();
    final createdAt = _asDate(
      sale['createdAt'] ?? sale['invoiceDate'] ?? sale['date'],
    );
    final dueDate = _asDate(sale['dueDate']);
    final amount = _amount(sale['totalAmount'] ?? sale['amount']);
    final amountPaid = _amount(sale['amountPaid']);
    final balance = (amount - amountPaid).clamp(0, amount).toDouble();
    final rawItems = sale['lineItems'] ?? sale['items'];
    final items = rawItems is List
        ? rawItems.whereType<Map>().toList()
        : const <Map>[];

    var itemDiscount = 0.0;
    final displayItems = <_ReceiptLine>[];
    for (final item in items) {
      final quantity = _amount(item['qty'] ?? item['quantity'] ?? 1);
      final chargedUnitPrice = _amount(item['unitPrice']);
      final basePrice = _amount(item['basePrice']);
      final displayUnitPrice =
          basePrice > chargedUnitPrice && chargedUnitPrice > 0
          ? basePrice
          : chargedUnitPrice;
      if (displayUnitPrice > chargedUnitPrice && quantity > 0) {
        itemDiscount += (displayUnitPrice - chargedUnitPrice) * quantity;
      }
      final storedTotal = _amount(item['lineTotal'] ?? item['total']);
      final displayTotal = displayUnitPrice > chargedUnitPrice && quantity > 0
          ? displayUnitPrice * quantity
          : storedTotal > 0
          ? storedTotal
          : displayUnitPrice * quantity;
      final name = (item['productName'] ?? item['name'] ?? '-')
          .toString()
          .trim();
      displayItems.add(
        _ReceiptLine(
          name: name.isEmpty ? '-' : name,
          quantity: quantity,
          unitPrice: displayUnitPrice,
          total: displayTotal,
        ),
      );
    }

    final storedSubtotal = _amount(sale['subtotal']);
    final subtotal =
        (storedSubtotal > 0 ? storedSubtotal : amount) + itemDiscount;
    final discount = _amount(sale['discountAmount']) + itemDiscount;
    final vat = _amount(sale['vatAmount']);
    final paymentMethod = _paymentMethod(
      (sale['paymentMethod'] ?? '').toString(),
      isSwahili: isSwahili,
    );
    final paymentReference = (sale['mpesaRef'] ?? '').toString().trim();
    final notes = (sale['notes'] ?? '').toString().trim();

    final document = pw.Document(
      title: '$documentTitle $invoiceNumber',
      author: businessName,
      subject: t('Customer sale receipt', 'Risiti ya mauzo ya mteja'),
    );
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        theme: pw.ThemeData.withFont(
          base: pw.Font.helvetica(),
          bold: pw.Font.helveticaBold(),
        ),
        footer: (context) => pw.Container(
          padding: const pw.EdgeInsets.only(top: 10),
          decoration: const pw.BoxDecoration(
            border: pw.Border(top: pw.BorderSide(color: _line, width: 0.7)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Powered by Mali Up',
                style: const pw.TextStyle(fontSize: 8, color: _muted),
              ),
              pw.Text(
                '${t("Page", "Ukurasa")} ${context.pageNumber}/${context.pagesCount}',
                style: const pw.TextStyle(fontSize: 8, color: _muted),
              ),
            ],
          ),
        ),
        build: (_) => [
          pw.Container(
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              color: _navy,
              borderRadius: pw.BorderRadius.circular(10),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: 42,
                  height: 42,
                  alignment: pw.Alignment.center,
                  decoration: pw.BoxDecoration(
                    color: _yellow,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Text(
                    'MU',
                    style: pw.TextStyle(
                      color: _navy,
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(width: 14),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        businessName.isEmpty ? 'Business' : businessName,
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        documentTitle,
                        style: const pw.TextStyle(
                          color: _yellow,
                          fontSize: 10,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.Text(
                  invoiceNumber,
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 22),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: _infoBlock(t('BILLED TO', 'MTEJA'), [
                  customer,
                  if (customerPhone.isNotEmpty) customerPhone,
                ]),
              ),
              pw.SizedBox(width: 24),
              pw.Expanded(
                child: _infoBlock(t('RECEIPT DETAILS', 'TAARIFA ZA RISITI'), [
                  '${t("Number", "Namba")}: $invoiceNumber',
                  if (createdAt != null)
                    '${t("Date", "Tarehe")}: ${_formatDate(createdAt)}',
                  if (dueDate != null && !isQuotation)
                    '${t("Due", "Mwisho")}: ${_formatDate(dueDate)}',
                ]),
              ),
            ],
          ),
          pw.SizedBox(height: 22),
          pw.Table(
            border: const pw.TableBorder(
              horizontalInside: pw.BorderSide(color: _line, width: 0.6),
              bottom: pw.BorderSide(color: _line, width: 0.8),
            ),
            columnWidths: const {
              0: pw.FlexColumnWidth(4.4),
              1: pw.FlexColumnWidth(1.1),
              2: pw.FlexColumnWidth(2.1),
              3: pw.FlexColumnWidth(2.1),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: _teal),
                children: [
                  _headerCell(t('ITEM', 'BIDHAA')),
                  _headerCell(t('QTY', 'IDADI'), align: pw.TextAlign.center),
                  _headerCell(
                    t('UNIT PRICE', 'BEI'),
                    align: pw.TextAlign.right,
                  ),
                  _headerCell(t('AMOUNT', 'KIASI'), align: pw.TextAlign.right),
                ],
              ),
              if (displayItems.isEmpty)
                pw.TableRow(
                  children: [
                    _bodyCell(t('Sale item', 'Bidhaa ya mauzo')),
                    _bodyCell('1', align: pw.TextAlign.center),
                    _bodyCell(_money(amount), align: pw.TextAlign.right),
                    _bodyCell(_money(amount), align: pw.TextAlign.right),
                  ],
                )
              else
                ...displayItems.map(
                  (item) => pw.TableRow(
                    children: [
                      _bodyCell(item.name),
                      _bodyCell(
                        _quantity(item.quantity),
                        align: pw.TextAlign.center,
                      ),
                      _bodyCell(
                        _money(item.unitPrice),
                        align: pw.TextAlign.right,
                      ),
                      _bodyCell(_money(item.total), align: pw.TextAlign.right),
                    ],
                  ),
                ),
            ],
          ),
          pw.SizedBox(height: 18),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (!isQuotation && paymentMethod.isNotEmpty) ...[
                      _smallLabel(t('PAYMENT', 'MALIPO')),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        paymentMethod,
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                      if (paymentReference.isNotEmpty)
                        pw.Text(
                          '${t("Reference", "Kumbukumbu")}: $paymentReference',
                          style: const pw.TextStyle(fontSize: 9, color: _muted),
                        ),
                    ],
                    if (notes.isNotEmpty) ...[
                      pw.SizedBox(height: 14),
                      _smallLabel(t('NOTES', 'MAELEZO')),
                      pw.SizedBox(height: 5),
                      pw.Text(notes, style: const pw.TextStyle(fontSize: 9)),
                    ],
                  ],
                ),
              ),
              pw.SizedBox(width: 30),
              pw.SizedBox(
                width: 220,
                child: pw.Column(
                  children: [
                    _totalRow(t('Subtotal', 'Jumla ndogo'), subtotal),
                    if (discount > 0)
                      _totalRow(t('Discount', 'Punguzo'), -discount),
                    if (vat > 0) _totalRow('VAT (18%)', vat),
                    pw.Divider(color: _navy, thickness: 1.4),
                    _totalRow(
                      t('TOTAL', 'JUMLA KUU'),
                      amount,
                      emphasized: true,
                    ),
                    if (!isQuotation) ...[
                      _totalRow(t('Paid', 'Imelipwa'), amountPaid),
                      if (balance > 0)
                        _totalRow(
                          t('Balance due', 'Baki'),
                          balance,
                          emphasized: true,
                        ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 26),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            decoration: pw.BoxDecoration(
              color: const PdfColor.fromInt(0xFFF8FAFC),
              borderRadius: pw.BorderRadius.circular(6),
              border: pw.Border.all(color: _line),
            ),
            child: pw.Text(
              '${t("Prepared by", "Imeandaliwa na")}: ${printedBy.isEmpty ? "User" : printedBy}',
              style: const pw.TextStyle(fontSize: 9, color: _muted),
            ),
          ),
        ],
      ),
    );

    return document.save();
  }

  static Future<bool> share({
    required Map<String, dynamic> sale,
    required String businessName,
    required String printedBy,
    required bool isSwahili,
    String? customerEmail,
  }) async {
    final invoiceNumber = (sale['invoiceNumber'] ?? sale['id'] ?? 'receipt')
        .toString();
    final bytes = await build(
      sale: sale,
      businessName: businessName,
      printedBy: printedBy,
      isSwahili: isSwahili,
    );
    final email = customerEmail?.trim() ?? '';
    return Printing.sharePdf(
      bytes: bytes,
      filename: filename(invoiceNumber),
      subject: isSwahili
          ? 'Risiti $invoiceNumber kutoka $businessName'
          : 'Receipt $invoiceNumber from $businessName',
      body: isSwahili
          ? 'Risiti yako imeambatishwa kama PDF.'
          : 'Your receipt is attached as a PDF.',
      emails: email.isEmpty ? null : [email],
    );
  }

  static Future<bool> print({
    required Map<String, dynamic> sale,
    required String businessName,
    required String printedBy,
    required bool isSwahili,
  }) {
    final invoiceNumber = (sale['invoiceNumber'] ?? sale['id'] ?? 'receipt')
        .toString();
    return Printing.layoutPdf(
      name: filename(invoiceNumber),
      onLayout: (_) => build(
        sale: sale,
        businessName: businessName,
        printedBy: printedBy,
        isSwahili: isSwahili,
      ),
    );
  }

  static String filename(String invoiceNumber) {
    final safe = invoiceNumber
        .trim()
        .replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return 'receipt_${safe.isEmpty ? "sale" : safe}.pdf';
  }

  static pw.Widget _infoBlock(String title, List<String> lines) => pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      _smallLabel(title),
      pw.SizedBox(height: 7),
      ...lines.map(
        (line) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 3),
          child: pw.Text(line, style: const pw.TextStyle(fontSize: 10)),
        ),
      ),
    ],
  );

  static pw.Widget _smallLabel(String value) => pw.Text(
    value,
    style: pw.TextStyle(
      color: _teal,
      fontSize: 8,
      letterSpacing: 0.8,
      fontWeight: pw.FontWeight.bold,
    ),
  );

  static pw.Widget _headerCell(
    String value, {
    pw.TextAlign align = pw.TextAlign.left,
  }) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 9, vertical: 8),
    child: pw.Text(
      value,
      textAlign: align,
      style: pw.TextStyle(
        color: PdfColors.white,
        fontSize: 8,
        fontWeight: pw.FontWeight.bold,
      ),
    ),
  );

  static pw.Widget _bodyCell(
    String value, {
    pw.TextAlign align = pw.TextAlign.left,
  }) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 9, vertical: 9),
    child: pw.Text(
      value,
      textAlign: align,
      style: const pw.TextStyle(fontSize: 9),
    ),
  );

  static pw.Widget _totalRow(
    String label,
    double value, {
    bool emphasized = false,
  }) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 4),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: emphasized ? 11 : 9,
            color: emphasized ? _navy : _muted,
            fontWeight: emphasized ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
        pw.Text(
          _money(value),
          style: pw.TextStyle(
            fontSize: emphasized ? 11 : 9,
            color: emphasized ? _navy : PdfColors.black,
            fontWeight: emphasized ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      ],
    ),
  );

  static double _amount(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(
          (value ?? '').toString().replaceAll(RegExp(r'[^0-9.-]'), ''),
        ) ??
        0;
  }

  static DateTime? _asDate(dynamic value) {
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static String _formatDate(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

  static String _quantity(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(2);

  static String _money(double value) {
    final sign = value < 0 ? '-' : '';
    final raw = value.abs().toStringAsFixed(0);
    final grouped = raw.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'),
      (match) => '${match[1]},',
    );
    return '${sign}TZS $grouped';
  }

  static String _paymentMethod(String value, {required bool isSwahili}) {
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

class _ReceiptLine {
  final String name;
  final double quantity;
  final double unitPrice;
  final double total;

  const _ReceiptLine({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.total,
  });
}

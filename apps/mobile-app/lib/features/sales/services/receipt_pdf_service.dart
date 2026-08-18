import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../core/services/business_profile_service.dart';
import '../../../core/services/pdf_export_service.dart';
import '../../../core/utils/online_guard.dart';

/// Builds and hands out customer-facing sale receipts as real PDF files.
///
/// The caller continues to own channel selection. [open] generates the PDF
/// and lets the user pick a viewer via the OS "Open with" chooser, printing
/// uses [print], while SMS can keep using the compact text receipt already
/// built by the sales screens.
abstract final class ReceiptPdfService {
  static const _navy = PdfColor.fromInt(0xFF0D1B3E);
  static const _teal = PdfColor.fromInt(0xFF1A6E8A);
  static const _yellow = PdfColor.fromInt(0xFFFFC107);
  static const _muted = PdfColor.fromInt(0xFF667085);
  static const _line = PdfColor.fromInt(0xFFE4E7EC);
  static const _cream = PdfColor.fromInt(0xFFFBF9F4);

  /// A tall, narrow "ticket" page that auto-sizes to its content (no fixed
  /// bottom edge, no pagination) — the same shape as an 80mm receipt-roll
  /// printout, which also makes it print cleanly on small POS printers.
  static const _ticketFormat = PdfPageFormat(
    80 * PdfPageFormat.mm,
    double.infinity,
    marginLeft: 16,
    marginRight: 16,
    marginTop: 22,
    marginBottom: 20,
  );

  static Future<Map<String, String>> loadMeta({
    required String uid,
    required String? businessId,
    String? createdByUid,
  }) async {
    final firestore = FirebaseFirestore.instance;
    var businessName = 'Business';
    var printedBy = 'User';
    var businessPhone = '';
    var businessEmail = '';
    var businessAddress = '';
    var businessLogoUrl = '';
    final creatorUid = (createdByUid ?? '').trim().isNotEmpty
        ? createdByUid!.trim()
        : uid;

    void readBusiness(Map business) {
      final name = (business['businessName'] ?? business['name'])
          ?.toString()
          .trim();
      if (name != null && name.isNotEmpty) businessName = name;
      businessPhone = (business['phone'] ?? business['businessPhone'] ?? '')
          .toString()
          .trim();
      businessEmail = (business['email'] ?? business['businessEmail'] ?? '')
          .toString()
          .trim();
      businessLogoUrl = (business['logoUrl'] ?? '').toString().trim();
      final district = (business['district'] ?? '').toString().trim();
      final city = (business['city'] ?? business['placeOfBusiness'] ?? '')
          .toString()
          .trim();
      businessAddress = [
        district,
        city,
      ].where((part) => part.isNotEmpty).join(', ');
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser?.uid == creatorUid) {
      final authName = currentUser?.displayName?.trim() ?? '';
      if (authName.isNotEmpty) printedBy = authName;
    }
    final cachedProfile = await BusinessProfileService.loadCachedProfile(uid);
    final cachedBusinesses = cachedProfile?['businesses'];
    if (cachedBusinesses is List && businessId != null) {
      for (final business in cachedBusinesses) {
        if (business is! Map || business['id']?.toString() != businessId) {
          continue;
        }
        readBusiness(business);
        break;
      }
    }
    try {
      if (!await OnlineGuard.isDeviceOnline()) {
        return {
          'businessName': businessName,
          'printedBy': printedBy,
          'businessPhone': businessPhone,
          'businessEmail': businessEmail,
          'businessAddress': businessAddress,
          'businessLogoUrl': businessLogoUrl,
        };
      }
    } catch (_) {
      // If connectivity cannot be determined, use the bounded reads below.
    }
    try {
      final userDoc = await firestore
          .collection('users')
          .doc(creatorUid)
          .get()
          .timeout(const Duration(seconds: 3));
      final data = userDoc.data();
      final firstName = (data?['firstName'] ?? '').toString().trim();
      final lastName = (data?['lastName'] ?? '').toString().trim();
      final fullName = [
        firstName,
        lastName,
      ].where((part) => part.isNotEmpty).join(' ');
      final storedName = (data?['displayName'] ?? data?['name'] ?? fullName)
          .toString()
          .trim();
      if (storedName.isNotEmpty) printedBy = storedName;

      // Older owner profiles embedded businesses in the user document.
      final businesses = creatorUid == uid ? (data?['businesses']) : null;
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
            readBusiness(business);
            break;
          }
        }
      }
    } catch (_) {
      // The business document fallback below can still supply the receipt name.
    }
    if (businessId != null && businessId.isNotEmpty) {
      try {
        final businessDoc = await firestore
            .collection('businesses')
            .doc(businessId)
            .get()
            .timeout(const Duration(seconds: 3));
        final data = businessDoc.data();
        if (data != null) readBusiness(data);
      } catch (_) {
        // A generic label is preferable to blocking an offline PDF receipt.
      }
    }
    return {
      'businessName': businessName,
      'printedBy': printedBy,
      'businessPhone': businessPhone,
      'businessEmail': businessEmail,
      'businessAddress': businessAddress,
      'businessLogoUrl': businessLogoUrl,
    };
  }

  static Future<Uint8List> build({
    required Map<String, dynamic> sale,
    required String businessName,
    required String printedBy,
    required bool isSwahili,
    String businessPhone = '',
    String businessEmail = '',
    String businessAddress = '',
    String businessLogoUrl = '',
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
    final businessLogo = await _networkImage(businessLogoUrl);
    final maliUpLogo = await _assetImage(
      'assets/branding/mali_up_wordmark.png',
    );

    final document = pw.Document(
      title: '$documentTitle $invoiceNumber',
      author: businessName,
      subject: t('Customer sale receipt', 'Risiti ya mauzo ya mteja'),
    );
    document.addPage(
      pw.Page(
        pageFormat: _ticketFormat,
        theme: pw.ThemeData.withFont(
          base: pw.Font.helvetica(),
          bold: pw.Font.helveticaBold(),
          italic: pw.Font.helveticaOblique(),
        ),
        build: (_) => pw.Column(
          mainAxisSize: pw.MainAxisSize.min,
          children: [
            _perforationDots(),
            pw.SizedBox(height: 14),
            pw.Container(
              width: 42,
              height: 42,
              alignment: pw.Alignment.center,
              decoration: pw.BoxDecoration(
                shape: pw.BoxShape.circle,
                border: pw.Border.all(color: _teal, width: 1.1),
              ),
              child: businessLogo != null
                  ? pw.ClipOval(
                      child: pw.Image(
                        businessLogo,
                        width: 42,
                        height: 42,
                        fit: pw.BoxFit.cover,
                      ),
                    )
                  : pw.Text(
                      _businessInitial(businessName),
                      style: pw.TextStyle(
                        color: _teal,
                        fontSize: 15,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              businessName.isEmpty || businessName == 'Business'
                  ? t('Business', 'Biashara')
                  : businessName,
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                color: _navy,
                fontSize: 13.5,
                fontWeight: pw.FontWeight.bold,
                letterSpacing: 0.2,
              ),
            ),
            if (businessAddress.isNotEmpty ||
                businessPhone.isNotEmpty ||
                businessEmail.isNotEmpty) ...[
              pw.SizedBox(height: 4),
              pw.Text(
                [
                  businessAddress,
                  businessPhone,
                  businessEmail,
                ].where((value) => value.isNotEmpty).join('  •  '),
                textAlign: pw.TextAlign.center,
                style: const pw.TextStyle(color: _muted, fontSize: 7.3),
              ),
            ],
            pw.SizedBox(height: 12),
            pw.Container(width: 32, height: 2, color: _yellow),
            pw.SizedBox(height: 12),
            pw.Text(
              documentTitle,
              style: pw.TextStyle(
                color: _teal,
                fontSize: 9.5,
                fontWeight: pw.FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            pw.SizedBox(height: 3),
            pw.Text(
              '${t("No.", "Namba")} $invoiceNumber',
              style: const pw.TextStyle(color: _muted, fontSize: 8.3),
            ),
            pw.SizedBox(height: 14),
            _dottedRule(),
            pw.SizedBox(height: 12),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _smallLabel(t('CUSTOMER', 'MTEJA')),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        customer,
                        style: const pw.TextStyle(fontSize: 9.5),
                      ),
                      if (customerPhone.isNotEmpty)
                        pw.Text(
                          customerPhone,
                          style: const pw.TextStyle(
                            fontSize: 7.8,
                            color: _muted,
                          ),
                        ),
                    ],
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    if (createdAt != null) ...[
                      _smallLabel(t('DATE', 'TAREHE')),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        _formatDateTime(createdAt),
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ],
                    if (dueDate != null && !isQuotation) ...[
                      pw.SizedBox(height: 6),
                      _smallLabel(t('DUE', 'MWISHO')),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        _formatDate(dueDate),
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 14),
            _dottedRule(),
            pw.SizedBox(height: 12),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: displayItems.isEmpty
                  ? [
                      _ticketItemRow(
                        t('Sale item', 'Bidhaa ya mauzo'),
                        1,
                        amount,
                        amount,
                      ),
                    ]
                  : displayItems
                        .map(
                          (item) => _ticketItemRow(
                            item.name,
                            item.quantity,
                            item.unitPrice,
                            item.total,
                          ),
                        )
                        .toList(),
            ),
            _dottedRule(),
            pw.SizedBox(height: 10),
            pw.Column(
              children: [
                _totalRow(t('Subtotal', 'Jumla ndogo'), subtotal),
                if (discount > 0)
                  _totalRow(t('Discount', 'Punguzo'), -discount),
                if (vat > 0) _totalRow('VAT (18%)', vat),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              decoration: pw.BoxDecoration(
                color: _cream,
                borderRadius: pw.BorderRadius.circular(5),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    t('TOTAL', 'JUMLA KUU'),
                    style: pw.TextStyle(
                      color: _navy,
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    _money(amount),
                    style: pw.TextStyle(
                      color: _navy,
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            if (!isQuotation) ...[
              pw.SizedBox(height: 8),
              _totalRow(t('Paid', 'Imelipwa'), amountPaid),
              if (balance > 0)
                _totalRow(
                  t('Balance due', 'Baki'),
                  balance,
                  emphasized: true,
                ),
            ],
            if (!isQuotation && paymentMethod.isNotEmpty) ...[
              pw.SizedBox(height: 14),
              _dottedRule(),
              pw.SizedBox(height: 12),
              _smallLabel(t('PAYMENT', 'MALIPO')),
              pw.SizedBox(height: 3),
              pw.Text(paymentMethod, style: const pw.TextStyle(fontSize: 9.5)),
              if (paymentReference.isNotEmpty)
                pw.Text(
                  '${t("Ref", "Kumb")}: $paymentReference',
                  style: const pw.TextStyle(fontSize: 8, color: _muted),
                ),
            ],
            if (notes.isNotEmpty) ...[
              pw.SizedBox(height: 12),
              _smallLabel(t('NOTES', 'MAELEZO')),
              pw.SizedBox(height: 3),
              pw.Text(
                notes,
                textAlign: pw.TextAlign.center,
                style: const pw.TextStyle(fontSize: 8.3),
              ),
            ],
            pw.SizedBox(height: 16),
            _dottedRule(),
            pw.SizedBox(height: 14),
            pw.Text(
              t('Thank you for your business!', 'Asante kwa kutuamini!'),
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                color: _teal,
                fontSize: 9.5,
                fontStyle: pw.FontStyle.italic,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              '${t("Recorded by", "Imerekodiwa na")} ${printedBy.isEmpty || printedBy == "User" ? t("User", "Mtumiaji") : printedBy}',
              textAlign: pw.TextAlign.center,
              style: const pw.TextStyle(fontSize: 7.3, color: _muted),
            ),
            pw.SizedBox(height: 14),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(
                  '${t("Powered by", "Imetengenezwa na")} ',
                  style: const pw.TextStyle(fontSize: 6.6, color: _muted),
                ),
                if (maliUpLogo != null)
                  pw.Image(maliUpLogo, width: 18, height: 18)
                else
                  pw.Text(
                    'Mali Up',
                    style: pw.TextStyle(
                      fontSize: 7.3,
                      color: _navy,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
              ],
            ),
            pw.SizedBox(height: 14),
            _perforationDots(),
          ],
        ),
      ),
    );

    return document.save();
  }

  static Future<void> open({
    required Map<String, dynamic> sale,
    required String businessName,
    required String printedBy,
    required bool isSwahili,
    String businessPhone = '',
    String businessEmail = '',
    String businessAddress = '',
    String businessLogoUrl = '',
  }) async {
    final invoiceNumber = (sale['invoiceNumber'] ?? sale['id'] ?? 'receipt')
        .toString();
    final bytes = await build(
      sale: sale,
      businessName: businessName,
      printedBy: printedBy,
      isSwahili: isSwahili,
      businessPhone: businessPhone,
      businessEmail: businessEmail,
      businessAddress: businessAddress,
      businessLogoUrl: businessLogoUrl,
    );
    await PdfExportService.openPdf(bytes, filename(invoiceNumber));
  }

  static Future<bool> print({
    required Map<String, dynamic> sale,
    required String businessName,
    required String printedBy,
    required bool isSwahili,
    String businessPhone = '',
    String businessEmail = '',
    String businessAddress = '',
    String businessLogoUrl = '',
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
        businessPhone: businessPhone,
        businessEmail: businessEmail,
        businessAddress: businessAddress,
        businessLogoUrl: businessLogoUrl,
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

  static Future<pw.MemoryImage?> _assetImage(String path) async {
    try {
      final data = await rootBundle.load(path);
      return pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {
      return null;
    }
  }

  static Future<pw.MemoryImage?> _networkImage(String url) async {
    final value = url.trim();
    if (value.isEmpty) return null;
    try {
      final response = await http
          .get(Uri.parse(value))
          .timeout(const Duration(seconds: 4));
      if (response.statusCode < 200 || response.statusCode >= 300) return null;
      return pw.MemoryImage(response.bodyBytes);
    } catch (_) {
      return null;
    }
  }

  static String _businessInitial(String businessName) {
    final value = businessName.trim();
    return value.isEmpty ? 'B' : value.substring(0, 1).toUpperCase();
  }

  static pw.Widget _smallLabel(String value) => pw.Text(
    value,
    style: pw.TextStyle(
      color: _teal,
      fontSize: 8,
      letterSpacing: 0.8,
      fontWeight: pw.FontWeight.bold,
    ),
  );

  /// A thin dotted rule — the classic ticket-stub divider between sections.
  static pw.Widget _dottedRule({PdfColor color = _line}) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 2),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: List.generate(
        34,
        (_) => pw.Container(width: 2, height: 1.2, color: color),
      ),
    ),
  );

  /// A row of small dots mimicking the perforated edge of a paper ticket.
  static pw.Widget _perforationDots() => pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: List.generate(
      16,
      (_) => pw.Container(
        width: 4,
        height: 4,
        decoration: const pw.BoxDecoration(
          color: _line,
          shape: pw.BoxShape.circle,
        ),
      ),
    ),
  );

  /// One line item: name + amount on the first line, qty × unit price below.
  static pw.Widget _ticketItemRow(
    String name,
    double quantity,
    double unitPrice,
    double total,
  ) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 9),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Text(
                name,
                style: pw.TextStyle(
                  color: _navy,
                  fontSize: 9.5,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(width: 8),
            pw.Text(
              _money(total),
              style: pw.TextStyle(
                color: _navy,
                fontSize: 9.5,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          '${_quantity(quantity)} x ${_money(unitPrice)}',
          style: const pw.TextStyle(fontSize: 7.8, color: _muted),
        ),
      ],
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

  static String _formatDateTime(DateTime value) =>
      '${_formatDate(value)} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

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

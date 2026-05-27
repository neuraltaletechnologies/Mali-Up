import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../data/reports_providers.dart';

// ─── Formatting helpers ───────────────────────────────────────────────────────

String _fmt(double v) => 'TZS ${v.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    )}';

String _pct(double v) => '${v.toStringAsFixed(1)}%';

String _monthLabel(int month) {
  const m = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
               'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return m[month];
}

// ─── PDF builder helpers ──────────────────────────────────────────────────────

pw.Widget _headerRow(String title, String period) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        'Mali Up — Financial Report',
        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
      ),
      pw.SizedBox(height: 4),
      pw.Text(
        title,
        style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
      ),
      pw.Text(
        'Period: $period',
        style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
      ),
      pw.Divider(color: PdfColors.grey300),
      pw.SizedBox(height: 8),
    ],
  );
}

pw.Widget _summaryRow(String label, String value, {bool bold = false}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 3),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: bold ? pw.TextStyle(fontWeight: pw.FontWeight.bold) : null),
        pw.Text(value, style: bold ? pw.TextStyle(fontWeight: pw.FontWeight.bold) : null),
      ],
    ),
  );
}

pw.Widget _tableHeader(List<String> cols) {
  return pw.Container(
    color: PdfColors.grey200,
    padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 4),
    child: pw.Row(
      children: cols.map((c) => pw.Expanded(
        child: pw.Text(c, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
      )).toList(),
    ),
  );
}

pw.Widget _tableRow(List<String> cells, {bool shaded = false}) {
  return pw.Container(
    color: shaded ? PdfColors.grey50 : PdfColors.white,
    padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4),
    child: pw.Row(
      children: cells.map((c) => pw.Expanded(
        child: pw.Text(c, style: const pw.TextStyle(fontSize: 9)),
      )).toList(),
    ),
  );
}

// ─── CSV builder helper ───────────────────────────────────────────────────────

String _csvEscape(String v) {
  if (v.contains(',') || v.contains('"') || v.contains('\n')) {
    return '"${v.replaceAll('"', '""')}"';
  }
  return v;
}

String _csvRow(List<String> cells) => cells.map(_csvEscape).join(',');

// ─── Export Service ───────────────────────────────────────────────────────────

abstract final class ReportExportService {
  // ── P&L ──────────────────────────────────────────────────────────────────────

  static Future<void> sharePnlPdf(PnlReport report, String period) async {
    final doc = pw.Document();
    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _headerRow('Profit & Loss Statement', period),
          pw.Text('Revenue', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13)),
          pw.SizedBox(height: 4),
          _summaryRow('Total Revenue', _fmt(report.revenue)),
          _summaryRow('VAT Collected', _fmt(report.vatCollected)),
          pw.Divider(),
          _summaryRow('Gross Profit', _fmt(report.grossProfit), bold: true),
          pw.SizedBox(height: 12),
          pw.Text('Expenses', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13)),
          pw.SizedBox(height: 4),
          ...report.expenseByCategory.entries.map((e) => _summaryRow(e.key, _fmt(e.value))),
          pw.Divider(),
          _summaryRow('Total Expenses', _fmt(report.totalExpenses), bold: true),
          pw.SizedBox(height: 12),
          pw.Divider(thickness: 2),
          _summaryRow('Net Profit', _fmt(report.netProfit), bold: true),
          _summaryRow('Profit Margin', _pct(report.profitMargin)),
        ],
      ),
    ));
    await Printing.sharePdf(bytes: await doc.save(), filename: 'profit_loss_$period.pdf');
  }

  static String pnlCsv(PnlReport report, String period) {
    final rows = [
      _csvRow(['Profit & Loss — $period', '']),
      _csvRow(['', '']),
      _csvRow(['REVENUE', '']),
      _csvRow(['Total Revenue', report.revenue.toStringAsFixed(2)]),
      _csvRow(['VAT Collected', report.vatCollected.toStringAsFixed(2)]),
      _csvRow(['Gross Profit', report.grossProfit.toStringAsFixed(2)]),
      _csvRow(['', '']),
      _csvRow(['EXPENSES', '']),
      ...report.expenseByCategory.entries
          .map((e) => _csvRow([e.key, e.value.toStringAsFixed(2)])),
      _csvRow(['Total Expenses', report.totalExpenses.toStringAsFixed(2)]),
      _csvRow(['', '']),
      _csvRow(['Net Profit', report.netProfit.toStringAsFixed(2)]),
      _csvRow(['Profit Margin %', _pct(report.profitMargin)]),
    ];
    return rows.join('\n');
  }

  // ── Sales Report ─────────────────────────────────────────────────────────────

  static Future<void> shareSalesPdf(SalesReport report, String period) async {
    final doc = pw.Document();
    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _headerRow('Sales Report', period),
          _summaryRow('Total Revenue', _fmt(report.totalRevenue), bold: true),
          _summaryRow('Number of Invoices', '${report.invoiceCount}'),
          _summaryRow('Average Invoice Value', _fmt(report.averageInvoiceValue)),
          pw.SizedBox(height: 12),
          pw.Text('By Payment Method', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          _tableHeader(['Method', 'Amount', 'Share']),
          ...report.byPaymentMethod.entries.toList().asMap().entries.map((e) {
            final pct = report.totalRevenue > 0
                ? (e.value.value / report.totalRevenue * 100).toStringAsFixed(1)
                : '0.0';
            return _tableRow(
              [e.value.key, _fmt(e.value.value), '$pct%'],
              shaded: e.key.isOdd,
            );
          }),
          pw.SizedBox(height: 12),
          pw.Text('Top Products', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          _tableHeader(['Product', 'Revenue']),
          ...report.byProduct.entries
              .toList()
              .sorted((a, b) => b.value.compareTo(a.value))
              .take(10)
              .toList()
              .asMap()
              .entries
              .map((e) => _tableRow([e.value.key, _fmt(e.value.value)], shaded: e.key.isOdd)),
        ],
      ),
    ));
    await Printing.sharePdf(bytes: await doc.save(), filename: 'sales_report_$period.pdf');
  }

  static String salesCsv(SalesReport report, String period) {
    final rows = [
      _csvRow(['Sales Report — $period', '']),
      _csvRow(['Total Revenue', report.totalRevenue.toStringAsFixed(2)]),
      _csvRow(['Invoice Count', report.invoiceCount.toString()]),
      _csvRow(['Avg Invoice Value', report.averageInvoiceValue.toStringAsFixed(2)]),
      _csvRow(['', '']),
      _csvRow(['BY PAYMENT METHOD', '']),
      _csvRow(['Method', 'Amount']),
      ...report.byPaymentMethod.entries.map((e) => _csvRow([e.key, e.value.toStringAsFixed(2)])),
      _csvRow(['', '']),
      _csvRow(['BY PRODUCT', '']),
      _csvRow(['Product', 'Revenue']),
      ...report.byProduct.entries
          .toList()
          .sorted((a, b) => b.value.compareTo(a.value))
          .map((e) => _csvRow([e.key, e.value.toStringAsFixed(2)])),
    ];
    return rows.join('\n');
  }

  // ── Expense Report ────────────────────────────────────────────────────────────

  static Future<void> shareExpensePdf(ExpenseReport report, String period) async {
    final doc = pw.Document();
    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _headerRow('Expense Report', period),
          _summaryRow('Total Expenses', _fmt(report.totalExpenses), bold: true),
          _summaryRow('Number of Expenses', '${report.expenseCount}'),
          pw.SizedBox(height: 12),
          pw.Text('By Category', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          _tableHeader(['Category', 'Amount', 'Share']),
          ...report.byCategory.entries.toList().asMap().entries.map((e) {
            final pct = report.totalExpenses > 0
                ? (e.value.value / report.totalExpenses * 100).toStringAsFixed(1)
                : '0.0';
            return _tableRow(
              [e.value.key, _fmt(e.value.value), '$pct%'],
              shaded: e.key.isOdd,
            );
          }),
          pw.SizedBox(height: 12),
          pw.Text('By Vendor', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          _tableHeader(['Vendor', 'Amount']),
          ...report.byVendor.entries
              .toList()
              .sorted((a, b) => b.value.compareTo(a.value))
              .take(10)
              .toList()
              .asMap()
              .entries
              .map((e) => _tableRow([e.value.key, _fmt(e.value.value)], shaded: e.key.isOdd)),
        ],
      ),
    ));
    await Printing.sharePdf(bytes: await doc.save(), filename: 'expense_report_$period.pdf');
  }

  static String expenseCsv(ExpenseReport report, String period) {
    final rows = [
      _csvRow(['Expense Report — $period', '']),
      _csvRow(['Total Expenses', report.totalExpenses.toStringAsFixed(2)]),
      _csvRow(['Expense Count', report.expenseCount.toString()]),
      _csvRow(['', '']),
      _csvRow(['BY CATEGORY', '']),
      _csvRow(['Category', 'Amount']),
      ...report.byCategory.entries.map((e) => _csvRow([e.key, e.value.toStringAsFixed(2)])),
      _csvRow(['', '']),
      _csvRow(['BY VENDOR', '']),
      _csvRow(['Vendor', 'Amount']),
      ...report.byVendor.entries.map((e) => _csvRow([e.key, e.value.toStringAsFixed(2)])),
    ];
    return rows.join('\n');
  }

  // ── VAT Summary ───────────────────────────────────────────────────────────────

  static Future<void> shareVatPdf(VatSummary report, String period) async {
    final doc = pw.Document();
    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _headerRow('VAT Summary — TRA Compliance', period),
          pw.Text('Output VAT (Sales)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          _summaryRow('Taxable Sales Amount', _fmt(report.taxableSalesAmount)),
          _summaryRow('VAT Collected (Output VAT)', _fmt(report.vatCollectedOnSales)),
          _summaryRow('Taxable Invoices', '${report.taxableSalesCount}'),
          pw.SizedBox(height: 12),
          pw.Text('Input VAT (Purchases)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          _summaryRow('Taxable Purchases Amount', _fmt(report.taxablePurchasesAmount)),
          _summaryRow('VAT Paid (Input VAT)', _fmt(report.vatPaidOnPurchases)),
          _summaryRow('Taxable Purchase Records', '${report.taxablePurchasesCount}'),
          pw.SizedBox(height: 12),
          pw.Divider(thickness: 2),
          _summaryRow(
            report.netVatPayable >= 0 ? 'NET VAT PAYABLE TO TRA' : 'NET VAT REFUNDABLE',
            _fmt(report.netVatPayable.abs()),
            bold: true,
          ),
        ],
      ),
    ));
    await Printing.sharePdf(bytes: await doc.save(), filename: 'vat_summary_$period.pdf');
  }

  static String vatCsv(VatSummary report, String period) {
    return [
      _csvRow(['VAT Summary — $period', '']),
      _csvRow(['Taxable Sales Amount', report.taxableSalesAmount.toStringAsFixed(2)]),
      _csvRow(['VAT Collected', report.vatCollectedOnSales.toStringAsFixed(2)]),
      _csvRow(['Taxable Sales Invoices', report.taxableSalesCount.toString()]),
      _csvRow(['Taxable Purchases Amount', report.taxablePurchasesAmount.toStringAsFixed(2)]),
      _csvRow(['VAT Paid', report.vatPaidOnPurchases.toStringAsFixed(2)]),
      _csvRow(['Net VAT Payable', report.netVatPayable.toStringAsFixed(2)]),
    ].join('\n');
  }

  // ── AR Aging ──────────────────────────────────────────────────────────────────

  static Future<void> shareArAgingPdf(ArAgingReport report, String period) async {
    final doc = pw.Document();
    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _headerRow('Accounts Receivable Aging', period),
          _tableHeader(['Customer', 'Invoice', 'Age (days)', 'Amount']),
          for (final bucket in [
            report.current,
            report.days31to60,
            report.days61to90,
            report.over90,
          ]) ...[
            pw.Container(
              color: PdfColors.grey100,
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text(bucket.label,
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
            ),
            ...bucket.items.asMap().entries.map((e) => _tableRow([
              (e.value['customerName'] ?? e.value['customer'] ?? 'Unknown').toString(),
              '#${e.value['invoiceNumber'] ?? e.value['id'].toString().substring(0, 6)}',
              '${e.value['_ageDays']} days',
              _fmt(e.value['_amount'] as double),
            ], shaded: e.key.isOdd)),
            _tableRow(['', '', 'Subtotal', _fmt(bucket.total)]),
          ],
          pw.Divider(thickness: 2),
          _summaryRow('TOTAL OUTSTANDING', _fmt(report.grandTotal), bold: true),
        ],
      ),
    ));
    await Printing.sharePdf(bytes: await doc.save(), filename: 'ar_aging_$period.pdf');
  }

  static String arAgingCsv(ArAgingReport report) {
    final rows = [
      _csvRow(['Customer', 'Invoice', 'Age (days)', 'Amount', 'Bucket']),
    ];
    for (final bucket in [
      report.current,
      report.days31to60,
      report.days61to90,
      report.over90,
    ]) {
      for (final item in bucket.items) {
        rows.add(_csvRow([
          (item['customerName'] ?? item['customer'] ?? 'Unknown').toString(),
          '#${item['invoiceNumber'] ?? item['id'].toString().substring(0, 6)}',
          '${item['_ageDays']}',
          (item['_amount'] as double).toStringAsFixed(2),
          bucket.label,
        ]));
      }
    }
    rows.add(_csvRow(['', '', '', report.grandTotal.toStringAsFixed(2), 'TOTAL']));
    return rows.join('\n');
  }

  // ── AP Aging ──────────────────────────────────────────────────────────────────

  static Future<void> shareApAgingPdf(ApAgingReport report, String period) async {
    final doc = pw.Document();
    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _headerRow('Accounts Payable Aging', period),
          _tableHeader(['Vendor', 'Category', 'Age (days)', 'Amount']),
          for (final bucket in [
            report.current,
            report.days31to60,
            report.days61to90,
            report.over90,
          ]) ...[
            pw.Container(
              color: PdfColors.grey100,
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text(bucket.label,
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
            ),
            ...bucket.items.asMap().entries.map((e) => _tableRow([
              (e.value['recipient'] ?? 'Unknown').toString(),
              (e.value['category'] ?? '').toString(),
              '${e.value['_ageDays']} days',
              _fmt(e.value['_amount'] as double),
            ], shaded: e.key.isOdd)),
            _tableRow(['', '', 'Subtotal', _fmt(bucket.total)]),
          ],
          pw.Divider(thickness: 2),
          _summaryRow('TOTAL OUTSTANDING', _fmt(report.grandTotal), bold: true),
        ],
      ),
    ));
    await Printing.sharePdf(bytes: await doc.save(), filename: 'ap_aging_$period.pdf');
  }

  static String apAgingCsv(ApAgingReport report) {
    final rows = [_csvRow(['Vendor', 'Category', 'Age (days)', 'Amount', 'Bucket'])];
    for (final bucket in [
      report.current,
      report.days31to60,
      report.days61to90,
      report.over90,
    ]) {
      for (final item in bucket.items) {
        rows.add(_csvRow([
          (item['recipient'] ?? 'Unknown').toString(),
          (item['category'] ?? '').toString(),
          '${item['_ageDays']}',
          (item['_amount'] as double).toStringAsFixed(2),
          bucket.label,
        ]));
      }
    }
    rows.add(_csvRow(['', '', '', report.grandTotal.toStringAsFixed(2), 'TOTAL']));
    return rows.join('\n');
  }

  // ── Cash Flow ─────────────────────────────────────────────────────────────────

  static Future<void> shareCashFlowPdf(CashFlowReport report, String period) async {
    final doc = pw.Document();
    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _headerRow('Cash Flow Statement', period),
          _summaryRow('Opening Balance', _fmt(report.openingBalance)),
          pw.SizedBox(height: 8),
          pw.Text('Operating Activities', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          _summaryRow('Cash Inflows (Sales)', _fmt(report.operatingInflows)),
          _summaryRow('Cash Outflows (Expenses)', '(${_fmt(report.operatingOutflows)})'),
          _summaryRow('Net Operating Cash Flow', _fmt(report.netOperating), bold: true),
          pw.Divider(thickness: 2),
          _summaryRow('Closing Balance', _fmt(report.closingBalance), bold: true),
        ],
      ),
    ));
    await Printing.sharePdf(bytes: await doc.save(), filename: 'cash_flow_$period.pdf');
  }

  static String cashFlowCsv(CashFlowReport report, String period) {
    return [
      _csvRow(['Cash Flow Statement — $period', '']),
      _csvRow(['Opening Balance', report.openingBalance.toStringAsFixed(2)]),
      _csvRow(['Cash Inflows', report.operatingInflows.toStringAsFixed(2)]),
      _csvRow(['Cash Outflows', report.operatingOutflows.toStringAsFixed(2)]),
      _csvRow(['Net Cash Flow', report.netOperating.toStringAsFixed(2)]),
      _csvRow(['Closing Balance', report.closingBalance.toStringAsFixed(2)]),
    ].join('\n');
  }

  // ── Balance Sheet ─────────────────────────────────────────────────────────────

  static Future<void> shareBalanceSheetPdf(BalanceSheet report, String date) async {
    final doc = pw.Document();
    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _headerRow('Balance Sheet', date),
          pw.Text('ASSETS', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          _summaryRow('Cash & Equivalents', _fmt(report.cashAndEquivalents)),
          _summaryRow('Accounts Receivable', _fmt(report.accountsReceivable)),
          _summaryRow('Inventory', _fmt(report.inventoryValue)),
          pw.Divider(),
          _summaryRow('TOTAL ASSETS', _fmt(report.totalAssets), bold: true),
          pw.SizedBox(height: 12),
          pw.Text('LIABILITIES', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          _summaryRow('Accounts Payable', _fmt(report.accountsPayable)),
          pw.Divider(),
          _summaryRow('TOTAL LIABILITIES', _fmt(report.totalLiabilities), bold: true),
          pw.SizedBox(height: 12),
          pw.Divider(thickness: 2),
          _summaryRow("OWNER'S EQUITY", _fmt(report.ownersEquity), bold: true),
        ],
      ),
    ));
    await Printing.sharePdf(bytes: await doc.save(), filename: 'balance_sheet_$date.pdf');
  }

  static String balanceSheetCsv(BalanceSheet report) {
    return [
      _csvRow(['ASSETS', '']),
      _csvRow(['Cash & Equivalents', report.cashAndEquivalents.toStringAsFixed(2)]),
      _csvRow(['Accounts Receivable', report.accountsReceivable.toStringAsFixed(2)]),
      _csvRow(['Inventory', report.inventoryValue.toStringAsFixed(2)]),
      _csvRow(['Total Assets', report.totalAssets.toStringAsFixed(2)]),
      _csvRow(['', '']),
      _csvRow(['LIABILITIES', '']),
      _csvRow(['Accounts Payable', report.accountsPayable.toStringAsFixed(2)]),
      _csvRow(['Total Liabilities', report.totalLiabilities.toStringAsFixed(2)]),
      _csvRow(['', '']),
      _csvRow(["Owner's Equity", report.ownersEquity.toStringAsFixed(2)]),
    ].join('\n');
  }

  // ── Inventory Valuation ───────────────────────────────────────────────────────

  static Future<void> shareInventoryPdf(InventoryValuationReport report, String date) async {
    final doc = pw.Document();
    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      build: (ctx) => [
        _headerRow('Inventory Valuation Report', date),
        _summaryRow('Total SKUs', '${report.totalSkus}'),
        _summaryRow('Total Value', _fmt(report.totalValue), bold: true),
        pw.SizedBox(height: 12),
        _tableHeader(['Item', 'SKU', 'Stock', 'Unit Price', 'Total Value']),
        ...report.items.asMap().entries.map((e) => _tableRow([
          e.value.name,
          e.value.sku.isEmpty ? '—' : e.value.sku,
          '${e.value.stock} ${e.value.unit}',
          _fmt(e.value.unitPrice),
          _fmt(e.value.totalValue),
        ], shaded: e.key.isOdd)),
      ],
    ));
    await Printing.sharePdf(bytes: await doc.save(), filename: 'inventory_valuation_$date.pdf');
  }

  static String inventoryCsv(InventoryValuationReport report) {
    final rows = [
      _csvRow(['Name', 'SKU', 'Category', 'Stock', 'Unit', 'Unit Price', 'Total Value']),
      ...report.items.map((i) => _csvRow([
        i.name,
        i.sku,
        i.category,
        i.stock.toStringAsFixed(2),
        i.unit,
        i.unitPrice.toStringAsFixed(2),
        i.totalValue.toStringAsFixed(2),
      ])),
      _csvRow(['', '', '', '', '', 'TOTAL', report.totalValue.toStringAsFixed(2)]),
    ];
    return rows.join('\n');
  }

  // ── Copy CSV to clipboard ─────────────────────────────────────────────────────

  static Future<void> copyToClipboard(String csv) async {
    await Clipboard.setData(ClipboardData(text: csv));
  }
}

// ─── Extension for sorting ────────────────────────────────────────────────────

extension _SortedList<T> on List<T> {
  List<T> sorted(int Function(T a, T b) compare) {
    final copy = [...this];
    copy.sort(compare);
    return copy;
  }
}

String monthLabel(int month) => _monthLabel(month);
String fmtCurrency(double v) => _fmt(v);

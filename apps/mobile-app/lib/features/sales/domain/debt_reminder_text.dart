import '../../debt/domain/models/debt.dart';
import '../data/sales_providers.dart' show parseNumericAmount;

/// Builds the itemized WhatsApp reminder for a receivable debt: every line
/// from the sale that created it (product/service + price), followed by
/// what's actually still owed.
///
/// Money figures come from [debt] rather than the invoice map, because a
/// payment recorded directly on the Debt page (DebtDetailScreen's
/// _RecordPaymentSheet) never touches the originating invoice's own
/// amountPaid — the debt is the one place that stays authoritative for what
/// is actually still owed. [invoice] (an Invoice.toFirestore()-shaped map,
/// or empty when the debt has no linked sale, e.g. a manually added debt)
/// supplies only the line items.
abstract final class DebtReminderText {
  static String build({
    required Debt debt,
    required Map<String, dynamic> invoice,
    required bool isSwahili,
  }) {
    String t(String en, String sw) => isSwahili ? sw : en;
    final buf = StringBuffer();

    buf.writeln(t('Dear *${debt.partyName}*,', 'Ndugu *${debt.partyName}*,'));
    buf.writeln();

    final invoiceNumber = ((invoice['invoiceNumber'] ?? '').toString().isNotEmpty
        ? invoice['invoiceNumber']
        : debt.invoiceRef)
        .toString();
    if (invoiceNumber.isNotEmpty) {
      buf.writeln('${t('Invoice', 'Ankara')} *$invoiceNumber*');
    }

    final rawItems = invoice['items'] ?? invoice['lineItems'];
    final items = rawItems is List
        ? rawItems.whereType<Map>().toList()
        : const <Map>[];
    if (items.isNotEmpty) {
      buf.writeln('━━━━━━━━━━━━━━━━━━━━━');
      for (final item in items) {
        final name = (item['name'] ?? item['productName'] ?? '').toString();
        if (name.isEmpty) continue;
        final rawQty = item['quantity'] ?? item['qty'] ?? 1;
        final qty = rawQty is num
            ? rawQty.toDouble()
            : double.tryParse('$rawQty') ?? 1;
        final qtyStr = qty % 1 == 0
            ? qty.toInt().toString()
            : qty.toStringAsFixed(1);
        final price = parseNumericAmount(item['unitPrice']);
        final lineTotal = parseNumericAmount(item['total'] ?? item['lineTotal']);
        buf.writeln(
          '• $name × $qtyStr @ TZS ${_fmtNum(price)} = *TZS ${_fmtNum(lineTotal)}*',
        );
      }
      buf.writeln('━━━━━━━━━━━━━━━━━━━━━');
    }
    buf.writeln();

    buf.writeln(
      '*${t('Amount Owed:', 'Kiasi Kinachodaiwa:')} TZS ${_fmtNum(debt.remainingAmount)}*',
    );
    if (debt.paidAmount > 0) {
      buf.writeln(
        '${t('Already paid:', 'Tayari umelipa:')} TZS ${_fmtNum(debt.paidAmount)}',
      );
    }
    final daysOver = debt.daysOverdue;
    if (daysOver > 0) {
      buf.writeln(
        t('Overdue by $daysOver days.', 'Imechelewa kwa siku $daysOver.'),
      );
    } else if (debt.dueDate.isNotEmpty) {
      buf.writeln('${t('Due:', 'Mwisho:')} ${_fmtDate(debt.dueDate)}');
    }
    buf.writeln();
    buf.writeln(
      t(
        'Please arrange payment at your earliest convenience. Thank you.',
        'Tafadhali panga malipo haraka iwezekanavyo. Asante.',
      ),
    );
    return buf.toString();
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

  static String _fmtDate(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) return iso;
    return '${d.day} ${_months[d.month - 1]} ${d.year}';
  }
}

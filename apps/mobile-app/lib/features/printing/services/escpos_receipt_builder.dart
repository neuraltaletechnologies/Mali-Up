import 'dart:typed_data';

import '../../sales/services/receipt_data.dart';
import '../domain/printer_settings.dart';

/// Lays out a receipt as raw ESC/POS text for 58mm/80mm thermal printers.
///
/// Text mode (not a rasterised PDF) on purpose: it prints in a fraction of
/// a second over Bluetooth, stays sharp on cheap print heads, and works on
/// every ESC/POS clone. Content mirrors [ReceiptPdfService] via the shared
/// [ReceiptData].
abstract final class EscPosReceiptBuilder {
  static Uint8List build({
    required ReceiptData receipt,
    required String businessName,
    required String printedBy,
    required ReceiptPaperWidth paperWidth,
    String businessPhone = '',
    String businessEmail = '',
    String businessAddress = '',
  }) {
    final r = receipt;
    final t = r.t;
    final w = EscPosWriter(paperWidth.charsPerLine)..init();

    // ── Header ──────────────────────────────────────────────
    w
      ..align(EscPosAlign.center)
      ..bold(true)
      ..size(tall: true)
      ..wrapped(
        businessName.isEmpty || businessName == 'Business'
            ? t('Business', 'Biashara')
            : businessName,
      )
      ..size()
      ..bold(false);
    for (final value in [businessAddress, businessPhone, businessEmail]) {
      if (value.trim().isNotEmpty) w.wrapped(value.trim());
    }
    w
      ..line()
      ..bold(true)
      ..line(r.documentTitle)
      ..bold(false)
      ..line('${t("No.", "Namba")} ${r.invoiceNumber}')
      ..align(EscPosAlign.left)
      ..rule();

    // ── Customer & dates ────────────────────────────────────
    w.labelled(t('Customer', 'Mteja'), r.customer);
    if (r.customerPhone.isNotEmpty) w.labelled(t('Phone', 'Simu'), r.customerPhone);
    if (r.createdAt != null) {
      w.labelled(t('Date', 'Tarehe'), ReceiptFormat.dateTime(r.createdAt!));
    }
    if (r.dueDate != null && !r.isQuotation) {
      w.labelled(t('Due', 'Mwisho'), ReceiptFormat.date(r.dueDate!));
    }
    w.rule();

    // ── Items (amounts in TZS, currency shown on the totals) ─
    for (final item in r.printableLines) {
      w
        ..bold(true)
        ..wrapped(item.name)
        ..bold(false)
        ..columns(
          '  ${ReceiptFormat.quantity(item.quantity)} x '
              '${ReceiptFormat.number(item.unitPrice)}',
          ReceiptFormat.number(item.total),
        );
    }
    w
      ..rule()
      // ── Totals ────────────────────────────────────────────
      ..columns(t('Subtotal', 'Jumla ndogo'), ReceiptFormat.money(r.subtotal));
    if (r.discount > 0) {
      w.columns(t('Discount', 'Punguzo'), ReceiptFormat.money(-r.discount));
    }
    if (r.vat > 0) w.columns('VAT (18%)', ReceiptFormat.money(r.vat));
    w
      ..bold(true)
      ..size(tall: true)
      ..columns(t('TOTAL', 'JUMLA KUU'), ReceiptFormat.money(r.amount))
      ..size()
      ..bold(false);
    if (!r.isQuotation) {
      w.columns(t('Paid', 'Imelipwa'), ReceiptFormat.money(r.amountPaid));
      if (r.balance > 0) {
        w
          ..bold(true)
          ..columns(t('Balance due', 'Baki'), ReceiptFormat.money(r.balance))
          ..bold(false);
      }
    }

    // ── Payment & notes ─────────────────────────────────────
    if (!r.isQuotation && r.paymentMethod.isNotEmpty) {
      w
        ..rule()
        ..labelled(t('Payment', 'Malipo'), r.paymentMethod);
      if (r.paymentReference.isNotEmpty) {
        w.labelled(t('Ref', 'Kumb'), r.paymentReference);
      }
    }
    if (r.notes.isNotEmpty) {
      w
        ..rule()
        ..wrapped(r.notes);
    }

    // ── Footer ──────────────────────────────────────────────
    final recordedBy = printedBy.isEmpty || printedBy == 'User'
        ? t('User', 'Mtumiaji')
        : printedBy;
    w
      ..rule()
      ..align(EscPosAlign.center)
      ..line(t('Thank you for your business!', 'Asante kwa kutuamini!'))
      ..wrapped('${t("Recorded by", "Imerekodiwa na")} $recordedBy')
      ..line('${t("Powered by", "Imetengenezwa na")} Mali Up')
      ..finish();
    return w.bytes;
  }

  /// A short page to check the printer, paper width and alignment.
  static Uint8List testPage({
    required ReceiptPaperWidth paperWidth,
    required bool isSwahili,
  }) {
    String t(String en, String sw) => isSwahili ? sw : en;
    final width = paperWidth.charsPerLine;
    final w = EscPosWriter(width)
      ..init()
      ..align(EscPosAlign.center)
      ..bold(true)
      ..size(tall: true)
      ..line('Mali Up')
      ..size()
      ..line(t('Printer test', 'Jaribio la printa'))
      ..bold(false)
      ..line('${paperWidth.mm}mm · $width ${t("characters", "herufi")}')
      ..align(EscPosAlign.left)
      ..rule()
      ..line(List.generate(width, (i) => '${(i + 1) % 10}').join())
      ..rule()
      ..columns(t('Left', 'Kushoto'), t('Right', 'Kulia'))
      ..bold(true)
      ..size(tall: true)
      ..columns(t('TOTAL', 'JUMLA KUU'), ReceiptFormat.money(12500))
      ..size()
      ..bold(false)
      ..rule()
      ..align(EscPosAlign.center)
      ..wrapped(
        t(
          'If the numbers above fill one line exactly, the paper width is right.',
          'Kama namba hapo juu zinajaza mstari mmoja kamili, upana wa karatasi uko sahihi.',
        ),
      )
      ..finish();
    return w.bytes;
  }
}

enum EscPosAlign { left, center, right }

/// Tiny ESC/POS command writer. Text is folded to plain ASCII — the one
/// character set every clone printer agrees on (Kiswahili needs nothing
/// beyond it).
class EscPosWriter {
  EscPosWriter(this.width);

  /// Characters per line at normal width.
  final int width;
  final _out = BytesBuilder(copy: false);

  Uint8List get bytes => _out.toBytes();

  void init() => _out.add(const [0x1B, 0x40]); // ESC @

  void align(EscPosAlign a) => _out.add([0x1B, 0x61, a.index]); // ESC a n

  void bold(bool on) => _out.add([0x1B, 0x45, on ? 1 : 0]); // ESC E n

  /// GS ! n. Only double *height* is used for emphasis so the line keeps
  /// its full character width and column layout stays valid.
  void size({bool tall = false}) => _out.add([0x1D, 0x21, tall ? 0x01 : 0]);

  void line([String text = '']) {
    _out.add(encode(text));
    _out.addByte(0x0A);
  }

  void rule() => line('-' * width);

  /// Word-wrapped text across as many lines as needed.
  void wrapped(String text) {
    for (final l in wrap(text, width)) {
      line(l);
    }
  }

  /// `Label: value`, wrapped.
  void labelled(String label, String value) => wrapped('$label: $value');

  /// [left] flush left, [right] flush right on one line; if they don't fit,
  /// [left] wraps and [right] goes right-aligned on its own line.
  void columns(String left, String right) {
    final l = fold(left);
    final r = fold(right);
    if (l.length + 1 + r.length <= width) {
      line(l + ' ' * (width - l.length - r.length) + r);
      return;
    }
    wrapped(l);
    line(r.length >= width ? r : ' ' * (width - r.length) + r);
  }

  /// Feed past the tear bar and cut (printers without a cutter ignore it).
  void finish() {
    _out.add(const [0x1B, 0x64, 4]); // ESC d 4 — feed 4 lines
    _out.add(const [0x1D, 0x56, 0x42, 0x00]); // GS V B 0 — partial cut
  }

  static List<String> wrap(String text, int width) {
    final words = fold(
      text,
    ).split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return const [''];
    final lines = <String>[];
    var current = '';
    for (var word in words) {
      while (word.length > width) {
        if (current.isNotEmpty) {
          lines.add(current);
          current = '';
        }
        lines.add(word.substring(0, width));
        word = word.substring(width);
      }
      if (current.isEmpty) {
        current = word;
      } else if (current.length + 1 + word.length <= width) {
        current = '$current $word';
      } else {
        lines.add(current);
        current = word;
      }
    }
    if (current.isNotEmpty) lines.add(current);
    return lines;
  }

  static const _folds = {
    '’': "'", '‘': "'", '“': '"', '”': '"', '–': '-', '—': '-', '•': '*',
    '·': '-', '×': 'x', '…': '...', ' ': ' ', 'à': 'a', 'á': 'a', 'â': 'a',
    'ä': 'a', 'ã': 'a', 'å': 'a', 'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e',
    'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i', 'ò': 'o', 'ó': 'o', 'ô': 'o',
    'ö': 'o', 'õ': 'o', 'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u', 'ç': 'c',
    'ñ': 'n', 'À': 'A', 'Á': 'A', 'Â': 'A', 'Ä': 'A', 'È': 'E', 'É': 'E',
    'Ê': 'E', 'Í': 'I', 'Ó': 'O', 'Ö': 'O', 'Ú': 'U', 'Ü': 'U', 'Ç': 'C',
    'Ñ': 'N',
  };

  /// Folds to printable ASCII; anything unknown (emoji etc.) becomes `?`.
  static String fold(String text) {
    final sb = StringBuffer();
    for (final ch in text.characters) {
      final mapped = _folds[ch];
      if (mapped != null) {
        sb.write(mapped);
      } else if (ch.length == 1 && ch.codeUnitAt(0) >= 0x20 && ch.codeUnitAt(0) < 0x7F) {
        sb.write(ch);
      } else if (ch == '\n' || ch == '\t') {
        sb.write(' ');
      } else {
        sb.write('?');
      }
    }
    return sb.toString();
  }

  static List<int> encode(String text) => fold(text).codeUnits;
}

extension on String {
  /// Code-unit iteration keeps surrogate pairs (emoji) together enough to
  /// map each to a single `?`.
  Iterable<String> get characters sync* {
    final units = codeUnits;
    for (var i = 0; i < units.length; i++) {
      final u = units[i];
      if (u >= 0xD800 && u <= 0xDBFF && i + 1 < units.length) {
        yield String.fromCharCodes([u, units[++i]]);
      } else {
        yield String.fromCharCode(u);
      }
    }
  }
}

import 'package:uuid/uuid.dart';

/// Creates human-readable invoice references without relying on a short
/// millisecond suffix, which could repeat every ten seconds.
abstract final class InvoiceNumberGenerator {
  static String create({
    bool isQuotation = false,
    DateTime? now,
    String? uniqueId,
  }) {
    final date = now ?? DateTime.now();
    final prefix = isQuotation ? 'QUO' : 'INV';
    final compactId = (uniqueId ?? const Uuid().v4())
        .replaceAll(RegExp('[^A-Za-z0-9]'), '')
        .toUpperCase();
    final suffix = compactId.length >= 8
        ? compactId.substring(0, 8)
        : compactId.padRight(8, '0');
    return '$prefix-${date.year}${date.month.toString().padLeft(2, '0')}-$suffix';
  }
}

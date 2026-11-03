import 'package:flutter/widgets.dart';

/// Layout breakpoints shared by every screen.
///
/// "Wide" is a laptop/desktop window or a tablet held sideways: there the
/// app switches slide-up sheets to a right-hand side panel and the Sales
/// screen to its point-of-sale layout. Phones (and phones in landscape,
/// which are wide but very short) keep the mobile layout.
class Responsive {
  Responsive._();

  static const double wideMinWidth = 840;
  static const double wideMinHeight = 500;

  static bool isWide(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return size.width >= wideMinWidth && size.height >= wideMinHeight;
  }
}

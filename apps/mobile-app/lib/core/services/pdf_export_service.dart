import 'dart:io';
import 'dart:typed_data';

import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

/// Hands a generated PDF to the user via the OS "Open with" chooser instead
/// of silently saving it into a fixed app folder.
///
/// The file is written to the app's temporary directory (cleared by the OS
/// on its own schedule) purely so a viewer app has something to open — it is
/// not a destination the user is expected to browse to.
abstract final class PdfExportService {
  static Future<void> openPdf(Uint8List bytes, String filename) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes, flush: true);
    final result = await OpenFilex.open(file.path);
    if (result.type != ResultType.done) {
      throw Exception(
        'Could not open PDF (${result.type}): ${result.message}',
      );
    }
  }
}

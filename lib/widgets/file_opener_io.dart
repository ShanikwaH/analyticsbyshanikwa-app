import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

/// Mobile / desktop: copy the bundled asset to a temp file and hand it to the
/// OS, so Excel, Sheets or the browser opens it. Throws if nothing can.
Future<void> openBundled(String fileName) async {
  final data = await rootBundle.load('assets/freebies/$fileName');
  final dir = await getTemporaryDirectory();
  final f = File('${dir.path}/$fileName');
  await f.writeAsBytes(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
  final result = await OpenFilex.open(f.path);
  if (result.type != ResultType.done) {
    throw Exception('no handler: ${result.type}');
  }
}

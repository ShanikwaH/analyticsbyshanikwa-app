import 'package:url_launcher/url_launcher.dart';

/// Web: there is no temp directory and no OS file handler. But Flutter already
/// serves bundled assets from the app's own origin, so the browser can just
/// open the file directly — .html renders in a tab, .xlsx downloads.
///
/// Flutter web publishes assets under `assets/assets/<declared path>`; the
/// doubled segment is correct, not a typo.
Future<void> openBundled(String fileName) async {
  final uri = Uri.base.resolve('assets/assets/freebies/$fileName');
  final ok = await launchUrl(uri, webOnlyWindowName: '_blank');
  if (!ok) {
    throw Exception('browser blocked opening $fileName');
  }
}

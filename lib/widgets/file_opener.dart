library;

/// Opening a bundled freebie works differently per platform, and the mobile
/// path cannot even be COMPILED for web — `dart:io` does not exist there, so a
/// single shared implementation breaks `flutter build web` outright.
///
/// This picks the right one at compile time: the dart:io version wherever
/// dart:io exists (Android, iOS, Windows, macOS), the browser version on web.
export 'file_opener_web.dart' if (dart.library.io) 'file_opener_io.dart';

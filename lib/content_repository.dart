import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

/// Loads content in three layers:
///   1. Bundled asset (always works, offline-safe).
///   2. Cached remote copy from a previous run (if newer than bundled).
///   3. Live remote file at <site>/app/content.json (if newer than both).
///
/// Upload an edited content.json to analyticsbyshanikwa.com/app/content.json
/// with a bumped "version" number and every installed app updates itself on
/// next launch — no store re-release needed.
class ContentRepository {
  static const _cacheKey = 'cached_content_json';

  Future<AppContent> loadInitial() async {
    final bundled = await _loadBundled();
    final cached = await _loadCached();
    if (cached != null && cached.version > bundled.version) return cached;
    return bundled;
  }

  Future<AppContent> _loadBundled() async {
    final raw = await rootBundle.loadString('assets/content/content.json');
    return AppContent.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<AppContent?> _loadCached() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw == null) return null;
      return AppContent.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null; // Corrupt cache never blocks launch.
    }
  }

  /// Returns updated content if the remote file is newer, else null.
  /// All failures are silent — the app keeps working offline.
  Future<AppContent?> checkRemote(AppContent current) async {
    try {
      final uri = Uri.parse(current.url('remote_content'));
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;
      final json = jsonDecode(utf8.decode(res.bodyBytes));
      if (json is! Map<String, dynamic>) return null;
      final remote = AppContent.fromJson(json);
      if (remote.version <= current.version || remote.stories.isEmpty) {
        return null; // Never downgrade or accept an empty/broken payload.
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, utf8.decode(res.bodyBytes));
      return remote;
    } catch (_) {
      return null;
    }
  }
}

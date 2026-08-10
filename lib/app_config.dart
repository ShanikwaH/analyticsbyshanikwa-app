import 'package:flutter/material.dart';

/// Which niche this build targets. Set at build time:
///   flutter build <platform> --dart-define=APP_NICHE=full|accounting|data|bible
/// Defaults to the all-in-one app.
enum AppNiche { full, accounting, data, bible }

class AppConfig {
  static const String _nicheRaw =
      String.fromEnvironment('APP_NICHE', defaultValue: 'full');

  static AppNiche get niche {
    switch (_nicheRaw) {
      case 'accounting':
        return AppNiche.accounting;
      case 'data':
        return AppNiche.data;
      case 'bible':
        return AppNiche.bible;
      default:
        return AppNiche.full;
    }
  }

  static bool get isFull => niche == AppNiche.full;

  /// Sibling-brand app names.
  static String get appName {
    switch (niche) {
      case AppNiche.accounting:
        return 'Balanced Books';
      case AppNiche.data:
        return 'Analytics by Shanikwa';
      case AppNiche.bible:
        return 'Faithful Tales';
      case AppNiche.full:
        return 'Analytics by Shanikwa';
    }
  }

  static String get tagline {
    switch (niche) {
      case AppNiche.accounting:
        return 'ACCOUNTING · CPA · STEWARDSHIP';
      case AppNiche.data:
        return 'DATA · CAREER · SKILLS';
      case AppNiche.bible:
        return 'BIBLE STORIES · FAITH · TRUTH';
      case AppNiche.full:
        return 'DATA · FAITH · FINANCE';
    }
  }

  // ---- Brand tokens (two-track palette; never mixed on one surface) ----
  // Web track — full / accounting / data builds.
  static const Color signalBlue = Color(0xFF3B82F6);
  static const Color insightGreen = Color(0xFF10B981);
  static const Color deepNavy = Color(0xFF0F172A);
  static const Color paperWhite = Color(0xFFF8FAFC);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate700 = Color(0xFF334155);

  // Social track — bible build.
  static const Color signaturePurple = Color(0xFF7B6FB8);
  static const Color softLavender = Color(0xFFB591D4);
  static const Color royalPlum = Color(0xFF5B3A9E);
  static const Color goldAccent = Color(0xFFD4A845);

  static bool get isSocialTrack => niche == AppNiche.bible;

  static Color get primary => isSocialTrack ? signaturePurple : signalBlue;
  static Color get secondary => isSocialTrack ? goldAccent : insightGreen;
  static Color get anchor => isSocialTrack ? royalPlum : deepNavy;

  static LinearGradient get heroGradient => isSocialTrack
      // Approved gradient 5 — Social Purple.
      ? const LinearGradient(colors: [signaturePurple, softLavender])
      // Approved gradient 1 — Primary hero.
      : const LinearGradient(colors: [signalBlue, insightGreen]);

  /// Which bottom-nav sections this build shows.
  /// full: Today, Stories, Play, Shop
  /// bible: Today, Stories, Play, Shop
  /// accounting: Today, Play, Shop, Resources
  /// data: Today, Play, Shop, Resources
  static List<String> get sections {
    switch (niche) {
      case AppNiche.bible:
        return ['today', 'stories', 'play', 'shop'];
      case AppNiche.accounting:
        return ['today', 'play', 'shop', 'resources'];
      case AppNiche.data:
        return ['today', 'play', 'shop', 'resources'];
      case AppNiche.full:
        return ['today', 'stories', 'play', 'shop'];
    }
  }
}

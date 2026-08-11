import 'dart:ui' show PlatformDispatcher;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform, visibleForTesting;
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

  // Read from the live site's styles/tokens.css so the app and the website
  // cannot drift apart. --electric-pink was the one brand token the app lacked.
  static const Color electricPink = Color(0xFFE879C9);
  // --grad-indigo-plum: the site's signature accent, used on "Faithful with
  // truth." in the hero and on its plum buttons.
  static const Color indigo = Color(0xFF667EEA);
  static const Color plum = Color(0xFF764BA2);

  /// The site's own gradients, matched exactly.
  static const LinearGradient gradIndigoPlum = LinearGradient(
      begin: Alignment.topLeft, end: Alignment.bottomRight,
      colors: [indigo, plum]);
  static const LinearGradient gradSocialPurple =
      LinearGradient(colors: [signaturePurple, softLavender]);
  static const LinearGradient gradPrimaryHero =
      LinearGradient(colors: [signalBlue, insightGreen]);

  /// The brand orb — the same circular logo the website shows in its header.
  static const String logoOrb = 'assets/brand/logo_orb.png';

  /// May this build show links that leave the app to buy digital goods?
  ///
  /// App Store Guideline 3.1.1 and Google Play's equivalent still forbid this
  /// in most countries. It is permitted on the US storefront (Epic injunction,
  /// no commission) and in Japan (Mobile Software Competition Act, 15% steering
  /// commission). Elsewhere the Shop is hidden so the app can still be listed
  /// there without breaking the rules.
  ///
  /// The allowed list lives in content.json, so it can be changed remotely when
  /// the rules move again — no app release, no store review.
  ///
  /// Caveat: this reads the DEVICE region, which is not strictly the App Store
  /// storefront. It fails closed — an unknown region hides the Shop rather than
  /// risking a violation.
  static bool canLinkOut(List<String> allowedRegions) {
    if (kIsWeb) return true; // store rules do not apply to the web build
    if (!_regionGateApplies) return true;
    if (allowedRegions.isEmpty) return true; // nothing configured
    final region =
        PlatformDispatcher.instance.locale.countryCode?.toUpperCase();
    if (region == null || region.isEmpty) return false; // fail closed
    return allowedRegions.contains(region);
  }

  /// Anti-steering rules are an **iOS and Android** phenomenon: Apple's
  /// Guideline 3.1.1 and Google Play's payments policy. The Microsoft Store
  /// imposes no such restriction, and a directly-distributed desktop build
  /// answers to no store at all.
  ///
  /// Without this, a Windows user in the UK would see no Shop — the gate would
  /// silently hide the storefront to satisfy a rule that does not apply to
  /// them.
  static bool get _regionGateApplies =>
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.android;

  /// Exposed so tests can assert the desktop carve-out without faking a store.
  @visibleForTesting
  static bool get regionGateAppliesForTest => _regionGateApplies;

  static bool get isSocialTrack => niche == AppNiche.bible;

  static Color get primary => isSocialTrack ? signaturePurple : signalBlue;
  static Color get secondary => isSocialTrack ? goldAccent : insightGreen;
  static Color get anchor => isSocialTrack ? royalPlum : deepNavy;

  static LinearGradient get heroGradient => isSocialTrack
      // Approved gradient 5 — Social Purple.
      ? gradSocialPurple
      // The website's signature accent (--grad-indigo-plum). Previously
      // blue->green, which appears nowhere on analyticsbyshanikwa.com and
      // clashed with the purple brand orb.
      : gradIndigoPlum;

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

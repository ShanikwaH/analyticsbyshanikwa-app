import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_config.dart';
import 'app_state.dart';
import 'commerce/purchases.dart';
import 'content_repository.dart';
import 'models.dart';
import 'screens/home_shell.dart';
import 'widgets/common.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AbsApp());
}

/// Simple inherited scope so any screen can reach content + talents state
/// without an external state-management dependency.
class AppScope extends InheritedNotifier<TalentsState> {
  final AppContent content;
  const AppScope({
    super.key,
    required this.content,
    required TalentsState talents,
    required super.child,
  }) : super(notifier: talents);

  static AppScope of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!;

  TalentsState get talents => notifier!;
}

/// Provides the in-app purchase state. Separate from AppScope so screens that
/// never sell anything do not rebuild when a purchase completes.
class PurchasesScope extends InheritedNotifier<Purchases> {
  const PurchasesScope({super.key, required Purchases purchases, required super.child})
      : super(notifier: purchases);

  static Purchases of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PurchasesScope>()!.notifier!;
}

class AbsApp extends StatefulWidget {
  const AbsApp({super.key});
  @override
  State<AbsApp> createState() => _AbsAppState();
}

class _AbsAppState extends State<AbsApp> {
  final _repo = ContentRepository();
  final _talents = TalentsState();
  final _purchases = Purchases();
  AppContent? _content;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    await _talents.load();
    final initial = await _repo.loadInitial();
    if (mounted) setState(() => _content = initial);
    // Ask the store about our products. No-ops on web and wherever the app
    // links out instead of selling in-app.
    unawaited(_purchases
        .init([for (final p in initial.products) p.iapId]));
    // Silent background check for a newer remote content file.
    final updated = await _repo.checkRemote(initial);
    if (updated != null && mounted) setState(() => _content = updated);
  }

  ThemeData _theme() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppConfig.primary,
      primary: AppConfig.primary,
      secondary: AppConfig.secondary,
    );
    final base = ThemeData(colorScheme: scheme, useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppConfig.paperWhite,
      textTheme: GoogleFonts.interTextTheme(base.textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: AppConfig.paperWhite,
        foregroundColor: AppConfig.deepNavy,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: AppConfig.deepNavy,
        ),
      ),
      cardTheme: const CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          side: BorderSide(color: AppConfig.slate200),
        ),
        color: Colors.white,
        margin: EdgeInsets.zero,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppConfig.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppConfig.primary,
          side: const BorderSide(color: AppConfig.slate200),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = _content;
    if (content == null) {
      return MaterialApp(
        title: AppConfig.appName,
        debugShowCheckedModeBanner: false,
        theme: _theme(),
        home: const _SplashScreen(),
      );
    }
    // AppScope MUST sit ABOVE MaterialApp. Inside `home:` it lives below the
    // Navigator, so every route pushed with Navigator.push is a sibling rather
    // than a descendant — AppScope.of() returns null, the `!` throws, and the
    // screen renders blank. That broke all 24 pushed screens (every game, the
    // audit, story details, the vault, free resources).
    return PurchasesScope(
      purchases: _purchases,
      child: AppScope(
      content: content,
      talents: _talents,
      child: MaterialApp(
        title: AppConfig.appName,
        debugShowCheckedModeBanner: false,
        theme: _theme(),
        // The game boards use fixed column counts with square cells, which is
        // right on a phone and absurd on a desktop browser — a 3x3 board became
        // 400px per cell at 1700px wide. Capping the content column keeps every
        // screen phone-shaped on the web without touching 20 game layouts.
        // Applied in `builder` so it covers pushed routes too.
        builder: (context, child) {
          if (child == null) return const SizedBox.shrink();
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: child,
            ),
          );
        },
        home: const HomeShell(),
      ),
    ),
    );
  }

  @override
  void dispose() {
    _purchases.dispose();
    super.dispose();
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BrandOrb(size: 72),
            const SizedBox(height: 20),
            Text(AppConfig.appName,
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(
              AppConfig.tagline,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 3,
                color: AppConfig.slate500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

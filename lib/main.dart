import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_config.dart';
import 'app_state.dart';
import 'content_repository.dart';
import 'models.dart';
import 'screens/home_shell.dart';

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

class AbsApp extends StatefulWidget {
  const AbsApp({super.key});
  @override
  State<AbsApp> createState() => _AbsAppState();
}

class _AbsAppState extends State<AbsApp> {
  final _repo = ContentRepository();
  final _talents = TalentsState();
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
    return AppScope(
      content: content,
      talents: _talents,
      child: MaterialApp(
        title: AppConfig.appName,
        debugShowCheckedModeBanner: false,
        theme: _theme(),
        home: const HomeShell(),
      ),
    );
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
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: AppConfig.heroGradient,
                shape: BoxShape.circle,
              ),
            ),
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

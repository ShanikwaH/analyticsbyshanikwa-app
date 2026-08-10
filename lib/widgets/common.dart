import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_config.dart';
import '../main.dart';
import 'file_opener.dart';

/// Opens a URL in an in-app browser view (SFSafariViewController / Custom
/// Tabs) so shoppers stay "inside" the app; falls back to the platform
/// default (desktop browsers on Windows/macOS).
Future<void> openLink(BuildContext context, String url) async {
  if (url.isEmpty) return;
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  try {
    final ok = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    if (!ok) await launchUrl(uri, mode: LaunchMode.platformDefault);
  } catch (_) {
    try {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open link.')),
        );
      }
    }
  }
}

/// Montserrat-style eyebrow: uppercase, wide tracking.
class Eyebrow extends StatelessWidget {
  final String text;
  const Eyebrow(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 2.6,
          color: AppConfig.slate500,
        ),
      );
}

/// Live Talents counter chip shown in every app bar.
class TalentsChip extends StatelessWidget {
  const TalentsChip({super.key});
  @override
  Widget build(BuildContext context) {
    final t = AppScope.of(context).talents;
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: AppConfig.heroGradient,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.toll_outlined, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text('${t.talents}',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

void showTalentsEarned(BuildContext context, int earned, {String? note}) {
  if (earned <= 0) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppConfig.anchor,
      content: Text(
        '+$earned Talents${note == null ? '' : ' — $note'}',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      duration: const Duration(seconds: 2),
    ),
  );
}

/// Opens a bundled freebie with a guaranteed fallback. Primary path: copy the
/// asset to a temp file and hand it to the OS (Excel/Sheets/browser). If no
/// app on the device can open it — or anything else goes wrong — fall back to
/// the site's free-resources page, where the same file is delivered by email
/// via the Omnisend-powered list. Nobody ever hits a dead end.
Future<void> openBundledFile(BuildContext context, dynamic bundled) async {
  final scope = AppScope.of(context);
  final fallbackUrl = scope.content.url('free_resources');
  try {
    // Platform-specific: temp file + OS handler on mobile/desktop, direct
    // asset URL on web. See file_opener.dart.
    await openBundled(bundled.file as String);
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      behavior: SnackBarBehavior.floating,
      content: Text(
          'No app on this device opens that file — sending you to the free-resources page instead. Enter your email and it lands in your inbox.'),
      duration: Duration(seconds: 3),
    ));
    openLink(context, fallbackUrl);
  }
}

/// Checks and toasts any newly earned badges (+25 each). Call after any
/// Talents-earning action.
void claimBadges(BuildContext context) {
  final scope = AppScope.of(context);
  final sizes = {
    for (final e in scope.content.quizzes.entries) e.key: e.value.length
  };
  for (final title in scope.talents.claimNewBadges(sizes)) {
    showTalentsEarned(context, 25, note: 'Badge unlocked: $title');
  }
}

class SectionCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  const SectionCard({super.key, required this.child, this.onTap});
  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(padding: const EdgeInsets.all(20), child: child),
      ),
    );
  }
}

class PillTag extends StatelessWidget {
  final String text;
  final Color? bg;
  final Color? fg;
  const PillTag(this.text, {super.key, this.bg, this.fg});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          // ignore: deprecated_member_use
          color: bg ?? AppConfig.primary.withOpacity(0.10),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(text,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: fg ?? AppConfig.primary)),
      );
}

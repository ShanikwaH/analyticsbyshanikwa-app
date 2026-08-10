import 'package:flutter/material.dart';

import '../app_config.dart';
import '../main.dart';
import '../widgets/common.dart';
import 'audit_screen.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final c = scope.content;
    final t = scope.talents;
    final week = c.thisWeek;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppConfig.appName),
        actions: const [TalentsChip()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ---- Hero: this week's letter ----
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: AppConfig.heroGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('THIS WEEK · ${week.readTime}'.toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        letterSpacing: 2.4,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                Text(week.title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        height: 1.15,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                Text('"${week.verse}" — ${week.reference}',
                    style: const TextStyle(
                        color: Colors.white, fontStyle: FontStyle.italic)),
                const SizedBox(height: 12),
                Text(week.summary,
                    style: const TextStyle(color: Colors.white, height: 1.5)),
                const SizedBox(height: 16),
                FilledButton(
                  style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppConfig.anchor),
                  onPressed: () => openLink(context, week.url),
                  child: const Text('Read this week\'s letter'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ---- Daily Stewardship Audit ----
          SectionCard(
            onTap: t.auditDoneToday
                ? null
                : () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AuditScreen())),
            child: Row(
              children: [
                Icon(
                  t.auditDoneToday
                      ? Icons.check_circle
                      : Icons.fact_check_outlined,
                  color:
                      t.auditDoneToday ? AppConfig.secondary : AppConfig.primary,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.auditDoneToday
                            ? 'Today\'s Stewardship Audit — done'
                            : 'Run today\'s Stewardship Audit',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        t.auditDoneToday
                            ? 'Streak: ${t.auditStreak} day${t.auditStreak == 1 ? '' : 's'}. Come back tomorrow.'
                            : 'Four questions. Five minutes. +${20} Talents. Streak: ${t.auditStreak}.',
                        style: const TextStyle(
                            color: AppConfig.slate500, height: 1.4),
                      ),
                    ],
                  ),
                ),
                if (!t.auditDoneToday)
                  const Icon(Icons.chevron_right, color: AppConfig.slate500),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ---- Rank progress ----
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Eyebrow('Steward rank'),
                const SizedBox(height: 8),
                Text(t.rank,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                if (t.nextRankAt != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: (t.talents / t.nextRankAt!).clamp(0.0, 1.0),
                      minHeight: 8,
                      backgroundColor: AppConfig.slate200,
                      color: AppConfig.secondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('${t.talents} / ${t.nextRankAt} Talents to the next rank',
                      style: const TextStyle(
                          color: AppConfig.slate500, fontSize: 13)),
                ] else
                  const Text('Top rank reached. Well done, good and faithful.',
                      style: TextStyle(color: AppConfig.slate500)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ---- Newsletter ----
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Eyebrow('The Sunday letter'),
                const SizedBox(height: 8),
                const Text(
                  'One Bible story. One dataset. One question for Monday.',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Free, every Sunday at 5:00 am ET. No spam. No upsells. Unsubscribe in one click.',
                  style: TextStyle(color: AppConfig.slate500, height: 1.5),
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  icon: const Icon(Icons.mail_outline),
                  onPressed: () => openLink(context, c.url('newsletter')),
                  label: const Text('Join the letter'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ---- Three disciplines footer ----
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Numbers tie. Sources cite. Promises ship.',
                style: TextStyle(
                    color: AppConfig.slate500,
                    fontStyle: FontStyle.italic,
                    fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

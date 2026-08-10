import 'package:flutter/material.dart';

import '../app_config.dart';
import '../app_state.dart';
import '../main.dart';
import '../widgets/common.dart';

/// The badge gallery. Ten achievements, +25 Talents each. Locked badges show
/// exactly what to do — the whole screen is a to-do list disguised as a
/// trophy case.
class BadgesScreen extends StatelessWidget {
  const BadgesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppScope.of(context).talents;
    final earned = t.badges;

    return Scaffold(
      appBar: AppBar(
          title: const Text("Steward's Badges"),
          actions: const [TalentsChip()]),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            '${earned.length} of ${TalentsState.badgeDefs.length} earned · +25 Talents each',
            style: const TextStyle(
                color: AppConfig.slate500, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 14),
          for (final def in TalentsState.badgeDefs)
            _BadgeTile(
              emoji: def.$2,
              title: def.$3,
              description: def.$4,
              unlocked: earned.contains(def.$1),
            ),
        ],
      ),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  final String emoji, title, description;
  final bool unlocked;
  const _BadgeTile(
      {required this.emoji,
      required this.title,
      required this.description,
      required this.unlocked});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Opacity(
        opacity: unlocked ? 1 : 0.55,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: unlocked ? AppConfig.heroGradient : null,
                    color: unlocked ? null : AppConfig.slate200,
                    shape: BoxShape.circle,
                  ),
                  child: Text(unlocked ? emoji : '🔒',
                      style: const TextStyle(fontSize: 24)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 15.5)),
                      const SizedBox(height: 3),
                      Text(description,
                          style: const TextStyle(
                              color: AppConfig.slate500,
                              fontSize: 13,
                              height: 1.4)),
                    ],
                  ),
                ),
                if (unlocked)
                  const Text('+25',
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppConfig.insightGreen)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

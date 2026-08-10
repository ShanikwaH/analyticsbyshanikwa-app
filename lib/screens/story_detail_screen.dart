import 'package:flutter/material.dart';

import '../app_config.dart';
import '../main.dart';
import '../models.dart';
import '../widgets/common.dart';

class StoryDetailScreen extends StatelessWidget {
  final Story story;
  const StoryDetailScreen({super.key, required this.story});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final t = scope.talents;
    final read = t.readStories.contains(story.id);

    // Cross-sell: Bible-niche products fit every story surface.
    final related = scope.content.products
        .where((p) => p.niche == 'bible')
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text(story.series), actions: const [TalentsChip()]),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(children: [
            PillTag(story.theme),
            const SizedBox(width: 8),
            Text(story.reference,
                style:
                    const TextStyle(color: AppConfig.slate500, fontSize: 13)),
          ]),
          const SizedBox(height: 12),
          Text(story.title,
              style: const TextStyle(
                  fontSize: 26, fontWeight: FontWeight.w800, height: 1.1)),
          const SizedBox(height: 8),
          Text(story.tagline,
              style: const TextStyle(
                  color: AppConfig.slate500, fontStyle: FontStyle.italic)),
          const SizedBox(height: 16),
          Text(story.summary,
              style: const TextStyle(fontSize: 16, height: 1.6)),
          const SizedBox(height: 20),
          FilledButton.icon(
            icon: Icon(read ? Icons.check_circle : Icons.auto_stories_outlined),
            onPressed: read
                ? null
                : () {
                    final earned = t.markStoryRead(story.id);
                    showTalentsEarned(context, earned, note: 'story read');
                    claimBadges(context);
                  },
            label: Text(read ? 'Read — Talents earned' : 'Mark as read (+5 Talents)'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            icon: const Icon(Icons.open_in_new),
            onPressed: () => openLink(context, story.url),
            label: const Text('Read the full article'),
          ),
          const SizedBox(height: 28),
          if (related.isNotEmpty) ...[
            const Eyebrow('Go deeper'),
            const SizedBox(height: 10),
            for (final p in related)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SectionCard(
                  onTap: () => openLink(context, p.payhipUrl),
                  child: Row(
                    children: [
                      Text(p.emoji, style: const TextStyle(fontSize: 26)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(height: 2),
                            Text(p.price,
                                style: const TextStyle(
                                    color: AppConfig.slate500, fontSize: 13)),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right,
                          color: AppConfig.slate500),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

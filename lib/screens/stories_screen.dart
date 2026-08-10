import 'package:flutter/material.dart';

import '../app_config.dart';
import '../main.dart';
import '../models.dart';
import '../widgets/common.dart';
import 'story_detail_screen.dart';

class StoriesScreen extends StatefulWidget {
  const StoriesScreen({super.key});
  @override
  State<StoriesScreen> createState() => _StoriesScreenState();
}

class _StoriesScreenState extends State<StoriesScreen> {
  String _series = 'All';

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final t = scope.talents;
    final all = scope.content.stories;
    final seriesNames = ['All', ...{for (final s in all) s.series}];
    final stories = _series == 'All'
        ? all
        : all.where((s) => s.series == _series).toList();
    final readCount = all.where((s) => t.readStories.contains(s.id)).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bible Stories'),
        actions: const [TalentsChip()],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '$readCount of ${all.length} stories read',
                    style: const TextStyle(
                        color: AppConfig.slate500,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                Text('+${TalentsStateRewards.read} each',
                    style: const TextStyle(
                        color: AppConfig.slate500, fontSize: 12)),
              ],
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                for (final name in seriesNames)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(name),
                      selected: _series == name,
                      onSelected: (_) => setState(() => _series = name),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: stories.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) => _StoryCard(story: stories[i]),
            ),
          ),
        ],
      ),
    );
  }
}

/// Local mirror of reward constants for display copy.
class TalentsStateRewards {
  static const read = 5;
}

class _StoryCard extends StatelessWidget {
  final Story story;
  const _StoryCard({required this.story});

  @override
  Widget build(BuildContext context) {
    final read =
        AppScope.of(context).talents.readStories.contains(story.id);
    return SectionCard(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => StoryDetailScreen(story: story)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PillTag(story.theme),
              const SizedBox(width: 8),
              Expanded(
                child: Text(story.reference,
                    style: const TextStyle(
                        color: AppConfig.slate500, fontSize: 12)),
              ),
              if (read)
                const Icon(Icons.check_circle,
                    size: 18, color: AppConfig.insightGreen),
            ],
          ),
          const SizedBox(height: 10),
          Text(story.title,
              style:
                  const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
            story.summary,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppConfig.slate700, height: 1.5),
          ),
        ],
      ),
    );
  }
}

import 'dart:math';

import 'package:flutter/material.dart';

import '../app_config.dart';
import '../main.dart';
import '../models.dart';
import '../widgets/common.dart';

/// Story Match: six stories, twelve cards — match each story title to its
/// scripture reference. +15 Talents on completion (first win each day).
/// Sneaky catechism: after a few rounds the references stick.
class MatchGameScreen extends StatefulWidget {
  const MatchGameScreen({super.key});
  @override
  State<MatchGameScreen> createState() => _MatchGameScreenState();
}

class _MatchCard {
  final String storyId;
  final String label;
  final bool isTitle;
  bool matched = false;
  _MatchCard(this.storyId, this.label, this.isTitle);
}

class _MatchGameScreenState extends State<MatchGameScreen> {
  List<_MatchCard> _cards = [];
  int? _selected;
  int _attempts = 0;
  bool _done = false;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _setup();
    }
  }

  void _setup() {
    final stories =
        List<Story>.from(AppScope.of(context).content.stories)..shuffle(Random());
    final picks = stories.take(6).toList();
    final cards = <_MatchCard>[
      for (final s in picks) _MatchCard(s.id, _shortTitle(s.title), true),
      for (final s in picks) _MatchCard(s.id, s.reference, false),
    ]..shuffle(Random());
    setState(() {
      _cards = cards;
      _selected = null;
      _attempts = 0;
      _done = false;
    });
  }

  static String _shortTitle(String t) =>
      t.length <= 42 ? t : '${t.substring(0, 39)}…';

  void _tap(int i) {
    if (_done || _cards[i].matched) return;
    if (_selected == null) {
      setState(() => _selected = i);
      return;
    }
    if (_selected == i) {
      setState(() => _selected = null);
      return;
    }
    final a = _cards[_selected!], b = _cards[i];
    _attempts++;
    if (a.storyId == b.storyId && a.isTitle != b.isTitle) {
      setState(() {
        a.matched = true;
        b.matched = true;
        _selected = null;
      });
      if (_cards.every((c) => c.matched)) {
        _done = true;
        final t = AppScope.of(context).talents;
        final earned = t.finishMatch();
        showTalentsEarned(context, earned, note: 'Story Match');
        final decks = AppScope.of(context).content.quizzes;
        final sizes = {for (final e in decks.entries) e.key: e.value.length};
        for (final badge in t.claimNewBadges(sizes)) {
          showTalentsEarned(context, 25, note: 'Badge: $badge');
        }
        setState(() {});
      }
    } else {
      setState(() => _selected = i);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppScope.of(context).talents;
    return Scaffold(
      appBar: AppBar(
          title: const Text('Story Match'), actions: const [TalentsChip()]),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            _done
                ? '✓ All matched in $_attempts attempts.'
                : 'Match each story to its scripture reference. ${t.matchRewardAvailable ? "+15 Talents on completion." : "Today's payout claimed — play for practice."}',
            style: const TextStyle(
                color: AppConfig.slate700, height: 1.5, fontSize: 14),
          ),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.55,
            ),
            itemCount: _cards.length,
            itemBuilder: (context, i) {
              final c = _cards[i];
              final selected = _selected == i;
              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _tap(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.all(10),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: c.matched
                        ? AppConfig.secondary
                        : selected
                            ? AppConfig.primary
                            : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: c.matched || selected
                            ? Colors.transparent
                            : AppConfig.slate200),
                  ),
                  child: Text(
                    c.label,
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: c.isTitle ? 12 : 13.5,
                      fontWeight:
                          c.isTitle ? FontWeight.w600 : FontWeight.w800,
                      color: c.matched || selected
                          ? Colors.white
                          : AppConfig.deepNavy,
                      height: 1.25,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          if (_done)
            FilledButton(
                onPressed: _setup, child: const Text('New round'))
          else
            OutlinedButton(onPressed: _setup, child: const Text('Shuffle')),
        ],
      ),
    );
  }
}

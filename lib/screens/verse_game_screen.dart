import 'dart:math';

import 'package:flutter/material.dart';

import '../app_config.dart';
import '../main.dart';
import '../models.dart';
import '../widgets/common.dart';

/// Scripture Memory Challenge: the verse's words are shuffled; tap them back
/// into order. Rebuild it perfectly and the verse counts as mastered
/// (+15 Talents, first time). The natural upsell is the Scripture Memory
/// System template — surfaced only after a win, never as a nag.
class VerseGameScreen extends StatefulWidget {
  const VerseGameScreen({super.key});
  @override
  State<VerseGameScreen> createState() => _VerseGameScreenState();
}

class _VerseGameScreenState extends State<VerseGameScreen> {
  int _verseIndex = 0;
  List<String> _pool = [];
  List<String> _placed = [];
  bool _won = false;
  bool _slipped = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_pool.isEmpty && _placed.isEmpty && !_won) _setup();
  }

  Verse get _verse => AppScope.of(context).content.verses[_verseIndex];

  void _setup() {
    final words = List<String>.from(_verse.words);
    words.shuffle(Random());
    setState(() {
      _pool = words;
      _placed = [];
      _won = false;
      _slipped = false;
    });
  }

  void _tapWord(int poolIndex) {
    final expected = _verse.words[_placed.length];
    final tapped = _pool[poolIndex];
    if (tapped == expected) {
      setState(() {
        _placed.add(tapped);
        _pool.removeAt(poolIndex);
      });
      if (_placed.length == _verse.words.length) {
        setState(() => _won = true);
        if (!_slipped) {
          final earned =
              AppScope.of(context).talents.markVerseMastered(_verse.id);
          showTalentsEarned(context, earned, note: 'verse mastered');
          claimBadges(context);
        }
      }
    } else {
      // Wrong word: gentle shake-equivalent — flag the slip (no mastery
      // reward this round) but let them keep going.
      setState(() => _slipped = true);
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Not that word next — keep going.'),
        duration: Duration(milliseconds: 900),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final verses = scope.content.verses;
    if (verses.isEmpty) {
      return Scaffold(
          appBar: AppBar(title: const Text('Scripture Memory')),
          body: const Center(child: Text('No verses loaded.')));
    }
    final mastered = scope.talents.masteredVerses.contains(_verse.id);
    final memoryProduct = scope.content.products
        .where((p) => p.title.toLowerCase().contains('scripture memory'))
        .toList();

    return Scaffold(
      appBar: AppBar(
          title: const Text('Scripture Memory'),
          actions: const [TalentsChip()]),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(_verse.reference,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800)),
              ),
              if (mastered)
                const PillTag('Mastered',
                    bg: Color(0x1A10B981), fg: AppConfig.insightGreen),
            ],
          ),
          const SizedBox(height: 6),
          const Text('Tap the words in order to rebuild the verse (KJV).',
              style: TextStyle(color: AppConfig.slate500)),
          const SizedBox(height: 20),

          // Built-so-far area.
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 110),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppConfig.slate200),
            ),
            child: Text(
              _placed.isEmpty ? '…' : _placed.join(' '),
              style: const TextStyle(
                  fontSize: 17, height: 1.6, fontStyle: FontStyle.italic),
            ),
          ),
          const SizedBox(height: 20),

          if (!_won)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < _pool.length; i++)
                  ActionChip(
                    label: Text(_pool[i]),
                    onPressed: () => _tapWord(i),
                  ),
              ],
            )
          else ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppConfig.heroGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _slipped
                        ? 'Rebuilt — run it clean for mastery.'
                        : '✓ Verse mastered.',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 17),
                  ),
                  const SizedBox(height: 6),
                  Text('"${_verse.text}" — ${_verse.reference}',
                      style:
                          const TextStyle(color: Colors.white, height: 1.5)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (memoryProduct.isNotEmpty)
              SectionCard(
                onTap: () =>
                    openLink(context, memoryProduct.first.payhipUrl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Eyebrow('Memorize 30 in 30'),
                    const SizedBox(height: 8),
                    Text(
                      '${memoryProduct.first.emoji}  ${memoryProduct.first.title} — ${memoryProduct.first.price}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Enjoyed this? The full spaced-repetition system with the memory heatmap lives in the template.',
                      style: TextStyle(color: AppConfig.slate700, height: 1.5),
                    ),
                  ],
                ),
              ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              OutlinedButton(
                onPressed: _setup,
                child: const Text('Retry'),
              ),
              const SizedBox(width: 10),
              FilledButton(
                onPressed: () {
                  _verseIndex = (_verseIndex + 1) % verses.length;
                  _setup();
                },
                child: const Text('Next verse'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

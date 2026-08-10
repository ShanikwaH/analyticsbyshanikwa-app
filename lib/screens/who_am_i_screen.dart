import 'package:flutter/material.dart';

import '../app_config.dart';
import '../main.dart';
import '../widgets/common.dart';

/// Who Am I? — ten characters from the actual story catalog, three clues
/// each, revealed one at a time. Guess right for +5 (first time per
/// character). Every character links back to their story.
class WhoAmIScreen extends StatefulWidget {
  const WhoAmIScreen({super.key});
  @override
  State<WhoAmIScreen> createState() => _WhoAmIScreenState();
}

class _WhoAmIScreenState extends State<WhoAmIScreen> {
  int _index = 0;
  int _cluesShown = 1;
  String? _picked;

  void _next() {
    final total = AppScope.of(context).content.whoAmI.length;
    setState(() {
      _index = (_index + 1) % total;
      _cluesShown = 1;
      _picked = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final list = scope.content.whoAmI;
    if (list.isEmpty) {
      return Scaffold(
          appBar: AppBar(title: const Text('Who Am I?')),
          body: const Center(child: Text('No characters loaded.')));
    }
    final w = list[_index];
    final t = scope.talents;
    final solved = t.whoAnswered.contains('who:$_index');
    final answered = _picked != null;
    final correct = _picked == w.answer;

    return Scaffold(
      appBar: AppBar(
          title: const Text('Who Am I?'), actions: const [TalentsChip()]),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Character ${_index + 1} of ${list.length}',
                  style: const TextStyle(
                      color: AppConfig.slate500, fontWeight: FontWeight.w600)),
              if (solved) const PillTag('Solved'),
            ],
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < _cluesShown && i < w.clues.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppConfig.slate200),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${i + 1}.',
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppConfig.primary)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text('"${w.clues[i]}"',
                          style: const TextStyle(
                              fontSize: 15.5,
                              fontStyle: FontStyle.italic,
                              height: 1.45)),
                    ),
                  ],
                ),
              ),
            ),
          if (!answered && _cluesShown < w.clues.length)
            OutlinedButton(
              onPressed: () => setState(() => _cluesShown++),
              child: Text(
                  'Reveal clue ${_cluesShown + 1} of ${w.clues.length}'),
            ),
          const SizedBox(height: 14),
          for (final opt in w.options)
            Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  backgroundColor: !answered
                      ? null
                      : opt == w.answer
                          ? AppConfig.secondary
                          : opt == _picked
                              ? Colors.red.shade400
                              : null,
                  foregroundColor:
                      answered && (opt == w.answer || opt == _picked)
                          ? Colors.white
                          : AppConfig.deepNavy,
                ),
                onPressed: answered
                    ? null
                    : () {
                        setState(() => _picked = opt);
                        if (opt == w.answer) {
                          final earned = t.markWhoCorrect(_index);
                          showTalentsEarned(context, earned,
                              note: 'Who Am I?');
                          claimBadges(context);
                        }
                      },
                child: Text(opt, style: const TextStyle(fontSize: 15)),
              ),
            ),
          if (answered) ...[
            const SizedBox(height: 6),
            Text(
              correct
                  ? '✓ ${w.answer} — ${w.reference}. Read the full story from the Stories tab.'
                  : 'It was ${w.answer} — ${w.reference}. Their story is worth the read.',
              style: const TextStyle(
                  color: AppConfig.slate700, height: 1.5, fontSize: 14),
            ),
            const SizedBox(height: 12),
            FilledButton(onPressed: _next, child: const Text('Next character')),
          ],
        ],
      ),
    );
  }
}

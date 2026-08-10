import 'dart:math';

import 'package:flutter/material.dart';

import '../app_config.dart';
import '../main.dart';
import '../models.dart';
import '../widgets/common.dart';

/// The Gauntlet — precision mode. Questions from every deck this build
/// carries; answer ten in a row and the run is conquered (+30, first win
/// each day). One miss ends the run. Best streak tracked forever.
class GauntletScreen extends StatefulWidget {
  final Map<String, List<QuizQuestion>> decks;
  const GauntletScreen({super.key, required this.decks});

  @override
  State<GauntletScreen> createState() => _GauntletScreenState();
}

class _GauntletScreenState extends State<GauntletScreen> {
  static const target = 10;

  List<QuizQuestion> _pool = [];
  int _pos = 0;
  int _streak = 0;
  bool _running = false;
  bool _over = false;
  bool _won = false;
  int? _picked;

  void _start() {
    final pool = [
      for (final qs in widget.decks.values) ...qs,
    ]..shuffle(Random());
    setState(() {
      _pool = pool;
      _pos = 0;
      _streak = 0;
      _running = true;
      _over = false;
      _won = false;
      _picked = null;
    });
  }

  void _finish(bool won) {
    final t = AppScope.of(context).talents;
    final earned = t.finishGauntlet(_streak);
    setState(() {
      _running = false;
      _over = true;
      _won = won;
    });
    if (earned > 0) {
      showTalentsEarned(context, earned, note: 'Gauntlet conquered');
    }
    claimBadges(context);
  }

  void _answer(int i) {
    if (_picked != null) return;
    final q = _pool[_pos % _pool.length];
    setState(() => _picked = i);
    final correct = i == q.answer;
    Future.delayed(const Duration(milliseconds: 550), () {
      if (!mounted) return;
      if (!correct) {
        _finish(false);
        return;
      }
      _streak++;
      if (_streak >= target) {
        _finish(true);
        return;
      }
      setState(() {
        _pos++;
        _picked = null;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppScope.of(context).talents;

    if (!_running) {
      return Scaffold(
        appBar: AppBar(
            title: const Text('The Gauntlet'),
            actions: const [TalentsChip()]),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Text(
                  _over
                      ? _won
                          ? '🏛️ Gauntlet conquered.'
                          : '⚔️ The run ends at $_streak.'
                      : '⚔️ Ten in a row. No mistakes.',
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              Text(
                _over
                    ? 'Best run: ${t.gauntletBest}. ${_won ? '' : 'Precision beats speed here — run it back.'}'
                    : 'No timer. No second chances. Answer $target straight from every deck to conquer the Gauntlet. ${t.gauntletRewardAvailable ? "First conquest today pays +30." : "Today's payout claimed — run for the record."} Best: ${t.gauntletBest}.',
                style: const TextStyle(
                    color: AppConfig.slate700, height: 1.5),
              ),
              const SizedBox(height: 20),
              FilledButton(
                  onPressed: _start,
                  child: Text(_over ? 'Run it back' : 'Enter the Gauntlet')),
            ],
          ),
        ),
      );
    }

    final q = _pool[_pos % _pool.length];
    final answered = _picked != null;

    return Scaffold(
      appBar: AppBar(
          title: const Text('The Gauntlet'),
          actions: const [TalentsChip()]),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                for (var i = 0; i < target; i++)
                  Expanded(
                    child: Container(
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: i < _streak
                            ? AppConfig.secondary
                            : AppConfig.slate200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text('$_streak / $target',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 15)),
            const SizedBox(height: 14),
            Text(q.q,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700, height: 1.3)),
            const SizedBox(height: 16),
            for (var i = 0; i < q.options.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    backgroundColor: !answered
                        ? null
                        : i == q.answer
                            ? AppConfig.secondary
                            : i == _picked
                                ? Colors.red.shade400
                                : null,
                    foregroundColor:
                        answered && (i == q.answer || i == _picked)
                            ? Colors.white
                            : AppConfig.deepNavy,
                  ),
                  onPressed: () => _answer(i),
                  child: Text(q.options[i]),
                ),
              ),
            const Spacer(),
            TextButton(
                onPressed: () => _finish(false),
                child: const Text('Retreat (end run)')),
          ],
        ),
      ),
    );
  }
}

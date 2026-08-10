import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../app_config.dart';
import '../main.dart';
import '../models.dart';
import '../widgets/common.dart';

/// Lightning Round: 60 seconds, questions from every deck this build shows,
/// shuffled endlessly. +2 Talents per correct answer on the first run each
/// day; the all-time best score is tracked for bragging rights.
class LightningScreen extends StatefulWidget {
  final Map<String, List<QuizQuestion>> decks;
  const LightningScreen({super.key, required this.decks});

  @override
  State<LightningScreen> createState() => _LightningScreenState();
}

class _LightningScreenState extends State<LightningScreen> {
  static const roundSeconds = 60;

  late List<(String, QuizQuestion)> _pool;
  int _pos = 0;
  int _score = 0;
  int _secondsLeft = roundSeconds;
  bool _running = false;
  bool _finished = false;
  int? _picked;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _buildPool();
  }

  void _buildPool() {
    final rng = Random();
    _pool = [
      for (final e in widget.decks.entries)
        for (final q in e.value) (e.key, q),
    ]..shuffle(rng);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    setState(() {
      _running = true;
      _finished = false;
      _score = 0;
      _pos = 0;
      _picked = null;
      _secondsLeft = roundSeconds;
    });
    _buildPool();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) _end();
    });
  }

  void _end() {
    _timer?.cancel();
    final t = AppScope.of(context).talents;
    final earned = t.finishLightning(_score);
    setState(() {
      _running = false;
      _finished = true;
    });
    showTalentsEarned(context, earned, note: 'Lightning Round');
    final sizes = {
      for (final e in widget.decks.entries) e.key: e.value.length
    };
    for (final b in t.claimNewBadges(sizes)) {
      showTalentsEarned(context, TalentsBadge.reward, note: 'Badge: $b');
    }
  }

  void _answer(int i) {
    if (_picked != null) return;
    final q = _pool[_pos % _pool.length].$2;
    setState(() => _picked = i);
    if (i == q.answer) _score++;
    // Fast pace: brief flash, then next question.
    Future.delayed(const Duration(milliseconds: 350), () {
      if (!mounted || !_running) return;
      setState(() {
        _pos++;
        _picked = null;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppScope.of(context).talents;
    final q = _pool.isEmpty ? null : _pool[_pos % _pool.length].$2;

    return Scaffold(
      appBar: AppBar(
          title: const Text('Lightning Round'),
          actions: const [TalentsChip()]),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: !_running
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  Text(_finished ? 'Time!' : '⚡ 60 seconds. Every deck. Go.',
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  if (_finished) ...[
                    Text('Score: $_score',
                        style: const TextStyle(
                            fontSize: 44, fontWeight: FontWeight.w800)),
                    Text('Best: ${t.lightningBest}',
                        style: const TextStyle(color: AppConfig.slate500)),
                  ] else ...[
                    Text(
                      'Answer as many as you can. ${t.lightningRewardAvailable ? "First run today pays +2 Talents per correct answer." : "Today's payout is claimed — this run is for the record."} Best so far: ${t.lightningBest}.',
                      style: const TextStyle(
                          color: AppConfig.slate700, height: 1.5),
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                      onPressed: _start,
                      child: Text(_finished ? 'Run it back' : 'Start')),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Score: $_score',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 18)),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: _secondsLeft <= 10
                              ? Colors.red.shade400
                              : AppConfig.anchor,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text('$_secondsLeft s',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: _secondsLeft / roundSeconds,
                      minHeight: 6,
                      backgroundColor: AppConfig.slate200,
                      color: AppConfig.secondary,
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (q != null) ...[
                    Text(q.q,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            height: 1.3)),
                    const SizedBox(height: 16),
                    for (var i = 0; i < q.options.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            alignment: Alignment.centerLeft,
                            backgroundColor: _picked == null
                                ? null
                                : i == q.answer
                                    ? AppConfig.secondary
                                    : i == _picked
                                        ? Colors.red.shade400
                                        : null,
                            foregroundColor: _picked != null &&
                                    (i == q.answer || i == _picked)
                                ? Colors.white
                                : AppConfig.deepNavy,
                          ),
                          onPressed: () => _answer(i),
                          child: Text(q.options[i]),
                        ),
                      ),
                  ],
                  const Spacer(),
                  TextButton(
                      onPressed: _end, child: const Text('End round early')),
                ],
              ),
      ),
    );
  }
}

/// Display constant mirror so widgets can toast badge rewards without
/// importing the whole state class API surface.
class TalentsBadge {
  static const reward = 25;
}

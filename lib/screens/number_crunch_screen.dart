import 'dart:math';

import 'package:flutter/material.dart';

import '../app_config.dart';
import '../main.dart';
import '../widgets/common.dart';

/// Number Crunch — procedurally generated mental math, so it never runs out.
/// Accounting builds get accounting-equation and net-income problems; data
/// builds get mean/median/range drills; the full app mixes both. +5 per
/// correct for the first five each day, free play after.
class NumberCrunchScreen extends StatefulWidget {
  const NumberCrunchScreen({super.key});
  @override
  State<NumberCrunchScreen> createState() => _NumberCrunchScreenState();
}

class _Problem {
  final String prompt;
  final int answer;
  final List<int> options;
  _Problem(this.prompt, this.answer, this.options);
}

class _NumberCrunchScreenState extends State<NumberCrunchScreen> {
  final _rng = Random();
  _Problem? _p;
  int? _picked;
  int _sessionCorrect = 0;

  bool get _accounting =>
      AppConfig.isFull || AppConfig.niche == AppNiche.accounting;
  bool get _data => AppConfig.isFull || AppConfig.niche == AppNiche.data;

  @override
  void initState() {
    super.initState();
    _p = null;
  }

  List<int> _mkOptions(int answer, int spread) {
    final opts = <int>{answer};
    while (opts.length < 4) {
      final delta = (_rng.nextInt(spread) + 1) * (_rng.nextBool() ? 1 : -1);
      final candidate = answer + delta;
      if (candidate != answer) opts.add(candidate);
    }
    final list = opts.toList()..shuffle(_rng);
    return list;
  }

  _Problem _generate() {
    final modes = <String>[];
    if (_accounting) modes.addAll(['equation', 'income']);
    if (_data) modes.addAll(['mean', 'range']);
    final mode = modes[_rng.nextInt(modes.length)];

    switch (mode) {
      case 'equation':
        final l = (_rng.nextInt(80) + 10) * 1000;
        final e = (_rng.nextInt(60) + 5) * 1000;
        final a = l + e;
        switch (_rng.nextInt(3)) {
          case 0:
            return _Problem(
                'Liabilities \$${_fmt(l)} · Equity \$${_fmt(e)}\n\nAssets = ?',
                a ~/ 1000,
                _mkOptions(a ~/ 1000, 12));
          case 1:
            return _Problem(
                'Assets \$${_fmt(a)} · Equity \$${_fmt(e)}\n\nLiabilities = ?',
                l ~/ 1000,
                _mkOptions(l ~/ 1000, 12));
          default:
            return _Problem(
                'Assets \$${_fmt(a)} · Liabilities \$${_fmt(l)}\n\nEquity = ?',
                e ~/ 1000,
                _mkOptions(e ~/ 1000, 12));
        }
      case 'income':
        final rev = (_rng.nextInt(90) + 20) * 1000;
        final exp = (_rng.nextInt(rev ~/ 2000) + 5) * 1000;
        final ni = rev - exp;
        return _Problem(
            'Revenue \$${_fmt(rev)} · Expenses \$${_fmt(exp)}\n\nNet income = ?',
            ni ~/ 1000,
            _mkOptions(ni ~/ 1000, 10));
      case 'mean':
        final vals = List.generate(3, (_) => (_rng.nextInt(8) + 1) * 3);
        final sum = vals.reduce((a, b) => a + b);
        final mean = sum ~/ 3 == sum / 3 ? sum ~/ 3 : -1;
        if (mean == -1) return _generate(); // regenerate until clean mean
        return _Problem(
            'Dataset: ${vals.join(', ')}\n\nMean = ?', mean,
            _mkOptions(mean, 5));
      default: // range
        final vals =
            List.generate(4, (_) => _rng.nextInt(85) + 5)..sort();
        final range = vals.last - vals.first;
        final shown = [...vals]..shuffle(_rng);
        return _Problem(
            'Dataset: ${shown.join(', ')}\n\nRange = ?', range,
            _mkOptions(range, 9));
    }
  }

  static String _fmt(int n) {
    final s = n.toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
      b.write(s[i]);
    }
    return b.toString();
  }

  String _optLabel(int v) {
    // Equation/income answers are in thousands.
    final p = _p!;
    if (p.prompt.contains('\$')) return '\$${_fmt(v * 1000)}';
    return '$v';
  }

  @override
  Widget build(BuildContext context) {
    final t = AppScope.of(context).talents;
    final left = t.crunchPaidLeftToday;

    if (_p == null) {
      return Scaffold(
        appBar: AppBar(
            title: const Text('Number Crunch'),
            actions: const [TalentsChip()]),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              const Text('🧮 Mental math, steward style.',
                  style:
                      TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              Text(
                'Freshly generated problems every round — ${_accounting && _data ? 'accounting equations and quick statistics' : _accounting ? 'the accounting equation and net income' : 'means, medians, and ranges'}. First $left correct today pay +5 each; after that it\'s pure practice.',
                style:
                    const TextStyle(color: AppConfig.slate700, height: 1.5),
              ),
              const SizedBox(height: 20),
              FilledButton(
                  onPressed: () => setState(() {
                        _p = _generate();
                        _picked = null;
                      }),
                  child: const Text('Start crunching')),
            ],
          ),
        ),
      );
    }

    final p = _p!;
    final answered = _picked != null;

    return Scaffold(
      appBar: AppBar(
          title: const Text('Number Crunch'),
          actions: const [TalentsChip()]),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Session: $_sessionCorrect correct',
                    style: const TextStyle(
                        color: AppConfig.slate500,
                        fontWeight: FontWeight.w600)),
                Text(
                    left > 0
                        ? '$left paid plays left today'
                        : 'Practice mode (paid out for today)',
                    style: const TextStyle(
                        color: AppConfig.slate500, fontSize: 12.5)),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppConfig.slate200),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(p.prompt,
                  style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      height: 1.45)),
            ),
            const SizedBox(height: 18),
            for (final opt in p.options)
              Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    backgroundColor: !answered
                        ? null
                        : opt == p.answer
                            ? AppConfig.secondary
                            : opt == _picked
                                ? Colors.red.shade400
                                : null,
                    foregroundColor:
                        answered && (opt == p.answer || opt == _picked)
                            ? Colors.white
                            : AppConfig.deepNavy,
                  ),
                  onPressed: answered
                      ? null
                      : () {
                          setState(() => _picked = opt);
                          if (opt == p.answer) {
                            _sessionCorrect++;
                            final earned = t.crunchCorrect();
                            showTalentsEarned(context, earned,
                                note: 'Number Crunch');
                            claimBadges(context);
                          }
                        },
                  child: Text(_optLabel(opt),
                      style: const TextStyle(
                          fontSize: 15.5, fontWeight: FontWeight.w600)),
                ),
              ),
            const Spacer(),
            if (answered)
              FilledButton(
                onPressed: () => setState(() {
                  _p = _generate();
                  _picked = null;
                }),
                child: const Text('Next problem'),
              ),
          ],
        ),
      ),
    );
  }
}

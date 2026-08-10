import 'dart:math';

import 'package:flutter/material.dart';

import '../app_config.dart';
import '../main.dart';
import '../models.dart';
import '../widgets/common.dart';

/// Order the Story: five real stories from the canon, shuffled. Tap them in
/// chronological order. Uses the curated story_order list in content.json so
/// every round is scripturally defensible. +15 on a clean board (first win
/// each day).
class OrderGameScreen extends StatefulWidget {
  const OrderGameScreen({super.key});
  @override
  State<OrderGameScreen> createState() => _OrderGameScreenState();
}

class _OrderGameScreenState extends State<OrderGameScreen> {
  List<Story> _round = [];
  List<Story> _placed = [];
  int _mistakes = 0;
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
    final c = AppScope.of(context).content;
    final ordered = [
      for (final id in c.storyOrder)
        c.stories.firstWhere((s) => s.id == id,
            orElse: () => c.stories.first)
    ];
    // Pick 5 positions, keep canonical order as the answer key.
    final idxs = List.generate(ordered.length, (i) => i)..shuffle(Random());
    final pickIdx = idxs.take(5).toList()..sort();
    final answer = [for (final i in pickIdx) ordered[i]];
    final shuffled = [...answer]..shuffle(Random());
    setState(() {
      _round = shuffled;
      _answerKey = answer;
      _placed = [];
      _mistakes = 0;
      _done = false;
    });
  }

  List<Story> _answerKey = [];

  void _tap(Story s) {
    if (_done || _placed.contains(s)) return;
    final expected = _answerKey[_placed.length];
    if (s.id == expected.id) {
      setState(() => _placed.add(s));
      if (_placed.length == _answerKey.length) {
        _done = true;
        final t = AppScope.of(context).talents;
        final earned = t.finishOrder();
        showTalentsEarned(context, earned, note: 'Order the Story');
        claimBadges(context);
        setState(() {});
      }
    } else {
      setState(() => _mistakes++);
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 900),
        content: Text('Not yet — something happens before ${s.reference}.'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppScope.of(context).talents;
    return Scaffold(
      appBar: AppBar(
          title: const Text('Order the Story'),
          actions: const [TalentsChip()]),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            _done
                ? '✓ In order — $_mistakes wrong taps along the way.'
                : 'Tap the events in the order they happened in scripture. ${t.orderRewardAvailable ? '+15 Talents on a finished board.' : 'Today\'s payout claimed — play for practice.'}',
            style: const TextStyle(
                color: AppConfig.slate700, height: 1.5, fontSize: 14),
          ),
          const SizedBox(height: 14),
          const Eyebrow('Your timeline'),
          const SizedBox(height: 8),
          if (_placed.isEmpty)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                border: Border.all(color: AppConfig.slate200),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('Earliest event goes first…',
                  style: TextStyle(
                      color: AppConfig.slate500,
                      fontStyle: FontStyle.italic)),
            ),
          for (var i = 0; i < _placed.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppConfig.secondary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Text('${i + 1}.',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                          '${_placed[i].title}  ·  ${_placed[i].reference}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13.5)),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          if (!_done) ...[
            const Eyebrow('Tap the next event'),
            const SizedBox(height: 8),
            for (final s in _round.where((s) => !_placed.contains(s)))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SectionCard(
                  onTap: () => _tap(s),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14.5)),
                            const SizedBox(height: 3),
                            Text(s.reference,
                                style: const TextStyle(
                                    color: AppConfig.slate500,
                                    fontSize: 12.5)),
                          ],
                        ),
                      ),
                      const Icon(Icons.add_circle_outline,
                          color: AppConfig.slate500),
                    ],
                  ),
                ),
              ),
          ] else
            FilledButton(onPressed: _setup, child: const Text('New round')),
        ],
      ),
    );
  }
}

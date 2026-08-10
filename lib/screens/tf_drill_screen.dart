import 'dart:math';

import 'package:flutter/material.dart';

import '../app_config.dart';
import '../main.dart';
import '../models.dart';
import '../widgets/common.dart';

/// True/False rapid drill. Two skins: "Ledger Lines" (accounting) and
/// "Data Signals" (data analytics). +5 per first-time correct call, with a
/// one-line why after every answer — the drill teaches even when you're right.
class TFDrillScreen extends StatefulWidget {
  final String nicheKey; // 'accounting' | 'data'
  final String title;
  const TFDrillScreen(
      {super.key, required this.nicheKey, required this.title});

  @override
  State<TFDrillScreen> createState() => _TFDrillScreenState();
}

class _TFDrillScreenState extends State<TFDrillScreen> {
  late List<int> _order;
  List<TFItem> _items = const [];
  int _pos = 0;
  int _correct = 0;
  bool? _picked;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _items = AppScope.of(context).content.tfDecks[widget.nicheKey] ?? const [];
    _order = List.generate(_items.length, (i) => i)..shuffle(Random());
  }

  @override
  Widget build(BuildContext context) {
    final t = AppScope.of(context).talents;

    if (_items.isEmpty) {
      return Scaffold(
          appBar: AppBar(title: Text(widget.title)),
          body: const Center(child: Text('No statements available.')));
    }
    if (_pos >= _order.length) {
      final pct = (_correct * 100 / _items.length).round();
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Text('$pct%',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 56, fontWeight: FontWeight.w800)),
              Text('$_correct of ${_items.length} correct calls',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppConfig.slate500)),
              const Spacer(),
              FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Back to Play')),
            ],
          ),
        ),
      );
    }

    final qi = _order[_pos];
    final item = _items[qi];
    final answered = _picked != null;
    final mastered = t.tfAnswered.contains('tf:${widget.nicheKey}:$qi');

    return Scaffold(
      appBar:
          AppBar(title: Text(widget.title), actions: const [TalentsChip()]),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${_pos + 1} of ${_order.length}',
                    style: const TextStyle(
                        color: AppConfig.slate500,
                        fontWeight: FontWeight.w600)),
                if (mastered) const PillTag('Mastered'),
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
              child: Text(item.s,
                  style: const TextStyle(
                      fontSize: 19, fontWeight: FontWeight.w700, height: 1.35)),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                for (final val in [true, false]) ...[
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: !answered
                            ? (val ? AppConfig.secondary : Colors.red.shade400)
                            : val == item.a
                                ? AppConfig.secondary
                                : val == _picked
                                    ? Colors.red.shade400
                                    : AppConfig.slate200,
                        foregroundColor: answered &&
                                val != item.a &&
                                val != _picked
                            ? AppConfig.slate500
                            : Colors.white,
                      ),
                      onPressed: answered
                          ? null
                          : () {
                              setState(() => _picked = val);
                              if (val == item.a) {
                                _correct++;
                                final earned = t.markTFCorrect(
                                    widget.nicheKey, qi);
                                showTalentsEarned(context, earned);
                                claimBadges(context);
                              }
                            },
                      child: Text(val ? 'TRUE' : 'FALSE',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 16)),
                    ),
                  ),
                  if (val) const SizedBox(width: 12),
                ],
              ],
            ),
            const SizedBox(height: 16),
            if (answered)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _picked == item.a
                      ? AppConfig.secondary.withOpacity(0.1)
                      : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_picked == item.a ? '✓ Correct.' : '✗ It\'s ${item.a ? 'TRUE' : 'FALSE'}.'} ${item.why}',
                  style: const TextStyle(height: 1.5, fontSize: 14),
                ),
              ),
            const Spacer(),
            if (answered)
              FilledButton(
                onPressed: () => setState(() {
                  _pos++;
                  _picked = null;
                }),
                child: Text(
                    _pos + 1 >= _order.length ? 'See results' : 'Next'),
              ),
          ],
        ),
      ),
    );
  }
}

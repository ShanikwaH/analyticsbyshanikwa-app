import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../app_config.dart';
import '../games/word_search_gen.dart';
import '../main.dart';
import '../widgets/common.dart';

/// Word Search — a 9×9 grid hiding six real terms from the niche's word bank
/// (Bible names from the story catalog, accounting terms, or data terms).
/// Tap the first letter, then the last letter of a word to claim it.
/// +15 on a cleared board (first win each day).
/// A pan recognizer that claims the gesture the instant the pointer lands.
///
/// The board sits inside the page's ListView. A normal GestureDetector's pan
/// recognizer has to win a gesture-arena contest against that ListView's
/// vertical-drag recognizer, and on a vertical swipe the ListView wins — so the
/// page scrolled instead of selecting, and vertical words could not be dragged
/// at all. Resolving as accepted up front takes the pointer before the
/// ListView can claim it, in every direction.
class _BoardPanRecognizer extends PanGestureRecognizer {
  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    resolve(GestureDisposition.accepted);
  }
}

class WordSearchScreen extends StatefulWidget {
  final String nicheKey; // 'bible' | 'accounting' | 'data'
  final String title;
  const WordSearchScreen(
      {super.key, required this.nicheKey, required this.title});

  @override
  State<WordSearchScreen> createState() => _WordSearchScreenState();
}

class _WordSearchScreenState extends State<WordSearchScreen> {
  static const size = 9;
  final _rng = Random();

  List<List<String>> _grid = [];
  List<String> _words = [];
  Set<String> _found = {};
  Set<int> _foundCells = {};
  int? _anchor;
  int? _dragStart;
  List<int> _dragCells = const [];
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
    final bank = List<String>.from(
        AppScope.of(context).content.gameWords[widget.nicheKey] ?? []);
    final board = generateWordSearch(bank, size, _rng);
    setState(() {
      _grid = board.grid;
      _words = board.words;
      _found = {};
      _foundCells = {};
      _anchor = null;
      _done = false;
    });
  }

  /// Claim a straight run of cells: match forward or backward, mark found.
  bool _claimRun(List<int> cells) {
    final buf = StringBuffer();
    for (final i in cells) {
      buf.write(_grid[i ~/ size][i % size]);
    }
    final str = buf.toString();
    final hit = _words.firstWhere(
        (w) =>
            !_found.contains(w) &&
            (w == str || w == str.split('').reversed.join()),
        orElse: () => '');
    if (hit.isEmpty) return false;
    setState(() {
      _found.add(hit);
      _foundCells.addAll(cells);
      if (_found.length == _words.length) {
        _done = true;
        final t = AppScope.of(context).talents;
        final earned = t.finishWordSearch();
        showTalentsEarned(context, earned, note: 'Word Search');
        claimBadges(context);
      }
    });
    return true;
  }

  /// Tap fallback: first tap anchors, second tap completes the line.
  void _tap(int index) {
    if (_done) return;
    if (_anchor == null) {
      setState(() => _anchor = index);
      return;
    }
    if (_anchor == index) {
      setState(() => _anchor = null);
      return;
    }
    final r0 = _anchor! ~/ size, c0 = _anchor! % size;
    final r1 = index ~/ size, c1 = index % size;
    final straight = (r0 == r1) || (c0 == c1) ||
        ((r1 - r0).abs() == (c1 - c0).abs());
    if (!straight) {
      setState(() => _anchor = index);
      return;
    }
    final dr = (r1 - r0).sign, dc = (c1 - c0).sign;
    final len = max((r1 - r0).abs(), (c1 - c0).abs());
    final cells = [
      for (var k = 0; k <= len; k++) (r0 + k * dr) * size + (c0 + k * dc)
    ];
    setState(() => _anchor = null);
    _claimRun(cells);
  }

  // ---- Drag mode: the pen-through-the-puzzle-book feel ----

  int _cellFromOffset(Offset p, double width) {
    final cell = width / size;
    final c = (p.dx / cell).floor().clamp(0, size - 1);
    final r = (p.dy / cell).floor().clamp(0, size - 1);
    return r * size + c;
  }

  void _dragBegin(int i) {
    if (_done) return;
    setState(() {
      _dragStart = i;
      _dragCells = [i];
    });
  }

  void _dragMove(int i) {
    if (_dragStart == null) return;
    setState(() => _dragCells = snapRun(_dragStart!, i, size));
  }

  void _dragEnd() {
    if (_dragStart == null) return;
    final run = List<int>.from(_dragCells);
    setState(() {
      _dragStart = null;
      _dragCells = const [];
    });
    if (run.length <= 1) {
      _tap(run.first); // a plain press → anchor mode
      return;
    }
    setState(() => _anchor = null);
    _claimRun(run);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppScope.of(context).talents;
    return Scaffold(
      appBar:
          AppBar(title: Text(widget.title), actions: const [TalentsChip()]),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            _done
                ? '✓ Board cleared.'
                : 'Drag across each hidden word like a pen through a puzzle book — or tap its first and last letters. ${t.wordSearchRewardAvailable ? '+15 on a cleared board.' : 'Today\'s payout claimed — play for practice.'}',
            style: const TextStyle(
                color: AppConfig.slate700, height: 1.5, fontSize: 14),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final w in _words)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _found.contains(w)
                        ? AppConfig.secondary
                        : Colors.white,
                    border: Border.all(
                        color: _found.contains(w)
                            ? Colors.transparent
                            : AppConfig.slate200),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(w,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _found.contains(w)
                            ? Colors.white
                            : AppConfig.deepNavy,
                        decoration: _found.contains(w)
                            ? TextDecoration.lineThrough
                            : null,
                      )),
                ),
            ],
          ),
          const SizedBox(height: 12),
          AspectRatio(
            aspectRatio: 1,
            child: LayoutBuilder(
              builder: (context, box) => RawGestureDetector(
                behavior: HitTestBehavior.opaque,
                gestures: {
                  // A press with no movement ends as a 1-cell run, which
                  // _dragEnd routes to _tap — so tap-first/tap-last still
                  // works and no separate tap recognizer is needed.
                  _BoardPanRecognizer:
                      GestureRecognizerFactoryWithHandlers<
                          _BoardPanRecognizer>(
                    () => _BoardPanRecognizer(),
                    // Block body, not a cascade: after an arrow lambda, `..`
                    // cascades onto the lambda's (void) result, not onto `r`.
                    (r) {
                      r.onStart = (d) => _dragBegin(
                          _cellFromOffset(d.localPosition, box.maxWidth));
                      r.onUpdate = (d) => _dragMove(
                          _cellFromOffset(d.localPosition, box.maxWidth));
                      r.onEnd = (_) => _dragEnd();
                      r.onCancel = _dragEnd;
                    },
                  ),
                },
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: size,
                          mainAxisSpacing: 3,
                          crossAxisSpacing: 3),
                  itemCount: size * size,
                  itemBuilder: (context, i) {
                    final foundCell = _foundCells.contains(i);
                    final dragging = _dragCells.contains(i);
                    final anchored = _anchor == i;
                    final lit = dragging || anchored;
                    return Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: foundCell
                            ? AppConfig.secondary
                            : lit
                                ? AppConfig.primary
                                : Colors.white,
                        border: Border.all(
                            color: foundCell || lit
                                ? Colors.transparent
                                : AppConfig.slate200),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _grid.isEmpty ? '' : _grid[i ~/ size][i % size],
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: foundCell || lit
                              ? Colors.white
                              : AppConfig.deepNavy,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (_done)
            FilledButton(onPressed: _setup, child: const Text('New board'))
          else
            OutlinedButton(onPressed: _setup, child: const Text('New board')),
        ],
      ),
    );
  }
}

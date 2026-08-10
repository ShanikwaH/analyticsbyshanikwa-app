import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../app_config.dart';
import '../main.dart';
import '../widgets/common.dart';

// ---------------------------------------------------------------------------
// Memory Flip — classic concentration. 16 cards face down, 8 themed pairs.
// Flip two; a match locks green, a miss flips back. +15 (first win each day).
// ---------------------------------------------------------------------------

class MemoryFlipScreen extends StatefulWidget {
  const MemoryFlipScreen({super.key});
  @override
  State<MemoryFlipScreen> createState() => _MemoryFlipScreenState();
}

class _MemoryFlipScreenState extends State<MemoryFlipScreen> {
  static const emojis = ['📖', '🪙', '⚖️', '📊', '🧾', '✝️', '📈', '🗝️'];
  List<String> _cards = [];
  Set<int> _matched = {};
  int? _first;
  int? _second;
  int _moves = 0;
  bool _lock = false;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _setup();
  }

  void _setup() {
    setState(() {
      _cards = [...emojis, ...emojis]..shuffle(Random());
      _matched = {};
      _first = null;
      _second = null;
      _moves = 0;
      _lock = false;
      _done = false;
    });
  }

  void _flip(int i) {
    if (_lock || _done || _matched.contains(i) || _first == i) return;
    if (_first == null) {
      setState(() => _first = i);
      return;
    }
    setState(() {
      _second = i;
      _moves++;
      _lock = true;
    });
    if (_cards[_first!] == _cards[i]) {
      setState(() {
        _matched.addAll([_first!, i]);
        _first = null;
        _second = null;
        _lock = false;
      });
      if (_matched.length == _cards.length) {
        _done = true;
        final t = AppScope.of(context).talents;
        final earned = t.finishMemory();
        showTalentsEarned(context, earned, note: 'Memory Flip');
        claimBadges(context);
        setState(() {});
      }
    } else {
      Timer(const Duration(milliseconds: 750), () {
        if (!mounted) return;
        setState(() {
          _first = null;
          _second = null;
          _lock = false;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppScope.of(context).talents;
    return Scaffold(
      appBar: AppBar(
          title: const Text('Memory Flip'), actions: const [TalentsChip()]),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            _done
                ? '✓ All pairs in $_moves moves.'
                : 'Flip two cards. Match the pair. Remember what you saw. ${t.memoryRewardAvailable ? '+15 on a cleared board.' : 'Today\'s payout claimed — play for practice.'}',
            style: const TextStyle(
                color: AppConfig.slate700, height: 1.5, fontSize: 14),
          ),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4, mainAxisSpacing: 10, crossAxisSpacing: 10),
            itemCount: _cards.length,
            itemBuilder: (context, i) {
              final faceUp =
                  _matched.contains(i) || _first == i || _second == i;
              return InkWell(
                onTap: () => _flip(i),
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _matched.contains(i)
                        ? AppConfig.secondary
                        : faceUp
                            ? Colors.white
                            : AppConfig.anchor,
                    border: Border.all(
                        color: faceUp && !_matched.contains(i)
                            ? AppConfig.slate200
                            : Colors.transparent),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(faceUp ? _cards[i] : '✦',
                      style: TextStyle(
                          fontSize: faceUp ? 28 : 18,
                          color: faceUp ? null : Colors.white54)),
                ),
              );
            },
          ),
          const SizedBox(height: 14),
          Text('Moves: $_moves',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppConfig.slate500, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          if (_done)
            FilledButton(onPressed: _setup, child: const Text('New game'))
          else
            OutlinedButton(onPressed: _setup, child: const Text('Restart')),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Number Slide — the classic 3×3 sliding puzzle (tiles 1–8 + a gap). Shuffled
// by valid moves so it's always solvable. +15 on solve (first win each day).
// ---------------------------------------------------------------------------

class SlidePuzzleScreen extends StatefulWidget {
  const SlidePuzzleScreen({super.key});
  @override
  State<SlidePuzzleScreen> createState() => _SlidePuzzleScreenState();
}

class _SlidePuzzleScreenState extends State<SlidePuzzleScreen> {
  static const n = 3;
  List<int> _tiles = []; // 0 = gap
  int _moves = 0;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _setup();
  }

  void _setup() {
    var tiles = List.generate(n * n, (i) => (i + 1) % (n * n));
    final rng = Random();
    // Shuffle with valid moves — guarantees solvability.
    for (var k = 0; k < 120; k++) {
      final gap = tiles.indexOf(0);
      final r = gap ~/ n, c = gap % n;
      final neighbors = <int>[];
      if (r > 0) neighbors.add(gap - n);
      if (r < n - 1) neighbors.add(gap + n);
      if (c > 0) neighbors.add(gap - 1);
      if (c < n - 1) neighbors.add(gap + 1);
      final pick = neighbors[rng.nextInt(neighbors.length)];
      tiles[gap] = tiles[pick];
      tiles[pick] = 0;
    }
    setState(() {
      _tiles = tiles;
      _moves = 0;
      _done = false;
    });
  }

  bool get _solved {
    for (var i = 0; i < n * n - 1; i++) {
      if (_tiles[i] != i + 1) return false;
    }
    return true;
  }

  void _tap(int i) {
    if (_done) return;
    final gap = _tiles.indexOf(0);
    final r = i ~/ n, c = i % n, gr = gap ~/ n, gc = gap % n;
    if ((r - gr).abs() + (c - gc).abs() != 1) return;
    setState(() {
      _tiles[gap] = _tiles[i];
      _tiles[i] = 0;
      _moves++;
    });
    if (_solved) {
      _done = true;
      final t = AppScope.of(context).talents;
      final earned = t.finishSlide();
      showTalentsEarned(context, earned, note: 'Number Slide');
      claimBadges(context);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppScope.of(context).talents;
    return Scaffold(
      appBar: AppBar(
          title: const Text('Number Slide'), actions: const [TalentsChip()]),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            _done
                ? '✓ Solved in $_moves moves.'
                : 'Slide the tiles into order, 1 through 8. ${t.slideRewardAvailable ? '+15 on a solve.' : 'Today\'s payout claimed — play for practice.'}',
            style: const TextStyle(
                color: AppConfig.slate700, height: 1.5, fontSize: 14),
          ),
          const SizedBox(height: 16),
          Center(
            child: SizedBox(
              width: 260,
              height: 260,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: n,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8),
                itemCount: n * n,
                itemBuilder: (context, i) {
                  final v = _tiles.isEmpty ? 0 : _tiles[i];
                  if (v == 0) return const SizedBox.shrink();
                  final inPlace = v == i + 1;
                  return InkWell(
                    onTap: () => _tap(i),
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: inPlace
                            ? AppConfig.secondary
                            : AppConfig.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('$v',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 26)),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text('Moves: $_moves',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppConfig.slate500, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          if (_done)
            FilledButton(onPressed: _setup, child: const Text('New shuffle'))
          else
            OutlinedButton(onPressed: _setup, child: const Text('Reshuffle')),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Letter Hunt — hangman without the gallows. Guess the hidden niche term one
// letter at a time; six misses and the word wins. +15 (first win each day).
// ---------------------------------------------------------------------------

class WordGuessScreen extends StatefulWidget {
  final String nicheKey;
  const WordGuessScreen({super.key, required this.nicheKey});
  @override
  State<WordGuessScreen> createState() => _WordGuessScreenState();
}

class _WordGuessScreenState extends State<WordGuessScreen> {
  static const maxMisses = 6;
  String _word = '';
  Set<String> _guessed = {};
  int _misses = 0;
  bool _won = false;
  bool _lost = false;
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
    final words =
        AppScope.of(context).content.gameWords[widget.nicheKey] ?? [];
    setState(() {
      _word = words.isEmpty ? 'LEDGER' : words[Random().nextInt(words.length)];
      _guessed = {};
      _misses = 0;
      _won = false;
      _lost = false;
    });
  }

  void _guess(String letter) {
    if (_won || _lost || _guessed.contains(letter)) return;
    setState(() {
      _guessed.add(letter);
      if (!_word.contains(letter)) {
        _misses++;
        if (_misses >= maxMisses) _lost = true;
      } else if (_word.split('').every(_guessed.contains)) {
        _won = true;
      }
    });
    if (_won) {
      final t = AppScope.of(context).talents;
      final earned = t.finishGuess();
      showTalentsEarned(context, earned, note: 'Letter Hunt');
      claimBadges(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppScope.of(context).talents;
    const rows = ['ABCDEFGHI', 'JKLMNOPQR', 'STUVWXYZ'];
    return Scaffold(
      appBar: AppBar(
          title: const Text('Letter Hunt'), actions: const [TalentsChip()]),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            _won
                ? '✓ $_word — got it with ${maxMisses - _misses} lives to spare.'
                : _lost
                    ? 'The word was $_word. Run it back.'
                    : 'Guess the hidden term, one letter at a time. Six misses and the word wins. ${t.guessRewardAvailable ? '+15 on a catch.' : 'Today\'s payout claimed — play for practice.'}',
            style: const TextStyle(
                color: AppConfig.slate700, height: 1.5, fontSize: 14),
          ),
          const SizedBox(height: 20),
          Center(
            child: Wrap(
              spacing: 8,
              children: [
                for (final ch in _word.split(''))
                  Container(
                    width: 34,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      border: Border(
                          bottom: BorderSide(
                              color: AppConfig.deepNavy, width: 3)),
                    ),
                    child: Text(
                      _guessed.contains(ch) || _lost ? ch : '',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: _lost && !_guessed.contains(ch)
                              ? Colors.red.shade400
                              : AppConfig.deepNavy),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Center(
            child: Text(
              '❤️' * (maxMisses - _misses) + '🖤' * _misses,
              style: const TextStyle(fontSize: 20, letterSpacing: 3),
            ),
          ),
          const SizedBox(height: 18),
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final ch in row.split(''))
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: SizedBox(
                        width: 34,
                        height: 40,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            backgroundColor: !_guessed.contains(ch)
                                ? null
                                : _word.contains(ch)
                                    ? AppConfig.secondary
                                    : AppConfig.slate200,
                            foregroundColor:
                                _guessed.contains(ch) && _word.contains(ch)
                                    ? Colors.white
                                    : AppConfig.deepNavy,
                          ),
                          onPressed: (_won || _lost || _guessed.contains(ch))
                              ? null
                              : () => _guess(ch),
                          child: Text(ch,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 10),
          if (_won || _lost)
            FilledButton(onPressed: _setup, child: const Text('New word')),
        ],
      ),
    );
  }
}

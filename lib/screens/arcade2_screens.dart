import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../app_config.dart';
import '../app_state.dart'; // TalentsState — was referenced but never imported
import '../main.dart';
import '../widgets/common.dart';

// ---------------------------------------------------------------------------
// Tic-Tac-Toe — you are ✕, the app is ◯ with a classic heuristic AI
// (win > block > center > corner > any). Beat it for +15, first win each day.
// ---------------------------------------------------------------------------

class TicTacToeScreen extends StatefulWidget {
  const TicTacToeScreen({super.key});
  @override
  State<TicTacToeScreen> createState() => _TicTacToeScreenState();
}

class _TicTacToeScreenState extends State<TicTacToeScreen> {
  List<String> _b = List.filled(9, '');
  bool _humanTurn = true;
  String _result = ''; // '', 'win', 'lose', 'draw'

  static const _lines = [
    [0, 1, 2], [3, 4, 5], [6, 7, 8],
    [0, 3, 6], [1, 4, 7], [2, 5, 8],
    [0, 4, 8], [2, 4, 6],
  ];

  void _reset() => setState(() {
        _b = List.filled(9, '');
        _humanTurn = true;
        _result = '';
      });

  String _winner(List<String> b) {
    for (final l in _lines) {
      if (b[l[0]].isNotEmpty && b[l[0]] == b[l[1]] && b[l[1]] == b[l[2]]) {
        return b[l[0]];
      }
    }
    return b.contains('') ? '' : 'draw';
  }

  int _aiMove(List<String> b) {
    int findLine(String mark) {
      for (final l in _lines) {
        final cells = [b[l[0]], b[l[1]], b[l[2]]];
        if (cells.where((c) => c == mark).length == 2 &&
            cells.contains('')) {
          return l[cells.indexOf('')];
        }
      }
      return -1;
    }

    final win = findLine('O');
    if (win >= 0) return win;
    final block = findLine('X');
    if (block >= 0) return block;
    if (b[4].isEmpty) return 4;
    final corners = [0, 2, 6, 8].where((i) => b[i].isEmpty).toList();
    if (corners.isNotEmpty) return corners[Random().nextInt(corners.length)];
    return b.indexOf('');
  }

  void _tap(int i) {
    if (!_humanTurn || _b[i].isNotEmpty || _result.isNotEmpty) return;
    setState(() {
      _b[i] = 'X';
      _humanTurn = false;
    });
    _check();
    if (_result.isNotEmpty) return;
    Timer(const Duration(milliseconds: 400), () {
      if (!mounted || _result.isNotEmpty) return;
      setState(() => _b[_aiMove(_b)] = 'O');
      _check();
      if (_result.isEmpty) setState(() => _humanTurn = true);
    });
  }

  void _check() {
    final w = _winner(_b);
    if (w.isEmpty) return;
    setState(() => _result = w == 'X' ? 'win' : w == 'O' ? 'lose' : 'draw');
    if (w == 'X') {
      final t = AppScope.of(context).talents;
      final earned = t.finishTTT();
      showTalentsEarned(context, earned, note: 'Tic-Tac-Toe');
      claimBadges(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppScope.of(context).talents;
    return Scaffold(
      appBar: AppBar(
          title: const Text('Tic-Tac-Toe'), actions: const [TalentsChip()]),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            _result == 'win'
                ? '✓ You beat the machine.'
                : _result == 'lose'
                    ? 'The machine holds the line. Run it back.'
                    : _result == 'draw'
                        ? 'A draw — nobody blinked.'
                        : 'You are ✕. Beat the app for ${t.tttRewardAvailable ? '+15 (first win today).' : 'the glory — today\'s payout is claimed.'}',
            style: const TextStyle(
                color: AppConfig.slate700, height: 1.5, fontSize: 14),
          ),
          const SizedBox(height: 16),
          Center(
            child: SizedBox(
              width: 250,
              height: 250,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8),
                itemCount: 9,
                itemBuilder: (context, i) => InkWell(
                  onTap: () => _tap(i),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _b[i].isEmpty ? Colors.white : null,
                      gradient: _b[i].isEmpty
                          ? null
                          : _b[i] == 'X'
                              ? AppConfig.heroGradient
                              : null,
                      border: Border.all(
                          color: _b[i].isEmpty
                              ? AppConfig.slate200
                              : Colors.transparent),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _b[i] == 'X'
                          ? '✕'
                          : _b[i] == 'O'
                              ? '◯'
                              : '',
                      style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w800,
                          color: _b[i] == 'X'
                              ? Colors.white
                              : AppConfig.deepNavy),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_result.isNotEmpty)
            FilledButton(onPressed: _reset, child: const Text('New game')),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Follow the Pattern — Simon. Watch the tiles flash, repeat the sequence.
// The sequence grows every round. Reach round 5 for +15 (first each day);
// best round tracked forever.
// ---------------------------------------------------------------------------

class SimonScreen extends StatefulWidget {
  const SimonScreen({super.key});
  @override
  State<SimonScreen> createState() => _SimonScreenState();
}

class _SimonScreenState extends State<SimonScreen> {
  static const colors = [Color(0xFF3B82F6), Color(0xFF10B981),
      Color(0xFFD4A845), Color(0xFF7B6FB8)];
  final _rng = Random();
  List<int> _seq = [];
  int _inputPos = 0;
  int _lit = -1;
  bool _watching = false;
  bool _running = false;
  bool _over = false;

  int get _round => _seq.length;

  void _start() {
    setState(() {
      _seq = [];
      _running = true;
      _over = false;
    });
    _nextRound();
  }

  void _nextRound() {
    _seq.add(_rng.nextInt(4));
    _inputPos = 0;
    _playback();
  }

  Future<void> _playback() async {
    final timing = AppScope.of(context).talents.simonTiming;
    setState(() => _watching = true);
    for (final c in _seq) {
      if (!mounted) return;
      setState(() => _lit = c);
      await Future.delayed(Duration(milliseconds: timing.flash));
      if (!mounted) return;
      setState(() => _lit = -1);
      await Future.delayed(Duration(milliseconds: timing.gap));
    }
    if (mounted) setState(() => _watching = false);
  }

  void _press(int c) {
    if (_watching || !_running || _over) return;
    setState(() => _lit = c);
    Timer(const Duration(milliseconds: 200), () {
      if (mounted) setState(() => _lit = -1);
    });
    if (c != _seq[_inputPos]) {
      _end();
      return;
    }
    _inputPos++;
    if (_inputPos == _seq.length) {
      final t = AppScope.of(context).talents;
      if (_round == 5) {
        final earned = t.finishSimon(_round);
        showTalentsEarned(context, earned, note: 'Follow the Pattern');
        claimBadges(context);
      }
      Timer(const Duration(milliseconds: 650), () {
        if (mounted && _running) _nextRound();
      });
    }
  }

  void _end() {
    final completed = _round - 1;
    AppScope.of(context).talents.finishSimon(completed);
    setState(() {
      _running = false;
      _over = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppScope.of(context).talents;
    return Scaffold(
      appBar: AppBar(
          title: const Text('Follow the Pattern'),
          actions: const [TalentsChip()]),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            !_running
                ? _over
                    ? 'The pattern broke at round $_round. Best: ${t.simonBest}.'
                    : 'Watch the tiles light up, then repeat the sequence. It grows every round. Reach round 5 for ${t.simonRewardAvailable ? '+15.' : 'the record — today\'s payout is claimed.'} Best: ${t.simonBest}.'
                : _watching
                    ? '👀 Watch… round $_round'
                    : '🖐️ Your turn — repeat ${_seq.length} step${_seq.length == 1 ? '' : 's'}.',
            style: const TextStyle(
                color: AppConfig.slate700, height: 1.5, fontSize: 14),
          ),
          const SizedBox(height: 18),
          Center(
            child: SizedBox(
              width: 250,
              height: 250,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10),
                itemCount: 4,
                itemBuilder: (context, i) => InkWell(
                  onTap: () => _press(i),
                  borderRadius: BorderRadius.circular(16),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    decoration: BoxDecoration(
                      color:
                          colors[i].withOpacity(_lit == i ? 1.0 : 0.35),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: _lit == i
                          ? [
                              BoxShadow(
                                  color: colors[i].withOpacity(0.6),
                                  blurRadius: 18)
                            ]
                          : null,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          SpeedChips(
            value: t.simonSpeed,
            enabled: !_running,
            onChanged: (v) => setState(() =>
                AppScope.of(context).talents.setSimonSpeed(v)),
          ),
          const SizedBox(height: 12),
          Center(
            child: FilledButton(
              onPressed: _watching ? null : _start,
              child: Text(_running ? 'Restart' : _over ? 'Run it back' : 'Start'),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Coin Catch — 30 seconds, coins pop up on a 3×3 board; tap them before they
// hop away. 15+ catches pays +15 (first each day); best score tracked.
// ---------------------------------------------------------------------------

class CoinCatchScreen extends StatefulWidget {
  const CoinCatchScreen({super.key});
  @override
  State<CoinCatchScreen> createState() => _CoinCatchScreenState();
}

class _CoinCatchScreenState extends State<CoinCatchScreen> {
  static const roundSeconds = 30;
  final _rng = Random();
  int _coin = -1;
  int _score = 0;
  int _secondsLeft = roundSeconds;
  bool _running = false;
  bool _over = false;
  bool _calibrating = false;
  int _calibStage = 0; // 0 none, 1 probing at 700ms, 2 confirming at tier hop
  int _calibRounds = 0; // total measurement rounds this session (cap 3)
  static const calibRoundCap = 3;
  String _provisional = '';
  int _stage2Hop = 700;
  String _calibResult = '';
  Timer? _hop;
  Timer? _clock;

  @override
  void dispose() {
    _hop?.cancel();
    _clock?.cancel();
    super.dispose();
  }

  void _start({bool calibrate = false}) {
    final continuing = calibrate && _calibStage == 2;
    setState(() {
      _running = true;
      _over = false;
      _calibrating = calibrate;
      if (calibrate && !continuing) {
        _calibStage = 1;
        _calibRounds = 0;
        _provisional = '';
      }
      _calibResult = '';
      _score = 0;
      _secondsLeft = calibrate ? 10 : roundSeconds;
      _coin = _rng.nextInt(9);
    });
    final hopMs = !calibrate
        ? AppScope.of(context).talents.coinHopMs
        : continuing
            ? _stage2Hop // round 2 measures at the provisional tier's hop
            : 700; // round 1 probes at the standard hop
    _hop?.cancel();
    _hop = Timer.periodic(Duration(milliseconds: hopMs), (_) {
      if (!mounted) return;
      setState(() => _coin = _rng.nextInt(9));
    });
    _clock?.cancel();
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) _end();
    });
  }

  void _end() {
    _hop?.cancel();
    _clock?.cancel();
    final t = AppScope.of(context).talents;
    if (_calibrating) {
      _calibRounds++;
      if (_calibStage == 1) {
        final rec = TalentsState.recommendCoinSpeed(_score);
        setState(() {
          _running = false;
          _over = false;
          _provisional = rec;
          _stage2Hop = TalentsState.coinTimings[rec] ?? 700;
          _calibStage = 2; // waits for the player to start round 2
        });
        return;
      }
      final rec = TalentsState.refineCoinSpeed(
          _provisional, _score, _stage2Hop);
      // If the measurement moved the tier and we still have budget, confirm
      // once more at the NEW tier — so a wildly wrong probe can travel two
      // tiers inside one 🎯 session instead of needing a second session.
      if (rec != _provisional && _calibRounds < calibRoundCap) {
        setState(() {
          _running = false;
          _over = false;
          _provisional = rec;
          _stage2Hop = TalentsState.coinTimings[rec] ?? 700;
          _calibStage = 2;
        });
        return;
      }
      t.setCoinSpeed(rec);
      setState(() {
        _running = false;
        _over = false;
        _calibrating = false;
        _calibStage = 0;
        _calibRounds = 0;
        _calibResult = rec;
      });
      return; // no payout, no best — calibration is a measurement
    }
    final earned = t.finishCoin(_score);
    setState(() {
      _running = false;
      _over = true;
    });
    showTalentsEarned(context, earned, note: 'Coin Catch');
    claimBadges(context);
  }

  void _tapCell(int i) {
    if (!_running) return;
    if (i == _coin) {
      setState(() {
        _score++;
        _coin = _rng.nextInt(9);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppScope.of(context).talents;
    return Scaffold(
      appBar: AppBar(
          title: const Text('Coin Catch'), actions: const [TalentsChip()]),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            _running
                ? (_calibrating
                    ? '🎯 Round ${_calibStage == 2 ? 2 : 1} of 2… $_secondsLeft s — just catch what you can!'
                    : 'Catch! $_secondsLeft s left')
                : _calibStage == 2
                    ? '🎯 Round $_calibRounds: $_score catches → trying ${SpeedChips.labels[_provisional]}. One more 10-second round at that speed to ${_calibRounds >= calibRoundCap - 1 ? 'lock it in' : 'confirm'}.'
                    : _calibResult.isNotEmpty
                    ? '🎯 You caught $_score in 10s — set to ${SpeedChips.labels[_calibResult]}. Same +15 at every speed.'
                    : _over
                        ? '⏱️ Time! You caught $_score of ${t.coinThreshold} needed. Best: ${t.coinBest}.${_score >= t.coinThreshold ? '' : ' Tip: a slower speed needs fewer catches — same +15.'}'
                        : '30 seconds. Tap the 🪙 before it hops away. Catch ${t.coinThreshold}+ for ${t.coinRewardAvailable ? '+15.' : 'the record — today\'s payout is claimed.'} Best: ${t.coinBest}.',
            style: const TextStyle(
                color: AppConfig.slate700, height: 1.5, fontSize: 14),
          ),
          const SizedBox(height: 10),
          if (_running)
            Text('Score: $_score',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 22)),
          const SizedBox(height: 10),
          Center(
            child: SizedBox(
              width: 260,
              height: 260,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8),
                itemCount: 9,
                itemBuilder: (context, i) => InkWell(
                  onTap: () => _tapCell(i),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: AppConfig.slate200),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(_running && i == _coin ? '🪙' : '',
                        style: const TextStyle(fontSize: 34)),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SpeedChips(
            value: t.coinSpeed,
            enabled: !_running,
            onChanged: (v) => setState(() =>
                AppScope.of(context).talents.setCoinSpeed(v)),
          ),
          const SizedBox(height: 12),
          Center(
            child: Wrap(
              spacing: 10,
              alignment: WrapAlignment.center,
              children: [
                FilledButton(
                    onPressed: _running ? null : _start,
                    child: Text(_over ? 'Run it back' : 'Start')),
                OutlinedButton(
                    onPressed:
                        _running ? null : () => _start(calibrate: true),
                    child: Text(_calibStage == 2
                        ? '🎯 Start round ${_calibRounds + 1}'
                        : '🎯 Find my speed (2×10s)')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


// ---------------------------------------------------------------------------
// Speed selector — Relaxed / Standard / Quick, persisted per game.
// ---------------------------------------------------------------------------

class SpeedChips extends StatelessWidget {
  final String value;
  final bool enabled;
  final ValueChanged<String> onChanged;
  const SpeedChips(
      {super.key,
      required this.value,
      required this.enabled,
      required this.onChanged});

  static const labels = {
    'gentle': '🐌 Gentle',
    'relaxed': '🐢 Relaxed',
    'standard': '⚖️ Standard',
    'quick': '⚡ Quick',
  };

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      alignment: WrapAlignment.center,
      children: [
        for (final e in labels.entries)
          ChoiceChip(
            label: Text(e.value, style: const TextStyle(fontSize: 12.5)),
            selected: value == e.key,
            onSelected:
                enabled ? (sel) => onChanged(e.key) : null,
            selectedColor: AppConfig.primary,
            labelStyle: TextStyle(
                color: value == e.key ? Colors.white : AppConfig.deepNavy,
                fontWeight: FontWeight.w600),
          ),
      ],
    );
  }
}

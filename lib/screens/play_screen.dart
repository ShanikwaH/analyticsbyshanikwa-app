import 'dart:math';

import 'package:flutter/material.dart';

import '../app_config.dart';
import '../main.dart';
import '../models.dart';
import '../widgets/common.dart';
import 'badges_screen.dart';
import 'ledger_screen.dart';
import 'lightning_screen.dart';
import 'match_game_screen.dart';
import 'arcade2_screens.dart';
import 'arcade_screens.dart';
import 'gauntlet_screen.dart';
import 'word_search_screen.dart';
import 'number_crunch_screen.dart';
import 'order_game_screen.dart';
import 'template_trivia_screen.dart';
import 'who_am_i_screen.dart';
import 'tf_drill_screen.dart';
import 'vault_screen.dart';
import 'verse_game_screen.dart';

/// The Play hub — the app's main selling point. Seven surfaces, one economy:
/// Daily Challenge, three quiz decks, Scripture Memory, Lightning Round,
/// Story Match, the badge gallery, and the reward unlock.
class PlayScreen extends StatelessWidget {
  const PlayScreen({super.key});

  Map<String, List<QuizQuestion>> _decksFor(AppContent c) {
    final all = <String, List<QuizQuestion>>{};
    void add(String k) {
      final qs = c.quizzes[k];
      if (qs != null && qs.isNotEmpty) all[k] = qs;
    }

    if (AppConfig.isFull || AppConfig.niche == AppNiche.bible) add('bible');
    if (AppConfig.isFull || AppConfig.niche == AppNiche.accounting) {
      add('accounting');
    }
    if (AppConfig.isFull || AppConfig.niche == AppNiche.data) add('data');
    return all;
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final t = scope.talents;
    final decks = _decksFor(scope.content);

    const deckMeta = {
      'bible': ('✝️', 'Bible Story Quiz'),
      'accounting': ('🧾', 'Accounting & CPA Drill'),
      'data': ('📊', 'Data Analytics Drill'),
    };

    final showStoriesGames =
        AppConfig.isFull || AppConfig.niche == AppNiche.bible;

    return Scaffold(
      appBar: AppBar(title: const Text('Play'), actions: const [TalentsChip()]),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Eyebrow('Put your talents to work'),
          const SizedBox(height: 8),
          const Text(
            'Daily plays reset every morning. First-time answers pay forever. Rank up, collect badges, unlock the reward.',
            style: TextStyle(color: AppConfig.slate700, height: 1.5),
          ),
          const SizedBox(height: 16),

          const Eyebrow('Today & this week'), const SizedBox(height: 10),
          // ---- Daily Challenge ----
          _DailyChallengeCard(decks: decks),
          const SizedBox(height: 12),

          // ---- Weekly Quest ----
          _WeeklyQuestCard(t: t),
          const SizedBox(height: 12),

          // ---- Quiz decks ----
          const Eyebrow('Arcade — real games'), const SizedBox(height: 10),

          // ---- Word Search ----
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _PlayTile(
              emoji: '🔎',
              title: 'Word Search',
              subtitle: t.wordSearchRewardAvailable
                  ? 'Six hidden ${AppConfig.niche == AppNiche.accounting ? 'accounting terms' : AppConfig.niche == AppNiche.data ? 'data terms' : 'Bible names'} in a 9×9 grid · +15 today'
                  : 'Today\'s payout claimed · play for practice',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => WordSearchScreen(
                      nicheKey: AppConfig.niche == AppNiche.accounting
                          ? 'accounting'
                          : AppConfig.niche == AppNiche.data
                              ? 'data'
                              : 'bible',
                      title: 'Word Search'))),
            ),
          ),

          // ---- Memory Flip ----
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _PlayTile(
              emoji: '🎴',
              title: 'Memory Flip',
              subtitle: t.memoryRewardAvailable
                  ? 'Classic pairs — flip, remember, match · +15 today'
                  : 'Today\'s payout claimed · play for practice',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const MemoryFlipScreen())),
            ),
          ),

          // ---- Number Slide ----
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _PlayTile(
              emoji: '🔢',
              title: 'Number Slide',
              subtitle: t.slideRewardAvailable
                  ? 'The classic 3×3 sliding puzzle · +15 on a solve'
                  : 'Today\'s payout claimed · play for practice',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const SlidePuzzleScreen())),
            ),
          ),

          // ---- Letter Hunt ----
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _PlayTile(
              emoji: '🔤',
              title: 'Letter Hunt',
              subtitle: t.guessRewardAvailable
                  ? 'Guess the hidden term, six lives · +15 today'
                  : 'Today\'s payout claimed · play for practice',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => WordGuessScreen(
                      nicheKey: AppConfig.niche == AppNiche.accounting
                          ? 'accounting'
                          : AppConfig.niche == AppNiche.data
                              ? 'data'
                              : 'bible'))),
            ),
          ),

          // ---- Tic-Tac-Toe ----
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _PlayTile(
              emoji: '⭕',
              title: 'Tic-Tac-Toe',
              subtitle: t.tttRewardAvailable
                  ? 'Beat the app · win > block > center, can you? · +15 today'
                  : 'Today\'s payout claimed · play for glory',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const TicTacToeScreen())),
            ),
          ),

          // ---- Follow the Pattern ----
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _PlayTile(
              emoji: '🎵',
              title: 'Follow the Pattern',
              subtitle: t.simonRewardAvailable
                  ? 'Watch, remember, repeat · reach round 5 for +15 · Best: ${t.simonBest}'
                  : 'Today\'s payout claimed · Best: ${t.simonBest}',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const SimonScreen())),
            ),
          ),

          // ---- Coin Catch ----
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _PlayTile(
              emoji: '🪙',
              title: 'Coin Catch',
              subtitle: t.coinRewardAvailable
                  ? '30 seconds of tap reflexes · catch 15+ for +15 · Best: ${t.coinBest}'
                  : 'Today\'s payout claimed · Best: ${t.coinBest}',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const CoinCatchScreen())),
            ),
          ),

          const Eyebrow('Drills & decks'), const SizedBox(height: 10),
          for (final e in decks.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _DeckCard(
                nicheKey: e.key,
                emoji: deckMeta[e.key]?.$1 ?? '❓',
                title: deckMeta[e.key]?.$2 ?? e.key,
                questions: e.value,
              ),
            ),

          // ---- Scripture Memory ----
          if (showStoriesGames)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _PlayTile(
                emoji: '🧠',
                title: 'Scripture Memory Challenge',
                subtitle:
                    '${t.masteredVerses.length} of ${scope.content.verses.length} verses mastered · +15 each',
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const VerseGameScreen())),
              ),
            ),

          // ---- Lightning Round ----
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _PlayTile(
              emoji: '⚡',
              title: 'Lightning Round',
              subtitle: t.lightningRewardAvailable
                  ? '60 seconds, every deck · +2 per correct today · Best: ${t.lightningBest}'
                  : 'Today\'s payout claimed · Best: ${t.lightningBest}',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => LightningScreen(decks: decks))),
            ),
          ),

          // ---- Ledger Lines (accounting) / Data Signals (data) ----
          if (AppConfig.isFull || AppConfig.niche == AppNiche.accounting)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _PlayTile(
                emoji: '⚖️',
                title: 'Ledger Lines',
                subtitle:
                    'True or false, debit or credit — call it · +5 per first-time correct',
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const TFDrillScreen(
                        nicheKey: 'accounting', title: 'Ledger Lines'))),
              ),
            ),
          if (AppConfig.isFull || AppConfig.niche == AppNiche.data)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _PlayTile(
                emoji: '📡',
                title: 'Data Signals',
                subtitle:
                    'True or false — trust the statistic or call the bluff · +5 each',
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const TFDrillScreen(
                        nicheKey: 'data', title: 'Data Signals'))),
              ),
            ),

          // ---- Number Crunch ----
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _PlayTile(
              emoji: '🧮',
              title: 'Number Crunch',
              subtitle: t.crunchPaidLeftToday > 0
                  ? 'Fresh generated problems · first ${t.crunchPaidLeftToday} today pay +5 each'
                  : 'Paid out for today · endless practice mode',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const NumberCrunchScreen())),
            ),
          ),

          // ---- The Gauntlet ----
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _PlayTile(
              emoji: '⚔️',
              title: 'The Gauntlet',
              subtitle: t.gauntletRewardAvailable
                  ? '10 in a row, no mistakes · +30 today · Best: ${t.gauntletBest}'
                  : 'Conquered today · Best: ${t.gauntletBest}',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => GauntletScreen(decks: decks))),
            ),
          ),

          // ---- Order the Story ----
          if (showStoriesGames)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _PlayTile(
                emoji: '⏳',
                title: 'Order the Story',
                subtitle: t.orderRewardAvailable
                    ? 'Put five events in biblical order · +15 today'
                    : 'Today\'s payout claimed · play for practice',
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const OrderGameScreen())),
              ),
            ),

          // ---- Who Am I? ----
          if (showStoriesGames)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _PlayTile(
                emoji: '🕵️',
                title: 'Who Am I?',
                subtitle:
                    '${t.whoAnswered.length} of ${scope.content.whoAmI.length} characters solved · 3 clues each · +5',
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const WhoAmIScreen())),
              ),
            ),

          // ---- Story Match ----
          if (showStoriesGames)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _PlayTile(
                emoji: '🃏',
                title: 'Story Match',
                subtitle: t.matchRewardAvailable
                    ? 'Match stories to their scriptures · +15 today'
                    : 'Today\'s payout claimed · play for practice',
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const MatchGameScreen())),
              ),
            ),

          // ---- Template Trivia ----
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _PlayTile(
              emoji: '🛍️',
              title: 'Template Trivia',
              subtitle:
                  '${t.triviaAnswered.length} of ${scope.content.templateTrivia.length} known · every answer is a real template feature · +5',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const TemplateTriviaScreen())),
            ),
          ),

          const Eyebrow('Records & rewards'), const SizedBox(height: 10),
          // ---- Badges ----
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _PlayTile(
              emoji: '🏅',
              title: 'Steward\'s Badges',
              subtitle:
                  '${t.badges.length} of ${TalentsBadgeCount.total} earned · +25 each',
              onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const BadgesScreen())),
            ),
          ),

          // ---- Talents Ledger ----
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _PlayTile(
              emoji: '📒',
              title: 'Talents Ledger',
              subtitle:
                  'Every Talent earned, posted and reconciled — numbers tie, even here',
              onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LedgerScreen())),
            ),
          ),

          // ---- Rewards Vault ----
          Container(
            decoration: BoxDecoration(
              gradient: AppConfig.heroGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const VaultScreen())),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Text(t.rewardUnlocked ? '🏆' : '🔐',
                          style: const TextStyle(fontSize: 30)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Rewards Vault',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16.5)),
                            const SizedBox(height: 4),
                            Text(
                              t.rewardUnlocked
                                  ? 'Reward unlocked — every download in one place.'
                                  : '${t.talents} / 250 Talents · every download in one place. Earn every badge, earn the reward.',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  height: 1.4),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyQuestCard extends StatelessWidget {
  final dynamic t;
  const _WeeklyQuestCard({required this.t});

  @override
  Widget build(BuildContext context) {
    final int progress = t.weekProgress;
    final bool claimed = t.weeklyQuestClaimed;
    return SectionCard(
      child: Row(
        children: [
          Text(claimed ? '🏁' : '🗺️', style: const TextStyle(fontSize: 30)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(claimed ? 'Weekly Quest — complete' : 'Weekly Quest',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: (progress / 5).clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: AppConfig.slate200,
                    color: AppConfig.secondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  claimed
                      ? '+75 banked. Fresh quest Monday.'
                      : '$progress / 5 different activities this week · +75 on completion',
                  style: const TextStyle(
                      color: AppConfig.slate500, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TalentsBadgeCount {
  static const total = 10;
}

// ---------------------------------------------------------------------------

class _PlayTile extends StatelessWidget {
  final String emoji, title, subtitle;
  final VoidCallback onTap;
  const _PlayTile(
      {required this.emoji,
      required this.title,
      required this.subtitle,
      required this.onTap});
  @override
  Widget build(BuildContext context) {
    return SectionCard(
      onTap: onTap,
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 30)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: const TextStyle(
                        color: AppConfig.slate500, fontSize: 13)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppConfig.slate500),
        ],
      ),
    );
  }
}

class _DailyChallengeCard extends StatelessWidget {
  final Map<String, List<QuizQuestion>> decks;
  const _DailyChallengeCard({required this.decks});

  @override
  Widget build(BuildContext context) {
    final t = AppScope.of(context).talents;
    final done = t.dailyDoneToday;
    return Container(
      decoration: BoxDecoration(
        gradient: AppConfig.heroGradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: done
              ? null
              : () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => DailyChallengeScreen(decks: decks))),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Text(done ? '✅' : '🎯', style: const TextStyle(fontSize: 30)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        done ? 'Daily Challenge — done' : 'Daily Challenge',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16.5),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        done
                            ? '${t.dailyCount} completed. New question tomorrow.'
                            : 'One question. Double reward: +20 Talents. Once a day.',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 13, height: 1.4),
                      ),
                    ],
                  ),
                ),
                if (!done)
                  const Icon(Icons.chevron_right, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One random question drawn from all available decks — unanswered questions
/// first so the challenge always teaches something new when it can.
class DailyChallengeScreen extends StatefulWidget {
  final Map<String, List<QuizQuestion>> decks;
  const DailyChallengeScreen({super.key, required this.decks});
  @override
  State<DailyChallengeScreen> createState() => _DailyChallengeScreenState();
}

class _DailyChallengeScreenState extends State<DailyChallengeScreen> {
  String? _deckKey;
  int _qIndex = -1;
  int? _picked;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final t = AppScope.of(context).talents;
    final rng = Random();
    final candidates = <(String, int)>[];
    final fallback = <(String, int)>[];
    for (final e in widget.decks.entries) {
      for (var i = 0; i < e.value.length; i++) {
        fallback.add((e.key, i));
        if (!t.answeredQuestions.contains('${e.key}:$i')) {
          candidates.add((e.key, i));
        }
      }
    }
    final pool = candidates.isNotEmpty ? candidates : fallback;
    if (pool.isNotEmpty) {
      final pick = pool[rng.nextInt(pool.length)];
      _deckKey = pick.$1;
      _qIndex = pick.$2;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppScope.of(context).talents;
    final q = (_deckKey == null || _qIndex < 0)
        ? null
        : widget.decks[_deckKey]![_qIndex];

    return Scaffold(
      appBar: AppBar(
          title: const Text('Daily Challenge'),
          actions: const [TalentsChip()]),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: q == null
            ? const Center(child: Text('No questions available.'))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Eyebrow('One shot · double reward'),
                  const SizedBox(height: 12),
                  Text(q.q,
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          height: 1.3)),
                  const SizedBox(height: 20),
                  for (var i = 0; i < q.options.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 9),
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
                        onPressed: _picked != null
                            ? null
                            : () {
                                setState(() => _picked = i);
                                final correct = i == q.answer;
                                final earned =
                                    t.completeDailyChallenge(correct);
                                if (correct) {
                                  // First-time deck credit too.
                                  t.markQuizCorrect(_deckKey!, _qIndex);
                                }
                                showTalentsEarned(context, earned,
                                    note: 'Daily Challenge');
                                claimBadges(context);
                              },
                        child: Text(q.options[i],
                            style: const TextStyle(fontSize: 15)),
                      ),
                    ),
                  const Spacer(),
                  if (_picked != null)
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(_picked == q.answer
                          ? 'Nailed it — back to Play'
                          : 'Tomorrow\'s another shot — back to Play'),
                    ),
                ],
              ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _DeckCard extends StatelessWidget {
  final String nicheKey, emoji, title;
  final List<QuizQuestion> questions;
  const _DeckCard(
      {required this.nicheKey,
      required this.emoji,
      required this.title,
      required this.questions});

  @override
  Widget build(BuildContext context) {
    final t = AppScope.of(context).talents;
    final done = List.generate(questions.length, (i) => i)
        .where((i) => t.answeredQuestions.contains('$nicheKey:$i'))
        .length;
    return SectionCard(
      onTap: questions.isEmpty
          ? null
          : () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => QuizScreen(
                  nicheKey: nicheKey, title: title, questions: questions))),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 30)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: questions.isEmpty ? 0 : done / questions.length,
                    minHeight: 6,
                    backgroundColor: AppConfig.slate200,
                    color: AppConfig.secondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text('$done / ${questions.length} mastered · +10 each',
                    style: const TextStyle(
                        color: AppConfig.slate500, fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppConfig.slate500),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class QuizScreen extends StatefulWidget {
  final String nicheKey, title;
  final List<QuizQuestion> questions;
  const QuizScreen(
      {super.key,
      required this.nicheKey,
      required this.title,
      required this.questions});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late final List<int> _order;
  int _pos = 0;
  int _correct = 0;
  int? _picked;

  @override
  void initState() {
    super.initState();
    _order = List.generate(widget.questions.length, (i) => i)
      ..shuffle(Random());
  }

  @override
  Widget build(BuildContext context) {
    if (_pos >= _order.length) {
      return _ResultView(widget: widget, correct: _correct);
    }

    final qi = _order[_pos];
    final q = widget.questions[qi];
    final answered = _picked != null;

    return Scaffold(
      appBar:
          AppBar(title: Text(widget.title), actions: const [TalentsChip()]),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Question ${_pos + 1} of ${_order.length}',
                style: const TextStyle(
                    color: AppConfig.slate500, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Text(q.q,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w700, height: 1.3)),
            const SizedBox(height: 20),
            for (var i = 0; i < q.options.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
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
                    foregroundColor: answered && (i == q.answer || i == _picked)
                        ? Colors.white
                        : AppConfig.deepNavy,
                  ),
                  onPressed: answered
                      ? null
                      : () {
                          setState(() => _picked = i);
                          if (i == q.answer) {
                            _correct++;
                            final earned = AppScope.of(context)
                                .talents
                                .markQuizCorrect(widget.nicheKey, qi);
                            showTalentsEarned(context, earned);
                            claimBadges(context);
                          }
                        },
                  child: Text(q.options[i],
                      style: const TextStyle(fontSize: 15)),
                ),
              ),
            const Spacer(),
            if (answered)
              FilledButton(
                onPressed: () => setState(() {
                  _pos++;
                  _picked = null;
                }),
                child:
                    Text(_pos + 1 >= _order.length ? 'See results' : 'Next'),
              ),
          ],
        ),
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  final QuizScreen widget;
  final int correct;
  const _ResultView({required this.widget, required this.correct});

  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context).content;
    final niche = widget.nicheKey == 'bible' ? 'bible' : widget.nicheKey;
    final match = c.products.where((p) => p.niche == niche).toList();
    final product = match.isNotEmpty ? match.first : null;
    final pct = widget.questions.isEmpty
        ? 0
        : (correct * 100 / widget.questions.length).round();

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
            Text('$correct of ${widget.questions.length} correct',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppConfig.slate500)),
            const SizedBox(height: 28),
            if (product != null)
              SectionCard(
                onTap: () => openLink(context, product.payhipUrl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Eyebrow('Keep building'),
                    const SizedBox(height: 8),
                    Text('${product.emoji}  ${product.title} — ${product.price}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(height: 6),
                    Text(product.summary,
                        style: const TextStyle(
                            color: AppConfig.slate700, height: 1.5)),
                  ],
                ),
              ),
            const Spacer(),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Back to Play'),
            ),
          ],
        ),
      ),
    );
  }
}

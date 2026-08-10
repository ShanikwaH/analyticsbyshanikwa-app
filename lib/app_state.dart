import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The Talents economy — the gamification core, named for the parable that
/// anchors the brand. Every earn is recorded in the Talents Ledger, because
/// this is a brand where numbers tie.
///
/// Earning rules:
///   Read a story ................ +5   (first time per story)
///   Quiz question correct ....... +10  (first time per question)
///   True/False call correct ..... +5   (first time per statement)
///   Verse mastered .............. +15  (first time per verse)
///   Daily Stewardship Audit ..... +20  (once per calendar day)
///   7-day audit streak bonus .... +50
///   Daily Challenge correct ..... +20  (once per calendar day)
///   Lightning Round ............. +2 per correct (first run each day)
///   Story Match completed ....... +15  (once per calendar day)
///   Order the Story completed ... +15  (once per calendar day)
///   Weekly Quest (5 activities) . +75  (once per calendar week)
///   Badge unlocked .............. +25 each (10 badges = 250 = the reward)
class TalentsState extends ChangeNotifier {
  static const readReward = 5;
  static const quizReward = 10;
  static const tfReward = 5;
  static const verseReward = 15;
  static const auditReward = 20;
  static const streakBonus = 50;
  static const dailyReward = 20;
  static const lightningPerCorrect = 2;
  static const matchReward = 15;
  static const orderReward = 15;
  static const weeklyQuestReward = 75;
  static const weeklyQuestTarget = 5;
  static const badgeReward = 25;
  static const whoReward = 5;
  static const triviaReward = 5;
  static const crunchReward = 5;
  static const crunchDailyPaidCap = 5;
  static const gauntletReward = 30;
  static const gauntletTarget = 10;
  static const arcadeReward = 15;

  int talents = 0;
  int auditStreak = 0;
  String lastAuditDay = '';
  Set<String> readStories = {};
  Set<String> answeredQuestions = {}; // "niche:index"
  Set<String> tfAnswered = {}; // "tf:niche:index"
  Set<String> masteredVerses = {};
  List<String> auditLog = [];

  // Play-tab feature state.
  String lastDailyDay = '';
  int dailyCount = 0;
  int lightningBest = 0;
  String lastLightningDay = '';
  String lastMatchDay = '';
  String lastOrderDay = '';
  Set<String> badges = {};

  // Weekly Quest.
  String questWeek = '';
  Set<String> weekActivities = {};
  Set<String> questWeeksClaimed = {};

  // Talents Ledger: "YYYY-MM-DD|label|amount|balance", newest first.
  List<String> ledger = [];

  // Round-3 Play features.
  Set<String> whoAnswered = {}; // "who:index"
  Set<String> triviaAnswered = {}; // "trivia:index"
  String crunchDay = '';
  int crunchPaidCount = 0;
  String lastGauntletDay = '';
  int gauntletBest = 0;
  String lastWordSearchDay = '';
  String lastMemoryDay = '';
  String lastSlideDay = '';
  String lastGuessDay = '';
  String lastTTTDay = '';
  String lastSimonDay = '';
  int simonBest = 0;
  String lastCoinDay = '';
  int coinBest = 0;
  String simonSpeed = 'standard'; // relaxed | standard | quick
  String coinSpeed = 'standard';

  SharedPreferences? _prefs;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final p = _prefs!;
    talents = p.getInt('talents') ?? 0;
    auditStreak = p.getInt('auditStreak') ?? 0;
    lastAuditDay = p.getString('lastAuditDay') ?? '';
    readStories = (p.getStringList('readStories') ?? []).toSet();
    answeredQuestions = (p.getStringList('answeredQuestions') ?? []).toSet();
    tfAnswered = (p.getStringList('tfAnswered') ?? []).toSet();
    masteredVerses = (p.getStringList('masteredVerses') ?? []).toSet();
    auditLog = p.getStringList('auditLog') ?? [];
    lastDailyDay = p.getString('lastDailyDay') ?? '';
    dailyCount = p.getInt('dailyCount') ?? 0;
    lightningBest = p.getInt('lightningBest') ?? 0;
    lastLightningDay = p.getString('lastLightningDay') ?? '';
    lastMatchDay = p.getString('lastMatchDay') ?? '';
    lastOrderDay = p.getString('lastOrderDay') ?? '';
    badges = (p.getStringList('badges') ?? []).toSet();
    questWeek = p.getString('questWeek') ?? '';
    weekActivities = (p.getStringList('weekActivities') ?? []).toSet();
    questWeeksClaimed = (p.getStringList('questWeeksClaimed') ?? []).toSet();
    ledger = p.getStringList('ledger') ?? [];
    whoAnswered = (p.getStringList('whoAnswered') ?? []).toSet();
    triviaAnswered = (p.getStringList('triviaAnswered') ?? []).toSet();
    crunchDay = p.getString('crunchDay') ?? '';
    crunchPaidCount = p.getInt('crunchPaidCount') ?? 0;
    lastGauntletDay = p.getString('lastGauntletDay') ?? '';
    gauntletBest = p.getInt('gauntletBest') ?? 0;
    lastWordSearchDay = p.getString('lastWordSearchDay') ?? '';
    lastMemoryDay = p.getString('lastMemoryDay') ?? '';
    lastSlideDay = p.getString('lastSlideDay') ?? '';
    lastGuessDay = p.getString('lastGuessDay') ?? '';
    lastTTTDay = p.getString('lastTTTDay') ?? '';
    lastSimonDay = p.getString('lastSimonDay') ?? '';
    simonBest = p.getInt('simonBest') ?? 0;
    lastCoinDay = p.getString('lastCoinDay') ?? '';
    coinBest = p.getInt('coinBest') ?? 0;
    simonSpeed = p.getString('simonSpeed') ?? 'standard';
    coinSpeed = p.getString('coinSpeed') ?? 'standard';
    notifyListeners();
  }

  Future<void> _save() async {
    final p = _prefs;
    if (p == null) return;
    await p.setInt('talents', talents);
    await p.setInt('auditStreak', auditStreak);
    await p.setString('lastAuditDay', lastAuditDay);
    await p.setStringList('readStories', readStories.toList());
    await p.setStringList('answeredQuestions', answeredQuestions.toList());
    await p.setStringList('tfAnswered', tfAnswered.toList());
    await p.setStringList('masteredVerses', masteredVerses.toList());
    await p.setStringList('auditLog', auditLog.take(60).toList());
    await p.setString('lastDailyDay', lastDailyDay);
    await p.setInt('dailyCount', dailyCount);
    await p.setInt('lightningBest', lightningBest);
    await p.setString('lastLightningDay', lastLightningDay);
    await p.setString('lastMatchDay', lastMatchDay);
    await p.setString('lastOrderDay', lastOrderDay);
    await p.setStringList('badges', badges.toList());
    await p.setString('questWeek', questWeek);
    await p.setStringList('weekActivities', weekActivities.toList());
    await p.setStringList('questWeeksClaimed', questWeeksClaimed.toList());
    await p.setStringList('ledger', ledger.take(200).toList());
    await p.setStringList('whoAnswered', whoAnswered.toList());
    await p.setStringList('triviaAnswered', triviaAnswered.toList());
    await p.setString('crunchDay', crunchDay);
    await p.setInt('crunchPaidCount', crunchPaidCount);
    await p.setString('lastGauntletDay', lastGauntletDay);
    await p.setInt('gauntletBest', gauntletBest);
    await p.setString('lastWordSearchDay', lastWordSearchDay);
    await p.setString('lastMemoryDay', lastMemoryDay);
    await p.setString('lastSlideDay', lastSlideDay);
    await p.setString('lastGuessDay', lastGuessDay);
    await p.setString('lastTTTDay', lastTTTDay);
    await p.setString('lastSimonDay', lastSimonDay);
    await p.setInt('simonBest', simonBest);
    await p.setString('lastCoinDay', lastCoinDay);
    await p.setInt('coinBest', coinBest);
    await p.setString('simonSpeed', simonSpeed);
    await p.setString('coinSpeed', coinSpeed);
  }

  static String _dayKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  static String get _today => _dayKey(DateTime.now());

  /// ISO-ish week key: year + week number (Mon-start).
  static String _weekKeyOf(DateTime d) {
    final jan1 = DateTime(d.year, 1, 1);
    final week = ((d.difference(jan1).inDays + jan1.weekday) / 7).ceil();
    return '${d.year}-W${week.toString().padLeft(2, '0')}';
  }

  static String get _thisWeek => _weekKeyOf(DateTime.now());

  // ---- Ledger + Weekly Quest bookkeeping ----

  void _credit(int amount, String label) {
    talents += amount;
    ledger.insert(0, '$_today|$label|$amount|$talents');
    if (ledger.length > 200) ledger.removeRange(200, ledger.length);
  }

  /// Records an activity type toward this week's quest. Auto-awards +75 the
  /// moment the 5th distinct activity lands (once per week). Returns the quest
  /// bonus earned (0 or 75) so callers can toast it.
  int _recordActivity(String type) {
    if (questWeek != _thisWeek) {
      questWeek = _thisWeek;
      weekActivities = {};
    }
    weekActivities.add(type);
    if (weekActivities.length >= weeklyQuestTarget &&
        !questWeeksClaimed.contains(questWeek)) {
      questWeeksClaimed.add(questWeek);
      _credit(weeklyQuestReward, 'Weekly Quest complete');
      return weeklyQuestReward;
    }
    return 0;
  }

  int get weekProgress =>
      questWeek == _thisWeek ? weekActivities.length : 0;
  bool get weeklyQuestClaimed => questWeeksClaimed.contains(_thisWeek);

  // ---- Core earning actions (all idempotent; all return TOTAL earned
  //      including any weekly-quest bonus triggered) ----

  int markStoryRead(String storyId) {
    if (storyId.isEmpty || readStories.contains(storyId)) return 0;
    readStories.add(storyId);
    _credit(readReward, 'Story read');
    final bonus = _recordActivity('story');
    _save();
    notifyListeners();
    return readReward + bonus;
  }

  int markQuizCorrect(String niche, int index) {
    final key = '$niche:$index';
    int earned = 0;
    if (!answeredQuestions.contains(key)) {
      answeredQuestions.add(key);
      _credit(quizReward, 'Quiz correct');
      earned = quizReward;
    }
    earned += _recordActivity('quiz');
    _save();
    notifyListeners();
    return earned;
  }

  int markTFCorrect(String niche, int index) {
    final key = 'tf:$niche:$index';
    int earned = 0;
    if (!tfAnswered.contains(key)) {
      tfAnswered.add(key);
      _credit(tfReward, 'True/False correct');
      earned = tfReward;
    }
    earned += _recordActivity('tf');
    _save();
    notifyListeners();
    return earned;
  }

  int markVerseMastered(String verseId) {
    if (verseId.isEmpty || masteredVerses.contains(verseId)) return 0;
    masteredVerses.add(verseId);
    _credit(verseReward, 'Verse mastered');
    final bonus = _recordActivity('verse');
    _save();
    notifyListeners();
    return verseReward + bonus;
  }

  bool get auditDoneToday => lastAuditDay == _today;

  int completeAudit(String given, String produced, String buried, String next) {
    if (auditDoneToday) return 0;
    final yesterday = _dayKey(DateTime.now().subtract(const Duration(days: 1)));
    auditStreak = (lastAuditDay == yesterday) ? auditStreak + 1 : 1;
    lastAuditDay = _today;
    _credit(auditReward, 'Stewardship Audit');
    int earned = auditReward;
    if (auditStreak > 0 && auditStreak % 7 == 0) {
      _credit(streakBonus, '$auditStreak-day streak bonus');
      earned += streakBonus;
    }
    auditLog.insert(0,
        '$_today|${_clean(given)}|${_clean(produced)}|${_clean(buried)}|${_clean(next)}');
    earned += _recordActivity('audit');
    _save();
    notifyListeners();
    return earned;
  }

  static String _clean(String s) => s.replaceAll('|', '/').trim();

  // ---- Daily Challenge ----

  bool get dailyDoneToday => lastDailyDay == _today;

  int completeDailyChallenge(bool correct) {
    if (dailyDoneToday) return 0;
    lastDailyDay = _today;
    int earned = 0;
    if (correct) {
      dailyCount++;
      _credit(dailyReward, 'Daily Challenge');
      earned = dailyReward + _recordActivity('daily');
    }
    _save();
    notifyListeners();
    return earned;
  }

  // ---- Lightning Round ----

  bool get lightningRewardAvailable => lastLightningDay != _today;

  int finishLightning(int score) {
    int earned = 0;
    if (lightningRewardAvailable && score > 0) {
      earned = score * lightningPerCorrect;
      _credit(earned, 'Lightning Round ($score correct)');
      lastLightningDay = _today;
      earned += _recordActivity('lightning');
    }
    if (score > lightningBest) lightningBest = score;
    _save();
    notifyListeners();
    return earned;
  }

  // ---- Story Match ----

  bool get matchRewardAvailable => lastMatchDay != _today;

  int finishMatch() {
    if (!matchRewardAvailable) return 0;
    lastMatchDay = _today;
    _credit(matchReward, 'Story Match');
    final earned = matchReward + _recordActivity('match');
    _save();
    notifyListeners();
    return earned;
  }

  // ---- Order the Story ----

  bool get orderRewardAvailable => lastOrderDay != _today;

  int finishOrder() {
    if (!orderRewardAvailable) return 0;
    lastOrderDay = _today;
    _credit(orderReward, 'Order the Story');
    final earned = orderReward + _recordActivity('order');
    _save();
    notifyListeners();
    return earned;
  }

  // ---- Who Am I? ----

  int markWhoCorrect(int index) {
    final key = 'who:$index';
    int earned = 0;
    if (!whoAnswered.contains(key)) {
      whoAnswered.add(key);
      _credit(whoReward, 'Who Am I? solved');
      earned = whoReward;
    }
    earned += _recordActivity('whoami');
    _save();
    notifyListeners();
    return earned;
  }

  // ---- Template Trivia ----

  int markTriviaCorrect(int index) {
    final key = 'trivia:$index';
    int earned = 0;
    if (!triviaAnswered.contains(key)) {
      triviaAnswered.add(key);
      _credit(triviaReward, 'Template Trivia');
      earned = triviaReward;
    }
    earned += _recordActivity('trivia');
    _save();
    notifyListeners();
    return earned;
  }

  // ---- Number Crunch ----

  int get crunchPaidLeftToday {
    if (crunchDay != _today) return crunchDailyPaidCap;
    return (crunchDailyPaidCap - crunchPaidCount).clamp(0, crunchDailyPaidCap);
  }

  /// +5 per correct for the first 5 correct answers each day; free play after.
  int crunchCorrect() {
    if (crunchDay != _today) {
      crunchDay = _today;
      crunchPaidCount = 0;
    }
    int earned = 0;
    if (crunchPaidCount < crunchDailyPaidCap) {
      crunchPaidCount++;
      _credit(crunchReward, 'Number Crunch');
      earned = crunchReward;
    }
    earned += _recordActivity('crunch');
    _save();
    notifyListeners();
    return earned;
  }

  // ---- The Gauntlet ----

  bool get gauntletRewardAvailable => lastGauntletDay != _today;

  /// Records a finished run. A run of [gauntletTarget]+ pays +30 (first win
  /// each day). Best run is tracked forever.
  int finishGauntlet(int streak) {
    int earned = 0;
    if (streak >= gauntletTarget && gauntletRewardAvailable) {
      lastGauntletDay = _today;
      _credit(gauntletReward, 'Gauntlet conquered');
      earned = gauntletReward + _recordActivity('gauntlet');
    }
    if (streak > gauntletBest) gauntletBest = streak;
    _save();
    notifyListeners();
    return earned;
  }

  // ---- Arcade games (Word Search, Memory Flip, Number Slide, Letter Hunt) ----

  bool get wordSearchRewardAvailable => lastWordSearchDay != _today;
  bool get memoryRewardAvailable => lastMemoryDay != _today;
  bool get slideRewardAvailable => lastSlideDay != _today;
  bool get guessRewardAvailable => lastGuessDay != _today;

  int _finishArcade(String which, String label) {
    switch (which) {
      case 'wordsearch':
        if (lastWordSearchDay == _today) return 0;
        lastWordSearchDay = _today;
      case 'memory':
        if (lastMemoryDay == _today) return 0;
        lastMemoryDay = _today;
      case 'slide':
        if (lastSlideDay == _today) return 0;
        lastSlideDay = _today;
      case 'wordguess':
        if (lastGuessDay == _today) return 0;
        lastGuessDay = _today;
      case 'tictactoe':
        if (lastTTTDay == _today) return 0;
        lastTTTDay = _today;
      case 'simon':
        if (lastSimonDay == _today) return 0;
        lastSimonDay = _today;
      case 'coincatch':
        if (lastCoinDay == _today) return 0;
        lastCoinDay = _today;
    }
    _credit(arcadeReward, label);
    final earned = arcadeReward + _recordActivity(which);
    _save();
    notifyListeners();
    return earned;
  }

  int finishWordSearch() => _finishArcade('wordsearch', 'Word Search');
  int finishMemory() => _finishArcade('memory', 'Memory Flip');
  int finishSlide() => _finishArcade('slide', 'Number Slide');
  int finishGuess() => _finishArcade('wordguess', 'Letter Hunt');

  bool get tttRewardAvailable => lastTTTDay != _today;
  int finishTTT() => _finishArcade('tictactoe', 'Tic-Tac-Toe win');

  bool get simonRewardAvailable => lastSimonDay != _today;

  /// Round 5 reached pays +15 (first time each day); best round tracked.
  int finishSimon(int round) {
    int earned = 0;
    if (round >= 5) earned = _finishArcade('simon', 'Follow the Pattern');
    if (round > simonBest) {
      simonBest = round;
      _save();
      notifyListeners();
    }
    return earned;
  }

  /// Game-speed presets. Same +15 payout at every speed — the daily cap
  /// already prevents farming, and the point is feel, not difficulty gating.
  static const simonTimings = {
    'gentle': (flash: 850, gap: 340),
    'relaxed': (flash: 650, gap: 260),
    'standard': (flash: 450, gap: 180),
    'quick': (flash: 300, gap: 120),
  };
  static const coinTimings = {
    'gentle': 1300,
    'relaxed': 950,
    'standard': 700,
    'quick': 500,
  };

  /// Effort-normalized payout thresholds. Slower hops mean fewer coins per
  /// 30s round, so a flat "catch 15" would quietly punish slow modes:
  /// gentle ≈23 spawns, quick ≈60. These keep the required catch-rate in a
  /// narrow band (~40–50%), so every speed is winnable and none is a farm.
  static const coinThresholds = {
    'gentle': 10,
    'relaxed': 12,
    'standard': 15,
    'quick': 18,
  };

  static const tierOrder = ['gentle', 'relaxed', 'standard', 'quick'];

  /// Stage 1 of calibration: a 10-second round at the standard 700ms hop
  /// (~14 spawns) maps raw catches to a PROVISIONAL tier. Pure, testable.
  static String recommendCoinSpeed(int catchesIn10s) {
    if (catchesIn10s >= 11) return 'quick';
    if (catchesIn10s >= 8) return 'standard';
    if (catchesIn10s >= 5) return 'relaxed';
    return 'gentle';
  }

  /// Stage 2: a second 10-second round AT the provisional tier's own hop.
  /// The 700ms probe understates slow players (3 catches at 700ms says
  /// nothing about what they can do at 1300ms), so this re-measures where
  /// they'll actually play: catch-rate ≥80% of that hop's spawns moves one
  /// tier faster, ≤35% moves one slower, otherwise the tier is confirmed.
  /// Clamped at both ends. Pure, testable.
  static String refineCoinSpeed(
      String provisional, int catches, int hopMs) {
    final spawns = 10000 / hopMs;
    var i = tierOrder.indexOf(provisional);
    if (i < 0) i = 2;
    final rate = catches / spawns;
    if (rate >= 0.8 && i < tierOrder.length - 1) {
      i++;
    } else if (rate <= 0.35 && i > 0) {
      i--;
    }
    return tierOrder[i];
  }

  ({int flash, int gap}) get simonTiming =>
      simonTimings[simonSpeed] ?? simonTimings['standard']!;
  int get coinHopMs => coinTimings[coinSpeed] ?? 700;
  int get coinThreshold => coinThresholds[coinSpeed] ?? 15;

  void setSimonSpeed(String v) {
    if (!simonTimings.containsKey(v)) return;
    simonSpeed = v;
    _save();
    notifyListeners();
  }

  void setCoinSpeed(String v) {
    if (!coinTimings.containsKey(v)) return;
    coinSpeed = v;
    _save();
    notifyListeners();
  }

  bool get coinRewardAvailable => lastCoinDay != _today;

  /// Meeting the speed's threshold pays +15 (first time each day);
  /// best tracked. Threshold is effort-normalized per speed.
  int finishCoin(int score) {
    int earned = 0;
    if (score >= coinThreshold) {
      earned = _finishArcade('coincatch', 'Coin Catch');
    }
    if (score > coinBest) {
      coinBest = score;
      _save();
      notifyListeners();
    }
    return earned;
  }

  // ---- Steward's Badges ----
  // Ten badges × 25 = 250 Talents: the trophy case alone is a complete path
  // to the Five Talents reward. Market it exactly that way.

  static const badgeDefs = [
    ('first_story', '📖', 'First Steps', 'Read your first Bible story'),
    ('ten_stories', '🕮', 'Bookworm', 'Read 10 stories'),
    ('all_stories', '📜', 'Scroll Scholar', 'Read all 30 stories'),
    ('ten_correct', '🧠', 'Sharp Mind', 'Answer 10 quiz questions correctly'),
    ('deck_master', '🏛️', 'Deck Master', 'Master every question in a deck'),
    ('verse_three', '🗝️', 'Verse Keeper', 'Master 3 verses'),
    ('verse_all', '💎', 'Hidden Word', 'Master every verse'),
    ('streak_seven', '🔥', 'Faithful Auditor', 'Hit a 7-day audit streak'),
    ('daily_five', '🍞', 'Daily Bread', 'Complete 5 Daily Challenges'),
    ('lightning_ten', '⚡', 'Lightning Steward', 'Score 10+ in a Lightning Round'),
  ];

  List<String> claimNewBadges(Map<String, int> deckSizes) {
    final newly = <String>[];
    void tryAdd(String id, String title, bool cond) {
      if (cond && !badges.contains(id)) {
        badges.add(id);
        _credit(badgeReward, 'Badge: $title');
        newly.add(title);
      }
    }

    bool anyDeckMastered() {
      for (final e in deckSizes.entries) {
        if (e.value == 0) continue;
        final done = answeredQuestions
            .where((k) => k.startsWith('${e.key}:'))
            .length;
        if (done >= e.value) return true;
      }
      return false;
    }

    tryAdd('first_story', 'First Steps', readStories.isNotEmpty);
    tryAdd('ten_stories', 'Bookworm', readStories.length >= 10);
    tryAdd('all_stories', 'Scroll Scholar', readStories.length >= 30);
    tryAdd('ten_correct', 'Sharp Mind', answeredQuestions.length >= 10);
    tryAdd('deck_master', 'Deck Master', anyDeckMastered());
    tryAdd('verse_three', 'Verse Keeper', masteredVerses.length >= 3);
    tryAdd('verse_all', 'Hidden Word',
        masteredVerses.length >= 10 && masteredVerses.isNotEmpty);
    tryAdd('streak_seven', 'Faithful Auditor', auditStreak >= 7);
    tryAdd('daily_five', 'Daily Bread', dailyCount >= 5);
    tryAdd('lightning_ten', 'Lightning Steward', lightningBest >= 10);

    if (newly.isNotEmpty) {
      _save();
      notifyListeners();
    }
    return newly;
  }

  // ---- Steward ranks ----
  static const ranks = [
    (0, 'Faithful in Little'),
    (100, 'Two Talents'),
    (250, 'Five Talents'),
    (500, 'Ruler Over Much'),
    (1000, 'Well Done, Good & Faithful'),
  ];

  String get rank {
    var name = ranks.first.$2;
    for (final r in ranks) {
      if (talents >= r.$1) name = r.$2;
    }
    return name;
  }

  int? get nextRankAt {
    for (final r in ranks) {
      if (talents < r.$1) return r.$1;
    }
    return null;
  }

  bool get rewardUnlocked => talents >= 250;
}

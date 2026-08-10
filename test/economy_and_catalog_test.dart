// Run with:  flutter test
//
// This suite does two jobs:
//  1. Compiling it forces full compilation of models.dart and app_state.dart —
//     so `flutter test` passing means the app builds beyond static checks.
//  2. It verifies the Talents economy math and the real-catalog content
//     contract (bundled files exist, Payhip URLs live in content.json, etc.)
//     without needing a device or emulator.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'dart:math';

import 'package:analyticsbyshanikwa_app/app_state.dart';
import 'package:analyticsbyshanikwa_app/games/word_search_gen.dart';
import 'package:analyticsbyshanikwa_app/models.dart';

void main() {
  group('Talents economy', () {
    test('daily challenge pays +20 once and locks for the day', () {
      final t = TalentsState();
      final first = t.completeDailyChallenge(true);
      expect(first, TalentsState.dailyReward);
      expect(t.dailyDoneToday, isTrue);
      expect(t.completeDailyChallenge(true), 0);
      expect(t.talents, TalentsState.dailyReward);
    });

    test('number crunch caps paid plays at 5 per day', () {
      final t = TalentsState();
      var earned = 0;
      for (var i = 0; i < 8; i++) {
        earned += t.crunchCorrect();
      }
      expect(earned, TalentsState.crunchReward * TalentsState.crunchDailyPaidCap);
      expect(t.crunchPaidLeftToday, 0);
    });

    test('gauntlet pays +30 on a 10-streak, once per day, best tracked', () {
      final t = TalentsState();
      expect(t.finishGauntlet(9), 0); // short run: no payout
      expect(t.gauntletBest, 9);
      expect(t.finishGauntlet(10), TalentsState.gauntletReward);
      expect(t.finishGauntlet(12), 0); // same day: record only
      expect(t.gauntletBest, 12);
    });

    test('weekly quest fires +75 exactly on the 5th distinct activity', () {
      final t = TalentsState();
      t.markStoryRead('s01'); // story
      t.markQuizCorrect('bible', 0); // quiz
      t.markTFCorrect('accounting', 0); // tf
      t.markVerseMastered('v01'); // verse
      final before = t.talents;
      final earned = t.crunchCorrect(); // crunch = 5th distinct
      expect(earned,
          TalentsState.crunchReward + TalentsState.weeklyQuestReward);
      expect(t.talents, before + earned);
      expect(t.weeklyQuestClaimed, isTrue);
      // 6th distinct activity must not double-pay the quest.
      expect(t.finishOrder(), TalentsState.orderReward);
    });

    test('idempotent earns never double-pay', () {
      final t = TalentsState();
      t.markStoryRead('s01');
      expect(t.markStoryRead('s01'), 0);
      t.markQuizCorrect('bible', 3);
      // Repeat pays 0 base (any weekly-quest bonus is separate and one-time).
      final repeat = t.markQuizCorrect('bible', 3);
      expect(repeat == 0 || repeat == TalentsState.weeklyQuestReward, isTrue);
      t.markWhoCorrect(2);
      expect(
          t.whoAnswered.contains('who:2') &&
              !t.whoAnswered.contains('who:3'),
          isTrue);
    });

    test('all ten badges pay exactly 250 — the reward threshold', () {
      expect(TalentsState.badgeDefs.length, 10);
      expect(TalentsState.badgeDefs.length * TalentsState.badgeReward, 250);
      final t = TalentsState();
      expect(t.rewardUnlocked, isFalse);
      t.talents = 250;
      expect(t.rewardUnlocked, isTrue);
      expect(t.rank, 'Five Talents');
    });

    test('every credit posts to the ledger with a running balance', () {
      final t = TalentsState();
      t.markStoryRead('s01');
      t.markVerseMastered('v01');
      expect(t.ledger.length, greaterThanOrEqualTo(2));
      final newest = t.ledger.first.split('|');
      expect(newest.length, 4);
      expect(int.parse(newest[3]), t.talents); // balance ties
    });
  });

  group('Word Search generator — deterministic placement', () {
    test('500 boards × 3 word banks: every word placed, every time', () {
      final banks = [
        ['JAEL', 'JONAH', 'ELIJAH', 'SAMUEL', 'HANNAH', 'SOLOMON'],
        ['DEBIT', 'CREDIT', 'ASSET', 'EQUITY', 'LEDGER', 'ACCRUAL'],
        ['MEAN', 'MEDIAN', 'QUERY', 'PIVOT', 'CHART', 'OUTLIER'],
      ];
      final rng = Random(42);
      for (var run = 0; run < 500; run++) {
        final bank = banks[run % 3];
        final board = generateWordSearch(bank, 9, rng);
        expect(board.words.length, bank.length,
            reason: 'run $run dropped a word');
        expect(board.placements.length, bank.length);
        // Every placement actually spells its word on the grid.
        for (final e in board.placements.entries) {
          final spelled = e.value
              .map((i) => board.grid[i ~/ 9][i % 9])
              .join();
          expect(spelled, e.key);
        }
      }
    });

    test('snapRun: drag snaps to straight lines and clamps to the board', () {
      // horizontal drift snaps flat: (0,0) → (1,5) is dominated by columns
      expect(snapRun(0, 1 * 9 + 5, 9), [0, 1, 2, 3, 4, 5]);
      // vertical drift snaps upright: (0,0) → (5,1)
      expect(snapRun(0, 5 * 9 + 1, 9), [0, 9, 18, 27, 36, 45]);
      // diagonal stays diagonal: (0,0) → (4,4)
      expect(snapRun(0, 4 * 9 + 4, 9), [0, 10, 20, 30, 40]);
      // reverse diagonal from bottom-right corner
      expect(snapRun(80, 4 * 9 + 4, 9), [80, 70, 60, 50, 40]);
      // clamp: diagonal aimed off the far edge stays on the board
      final run = snapRun(6, 8 * 9 + 14, 9); // impossible target col
      expect(run.every((i) => i >= 0 && i < 81), isTrue);
      // single cell drag = just that cell (tap fallback territory)
      expect(snapRun(40, 40, 9), [40]);
    });

    test('fallback path: pathological bank still places everything', () {
      // Words engineered to collide constantly on a tiny board.
      final board =
          generateWordSearch(['AAAAAAAAA', 'AAAAAAAAB', 'BAAAAAAAA'], 9,
              Random(7));
      expect(board.words.length, 3);
      expect(board.placements.length, 3);
    });
  });

  group('New arcade finishers', () {
    test('tic-tac-toe pays +15 once per day', () {
      final t = TalentsState();
      expect(t.finishTTT(), TalentsState.arcadeReward);
      expect(t.finishTTT(), 0);
    });
    test('simon pays at round 5+, tracks best', () {
      final t = TalentsState();
      expect(t.finishSimon(4), 0);
      expect(t.simonBest, 4);
      expect(t.finishSimon(5), TalentsState.arcadeReward);
      expect(t.finishSimon(7), 0); // same day
      expect(t.simonBest, 7);
    });
    test('speed presets: three per game, standard default, setters guard', () {
      final t = TalentsState();
      expect(t.simonSpeed, 'standard');
      expect(t.coinSpeed, 'standard');
      expect(TalentsState.simonTimings.length, 3);
      expect(TalentsState.coinTimings.length, 3);
      // relaxed slower than standard slower than quick
      expect(TalentsState.coinTimings['relaxed']!,
          greaterThan(TalentsState.coinTimings['standard']!));
      expect(TalentsState.coinTimings['standard']!,
          greaterThan(TalentsState.coinTimings['quick']!));
      expect(TalentsState.simonTimings['relaxed']!.flash,
          greaterThan(TalentsState.simonTimings['quick']!.flash));
      t.setCoinSpeed('quick');
      expect(t.coinHopMs, TalentsState.coinTimings['quick']);
      t.setCoinSpeed('bogus'); // ignored
      expect(t.coinSpeed, 'quick');
      t.setSimonSpeed('relaxed');
      expect(t.simonTiming.flash, 650);
    });

    test('coin catch pays at its speed threshold, tracks best', () {
      final t = TalentsState();
      expect(t.coinThreshold, 15); // standard default
      expect(t.finishCoin(14), 0);
      expect(t.finishCoin(16), TalentsState.arcadeReward);
      expect(t.coinBest, 16);
    });

    test('four speed tiers, monotone, effort-normalized thresholds', () {
      expect(TalentsState.coinTimings.length, 4);
      expect(TalentsState.simonTimings.length, 4);
      expect(TalentsState.coinTimings['gentle']!,
          greaterThan(TalentsState.coinTimings['relaxed']!));
      expect(TalentsState.simonTimings['gentle']!.flash,
          greaterThan(TalentsState.simonTimings['relaxed']!.flash));
      // fairness: required catch-rate stays under ~55% at every speed
      TalentsState.coinTimings.forEach((speed, hop) {
        final spawns = 30000 / hop;
        final th = TalentsState.coinThresholds[speed]!;
        expect(th / spawns, lessThan(0.55),
            reason: '$speed asks $th of ~${spawns.round()} spawns');
      });
      // thresholds rise with speed — faster modes can't farm cheaper
      expect(TalentsState.coinThresholds['gentle']!,
          lessThan(TalentsState.coinThresholds['relaxed']!));
      expect(TalentsState.coinThresholds['relaxed']!,
          lessThan(TalentsState.coinThresholds['standard']!));
      expect(TalentsState.coinThresholds['standard']!,
          lessThan(TalentsState.coinThresholds['quick']!));
    });

    test('calibration mapping covers the whole range', () {
      expect(TalentsState.recommendCoinSpeed(0), 'gentle');
      expect(TalentsState.recommendCoinSpeed(4), 'gentle');
      expect(TalentsState.recommendCoinSpeed(5), 'relaxed');
      expect(TalentsState.recommendCoinSpeed(7), 'relaxed');
      expect(TalentsState.recommendCoinSpeed(8), 'standard');
      expect(TalentsState.recommendCoinSpeed(10), 'standard');
      expect(TalentsState.recommendCoinSpeed(11), 'quick');
      expect(TalentsState.recommendCoinSpeed(99), 'quick');
    });

    test('stage-2 refinement: re-measures at the tier hop, moves ±1, clamps',
        () {
      // Understated slow player: probe said gentle, but 7 of ~7.7 spawns
      // at gentle's 1300ms hop is a >90% catch rate → refined UP.
      expect(TalentsState.refineCoinSpeed('gentle', 7, 1300), 'relaxed');
      // Truly gentle player: 3 of ~7.7 (39%) → confirmed gentle.
      expect(TalentsState.refineCoinSpeed('gentle', 3, 1300), 'gentle');
      // Struggling even at gentle (≤35%) clamps at the floor.
      expect(TalentsState.refineCoinSpeed('gentle', 2, 1300), 'gentle');
      // Quick player crushing quick (17+ of 20 = 85%) clamps at the top.
      expect(TalentsState.refineCoinSpeed('quick', 18, 500), 'quick');
      // Overstated fast probe: 6 of 20 at quick (30%) → down to standard.
      expect(TalentsState.refineCoinSpeed('quick', 6, 500), 'standard');
      // Mid-band confirms: 8 of ~14.3 at standard (56%) → standard.
      expect(TalentsState.refineCoinSpeed('standard', 8, 700), 'standard');
      // Unknown tier defaults safely to the standard slot.
      expect(TalentsState.refineCoinSpeed('bogus', 8, 700), 'standard');
    });

    test('gentle threshold is reachable and pays', () {
      final t = TalentsState();
      t.setCoinSpeed('gentle');
      expect(t.coinThreshold, 10);
      expect(t.finishCoin(10), TalentsState.arcadeReward);
    });
  });

  group('Real-catalog content contract', () {
    late Map<String, dynamic> raw;
    late AppContent content;

    setUpAll(() {
      raw = jsonDecode(
              File('assets/content/content.json').readAsStringSync())
          as Map<String, dynamic>;
      content = AppContent.fromJson(raw);
    });

    test('all four products carry live Payhip URLs and cover images', () {
      expect(content.products.length, 4);
      for (final p in content.products) {
        expect(p.payhipUrl, startsWith('https://payhip.com/b/'));
        expect(p.image, contains('payhip.com/cdn-cgi'));
        expect(p.price, startsWith('\$'));
      }
    });

    test('every bundled file exists in assets/freebies', () {
      expect(content.bundledFiles.length, 4);
      for (final b in content.bundledFiles) {
        expect(File('assets/freebies/${b.file}').existsSync(), isTrue,
            reason: '${b.file} missing from assets/freebies');
      }
    });

    test('free resources are the four live site downloads', () {
      expect(content.freeResources.length, 4);
      for (final f in content.freeResources) {
        expect(f.url, contains('free-resources.html#'));
      }
    });

    test('fallback URL for bundled-file opening exists', () {
      expect(content.url('free_resources'),
          contains('analyticsbyshanikwa.com'));
      expect(content.url('newsletter'), contains('analyticsbyshanikwa.com'));
    });

    test('who_am_i entries all carry scripture references', () {
      expect(content.whoAmI.length, 10);
      for (final w in content.whoAmI) {
        expect(w.reference.length, greaterThan(3));
        expect(w.clues.length, 3);
        expect(w.options, contains(w.answer));
      }
    });

    test('template trivia only references real product ids', () {
      final ids = content.products.map((p) => p.id).toSet();
      expect(content.templateTrivia.length, 8);
      for (final q in content.templateTrivia) {
        expect(ids, contains(q.pid));
      }
    });

    test('story_order ids all resolve to real stories', () {
      final ids = content.stories.map((s) => s.id).toSet();
      for (final id in content.storyOrder) {
        expect(ids, contains(id));
      }
    });
  });
}

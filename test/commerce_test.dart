import 'dart:convert';
import 'dart:io';

import 'package:analyticsbyshanikwa_app/commerce/purchases.dart';
import 'package:analyticsbyshanikwa_app/models.dart';
import 'package:analyticsbyshanikwa_app/app_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Purchases.sellable — never take money we cannot fulfil', () {
    const ok = {
      'iapEnabled': true,
      'iapId': 'com.example.thing',
      'fulfillmentUrl': 'https://example.com/file.xlsx',
      'storeReady': true,
    };

    bool call(Map<String, Object> m) => Purchases.sellable(
          iapEnabled: m['iapEnabled'] as bool,
          iapId: m['iapId'] as String,
          fulfillmentUrl: m['fulfillmentUrl'] as String,
          storeReady: m['storeReady'] as bool,
        );

    test('all four conditions met -> sellable', () {
      expect(call(ok), isTrue);
    });

    test('master switch off -> not sellable', () {
      expect(call({...ok, 'iapEnabled': false}), isFalse);
    });

    test('no store product id -> not sellable', () {
      expect(call({...ok, 'iapId': ''}), isFalse);
    });

    test('no fulfilment URL -> not sellable, even with a valid product', () {
      // The important one: a product configured in App Store Connect but with
      // nowhere to deliver the file would otherwise charge and deliver nothing.
      expect(call({...ok, 'fulfillmentUrl': ''}), isFalse);
    });

    test('store not reachable -> not sellable', () {
      expect(call({...ok, 'storeReady': false}), isFalse);
    });
  });

  group('content.json commerce config', () {
    late AppContent content;

    setUpAll(() {
      final raw = File('assets/content/content.json').readAsStringSync();
      content = AppContent.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    });

    test('link-out regions are exactly the storefronts that permit it', () {
      // US: Epic injunction, no commission. JP: Mobile Software Competition
      // Act since 2025-12-18, 15% steering commission. Adding a country here
      // that still bans link-outs would ship a Guideline 3.1.1 violation.
      expect(content.linkOutRegions, containsAll(<String>['US', 'JP']));
      for (final banned in ['GB', 'CA', 'AU', 'DE', 'FR']) {
        expect(content.linkOutRegions, isNot(contains(banned)),
            reason: '$banned still bans in-app links out to buy');
      }
    });

    test('IAP stays off until every product is fully configured', () {
      if (!content.iapEnabled) return; // off is always safe
      for (final p in content.products) {
        expect(p.iapId, isNotEmpty,
            reason: '${p.title} has no store product id');
        expect(p.fulfillmentUrl, isNotEmpty,
            reason: '${p.title} has nowhere to deliver the file');
      }
    });

    test('every product still carries app attribution', () {
      for (final p in content.products) {
        expect(p.payhipUrl, contains('utm_source=app'));
        expect(p.payhipUrl, contains('utm_content=${p.id}'));
      }
    });
  });

  // Regression: the link-out region gate exists for Apple's Guideline 3.1.1 and
  // Google Play's payments policy. Applying it on desktop hid the Shop from,
  // say, a Windows user in the UK - satisfying a rule that does not apply to
  // them and costing the sale.
  group('link-out region gate applies only to mobile stores', () {
    final mobile = {TargetPlatform.iOS, TargetPlatform.android};

    tearDown(() => debugDefaultTargetPlatformOverride = null);

    test('desktop platforms always allow linking out, whatever the region', () {
      for (final tp in [
        TargetPlatform.windows,
        TargetPlatform.macOS,
        TargetPlatform.linux,
      ]) {
        debugDefaultTargetPlatformOverride = tp;
        expect(AppConfig.regionGateAppliesForTest, isFalse, reason: '$tp');
        // 'ZZ' can never match the host locale, so this assertion has teeth on
        // any machine — without the desktop carve-out it returns false.
        expect(
          AppConfig.canLinkOut(const ['ZZ']),
          isTrue,
          reason: '$tp must show the Shop regardless of region',
        );
      }
    });

    test('mobile platforms still enforce the gate', () {
      for (final tp in mobile) {
        debugDefaultTargetPlatformOverride = tp;
        expect(AppConfig.regionGateAppliesForTest, isTrue, reason: '$tp');
      }
    });
  });
}

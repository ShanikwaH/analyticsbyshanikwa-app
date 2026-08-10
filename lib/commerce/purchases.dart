import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// In-app purchase for storefronts where linking out to buy is still banned —
/// the UK, Canada, Australia and the EU. In the US and Japan the app links out
/// instead and none of this runs.
///
/// Design notes, because they matter for review and for money:
///
/// * **No server.** Entitlements are stored on-device, matching the rest of the
///   app (no accounts, no backend, no privacy liability). That means we trust
///   the store's own `PurchaseStatus.purchased`. For $15–20 templates that is
///   the normal trade-off; a jailbroken device could fake it. If that ever
///   matters, add server-side receipt validation — the shape here does not
///   change, only `_verify`.
/// * **Restore is mandatory.** Apple rejects apps selling non-consumables
///   without a visible restore control. `restore()` backs that button.
/// * **completePurchase is mandatory.** Skip it and iOS re-delivers the
///   purchase forever and Android auto-refunds after three days.
/// * **Web is a no-op.** `in_app_purchase` has no web implementation, so every
///   entry point returns early under `kIsWeb` rather than throwing.
class Purchases extends ChangeNotifier {
  static const _prefsKey = 'owned_iap_products';

  final Set<String> _owned = {};
  final Map<String, ProductDetails> _details = {};
  StreamSubscription<List<PurchaseDetails>>? _sub;

  /// True once the store has answered and at least one product resolved.
  bool storeReady = false;

  /// Set when the store is reachable but a product id did not resolve — almost
  /// always a console configuration mistake, and worth surfacing rather than
  /// silently showing no buy button.
  final Set<String> missingIds = {};

  bool owns(String iapId) => iapId.isNotEmpty && _owned.contains(iapId);

  /// Localised price string from the store ("£14.99", "A$21.99"), which is what
  /// Apple and Google require you to display — never a hardcoded USD price.
  String? priceOf(String iapId) => _details[iapId]?.price;

  /// Call once at startup with every configured product id.
  Future<void> init(List<String> iapIds) async {
    if (kIsWeb) return;
    final prefs = await SharedPreferences.getInstance();
    _owned.addAll(prefs.getStringList(_prefsKey) ?? const []);
    notifyListeners();

    final ids = iapIds.where((e) => e.isNotEmpty).toSet();
    if (ids.isEmpty) return;

    late final bool available;
    try {
      available = await InAppPurchase.instance.isAvailable();
    } catch (_) {
      return; // no store on this platform (desktop, emulator without Play)
    }
    if (!available) return;

    _sub = InAppPurchase.instance.purchaseStream.listen(
      _onPurchases,
      onError: (_) {},
    );

    final resp = await InAppPurchase.instance.queryProductDetails(ids);
    for (final p in resp.productDetails) {
      _details[p.id] = p;
    }
    missingIds
      ..clear()
      ..addAll(resp.notFoundIDs);
    storeReady = _details.isNotEmpty;
    notifyListeners();
  }

  /// Start a purchase. Returns false if the product never resolved.
  Future<bool> buy(String iapId) async {
    if (kIsWeb) return false;
    final product = _details[iapId];
    if (product == null) return false;
    // Templates are permanent unlocks, so non-consumable.
    await InAppPurchase.instance.buyNonConsumable(
      purchaseParam: PurchaseParam(productDetails: product),
    );
    return true;
  }

  /// Apple requires a user-visible way to restore non-consumables.
  Future<void> restore() async {
    if (kIsWeb) return;
    try {
      await InAppPurchase.instance.restorePurchases();
    } catch (_) {}
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    var changed = false;
    for (final p in purchases) {
      switch (p.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          if (_verify(p)) {
            changed = _owned.add(p.productID) || changed;
          }
          break;
        case PurchaseStatus.error:
        case PurchaseStatus.canceled:
          break;
        case PurchaseStatus.pending:
          continue; // not finished; do NOT complete it yet
      }
      // Every non-pending purchase must be completed or the store keeps
      // re-delivering it (iOS) or refunds it after 3 days (Android).
      if (p.pendingCompletePurchase) {
        await InAppPurchase.instance.completePurchase(p);
      }
    }
    if (changed) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prefsKey, _owned.toList());
      notifyListeners();
    }
  }

  /// The single place to add server-side receipt validation later.
  bool _verify(PurchaseDetails p) => true;

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  // ---- Pure helpers, unit-tested ----

  /// Whether a product can actually be sold in-app right now.
  /// All four conditions must hold, so a half-configured product never shows a
  /// buy button that would take money and deliver nothing.
  static bool sellable({
    required bool iapEnabled,
    required String iapId,
    required String fulfillmentUrl,
    required bool storeReady,
  }) =>
      iapEnabled &&
      iapId.isNotEmpty &&
      fulfillmentUrl.isNotEmpty &&
      storeReady;
}

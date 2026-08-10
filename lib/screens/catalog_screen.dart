import 'package:flutter/material.dart';

import '../app_config.dart';
import '../commerce/purchases.dart';
import '../main.dart';
import '../models.dart';
import '../widgets/common.dart';

/// The full catalog — 115 products across six categories. A plain scrolling
/// list of 115 hero cards would be unusable, so this is search + category
/// chips + compact rows.
class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});
  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final _search = TextEditingController();
  String _category = 'All';
  bool _bundlesOnly = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = AppScope.of(context).content;
    final all = content.catalog;

    final categories = <String>{'All', for (final c in all) c.category}.toList()
      ..sort((a, b) => a == 'All' ? -1 : (b == 'All' ? 1 : a.compareTo(b)));

    final q = _search.text.trim();
    final shown = [
      for (final c in all)
        if ((_category == 'All' || c.category == _category) &&
            (!_bundlesOnly || c.bundle) &&
            c.matches(q))
          c
    ];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search ${all.length} templates…',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: q.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => setState(_search.clear),
                    ),
              isDense: true,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppConfig.slate200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppConfig.slate200),
              ),
            ),
          ),
        ),
        SizedBox(
          height: 46,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              for (final c in categories)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(c),
                    selected: _category == c,
                    onSelected: (_) => setState(() => _category = c),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: const Text('Bundles'),
                  selected: _bundlesOnly,
                  onSelected: (v) => setState(() => _bundlesOnly = v),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Text('${shown.length} of ${all.length}',
                  style: const TextStyle(
                      fontSize: 12, color: AppConfig.slate500)),
            ],
          ),
        ),
        Expanded(
          child: shown.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('Nothing matches that search yet.',
                        style: TextStyle(color: AppConfig.slate500)),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: shown.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _CatalogRow(item: shown[i]),
                ),
        ),
      ],
    );
  }
}

class _CatalogRow extends StatelessWidget {
  final CatalogItem item;
  const _CatalogRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final content = AppScope.of(context).content;
    final canLink = AppConfig.canLinkOut(content.linkOutRegions);
    final purchases = PurchasesScope.of(context);
    final owned = purchases.owns(item.iapId);
    final sellable = Purchases.sellable(
      iapEnabled: content.iapEnabled,
      iapId: item.iapId,
      fulfillmentUrl: item.fulfillmentUrl,
      storeReady: purchases.storeReady,
    );

    // Nothing to offer here: no link-out allowed and no configured IAP.
    if (!canLink && !sellable && !owned) return const SizedBox.shrink();

    return SectionCard(
      onTap: () {
        if (owned) {
          openLink(context, item.fulfillmentUrl);
        } else if (canLink) {
          openLink(context, item.shopifyUrl);
        } else if (sellable) {
          purchases.buy(item.iapId);
        }
      },
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: item.bundle ? AppConfig.heroGradient : null,
              color: item.bundle ? null : const Color(0x14667EEA),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text(
              item.category.substring(0, 1),
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: item.bundle ? Colors.white : AppConfig.indigo,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (item.bundle)
                      const Padding(
                        padding: EdgeInsets.only(right: 6),
                        child: PillTag('BUNDLE'),
                      ),
                    Expanded(
                      child: Text(item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14)),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(item.format,
                    style: const TextStyle(
                        fontSize: 11.5, color: AppConfig.slate500)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                owned ? 'Owned' : (purchases.priceOf(item.iapId) ?? item.price),
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: owned ? AppConfig.insightGreen : AppConfig.primary),
              ),
              Icon(owned ? Icons.download_outlined : Icons.chevron_right,
                  size: 18, color: AppConfig.slate500),
            ],
          ),
        ],
      ),
    );
  }
}

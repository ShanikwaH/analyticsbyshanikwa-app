import 'package:flutter/material.dart';

import '../app_config.dart';
import '../main.dart';
import '../models.dart';
import '../widgets/common.dart';
import 'resources_screen.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final c = scope.content;
    final t = scope.talents;

    // Niche builds lead with their own products but still show the rest.
    final products = List<Product>.from(c.products);
    if (!AppConfig.isFull) {
      final key = AppConfig.niche.name;
      products.sort((a, b) =>
          (b.niche == key ? 1 : 0).compareTo(a.niche == key ? 1 : 0));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Shop'), actions: const [TalentsChip()]),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Eyebrow('Templates built for the work, not the theory'),
          const SizedBox(height: 8),
          const Text(
            'Instant digital downloads. Checkout opens securely on Payhip or Shopify.',
            style: TextStyle(color: AppConfig.slate700, height: 1.5),
          ),
          if (t.rewardUnlocked) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppConfig.heroGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '🏆 Five Talents rank reached — your shop reward is live. Look for the reward note at checkout.',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    height: 1.4),
              ),
            ),
          ],
          const SizedBox(height: 16),
          for (final p in products)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _ProductCard(product: p),
            ),
          const SizedBox(height: 4),
          SectionCard(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const ResourcesScreen(pushed: true))),
            child: const Row(
              children: [
                Text('🎁', style: TextStyle(fontSize: 26)),
                SizedBox(width: 14),
                Expanded(
                  child: Text('Not ready to buy? Grab a free template first.',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
                Icon(Icons.chevron_right, color: AppConfig.slate500),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () => openLink(context, c.url('payhip_store')),
              child: const Text('Browse the full storefront'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(product.emoji, style: const TextStyle(fontSize: 30)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (product.badge.isNotEmpty)
                        PillTag(product.badge,
                            bg: const Color(0x1AD4A845),
                            fg: const Color(0xFF92400E)),
                      Text(product.title,
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
                Text(product.price,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppConfig.primary)),
              ],
            ),
            const SizedBox(height: 10),
            Text(product.summary,
                style:
                    const TextStyle(color: AppConfig.slate700, height: 1.5)),
            const SizedBox(height: 10),
            for (final f in product.features)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check,
                        size: 16, color: AppConfig.insightGreen),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(f,
                            style: const TextStyle(
                                fontSize: 13.5, height: 1.4))),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () => openLink(context, product.payhipUrl),
                    child: Text('Payhip — ${product.price}'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => openLink(context, product.shopifyUrl),
                    child: const Text('Shopify'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../app_config.dart';
import '../main.dart';
import '../widgets/common.dart';

/// The Rewards Vault: every real downloadable in one place — the four paid
/// templates (live Payhip listings, real cover art) and the four free
/// resources (email-gated on the site via Omnisend). At 250 Talents the
/// reward callout unlocks. All ten badges = 250 = the reward: earn every
/// badge, earn the reward.
class VaultScreen extends StatelessWidget {
  const VaultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final t = scope.talents;
    final c = scope.content;
    final unlocked = t.rewardUnlocked;

    return Scaffold(
      appBar: AppBar(
          title: const Text('Rewards Vault'), actions: const [TalentsChip()]),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ---- Reward status ----
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppConfig.heroGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  unlocked
                      ? '🏆 Five Talents rank — reward unlocked'
                      : '🔒 ${t.talents} / 250 Talents',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 17),
                ),
                const SizedBox(height: 6),
                Text(
                  unlocked
                      ? 'Your reward is live in the shop — look for the reward note at checkout on Payhip or Shopify.'
                      : 'Earn every badge, earn the reward: the ten Steward\'s Badges pay exactly 250 Talents — a complete path to the unlock, all by themselves.',
                  style: const TextStyle(color: Colors.white, height: 1.5),
                ),
                if (!unlocked) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: (t.talents / 250).clamp(0.0, 1.0),
                      minHeight: 8,
                      backgroundColor: Colors.white24,
                      color: Colors.white,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),

          // ---- Paid templates (real catalog) ----
          const Eyebrow('The templates — instant downloads'),
          const SizedBox(height: 10),
          for (final p in c.products)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SectionCard(
                onTap: () => openLink(context, p.payhipUrl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (p.image.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          p.image,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const SizedBox.shrink(),
                        ),
                      ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text('${p.emoji}  ${p.title}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15.5)),
                        ),
                        Text(p.price,
                            style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: AppConfig.primary,
                                fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(p.format,
                        style: const TextStyle(
                            color: AppConfig.slate500, fontSize: 12.5)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton(
                            onPressed: () =>
                                openLink(context, p.payhipUrl),
                            child: const Text('Payhip'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () =>
                                openLink(context, p.shopifyUrl),
                            child: const Text('Shopify'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          // ---- Bundled with the app (real files, offline) ----
          const SizedBox(height: 6),
          const Eyebrow('Bundled with the app — yours offline'),
          const SizedBox(height: 10),
          for (final b in c.bundledFiles)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SectionCard(
                onTap: () => openBundledFile(context, b),
                child: Row(
                  children: [
                    Text(b.emoji, style: const TextStyle(fontSize: 26)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(b.title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14.5)),
                          const SizedBox(height: 3),
                          Text('${b.format} · tap to open — offline',
                              style: const TextStyle(
                                  color: AppConfig.slate500,
                                  fontSize: 12.5)),
                        ],
                      ),
                    ),
                    Icon(Icons.open_in_new, color: AppConfig.primary),
                  ],
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.only(bottom: 14, left: 4),
            child: InkWell(
              onTap: () => openLink(
                  context, AppScope.of(context).content.url('newsletter')),
              child: Text(
                '✉️ Want updates to these templates? Join the letter.',
                style: TextStyle(
                    color: AppConfig.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5),
              ),
            ),
          ),
          // ---- Free downloads (real, email-gated on the site) ----
          const SizedBox(height: 6),
          const Eyebrow('Free downloads — via the site'),
          const SizedBox(height: 6),
          const Text(
            'Enter your email on the site and any of these arrives in your inbox instantly, powered by the Sunday-letter list.',
            style: TextStyle(
                color: AppConfig.slate700, fontSize: 13.5, height: 1.5),
          ),
          const SizedBox(height: 10),
          for (final f in c.freeResources)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SectionCard(
                onTap: () => openLink(context, f.url),
                child: Row(
                  children: [
                    Text(f.emoji, style: const TextStyle(fontSize: 26)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(f.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14.5)),
                    ),
                    Icon(Icons.download_outlined,
                        color: AppConfig.primary),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

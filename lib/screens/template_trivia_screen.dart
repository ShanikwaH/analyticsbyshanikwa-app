import 'package:flutter/material.dart';

import '../app_config.dart';
import '../main.dart';
import '../widgets/common.dart';

/// Template Trivia — every question is a real feature of a real product in
/// the live catalog. Answer right for +5; every reveal shows the product card
/// with its live Payhip link. The most honest ad format ever shipped: the
/// game literally teaches the catalog.
class TemplateTriviaScreen extends StatefulWidget {
  const TemplateTriviaScreen({super.key});
  @override
  State<TemplateTriviaScreen> createState() => _TemplateTriviaScreenState();
}

class _TemplateTriviaScreenState extends State<TemplateTriviaScreen> {
  int _index = 0;
  String? _picked;

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final list = scope.content.templateTrivia;
    if (list.isEmpty) {
      return Scaffold(
          appBar: AppBar(title: const Text('Template Trivia')),
          body: const Center(child: Text('No questions loaded.')));
    }
    final q = list[_index];
    final t = scope.talents;
    final productMatches =
        scope.content.products.where((p) => p.id == q.pid).toList();
    final product = productMatches.isNotEmpty ? productMatches.first : null;
    final correctTitle = product?.title ?? '';
    final answered = _picked != null;
    final known = t.triviaAnswered.contains('trivia:$_index');

    return Scaffold(
      appBar: AppBar(
          title: const Text('Template Trivia'),
          actions: const [TalentsChip()]),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${_index + 1} of ${list.length}',
                  style: const TextStyle(
                      color: AppConfig.slate500, fontWeight: FontWeight.w600)),
              if (known) const PillTag('Known'),
            ],
          ),
          const SizedBox(height: 12),
          Text(q.q,
              style: const TextStyle(
                  fontSize: 19, fontWeight: FontWeight.w700, height: 1.35)),
          const SizedBox(height: 18),
          for (final opt in q.options)
            Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  backgroundColor: !answered
                      ? null
                      : opt == correctTitle
                          ? AppConfig.secondary
                          : opt == _picked
                              ? Colors.red.shade400
                              : null,
                  foregroundColor:
                      answered && (opt == correctTitle || opt == _picked)
                          ? Colors.white
                          : AppConfig.deepNavy,
                ),
                onPressed: answered
                    ? null
                    : () {
                        setState(() => _picked = opt);
                        if (opt == correctTitle) {
                          final earned = t.markTriviaCorrect(_index);
                          showTalentsEarned(context, earned,
                              note: 'Template Trivia');
                          claimBadges(context);
                        }
                      },
                child: Text(opt,
                    style: const TextStyle(fontSize: 14.5)),
              ),
            ),
          if (answered && product != null) ...[
            const SizedBox(height: 8),
            SectionCard(
              onTap: () => openLink(context, product.payhipUrl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Eyebrow('The real thing'),
                  const SizedBox(height: 8),
                  Text('${product.emoji}  ${product.title} — ${product.price}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15.5)),
                  const SizedBox(height: 5),
                  Text(product.summary,
                      style: const TextStyle(
                          color: AppConfig.slate700,
                          height: 1.5,
                          fontSize: 13.5)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => setState(() {
                _index = (_index + 1) % list.length;
                _picked = null;
              }),
              child: const Text('Next question'),
            ),
          ],
        ],
      ),
    );
  }
}

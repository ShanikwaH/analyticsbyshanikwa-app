import 'package:flutter/material.dart';

import '../app_config.dart';
import '../main.dart';
import '../widgets/common.dart';

/// The Talents Ledger — every Talent earned, as a running-balance statement.
/// Because this is a brand where numbers tie: the gamification itself keeps
/// books you can audit.
class LedgerScreen extends StatelessWidget {
  const LedgerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppScope.of(context).talents;
    final entries = t.ledger;

    return Scaffold(
      appBar: AppBar(
          title: const Text('Talents Ledger'),
          actions: const [TalentsChip()]),
      body: entries.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No entries yet. Every Talent you earn posts here — dated, labeled, and reconciled to your balance. Go earn the first one.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppConfig.slate500, height: 1.5),
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: AppConfig.heroGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Closing balance',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600)),
                      Text('🪙 ${t.talents}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 20)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: const [
                    Expanded(
                        flex: 5,
                        child: Text('ENTRY',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                                color: AppConfig.slate500))),
                    Expanded(
                        flex: 2,
                        child: Text('CREDIT',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                                color: AppConfig.slate500))),
                    Expanded(
                        flex: 2,
                        child: Text('BALANCE',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                                color: AppConfig.slate500))),
                  ],
                ),
                const Divider(),
                for (final e in entries) _LedgerRow(e),
                const SizedBox(height: 8),
                const Text('Numbers tie. Even here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: AppConfig.slate500,
                        fontStyle: FontStyle.italic,
                        fontSize: 12.5)),
              ],
            ),
    );
  }
}

class _LedgerRow extends StatelessWidget {
  final String raw;
  const _LedgerRow(this.raw);

  @override
  Widget build(BuildContext context) {
    final parts = raw.split('|');
    if (parts.length < 4) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(parts[1],
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13.5)),
                Text(parts[0],
                    style: const TextStyle(
                        color: AppConfig.slate500, fontSize: 11.5)),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text('+${parts[2]}',
                textAlign: TextAlign.right,
                style: const TextStyle(
                    color: AppConfig.insightGreen,
                    fontWeight: FontWeight.w700)),
          ),
          Expanded(
            flex: 2,
            child: Text(parts[3],
                textAlign: TextAlign.right,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

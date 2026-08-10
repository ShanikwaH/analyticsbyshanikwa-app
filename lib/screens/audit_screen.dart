import 'package:flutter/material.dart';

import '../app_config.dart';
import '../main.dart';
import '../widgets/common.dart';

/// The daily Stewardship Audit — the Proverbs 27:23 framework from the site,
/// turned into the app's habit loop. Four questions, one entry per day,
/// +20 Talents (with a +50 bonus every 7-day streak). Entries stay on-device.
class AuditScreen extends StatefulWidget {
  const AuditScreen({super.key});
  @override
  State<AuditScreen> createState() => _AuditScreenState();
}

class _AuditScreenState extends State<AuditScreen> {
  final _controllers = List.generate(4, (_) => TextEditingController());

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    if (_controllers.any((c) => c.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Answer all four — this is where the audit gets honest.')));
      return;
    }
    final t = AppScope.of(context).talents;
    final earned = t.completeAudit(
      _controllers[0].text,
      _controllers[1].text,
      _controllers[2].text,
      _controllers[3].text,
    );
    showTalentsEarned(context, earned,
        note: t.auditStreak % 7 == 0 && earned > 20
            ? '${t.auditStreak}-day streak bonus!'
            : 'audit complete');
    claimBadges(context);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final questions = scope.content.audit;
    final t = scope.talents;

    return Scaffold(
      appBar: AppBar(
          title: const Text('Stewardship Audit'),
          actions: const [TalentsChip()]),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Eyebrow('Proverbs 27:23'),
          const SizedBox(height: 6),
          const Text(
            '"Be thou diligent to know the state of thy flocks." Four questions for the numbers you actually own.',
            style: TextStyle(color: AppConfig.slate700, height: 1.5),
          ),
          const SizedBox(height: 8),
          Text('Current streak: ${t.auditStreak} day${t.auditStreak == 1 ? '' : 's'}',
              style: const TextStyle(
                  color: AppConfig.slate500, fontWeight: FontWeight.w600)),
          const SizedBox(height: 18),
          for (var i = 0; i < questions.length && i < 4; i++) ...[
            Text(questions[i].q,
                style: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 4),
            Text(questions[i].hint,
                style: const TextStyle(
                    color: AppConfig.slate500, fontSize: 13, height: 1.4)),
            const SizedBox(height: 8),
            TextField(
              controller: _controllers[i],
              maxLines: 3,
              minLines: 2,
              decoration: InputDecoration(
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
            const SizedBox(height: 18),
          ],
          FilledButton(
            onPressed: t.auditDoneToday ? null : _submit,
            child: Text(t.auditDoneToday
                ? 'Done for today'
                : 'Complete audit (+20 Talents)'),
          ),
          const SizedBox(height: 28),
          if (t.auditLog.isNotEmpty) ...[
            const Eyebrow('Past audits (on this device)'),
            const SizedBox(height: 10),
            for (final entry in t.auditLog.take(14))
              _AuditLogTile(entry: entry),
          ],
        ],
      ),
    );
  }
}

class _AuditLogTile extends StatelessWidget {
  final String entry;
  const _AuditLogTile({required this.entry});
  @override
  Widget build(BuildContext context) {
    final parts = entry.split('|');
    if (parts.length < 5) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: ExpansionTile(
          shape: const RoundedRectangleBorder(side: BorderSide.none),
          title: Text(parts[0],
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 14)),
          subtitle: Text('Commitment: ${parts[4]}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  const TextStyle(color: AppConfig.slate500, fontSize: 13)),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            _row('Given', parts[1]),
            _row('Produced', parts[2]),
            _row('Buried', parts[3]),
            _row('Next week', parts[4]),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
                width: 90,
                child: Text(label,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13))),
            Expanded(
                child: Text(value,
                    style: const TextStyle(fontSize: 13, height: 1.4))),
          ],
        ),
      );
}

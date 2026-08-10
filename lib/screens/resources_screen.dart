import 'package:flutter/material.dart';

import '../app_config.dart';
import '../main.dart';
import '../widgets/common.dart';

class ResourcesScreen extends StatelessWidget {
  final bool pushed;
  const ResourcesScreen({super.key, this.pushed = false});

  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context).content;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Free Resources'),
        automaticallyImplyLeading: pushed,
        actions: const [TalentsChip()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Eyebrow('Tools for the faithful professional'),
          const SizedBox(height: 8),
          const Text(
            'Enter your email on the site and any of these arrives in your inbox instantly — free.',
            style: TextStyle(color: AppConfig.slate700, height: 1.5),
          ),
          const SizedBox(height: 16),
          const Eyebrow('Bundled with this app — no download needed'),
          const SizedBox(height: 8),
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
                          Text(b.summary,
                              style: const TextStyle(
                                  color: AppConfig.slate500,
                                  fontSize: 12.5,
                                  height: 1.4)),
                        ],
                      ),
                    ),
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
          const SizedBox(height: 10),
          const Eyebrow('More free templates — via the site'),
          const SizedBox(height: 8),
          for (final f in c.freeResources)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SectionCard(
                onTap: () => openLink(context, f.url),
                child: Row(
                  children: [
                    Text(f.emoji, style: const TextStyle(fontSize: 28)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(f.title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text(f.summary,
                              style: const TextStyle(
                                  color: AppConfig.slate500,
                                  height: 1.4,
                                  fontSize: 13.5)),
                        ],
                      ),
                    ),
                    Icon(Icons.download_outlined,
                        color: AppConfig.primary),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          SectionCard(
            onTap: () => openLink(context, c.url('newsletter')),
            child: Row(
              children: [
                Icon(Icons.mail_outline, color: AppConfig.primary, size: 28),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Want them all plus the Sunday letter? Join the list once.',
                    style: TextStyle(fontWeight: FontWeight.w700, height: 1.4),
                  ),
                ),
                Icon(Icons.chevron_right, color: AppConfig.slate500),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

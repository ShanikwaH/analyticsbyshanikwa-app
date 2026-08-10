import 'package:flutter/material.dart';

import '../app_config.dart';
import '../main.dart';
import '../widgets/common.dart';
import 'play_screen.dart';
import 'resources_screen.dart';
import 'shop_screen.dart';
import 'stories_screen.dart';
import 'today_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _meta = {
    'today': (Icons.wb_sunny_outlined, Icons.wb_sunny, 'Today'),
    'stories': (Icons.menu_book_outlined, Icons.menu_book, 'Stories'),
    'play': (Icons.sports_esports_outlined, Icons.sports_esports, 'Play'),
    'shop': (Icons.storefront_outlined, Icons.storefront, 'Shop'),
    'resources': (Icons.card_giftcard_outlined, Icons.card_giftcard, 'Free'),
  };

  Widget _screenFor(String key) {
    switch (key) {
      case 'stories':
        return const StoriesScreen();
      case 'play':
        return const PlayScreen();
      case 'shop':
        return const ShopScreen();
      case 'resources':
        return const ResourcesScreen();
      default:
        return const TodayScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Drop the Shop where store rules forbid linking out to buy. Doing it here
    // rather than restricting the app to the US storefront means the app can be
    // listed in the UK, Canada, Australia and everywhere else — those users get
    // the full free app, and buy on the website instead.
    // Keep the Shop when we can link out (US, Japan) OR when in-app purchase is
    // configured — that is what makes the UK, Canada and Australia sellable.
    final content = AppScope.of(context).content;
    final allowShop = AppConfig.canLinkOut(content.linkOutRegions) ||
        content.iapEnabled;
    final sections = [
      for (final s in AppConfig.sections)
        if (s != 'shop' || allowShop) s,
    ];
    if (_index >= sections.length) _index = 0;
    final wide = MediaQuery.of(context).size.width >= 840;
    final body = _screenFor(sections[_index]);

    if (wide) {
      // Desktop (Windows/macOS) and tablets: navigation rail.
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              labelType: NavigationRailLabelType.all,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: const BrandOrb(size: 40),
              ),
              destinations: [
                for (final s in sections)
                  NavigationRailDestination(
                    icon: Icon(_meta[s]!.$1),
                    selectedIcon: Icon(_meta[s]!.$2),
                    label: Text(_meta[s]!.$3),
                  ),
              ],
            ),
            const VerticalDivider(width: 1, color: AppConfig.slate200),
            Expanded(child: body),
          ],
        ),
      );
    }

    return Scaffold(
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          for (final s in sections)
            NavigationDestination(
              icon: Icon(_meta[s]!.$1),
              selectedIcon: Icon(_meta[s]!.$2),
              label: _meta[s]!.$3,
            ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../app_config.dart';
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
    final sections = AppConfig.sections;
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
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: AppConfig.heroGradient,
                    shape: BoxShape.circle,
                  ),
                ),
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

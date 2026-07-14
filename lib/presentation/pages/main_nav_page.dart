import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../providers/recipe_providers.dart';
import 'home_page.dart';
import 'search_page.dart';
import 'fridge_mode_page.dart';
import 'drinks_page.dart';
import 'favorites_page.dart';
import 'nutrition_lookup_page.dart';

class MainNavPage extends ConsumerStatefulWidget {
  const MainNavPage({super.key});

  @override
  ConsumerState<MainNavPage> createState() => _MainNavPageState();
}

class _MainNavPageState extends ConsumerState<MainNavPage> {
  int _currentIndex = 0;

  final _pages = const [
    HomePage(),
    SearchPage(),
    FridgeModePage(),
    DrinksPage(),
    FavoritesPage(),
  ];

  static const _drinkColor = Color(0xFFE63946);

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(isDarkModeProvider);

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: _pages,
          ),
          // Floating nutrition button
          Positioned(
            right: 16,
            bottom: 80,
            child: FloatingActionButton.small(
              heroTag: 'nutrition_fab',
              backgroundColor: AppColors.primary,
              tooltip: 'Nutrition Lookup',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NutritionLookupPage()),
              ),
              child: const Icon(Icons.food_bank_outlined, color: Colors.white),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(20),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: _currentIndex == 3 ? _drinkColor : AppColors.primary,
          unselectedItemColor: isDark ? Colors.white54 : Colors.black38,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search_outlined),
              activeIcon: Icon(Icons.search_rounded),
              label: 'Search',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.kitchen_outlined),
              activeIcon: Icon(Icons.kitchen_rounded),
              label: 'Fridge',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.local_bar_outlined),
              activeIcon: Icon(Icons.local_bar_rounded),
              label: 'Drinks',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite_border_rounded),
              activeIcon: Icon(Icons.favorite_rounded),
              label: 'Favorites',
            ),
          ],
        ),
      ),
    );
  }
}

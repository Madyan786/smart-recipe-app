import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/cocktail_models.dart';
import '../providers/recipe_providers.dart';
import 'cocktail_detail_page.dart';

class DrinksPage extends ConsumerStatefulWidget {
  const DrinksPage({super.key});

  @override
  ConsumerState<DrinksPage> createState() => _DrinksPageState();
}

class _DrinksPageState extends ConsumerState<DrinksPage> {
  final _searchCtrl = TextEditingController();
  bool _showMocktail = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(isDarkModeProvider);
    final selectedCat = ref.watch(selectedCocktailCategoryProvider);

    return Scaffold(
      body: RefreshIndicator(
        color: const Color(0xFFE63946),
        onRefresh: () async {
          ref.invalidate(randomCocktailProvider);
          ref.invalidate(cocktailCategoriesProvider);
        },
        child: CustomScrollView(
          slivers: [
            _appBar(context, isDark),
            _searchBar(context),
            _searchResults(context),
            if (ref.watch(cocktailSearchQueryProvider).isEmpty) ...[
              _featuredDrink(context),
              _filterRow(context),
              if (selectedCat == null) _categoriesGrid(context) else _categoryDrinks(context),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 30)),
          ],
        ),
      ),
    );
  }

  SliverAppBar _appBar(BuildContext context, bool isDark) {
    return SliverAppBar(
      floating: true,
      snap: true,
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE63946), Color(0xFFFF6B6B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.local_bar_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Text('Drinks Bar',
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(color: const Color(0xFFE63946))),
        ],
      ),
      actions: [
        IconButton(
          tooltip: _showMocktail ? 'Show All' : 'Mocktails Only',
          icon: Icon(
            _showMocktail ? Icons.no_drinks_outlined : Icons.emoji_food_beverage_outlined,
            color: _showMocktail ? const Color(0xFFE63946) : null,
          ),
          onPressed: () => setState(() => _showMocktail = !_showMocktail),
        ),
        const SizedBox(width: 6),
      ],
    );
  }

  Widget _searchBar(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: TextField(
          controller: _searchCtrl,
          onChanged: (v) => ref.read(cocktailSearchQueryProvider.notifier).state = v,
          decoration: InputDecoration(
            hintText: 'Search cocktails, mocktails...',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: _searchCtrl.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded),
                    onPressed: () {
                      _searchCtrl.clear();
                      ref.read(cocktailSearchQueryProvider.notifier).state = '';
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _searchResults(BuildContext context) {
    final query = ref.watch(cocktailSearchQueryProvider);
    if (query.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
    final resultsAsync = ref.watch(cocktailSearchResultsProvider);
    return resultsAsync.when(
      data: (drinks) => drinks.isEmpty
          ? SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    const Icon(Icons.search_off_rounded, size: 60, color: AppColors.textSecondary),
                    const SizedBox(height: 12),
                    Text('No drinks found for "$query"',
                        style: Theme.of(context).textTheme.headlineMedium,
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
            )
          : SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _CocktailCard(cocktail: drinks[i], index: i),
                  childCount: drinks.length,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                ),
              ),
            ),
      loading: () => SliverToBoxAdapter(child: _shimmerGrid()),
      error: (_, _) => const SliverToBoxAdapter(child: SizedBox.shrink()),
    );
  }

  Widget _featuredDrink(BuildContext context) {
    final drinkAsync = ref.watch(randomCocktailProvider);
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: drinkAsync.when(
          data: (drink) => drink == null
              ? const SizedBox.shrink()
              : _DrinkHeroCard(cocktail: drink),
          loading: () => Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                  color: Colors.grey[300], borderRadius: BorderRadius.circular(24)),
            ),
          ),
          error: (_, _) => const SizedBox.shrink(),
        ),
      ),
    );
  }

  Widget _filterRow(BuildContext context) {
    final selectedCat = ref.watch(selectedCocktailCategoryProvider);
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              selectedCat ?? 'Categories 🍹',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            if (selectedCat != null)
              TextButton.icon(
                onPressed: () =>
                    ref.read(selectedCocktailCategoryProvider.notifier).state = null,
                icon: const Icon(Icons.arrow_back_rounded, size: 16),
                label: const Text('All'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _categoriesGrid(BuildContext context) {
    final catsAsync = ref.watch(cocktailCategoriesProvider);
    return catsAsync.when(
      data: (cats) => SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
        sliver: SliverGrid(
          delegate: SliverChildBuilderDelegate(
            (ctx, i) => _CategoryCard(
              name: cats[i].name,
              index: i,
              onTap: () =>
                  ref.read(selectedCocktailCategoryProvider.notifier).state = cats[i].name,
            ),
            childCount: cats.length,
          ),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.8,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
          ),
        ),
      ),
      loading: () => SliverToBoxAdapter(child: _shimmerGrid()),
      error: (_, _) => const SliverToBoxAdapter(child: SizedBox.shrink()),
    );
  }

  Widget _categoryDrinks(BuildContext context) {
    final drinksAsync = ref.watch(cocktailsByCategoryProvider);
    return drinksAsync.when(
      data: (drinks) => SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
        sliver: SliverGrid(
          delegate: SliverChildBuilderDelegate(
            (ctx, i) => _CocktailCard(cocktail: drinks[i], index: i),
            childCount: drinks.length,
          ),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
          ),
        ),
      ),
      loading: () => SliverToBoxAdapter(child: _shimmerGrid()),
      error: (_, _) => const SliverToBoxAdapter(child: SizedBox.shrink()),
    );
  }

  Widget _shimmerGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
      ),
      itemCount: 4,
      itemBuilder: (_, _) => Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          decoration: BoxDecoration(
              color: Colors.grey[300], borderRadius: BorderRadius.circular(20)),
        ),
      ),
    );
  }
}

// ── Hero Card ─────────────────────────────────────────────────
class _DrinkHeroCard extends StatelessWidget {
  final Cocktail cocktail;
  const _DrinkHeroCard({required this.cocktail});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CocktailDetailPage(id: cocktail.id, name: cocktail.name, thumb: cocktail.thumbnail),
        ),
      ),
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE63946).withAlpha(40),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(imageUrl: cocktail.thumbnail, fit: BoxFit.cover),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withAlpha(210)],
                    stops: const [0.3, 1.0],
                  ),
                ),
              ),
              Positioned(
                top: 14,
                left: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE63946),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.local_bar_rounded, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text('Drink of the Day',
                          style: TextStyle(
                              color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 14,
                right: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: cocktail.isAlcoholic
                        ? Colors.orange.withAlpha(200)
                        : Colors.green.withAlpha(200),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    cocktail.isAlcoholic ? '🍸 Cocktail' : '🧃 Mocktail',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cocktail.name,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (cocktail.category != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.category_outlined, color: Colors.white70, size: 13),
                          const SizedBox(width: 4),
                          Text(cocktail.category!,
                              style:
                                  const TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1);
  }
}

// ── Cocktail Card ─────────────────────────────────────────────
class _CocktailCard extends StatelessWidget {
  final Cocktail cocktail;
  final int index;
  const _CocktailCard({required this.cocktail, required this.index});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CocktailDetailPage(
              id: cocktail.id, name: cocktail.name, thumb: cocktail.thumbnail),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: cocktail.thumbnail,
                      fit: BoxFit.cover,
                      placeholder: (_, _) => Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(color: Colors.grey[300]),
                      ),
                      errorWidget: (_, _, _) => Container(
                        color: const Color(0xFFE63946).withAlpha(30),
                        child: const Icon(Icons.local_bar_rounded,
                            color: Color(0xFFE63946), size: 40),
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: cocktail.isAlcoholic
                              ? Colors.orange.withAlpha(220)
                              : Colors.green.withAlpha(220),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          cocktail.isAlcoholic ? '🍸' : '🧃',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cocktail.name,
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(fontWeight: FontWeight.w700, fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (cocktail.ingredients.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        cocktail.ingredients.take(3).join(', '),
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontSize: 10),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms, delay: (index * 50).ms).scale(begin: const Offset(0.9, 0.9));
  }
}

// ── Category Card ─────────────────────────────────────────────
class _CategoryCard extends StatelessWidget {
  final String name;
  final int index;
  final VoidCallback onTap;

  const _CategoryCard({required this.name, required this.index, required this.onTap});

  static const _icons = [
    '🍸', '🍹', '🥃', '🍺', '🧃', '🍷', '☕', '🥤', '🍵', '🧋',
  ];

  @override
  Widget build(BuildContext context) {
    final icon = _icons[index % _icons.length];
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            colors: [
              const Color(0xFFE63946).withAlpha(15),
              const Color(0xFFE63946).withAlpha(30),
            ],
          ),
          border: Border.all(color: const Color(0xFFE63946).withAlpha(40)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                name,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600, fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                size: 16, color: AppColors.textSecondary),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 350.ms, delay: (index * 40).ms);
  }
}

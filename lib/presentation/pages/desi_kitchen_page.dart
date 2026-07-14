import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/meal_db_models.dart';
import '../../data/models/food_product_model.dart';
import '../providers/recipe_providers.dart';
import 'meal_detail_page.dart';

// ── Desi dish quick-search chips ─────────────────────────────
const _desiDishes = [
  ('Biryani', '🍚'),
  ('Chicken', '🍗'),
  ('Kebab', '🥩'),
  ('Korma', '🫕'),
  ('Dal', '🥣'),
  ('Tikka', '🔥'),
  ('Curry', '🍛'),
  ('Lamb', '🐑'),
  ('Pilaf', '🍙'),
  ('Samosa', '🥟'),
  ('Haleem', '🍲'),
  ('Seekh', '🍢'),
];

class DesiKitchenPage extends ConsumerStatefulWidget {
  const DesiKitchenPage({super.key});

  @override
  ConsumerState<DesiKitchenPage> createState() => _DesiKitchenPageState();
}

class _DesiKitchenPageState extends ConsumerState<DesiKitchenPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _halalCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _halalCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ── ALL ref.watch at top ───────────────────────────────
    final desiQuery   = ref.watch(desiSearchQueryProvider);
    final desiAsync   = ref.watch(desiSearchResultsProvider);
    final indianAsync = ref.watch(indianAreaMealsProvider);
    final moroccanAsync = ref.watch(moroccanAreaMealsProvider);
    final halalAsync  = ref.watch(halalProductsProvider);
    final isDark      = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (ctx, inner) => [
          _buildSliverAppBar(ctx),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              TabBar(
                controller: _tabs,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                indicatorWeight: 3,
                labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                tabs: const [
                  Tab(text: '🍛  Desi Recipes'),
                  Tab(text: '🌍  South Asian'),
                  Tab(text: '✅  Halal Products'),
                ],
              ),
              isDark: isDark,
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabs,
          children: [
            _DesiRecipesTab(
              desiQuery: desiQuery,
              desiAsync: desiAsync,
              onChipTap: (dish) =>
                  ref.read(desiSearchQueryProvider.notifier).state = dish,
              onSearch: (q) =>
                  ref.read(desiSearchQueryProvider.notifier).state = q,
            ),
            _SouthAsianTab(
              indianAsync: indianAsync,
              moroccanAsync: moroccanAsync,
            ),
            _HalalProductsTab(
              ctrl: _halalCtrl,
              halalAsync: halalAsync,
              onSearch: (q) =>
                  ref.read(halalProductQueryProvider.notifier).state = q,
            ),
          ],
        ),
      ),
    );
  }

  SliverAppBar _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      stretch: true,
      backgroundColor: AppColors.primaryDark,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Gradient background
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1B4332),
                    Color(0xFF2D6A4F),
                    Color(0xFFFF6B35),
                  ],
                  stops: [0.0, 0.6, 1.0],
                ),
              ),
            ),
            // Pattern overlay
            Opacity(
              opacity: 0.08,
              child: Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(
                      'https://www.themealdb.com/images/category/chicken.png',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            // Content
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('🌙', style: TextStyle(fontSize: 28)),
                      const SizedBox(width: 10),
                      const Text(
                        'Desi Halal Kitchen',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Authentic South Asian & Halal Certified Recipes',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      leading: const BackButton(color: Colors.white),
    );
  }
}

// ── Tab 1: Desi Recipe Search ─────────────────────────────────
class _DesiRecipesTab extends StatelessWidget {
  final String desiQuery;
  final AsyncValue<List<MealDbRecipe>> desiAsync;
  final void Function(String) onChipTap;
  final void Function(String) onSearch;

  const _DesiRecipesTab({
    required this.desiQuery,
    required this.desiAsync,
    required this.onChipTap,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // Search bar
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _SearchBar(
              hint: 'Search biryani, karahi, nihari...',
              onSubmit: onSearch,
              initial: desiQuery,
            ),
          ),
        ),

        // Dish chips
        SliverToBoxAdapter(
          child: SizedBox(
            height: 52,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _desiDishes.length,
              separatorBuilder: (c, i) => const SizedBox(width: 8),
              itemBuilder: (c, i) {
                final (dish, emoji) = _desiDishes[i];
                final selected = desiQuery.toLowerCase() == dish.toLowerCase();
                return GestureDetector(
                  onTap: () => onChipTap(dish),
                  child: AnimatedContainer(
                    duration: 200.ms,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primary
                          : AppColors.primary.withAlpha(15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected
                            ? AppColors.primary
                            : AppColors.primary.withAlpha(40),
                      ),
                    ),
                    child: Text(
                      '$emoji $dish',
                      style: TextStyle(
                        color: selected ? Colors.white : AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        if (desiQuery.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  const Text('🍛', style: TextStyle(fontSize: 60)),
                  const SizedBox(height: 12),
                  Text(
                    'Tap a dish or search above',
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Biryani, Kebab, Korma and more...',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          desiAsync.when(
            data: (meals) => meals.isEmpty
                ? SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        children: [
                          const Text('😔', style: TextStyle(fontSize: 50)),
                          const SizedBox(height: 12),
                          Text(
                            'No results for "$desiQuery"',
                            style: Theme.of(context).textTheme.headlineMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          const Text('Try Biryani, Curry, or Lamb',
                              textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  )
                : _MealGrid(meals: meals),
            loading: () => _ShimmerGrid(),
            error: (e, _) => SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Text('Error: $e'),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Tab 2: South Asian Regions ────────────────────────────────
class _SouthAsianTab extends StatelessWidget {
  final AsyncValue<List<MealDbRecipe>> indianAsync;
  final AsyncValue<List<MealDbRecipe>> moroccanAsync;

  const _SouthAsianTab({
    required this.indianAsync,
    required this.moroccanAsync,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // Indian section
        SliverToBoxAdapter(
          child: _SectionHeader(
            emoji: '🇮🇳',
            title: 'Indian Recipes',
            subtitle: 'Subcontinental classics',
          ),
        ),
        indianAsync.when(
          data: (meals) => _MealGrid(meals: meals),
          loading: () => _ShimmerGrid(),
          error: (e, _) => SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Could not load: $e'),
              ),
            ),
          ),
        ),

        // Moroccan section
        SliverToBoxAdapter(
          child: _SectionHeader(
            emoji: '🇲🇦',
            title: 'Moroccan Recipes',
            subtitle: 'North African halal cuisine',
          ),
        ),
        moroccanAsync.when(
          data: (meals) => _MealGrid(meals: meals),
          loading: () => _ShimmerGrid(),
          error: (e, _) => SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Could not load: $e'),
              ),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );
  }
}

// ── Tab 3: Halal Certified Products ──────────────────────────
class _HalalProductsTab extends StatelessWidget {
  final TextEditingController ctrl;
  final AsyncValue<List<FoodProduct>> halalAsync;
  final void Function(String) onSearch;

  const _HalalProductsTab({
    required this.ctrl,
    required this.halalAsync,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Halal badge banner
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withAlpha(30),
                        AppColors.secondary.withAlpha(20),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: AppColors.primary.withAlpha(60)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text('✅ HALAL',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 12)),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Search Open Food Facts for halal-certified products',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _SearchBar(
                  hint: 'Search halal chicken, rice, spices...',
                  onSubmit: onSearch,
                  initial: ctrl.text,
                ),
              ],
            ),
          ),
        ),
        halalAsync.when(
          data: (products) => products.isEmpty
              ? SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        const Text('🔍', style: TextStyle(fontSize: 50)),
                        const SizedBox(height: 12),
                        Text(
                          'Search for halal products',
                          style: Theme.of(context).textTheme.headlineMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        const Text('e.g. "chicken", "rice", "masala"',
                            textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => _HalalProductTile(
                          product: products[i], index: i),
                      childCount: products.length,
                    ),
                  ),
                ),
          loading: () => SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) => Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  height: 80,
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              childCount: 5,
            ),
          ),
          error: (e, _) => SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Text('Error: $e'),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Shared Widgets ────────────────────────────────────────────

class _SearchBar extends StatefulWidget {
  final String hint;
  final void Function(String) onSubmit;
  final String initial;

  const _SearchBar(
      {required this.hint, required this.onSubmit, required this.initial});

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initial);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _ctrl,
      textInputAction: TextInputAction.search,
      onSubmitted: widget.onSubmit,
      decoration: InputDecoration(
        hintText: widget.hint,
        prefixIcon:
            const Icon(Icons.search_rounded, color: AppColors.primary),
        suffixIcon: IconButton(
          icon: const Icon(Icons.arrow_forward_rounded,
              color: AppColors.primary),
          onPressed: () => widget.onSubmit(_ctrl.text),
        ),
        border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
              const BorderSide(color: AppColors.primary, width: 2),
        ),
        filled: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;

  const _SectionHeader(
      {required this.emoji,
      required this.title,
      required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w800)),
              Text(subtitle,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

class _MealGrid extends StatelessWidget {
  final List<MealDbRecipe> meals;
  const _MealGrid({required this.meals});

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (ctx, i) => _MealCard(meal: meals[i], index: i),
          childCount: meals.length,
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.82,
        ),
      ),
    );
  }
}

class _ShimmerGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (ctx, i) => Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          childCount: 6,
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.82,
        ),
      ),
    );
  }
}

class _MealCard extends StatelessWidget {
  final MealDbRecipe meal;
  final int index;

  const _MealCard({required this.meal, required this.index});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MealDetailPage(
            mealId: meal.id,
            mealName: meal.name,
            mealThumb: meal.thumbnail,
          ),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withAlpha(12),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: meal.thumbnail,
                      fit: BoxFit.cover,
                      placeholder: (c, u) => Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(color: Colors.grey[300]),
                      ),
                      errorWidget: (c, u, e) => Container(
                        color: AppColors.primaryLight.withAlpha(30),
                        child: const Icon(Icons.restaurant,
                            color: AppColors.primaryLight),
                      ),
                    ),
                    // Halal badge
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(220),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('✅ Halal',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Text(
                meal.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms, delay: (index * 50).ms).slideY(begin: 0.15);
  }
}

class _HalalProductTile extends StatelessWidget {
  final FoodProduct product;
  final int index;

  const _HalalProductTile({required this.product, required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(10),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Product image
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 64,
              height: 64,
              child: product.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: product.imageUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (c, u, e) =>
                          const Icon(Icons.fastfood_outlined,
                              color: AppColors.primaryLight, size: 30),
                    )
                  : Container(
                      color: AppColors.primary.withAlpha(20),
                      child: const Icon(Icons.fastfood_outlined,
                          color: AppColors.primaryLight, size: 30),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14),
                ),
                if (product.brands != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    product.brands!,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    _NutriBadge(product.nutriscore),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('✅ Halal Certified',
                          style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 350.ms, delay: (index * 40).ms);
  }
}

class _NutriBadge extends StatelessWidget {
  final String? grade;
  const _NutriBadge(this.grade);

  static const _colors = {
    'a': Color(0xFF1E8F4E),
    'b': Color(0xFF56A80D),
    'c': Color(0xFFEFCB0C),
    'd': Color(0xFFEF8200),
    'e': Color(0xFFE63312),
  };

  @override
  Widget build(BuildContext context) {
    if (grade == null) return const SizedBox.shrink();
    final g = grade!.toLowerCase();
    final color = _colors[g] ?? Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'Nutri-${grade!.toUpperCase()}',
        style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w700),
      ),
    );
  }
}

// ── Pinned TabBar delegate ────────────────────────────────────
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final bool isDark;

  _TabBarDelegate(this.tabBar, {required this.isDark});

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: isDark ? const Color(0xFF1C1C2E) : Colors.white,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate old) => old.isDark != isDark;
}

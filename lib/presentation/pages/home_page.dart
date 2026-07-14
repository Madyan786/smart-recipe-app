import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/area_flags.dart';
import '../../data/models/meal_db_models.dart';
import '../providers/recipe_providers.dart';
import '../widgets/recipe_card.dart';
import 'recipe_detail_page.dart';
import 'meal_detail_page.dart';
import 'category_page.dart';
import 'meal_planner_page.dart';
import 'desi_kitchen_page.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(isDarkModeProvider);
    return Scaffold(
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(randomRecipesProvider);
          ref.invalidate(featuredMealProvider);
        },
        child: CustomScrollView(
          slivers: [
            _appBar(context, ref, isDark),
            _header(context),
            _featuredHero(context, ref),
            _quickActions(context),
            _cookingTip(context, ref),
            _categoriesSection(context, ref),
            _trendingHeader(context, ref),
            _trendingGrid(ref),
            const SliverToBoxAdapter(child: SizedBox(height: 30)),
          ],
        ),
      ),
    );
  }

  // ── App bar ───────────────────────────────────────────────
  SliverAppBar _appBar(BuildContext context, WidgetRef ref, bool isDark) {
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
                colors: [AppColors.primary, AppColors.primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.restaurant_menu, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Text('SmartRecipe',
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(color: AppColors.primary)),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
          onPressed: () => ref.read(isDarkModeProvider.notifier).state = !isDark,
        ),
        const SizedBox(width: 6),
      ],
    );
  }

  // ── Header text ───────────────────────────────────────────
  Widget _header(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'What are you\ncooking today? 👨‍🍳',
              style: Theme.of(context)
                  .textTheme
                  .displayLarge
                  ?.copyWith(fontSize: 28, height: 1.2),
            ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.2),
            const SizedBox(height: 4),
            Text('Discover amazing recipes from around the world',
                    style: Theme.of(context).textTheme.bodyMedium)
                .animate()
                .fadeIn(duration: 500.ms, delay: 100.ms),
          ],
        ),
      ),
    );
  }

  // ── Hero featured meal (TheMealDB — FREE) ────────────────
  Widget _featuredHero(BuildContext context, WidgetRef ref) {
    final mealAsync = ref.watch(featuredMealProvider);
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: mealAsync.when(
          data: (meal) => meal == null
              ? const SizedBox.shrink()
              : _HeroCard(meal: meal),
          loading: () => _heroShimmer(),
          error: (_, _) => const SizedBox.shrink(),
        ),
      ),
    );
  }

  Widget _heroShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        height: 200,
        decoration:
            BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(24)),
      ),
    );
  }

  // ── Quick actions row ─────────────────────────────────────
  Widget _quickActions(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Column(
          children: [
            Row(
              children: [
                _QuickActionBtn(
                  icon: Icons.calendar_month_rounded,
                  label: 'Meal Plan',
                  color: AppColors.primary,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MealPlannerPage()),
                  ),
                ),
                const SizedBox(width: 10),
                _QuickActionBtn(
                  icon: Icons.local_fire_department_rounded,
                  label: 'Popular',
                  color: AppColors.secondary,
                  onTap: () {},
                ),
                const SizedBox(width: 10),
                _QuickActionBtn(
                  icon: Icons.emoji_food_beverage_rounded,
                  label: 'Healthy',
                  color: const Color(0xFF52B788),
                  onTap: () {},
                ),
                const SizedBox(width: 10),
                _QuickActionBtn(
                  icon: Icons.timer_rounded,
                  label: 'Quick',
                  color: const Color(0xFFFF6B35),
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Desi Halal Kitchen banner
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DesiKitchenPage()),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1B4332), Color(0xFF2D6A4F), Color(0xFFFF6B35)],
                    stops: [0.0, 0.55, 1.0],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withAlpha(60),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Text('🌙', style: TextStyle(fontSize: 26)),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Desi Halal Kitchen',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Biryani • Karahi • Kebab • Halal Certified',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded,
                        color: Colors.white70, size: 16),
                  ],
                ),
              ).animate().fadeIn(duration: 500.ms, delay: 200.ms).slideX(begin: 0.1),
            ),
          ],
        ),
      ),
    );
  }

  // ── Cooking tip (Adviceslip API — FREE) ──────────────────
  Widget _cookingTip(BuildContext context, WidgetRef ref) {
    final tipAsync = ref.watch(cookingTipProvider);
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: tipAsync.when(
          data: (tip) => Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2D6A4F), Color(0xFF52B788)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withAlpha(50),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('💡', style: TextStyle(fontSize: 22)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Chef\'s Tip',
                        style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tip,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            height: 1.4),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded,
                      color: Colors.white70, size: 20),
                  onPressed: () => ref.invalidate(cookingTipProvider),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 500.ms).slideX(begin: -0.1),
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
        ),
      ),
    );
  }

  // ── Categories (TheMealDB — FREE) ────────────────────────
  Widget _categoriesSection(BuildContext context, WidgetRef ref) {
    final catsAsync = ref.watch(categoriesProvider);
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Text('Browse Categories 🍽️',
                style: Theme.of(context).textTheme.headlineMedium),
          ),
          SizedBox(
            height: 110,
            child: catsAsync.when(
              data: (cats) => ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: cats.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (_, i) => _CategoryTile(category: cats[i], index: i),
              ),
              loading: () => _categoryShimmer(),
              error: (_, _) => const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryShimmer() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      scrollDirection: Axis.horizontal,
      itemCount: 6,
      separatorBuilder: (_, _) => const SizedBox(width: 12),
      itemBuilder: (_, _) => Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          width: 80,
          decoration: BoxDecoration(
              color: Colors.grey[300], borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  // ── Trending header ───────────────────────────────────────
  Widget _trendingHeader(BuildContext context, WidgetRef ref) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Trending Recipes 🔥',
                style: Theme.of(context).textTheme.headlineMedium),
            TextButton.icon(
              onPressed: () => ref.invalidate(randomRecipesProvider),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Trending grid ─────────────────────────────────────────
  Widget _trendingGrid(WidgetRef ref) {
    final recipesAsync = ref.watch(randomRecipesProvider);
    return recipesAsync.when(
      data: (recipes) => SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        sliver: SliverGrid(
          delegate: SliverChildBuilderDelegate(
            (context, i) => RecipeCard(
              recipe: recipes[i],
              index: i,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => RecipeDetailPage(recipe: recipes[i])),
              ),
            ),
            childCount: recipes.length,
          ),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.75,
          ),
        ),
      ),
      loading: () => SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        sliver: SliverGrid(
          delegate: SliverChildBuilderDelegate(
            (_, _) => Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                  decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(20))),
            ),
            childCount: 6,
          ),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.75,
          ),
        ),
      ),
      error: (e, _) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              const Icon(Icons.wifi_off_rounded, size: 60, color: AppColors.textSecondary),
              const SizedBox(height: 16),
              Text('Could not load recipes',
                  style: Theme.of(ref.context).textTheme.headlineMedium,
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(e.toString().replaceAll('Exception: ', ''),
                  style: Theme.of(ref.context).textTheme.bodyMedium,
                  textAlign: TextAlign.center),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(randomRecipesProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Hero Card Widget ─────────────────────────────────────────
class _HeroCard extends StatelessWidget {
  final MealDbRecipe meal;

  const _HeroCard({required this.meal});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => MealDetailPage(mealId: meal.id, mealName: meal.name, mealThumb: meal.thumbnail)),
      ),
      child: Container(
        height: 210,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: AppColors.primary.withAlpha(40), blurRadius: 20, offset: const Offset(0, 8)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: meal.thumbnail,
                fit: BoxFit.cover,
                errorWidget: (_, _, _) => Container(
                  color: AppColors.primaryLight.withAlpha(60),
                  child: const Icon(Icons.restaurant, size: 60, color: AppColors.primary),
                ),
              ),
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
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text('Meal of the Day',
                          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
              if (meal.youtubeUrl != null && meal.youtubeUrl!.isNotEmpty)
                Positioned(
                  top: 14,
                  right: 14,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF0000),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 18),
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
                      meal.name,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (meal.category.isNotEmpty) ...[
                          const Icon(Icons.category_outlined, color: Colors.white70, size: 13),
                          const SizedBox(width: 4),
                          Text(meal.category,
                              style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          const SizedBox(width: 10),
                        ],
                        if (meal.area.isNotEmpty) ...[
                          Text(flagForArea(meal.area),
                              style: const TextStyle(fontSize: 13)),
                          const SizedBox(width: 4),
                          Text(meal.area,
                              style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ],
                    ),
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

// ── Quick Action Button ───────────────────────────────────────
class _QuickActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionBtn(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withAlpha(18),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withAlpha(50)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 4),
              Text(label,
                  style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Category Tile Widget ──────────────────────────────────────
class _CategoryTile extends StatelessWidget {
  final MealCategory category;
  final int index;

  const _CategoryTile({required this.category, required this.index});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => CategoryPage(category: category)),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: AppColors.primary.withAlpha(10),
              border: Border.all(color: AppColors.primary.withAlpha(30)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: CachedNetworkImage(
                imageUrl: category.thumbnail,
                fit: BoxFit.cover,
                placeholder: (_, _) => Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(color: Colors.grey[300]),
                ),
                errorWidget: (_, _, _) => const Icon(Icons.restaurant, color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            category.name,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontSize: 11, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: (index * 50).ms).scale(begin: const Offset(0.8, 0.8));
  }
}

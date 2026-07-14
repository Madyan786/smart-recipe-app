import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/recipe.dart';
import '../providers/recipe_providers.dart';

class RecipeDetailPage extends ConsumerStatefulWidget {
  final Recipe? recipe;
  final int? recipeId;
  final String? recipeTitle;
  final String? recipeImage;

  const RecipeDetailPage({super.key, required this.recipe})
      : recipeId = null,
        recipeTitle = null,
        recipeImage = null;

  const RecipeDetailPage.fromFridge({
    super.key,
    required int id,
    required String title,
    required String image,
  })  : recipe = null,
        recipeId = id,
        recipeTitle = title,
        recipeImage = image;

  int get _id => recipe?.id ?? recipeId!;
  String get _title => recipe?.title ?? recipeTitle!;
  String get _image => recipe?.image ?? recipeImage!;

  @override
  ConsumerState<RecipeDetailPage> createState() => _RecipeDetailPageState();
}

class _RecipeDetailPageState extends ConsumerState<RecipeDetailPage> {
  int _servings = 0;

  int get _id => widget._id;
  String get _title => widget._title;
  String get _image => widget._image;

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(recipeDetailProvider(_id));
    final favoritesState = ref.watch(favoritesProvider);
    final isFav = favoritesState.whenOrNull(
      data: (list) => list.any((r) => r.id == _id),
    ) ?? false;

    return Scaffold(
      body: detailAsync.when(
        data: (detail) {
          if (_servings == 0) _servings = detail.servings;
          return _buildContent(context, ref, detail, isFav);
        },
        loading: () => _buildLoadingState(context),
        error: (e, _) => _buildErrorState(context, e, ref),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, RecipeDetail detail, bool isFav) {
    return CustomScrollView(
      slivers: [
        _buildSliverAppBar(context, ref, detail, isFav),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMetaRow(context, detail),
                const SizedBox(height: 16),
                if (detail.diets.isNotEmpty) ...[
                  _buildDietChips(context, detail),
                  const SizedBox(height: 20),
                ],
                if (detail.summary.isNotEmpty) ...[
                  _buildSectionTitle(context, 'About'),
                  const SizedBox(height: 8),
                  Text(
                    detail.summary.length > 400
                        ? '${detail.summary.substring(0, 400)}...'
                        : detail.summary,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6),
                  ),
                  const SizedBox(height: 24),
                ],
                if (detail.nutrition != null) ...[
                  _buildNutritionSection(context, detail.nutrition!),
                  const SizedBox(height: 24),
                ],
                if (detail.ingredients.isNotEmpty) ...[
                  _buildIngredientsHeader(context, detail),
                  const SizedBox(height: 12),
                  _buildIngredientsList(context, detail),
                  const SizedBox(height: 24),
                ],
                if (detail.steps.isNotEmpty) ...[
                  _buildSectionTitle(context, 'Instructions'),
                  const SizedBox(height: 12),
                  _buildStepsList(context, detail),
                  const SizedBox(height: 40),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSliverAppBar(BuildContext context, WidgetRef ref, RecipeDetail detail, bool isFav) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      stretch: true,
      backgroundColor: AppColors.primary,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            _image.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: _image,
                    fit: BoxFit.cover,
                    errorWidget: (_, _, _) => Container(
                      color: AppColors.primaryLight.withAlpha(80),
                      child: const Icon(Icons.restaurant, size: 80, color: AppColors.primary),
                    ),
                  )
                : Container(color: AppColors.primaryLight.withAlpha(80)),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withAlpha(180)],
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              left: 20,
              right: 70,
              child: Text(
                _title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  shadows: [Shadow(blurRadius: 8, color: Colors.black45)],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        // Share
        Container(
          margin: const EdgeInsets.only(right: 4),
          decoration: BoxDecoration(color: Colors.white.withAlpha(200), shape: BoxShape.circle),
          child: IconButton(
            icon: const Icon(Icons.share_outlined, color: AppColors.textPrimary),
            onPressed: () => Share.share(
              '🍽️ Try this amazing recipe: $_title\n\nReady in ${detail.readyInMinutes} min | ${detail.servings} servings\n\nMade with SmartRecipe App!',
              subject: _title,
            ),
          ),
        ),
        // Favorite
        Container(
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(color: Colors.white.withAlpha(200), shape: BoxShape.circle),
          child: IconButton(
            icon: Icon(
              isFav ? Icons.favorite : Icons.favorite_border,
              color: isFav ? AppColors.error : AppColors.textPrimary,
            ),
            onPressed: () {
              final r = widget.recipe ?? Recipe(id: _id, title: _title, image: _image);
              ref.read(favoritesProvider.notifier).toggle(r);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildIngredientsHeader(BuildContext context, RecipeDetail detail) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Ingredients 🥕',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize: 20)),
        Row(
          children: [
            const Icon(Icons.people_outline, size: 16, color: AppColors.primary),
            const SizedBox(width: 6),
            _adjBtn(Icons.remove, () {
              if (_servings > 1) setState(() => _servings--);
            }),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text('$_servings',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, color: AppColors.primary, fontSize: 16)),
            ),
            _adjBtn(Icons.add, () => setState(() => _servings++)),
          ],
        ),
      ],
    );
  }

  Widget _adjBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: AppColors.primary.withAlpha(20),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: AppColors.primary),
      ),
    );
  }

  Widget _buildMetaRow(BuildContext context, RecipeDetail detail) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _MetaItem(icon: Icons.timer_outlined, value: '${detail.readyInMinutes}', label: 'Minutes'),
        _MetaItem(icon: Icons.people_outline, value: '${detail.servings}', label: 'Servings'),
        if (detail.nutrition != null)
          _MetaItem(
            icon: Icons.local_fire_department_outlined,
            value: '${detail.nutrition!.calories.toInt()}',
            label: 'Calories',
          ),
      ],
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2);
  }

  Widget _buildDietChips(BuildContext context, RecipeDetail detail) {
    final badges = <Widget>[];
    if (detail.vegan) badges.add(_badge('🌱 Vegan', AppColors.primary));
    if (detail.vegetarian && !detail.vegan) badges.add(_badge('🥦 Vegetarian', AppColors.primaryLight));
    if (detail.glutenFree) badges.add(_badge('🌾 Gluten Free', AppColors.secondary));
    for (final diet in detail.diets.take(3)) {
      if (!diet.contains('vegan') && !diet.contains('vegetarian') && !diet.contains('gluten')) {
        badges.add(_badge(diet, AppColors.accent.withAlpha(200)));
      }
    }

    return Wrap(spacing: 8, runSpacing: 8, children: badges);
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(title, style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize: 20));
  }

  Widget _buildNutritionSection(BuildContext context, NutritionInfo nutrition) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, 'Nutrition Per Serving'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary.withAlpha(15), AppColors.primaryLight.withAlpha(10)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primary.withAlpha(40)),
          ),
          child: Column(
            children: [
              _BigCalorieDisplay(calories: nutrition.calories),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NutrientBar(label: 'Protein', value: nutrition.protein, unit: 'g', color: AppColors.secondary),
                  _NutrientBar(label: 'Carbs', value: nutrition.carbs, unit: 'g', color: AppColors.accent),
                  _NutrientBar(label: 'Fat', value: nutrition.fat, unit: 'g', color: AppColors.primary),
                  _NutrientBar(label: 'Fiber', value: nutrition.fiber, unit: 'g', color: AppColors.primaryLight),
                ],
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(duration: 500.ms);
  }

  Widget _buildIngredientsList(BuildContext context, RecipeDetail detail) {
    return Column(
      children: detail.ingredients.asMap().entries.map((e) {
        final i = e.key;
        final ing = e.value;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  ing.original,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 14),
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 300.ms, delay: (i * 30).ms);
      }).toList(),
    );
  }

  Widget _buildStepsList(BuildContext context, RecipeDetail detail) {
    return Column(
      children: detail.steps.map((step) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '${step.number}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    step.step,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6),
                  ),
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 400.ms, delay: (step.number * 50).ms).slideX(begin: 0.1);
      }).toList(),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 300,
          color: AppColors.primaryLight.withAlpha(40),
          child: const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ),
        const Padding(
          padding: EdgeInsets.all(20),
          child: Text('Loading recipe details...'),
        ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context, Object error, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 60, color: AppColors.error),
          const SizedBox(height: 16),
          Text('Failed to load recipe', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(error.toString().replaceAll('Exception: ', ''),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => ref.refresh(recipeDetailProvider(_id)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _MetaItem({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(15),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.primary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 11),
        ),
      ],
    );
  }
}

class _BigCalorieDisplay extends StatelessWidget {
  final double calories;

  const _BigCalorieDisplay({required this.calories});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.local_fire_department, color: AppColors.secondary, size: 28),
        const SizedBox(width: 8),
        Text(
          '${calories.toInt()} kcal',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AppColors.secondary,
          ),
        ),
      ],
    );
  }
}

class _NutrientBar extends StatelessWidget {
  final String label;
  final double value;
  final String unit;
  final Color color;

  const _NutrientBar({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '${value.toInt()}$unit',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: color),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 11),
        ),
      ],
    );
  }
}

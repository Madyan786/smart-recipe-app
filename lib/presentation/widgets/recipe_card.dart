import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/recipe.dart';
import '../providers/recipe_providers.dart';

class RecipeCard extends ConsumerWidget {
  final Recipe recipe;
  final VoidCallback onTap;
  final int index;

  const RecipeCard({
    super.key,
    required this.recipe,
    required this.onTap,
    this.index = 0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(isDarkModeProvider);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: isDark ? AppColors.darkCard : AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withAlpha(20),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImage(context),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (recipe.readyInMinutes > 0) ...[
                        Icon(Icons.timer_outlined, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          '${recipe.readyInMinutes} min',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
                        ),
                        const SizedBox(width: 10),
                      ],
                      if (recipe.vegan)
                        _DietBadge(label: 'Vegan', color: AppColors.primary)
                      else if (recipe.vegetarian)
                        _DietBadge(label: 'Veg', color: AppColors.primaryLight)
                      else if (recipe.glutenFree)
                        _DietBadge(label: 'GF', color: AppColors.secondary),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms, delay: (index * 60).ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildImage(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: recipe.image.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: recipe.image,
                fit: BoxFit.cover,
                placeholder: (_, _) => _shimmerPlaceholder(),
                errorWidget: (_, _, _) => _errorPlaceholder(context),
              )
            : _errorPlaceholder(context),
      ),
    );
  }

  Widget _shimmerPlaceholder() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(color: Colors.grey[300]),
    );
  }

  Widget _errorPlaceholder(BuildContext context) {
    return Container(
      color: AppColors.primaryLight.withAlpha(40),
      child: const Center(
        child: Icon(Icons.restaurant, size: 40, color: AppColors.primaryLight),
      ),
    );
  }
}

class _DietBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _DietBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class FridgeRecipeCard extends ConsumerWidget {
  final FridgeRecipe recipe;
  final VoidCallback onTap;
  final int index;

  const FridgeRecipeCard({
    super.key,
    required this.recipe,
    required this.onTap,
    this.index = 0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(isDarkModeProvider);
    final matchPercent = recipe.usedIngredientCount > 0
        ? (recipe.usedIngredientCount / (recipe.usedIngredientCount + recipe.missedIngredientCount) * 100).toInt()
        : 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: isDark ? AppColors.darkCard : AppColors.surface,
          boxShadow: [
            BoxShadow(color: AppColors.primary.withAlpha(15), blurRadius: 20, offset: const Offset(0, 6)),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
              child: SizedBox(
                width: 110,
                height: 110,
                child: recipe.image.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: recipe.image,
                        fit: BoxFit.cover,
                        placeholder: (_, _) => Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: Container(color: Colors.grey[300]),
                        ),
                        errorWidget: (_, _, _) => Container(
                          color: AppColors.primaryLight.withAlpha(40),
                          child: const Icon(Icons.restaurant, color: AppColors.primaryLight),
                        ),
                      )
                    : Container(
                        color: AppColors.primaryLight.withAlpha(40),
                        child: const Icon(Icons.restaurant, color: AppColors.primaryLight),
                      ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.check_circle, size: 14, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          '${recipe.usedIngredientCount} matching',
                          style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (recipe.missedIngredientCount > 0)
                      Text(
                        'Need: ${recipe.missedIngredients.take(3).join(', ')}${recipe.missedIngredients.length > 3 ? '...' : ''}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: matchPercent / 100,
                        backgroundColor: AppColors.primary.withAlpha(30),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          matchPercent > 70 ? AppColors.primary : AppColors.secondary,
                        ),
                        minHeight: 5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$matchPercent% match',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: matchPercent > 70 ? AppColors.primary : AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms, delay: (index * 80).ms).slideX(begin: 0.1, end: 0);
  }
}

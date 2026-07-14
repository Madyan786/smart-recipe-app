import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/food_product_model.dart';
import '../providers/recipe_providers.dart';

class NutritionLookupPage extends ConsumerStatefulWidget {
  const NutritionLookupPage({super.key});

  @override
  ConsumerState<NutritionLookupPage> createState() => _NutritionLookupPageState();
}

class _NutritionLookupPageState extends ConsumerState<NutritionLookupPage> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(foodSearchQueryProvider);
    final productsAsync = ref.watch(foodProductsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutrition Lookup'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _ctrl,
              autofocus: true,
              onChanged: (v) => ref.read(foodSearchQueryProvider.notifier).state = v,
              decoration: InputDecoration(
                hintText: 'Search food products (e.g. "chocolate", "milk")...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _ctrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _ctrl.clear();
                          ref.read(foodSearchQueryProvider.notifier).state = '';
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
          if (query.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('🥗', style: TextStyle(fontSize: 60)),
                    const SizedBox(height: 16),
                    Text('Search any food product',
                        style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 8),
                    Text(
                      'Get nutrition facts from Open Food Facts\nDatabase of 3M+ real products',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: ['Chocolate', 'Milk', 'Pasta', 'Bread', 'Yogurt', 'Oats']
                          .map(
                            (s) => ActionChip(
                              label: Text(s),
                              onPressed: () {
                                _ctrl.text = s;
                                ref.read(foodSearchQueryProvider.notifier).state = s;
                              },
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: productsAsync.when(
                data: (products) => products.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.search_off_rounded,
                                size: 60, color: AppColors.textSecondary),
                            const SizedBox(height: 12),
                            Text('No products found for "$query"',
                                style: Theme.of(context).textTheme.headlineMedium,
                                textAlign: TextAlign.center),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                        itemCount: products.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (ctx, i) => _ProductCard(product: products[i]),
                      ),
                loading: () => ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  itemCount: 6,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, _) => Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(
                      height: 90,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                error: (e, _) => Center(
                  child: Text('Error: $e',
                      style: Theme.of(context).textTheme.bodyMedium),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final FoodProduct product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: product.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: product.imageUrl!,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) => _placeholder(),
                    )
                  : _placeholder(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (product.brands != null && product.brands!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(product.brands!,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontSize: 12, color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (product.nutrition?.calories != null)
                        _NutBadge(
                          label: '${product.nutrition!.calories!.toStringAsFixed(0)} kcal',
                          color: AppColors.secondary,
                        ),
                      const SizedBox(width: 6),
                      if (product.nutriscore != null)
                        _NutBadge(
                          label: 'Nutri-Score ${product.nutriscore}',
                          color: _nutriscoreColor(product.nutriscore!),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(20),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.fastfood_outlined, color: AppColors.primary, size: 28),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProductDetailSheet(product: product),
    );
  }

  Color _nutriscoreColor(String score) {
    switch (score.toUpperCase()) {
      case 'A': return const Color(0xFF1A9641);
      case 'B': return const Color(0xFF8FC44A);
      case 'C': return const Color(0xFFF9C000);
      case 'D': return const Color(0xFFE97D1B);
      case 'E': return const Color(0xFFD7191C);
      default: return Colors.grey;
    }
  }
}

class _NutBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _NutBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w700)),
    );
  }
}

class _ProductDetailSheet extends StatelessWidget {
  final FoodProduct product;
  const _ProductDetailSheet({required this.product});

  @override
  Widget build(BuildContext context) {
    final n = product.nutrition;
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, ctrl) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Expanded(
              child: ListView(
                controller: ctrl,
                padding: const EdgeInsets.all(20),
                children: [
                  if (product.imageUrl != null)
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: CachedNetworkImage(
                          imageUrl: product.imageUrl!,
                          height: 180,
                          fit: BoxFit.contain,
                          errorWidget: (_, _, _) => const SizedBox.shrink(),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Text(product.name,
                      style: Theme.of(context)
                          .textTheme
                          .displayLarge
                          ?.copyWith(fontSize: 22)),
                  if (product.brands != null) ...[
                    const SizedBox(height: 4),
                    Text(product.brands!,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: AppColors.textSecondary)),
                  ],
                  const SizedBox(height: 20),
                  if (n != null) ...[
                    Text('Nutrition Facts (per 100g)',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(fontSize: 16)),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(8),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.primary.withAlpha(30)),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          if (n.calories != null)
                            _NutritionRow('Calories', '${n.calories!.toStringAsFixed(1)} kcal',
                                isHighlight: true),
                          if (n.fat != null)
                            _NutritionRow('Total Fat', '${n.fat!.toStringAsFixed(1)} g'),
                          if (n.saturatedFat != null)
                            _NutritionRow(
                                '  Saturated Fat', '${n.saturatedFat!.toStringAsFixed(1)} g',
                                isIndented: true),
                          if (n.carbs != null)
                            _NutritionRow('Carbohydrates', '${n.carbs!.toStringAsFixed(1)} g'),
                          if (n.sugars != null)
                            _NutritionRow('  Sugars', '${n.sugars!.toStringAsFixed(1)} g',
                                isIndented: true),
                          if (n.fiber != null)
                            _NutritionRow('Fiber', '${n.fiber!.toStringAsFixed(1)} g'),
                          if (n.protein != null)
                            _NutritionRow('Protein', '${n.protein!.toStringAsFixed(1)} g'),
                          if (n.salt != null)
                            _NutritionRow('Salt', '${n.salt!.toStringAsFixed(2)} g'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (product.allergens.isNotEmpty) ...[
                    Text('Allergens', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 16)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: product.allergens
                          .map((a) => Chip(
                                label: Text(a,
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.white)),
                                backgroundColor: Colors.red[600],
                                padding: EdgeInsets.zero,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (product.ingredients != null && product.ingredients!.isNotEmpty) ...[
                    Text('Ingredients',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(fontSize: 16)),
                    const SizedBox(height: 8),
                    Text(
                      product.ingredients!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
                    ),
                    const SizedBox(height: 16),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    'Data from Open Food Facts — Community Database',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontSize: 11, color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NutritionRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlight;
  final bool isIndented;

  const _NutritionRow(this.label, this.value,
      {this.isHighlight = false, this.isIndented = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(isIndented ? 16 : 0, 0, 0, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: isHighlight ? FontWeight.w800 : FontWeight.w500,
                  fontSize: isHighlight ? 15 : 13,
                ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isHighlight ? FontWeight.w800 : FontWeight.w600,
              fontSize: isHighlight ? 15 : 13,
              color: isHighlight ? AppColors.secondary : null,
            ),
          ),
        ],
      ),
    );
  }
}

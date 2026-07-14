import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../providers/recipe_providers.dart';
import '../widgets/recipe_card.dart';
import 'recipe_detail_page.dart';

class FridgeModePage extends ConsumerStatefulWidget {
  const FridgeModePage({super.key});

  @override
  ConsumerState<FridgeModePage> createState() => _FridgeModePageState();
}

class _FridgeModePageState extends ConsumerState<FridgeModePage> {
  final _controller = TextEditingController();
  bool _searched = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addIngredient() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    ref.read(fridgeIngredientsProvider.notifier).addIngredient(text);
    _controller.clear();
    setState(() => _searched = false);
  }

  @override
  Widget build(BuildContext context) {
    final ingredients = ref.watch(fridgeIngredientsProvider);
    final recipesAsync = ref.watch(fridgeRecipesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fridge Mode 🧊'),
        actions: [
          if (ingredients.isNotEmpty)
            TextButton.icon(
              onPressed: () {
                ref.read(fridgeIngredientsProvider.notifier).clear();
                setState(() => _searched = false);
              },
              icon: const Icon(Icons.clear_all, size: 18),
              label: const Text('Clear'),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildHeader(context),
          _buildIngredientInput(context, ingredients),
          if (ingredients.isNotEmpty) _buildIngredientList(context, ingredients),
          if (ingredients.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() => _searched = true);
                    // ignore: unused_result
                    ref.refresh(fridgeRecipesProvider);
                  },
                  icon: const Icon(Icons.auto_awesome),
                  label: Text(
                    'Find Recipes (${ingredients.length} ingredient${ingredients.length > 1 ? 's' : ''})',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ),
          const Divider(height: 1),
          Expanded(
            child: _searched
                ? recipesAsync.when(
                    data: (recipes) {
                      if (recipes.isEmpty) return _buildNoResults(context);
                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
                        itemCount: recipes.length,
                        itemBuilder: (context, i) => FridgeRecipeCard(
                          recipe: recipes[i],
                          index: i,
                          onTap: () {
                            final r = recipes[i];
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => RecipeDetailPage.fromFridge(
                                  id: r.id,
                                  title: r.title,
                                  image: r.image,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                    loading: () => const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: AppColors.primary),
                          SizedBox(height: 16),
                          Text('Finding what you can cook...'),
                        ],
                      ),
                    ),
                    error: (e, _) => Center(
                      child: Text(e.toString().replaceAll('Exception: ', '')),
                    ),
                  )
                : _buildInstructions(context, ingredients),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withAlpha(30), AppColors.primaryLight.withAlpha(20)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withAlpha(50)),
      ),
      child: Row(
        children: [
          const Text('🧊', style: TextStyle(fontSize: 32)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'What\'s in your fridge?',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  'Add ingredients & discover recipes you can make right now',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1);
  }

  Widget _buildIngredientInput(BuildContext context, List<String> ingredients) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              onSubmitted: (_) => _addIngredient(),
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'e.g. chicken, tomatoes, garlic...',
                prefixIcon: Icon(Icons.add_circle_outline, color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _addIngredient,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              elevation: 0,
            ),
            child: const Text('Add', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientList(BuildContext context, List<String> ingredients) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: ingredients.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) => Chip(
          label: Text(
            ingredients[i],
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          backgroundColor: AppColors.primary.withAlpha(20),
          deleteIcon: const Icon(Icons.close, size: 16, color: AppColors.primary),
          onDeleted: () => ref.read(fridgeIngredientsProvider.notifier).removeIngredient(ingredients[i]),
          side: BorderSide.none,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ).animate().fadeIn(duration: 300.ms).scale(begin: const Offset(0.8, 0.8)),
      ),
    );
  }

  Widget _buildInstructions(BuildContext context, List<String> ingredients) {
    if (ingredients.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🥕🧅🍅', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 20),
            Text('Add your ingredients above', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              'We\'ll find recipes you can make\nwith what you already have!',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ).animate().fadeIn(),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('✨', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text('${ingredients.length} ingredient${ingredients.length > 1 ? 's' : ''} added!',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Hit "Find Recipes" to see what\nyou can cook right now',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ).animate().fadeIn(),
    );
  }

  Widget _buildNoResults(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('😔', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text('No matching recipes', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Try adding more ingredients\nor different ones',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ).animate().fadeIn(),
    );
  }
}

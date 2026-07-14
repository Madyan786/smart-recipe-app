import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/api_constants.dart';
import '../../core/theme/app_theme.dart';
import '../providers/recipe_providers.dart';
import '../widgets/recipe_card.dart';
import 'recipe_detail_page.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final search = ref.watch(searchStateProvider);
    final resultsAsync = ref.watch(searchResultsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Recipes'),
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildSearchBar(context, search),
          _buildFilters(context, search),
          const Divider(height: 1),
          Expanded(
            child: resultsAsync.when(
              data: (recipes) {
                if (search.query.isEmpty && search.selectedCuisine == null && search.selectedDiet == null) {
                  return _buildEmptyState(context);
                }
                if (recipes.isEmpty) return _buildNoResults(context);
                return GridView.builder(
                  padding: const EdgeInsets.all(20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: recipes.length,
                  itemBuilder: (context, i) => RecipeCard(
                    recipe: recipes[i],
                    index: i,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => RecipeDetailPage(recipe: recipes[i])),
                    ),
                  ),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                    const SizedBox(height: 16),
                    Text(e.toString().replaceAll('Exception: ', ''),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, SearchState search) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: TextField(
        controller: _controller,
        onChanged: (val) => ref.read(searchStateProvider.notifier).setQuery(val),
        onSubmitted: (_) {},
        decoration: InputDecoration(
          hintText: 'Search pasta, curry, tacos...',
          prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
          suffixIcon: search.query.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: AppColors.textSecondary),
                  onPressed: () {
                    _controller.clear();
                    ref.read(searchStateProvider.notifier).setQuery('');
                  },
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildFilters(BuildContext context, SearchState search) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: Text('Cuisine', style: Theme.of(context).textTheme.labelLarge),
        ),
        SizedBox(
          height: 44,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            scrollDirection: Axis.horizontal,
            itemCount: ApiConstants.cuisines.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final cuisine = ApiConstants.cuisines[i];
              final selected = search.selectedCuisine == cuisine;
              return FilterChip(
                label: Text(cuisine),
                selected: selected,
                onSelected: (v) => ref.read(searchStateProvider.notifier).setCuisine(v ? cuisine : null),
                selectedColor: AppColors.primary,
                checkmarkColor: Colors.white,
                labelStyle: TextStyle(
                  color: selected ? Colors.white : AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: Text('Diet', style: Theme.of(context).textTheme.labelLarge),
        ),
        SizedBox(
          height: 44,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            scrollDirection: Axis.horizontal,
            itemCount: ApiConstants.diets.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final diet = ApiConstants.diets[i];
              final selected = search.selectedDiet == diet['value'];
              return FilterChip(
                avatar: Text(diet['icon'] as String, style: const TextStyle(fontSize: 14)),
                label: Text(diet['label'] as String),
                selected: selected,
                onSelected: (v) => ref.read(searchStateProvider.notifier).setDiet(v ? diet['value'] as String : null),
                selectedColor: AppColors.secondary,
                checkmarkColor: Colors.white,
                labelStyle: TextStyle(
                  color: selected ? Colors.white : AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🔍', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(
            'Search for any recipe',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Try "pasta", "chicken curry", or\nfilter by cuisine and diet',
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
          const Text('😕', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text('No recipes found', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Try a different search term\nor remove some filters',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ).animate().fadeIn(),
    );
  }
}

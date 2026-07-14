import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/recipe.dart';
import '../../data/models/meal_db_models.dart';
import '../../data/models/cocktail_models.dart';
import '../../data/models/food_product_model.dart';
import '../../data/services/spoonacular_service.dart';
import '../../data/services/meal_db_service.dart';
import '../../data/services/cocktail_service.dart';
import '../../data/services/open_food_service.dart';
import '../../data/repositories/favorites_repository.dart';

// ── Services ──────────────────────────────────────────────
final spoonacularServiceProvider = Provider<SpoonacularService>((ref) {
  final s = SpoonacularService();
  ref.onDispose(s.dispose);
  return s;
});

final mealDbServiceProvider = Provider<MealDbService>((ref) {
  final s = MealDbService();
  ref.onDispose(s.dispose);
  return s;
});

final cocktailServiceProvider = Provider<CocktailService>((ref) {
  final s = CocktailService();
  ref.onDispose(s.dispose);
  return s;
});

final openFoodServiceProvider = Provider<OpenFoodService>((ref) {
  final s = OpenFoodService();
  ref.onDispose(s.dispose);
  return s;
});

final favoritesRepositoryProvider = Provider<FavoritesRepository>((ref) {
  return FavoritesRepository();
});

// ── Home ──────────────────────────────────────────────────
final randomRecipesProvider = FutureProvider<List<Recipe>>((ref) async {
  return ref.watch(spoonacularServiceProvider).getRandomRecipes(number: 10);
});

final featuredMealProvider = FutureProvider<MealDbRecipe?>((ref) async {
  return ref.watch(mealDbServiceProvider).getRandomMeal();
});

final categoriesProvider = FutureProvider<List<MealCategory>>((ref) async {
  return ref.watch(mealDbServiceProvider).getCategories();
});

// ── Category browsing ─────────────────────────────────────
final selectedCategoryProvider = StateProvider<String?>((ref) => null);

final categoryMealsProvider = FutureProvider<List<MealDbRecipe>>((ref) async {
  final cat = ref.watch(selectedCategoryProvider);
  if (cat == null) return [];
  return ref.watch(mealDbServiceProvider).filterByCategory(cat);
});

// ── Meal detail (TheMealDB) ───────────────────────────────
final mealDetailProvider = FutureProvider.family<MealDbRecipe?, String>((ref, id) async {
  return ref.watch(mealDbServiceProvider).getMealById(id);
});

// ── Search ────────────────────────────────────────────────
class SearchState {
  final String query;
  final String? selectedCuisine;
  final String? selectedDiet;

  const SearchState({this.query = '', this.selectedCuisine, this.selectedDiet});

  SearchState copyWith({
    String? query,
    String? selectedCuisine,
    String? selectedDiet,
    bool clearCuisine = false,
    bool clearDiet = false,
  }) {
    return SearchState(
      query: query ?? this.query,
      selectedCuisine: clearCuisine ? null : (selectedCuisine ?? this.selectedCuisine),
      selectedDiet: clearDiet ? null : (selectedDiet ?? this.selectedDiet),
    );
  }
}

class SearchStateNotifier extends StateNotifier<SearchState> {
  SearchStateNotifier() : super(const SearchState());
  void setQuery(String q) => state = state.copyWith(query: q);
  void setCuisine(String? c) => state = state.copyWith(selectedCuisine: c, clearCuisine: c == null);
  void setDiet(String? d) => state = state.copyWith(selectedDiet: d, clearDiet: d == null);
  void clear() => state = const SearchState();
}

final searchStateProvider = StateNotifierProvider<SearchStateNotifier, SearchState>((ref) {
  return SearchStateNotifier();
});

final searchResultsProvider = FutureProvider<List<Recipe>>((ref) async {
  final s = ref.watch(searchStateProvider);
  if (s.query.isEmpty && s.selectedCuisine == null && s.selectedDiet == null) return [];
  return ref.watch(spoonacularServiceProvider).searchRecipes(
    query: s.query,
    cuisine: s.selectedCuisine,
    diet: s.selectedDiet,
  );
});

// MealDB search results
final mealDbSearchProvider = FutureProvider<List<MealDbRecipe>>((ref) async {
  final s = ref.watch(searchStateProvider);
  if (s.query.isEmpty) return [];
  return ref.watch(mealDbServiceProvider).searchMeals(s.query);
});

// ── Fridge ────────────────────────────────────────────────
class FridgeModeNotifier extends StateNotifier<List<String>> {
  FridgeModeNotifier() : super([]);
  void addIngredient(String ing) {
    final t = ing.trim().toLowerCase();
    if (t.isNotEmpty && !state.contains(t)) state = [...state, t];
  }
  void removeIngredient(String ing) => state = state.where((i) => i != ing).toList();
  void clear() => state = [];
}

final fridgeIngredientsProvider = StateNotifierProvider<FridgeModeNotifier, List<String>>((ref) {
  return FridgeModeNotifier();
});

final fridgeRecipesProvider = FutureProvider<List<FridgeRecipe>>((ref) async {
  final ings = ref.watch(fridgeIngredientsProvider);
  if (ings.isEmpty) return [];
  return ref.watch(spoonacularServiceProvider).findByIngredients(ings);
});

// ── Recipe detail (Spoonacular) ───────────────────────────
final recipeDetailProvider = FutureProvider.family<RecipeDetail, int>((ref, id) async {
  return ref.watch(spoonacularServiceProvider).getRecipeDetail(id);
});

// ── Servings adjuster ─────────────────────────────────────
final servingsProvider = StateProvider.family<int, int>((ref, defaultServings) => defaultServings);

// ── Timer ─────────────────────────────────────────────────
class TimerState {
  final int totalSeconds;
  final int remaining;
  final bool isRunning;
  final bool isDone;

  const TimerState({
    required this.totalSeconds,
    required this.remaining,
    this.isRunning = false,
    this.isDone = false,
  });

  double get progress => totalSeconds > 0 ? (totalSeconds - remaining) / totalSeconds : 0;
}

// ── Favorites ─────────────────────────────────────────────
class FavoritesNotifier extends StateNotifier<AsyncValue<List<Recipe>>> {
  final FavoritesRepository _repo;

  FavoritesNotifier(this._repo) : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    try {
      state = AsyncValue.data(await _repo.getFavorites());
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> toggle(Recipe recipe) async {
    if (await _repo.isFavorite(recipe.id)) {
      await _repo.removeFavorite(recipe.id);
    } else {
      await _repo.addFavorite(recipe);
    }
    await _load();
  }

  Future<bool> isFavorite(int id) => _repo.isFavorite(id);
}

final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, AsyncValue<List<Recipe>>>((ref) {
  return FavoritesNotifier(ref.watch(favoritesRepositoryProvider));
});

// ── Theme ─────────────────────────────────────────────────
final isDarkModeProvider = StateProvider<bool>((ref) => false);

// ── Cocktails (TheCocktailDB — FREE) ──────────────────────
final randomCocktailProvider = FutureProvider<Cocktail?>((ref) async {
  return ref.watch(cocktailServiceProvider).getRandomCocktail();
});

final cocktailCategoriesProvider = FutureProvider<List<CocktailCategory>>((ref) async {
  return ref.watch(cocktailServiceProvider).getCategories();
});

final selectedCocktailCategoryProvider = StateProvider<String?>((ref) => null);

final cocktailsByCategoryProvider = FutureProvider<List<Cocktail>>((ref) async {
  final cat = ref.watch(selectedCocktailCategoryProvider);
  if (cat == null) return [];
  return ref.watch(cocktailServiceProvider).filterByCategory(cat);
});

final cocktailDetailProvider = FutureProvider.family<CocktailDetail?, String>((ref, id) async {
  return ref.watch(cocktailServiceProvider).getCocktailById(id);
});

final cocktailSearchQueryProvider = StateProvider<String>((ref) => '');

final cocktailSearchResultsProvider = FutureProvider<List<Cocktail>>((ref) async {
  final q = ref.watch(cocktailSearchQueryProvider);
  if (q.isEmpty) return [];
  return ref.watch(cocktailServiceProvider).searchCocktails(q);
});

// ── Open Food Facts (nutrition lookup — FREE) ─────────────
final foodSearchQueryProvider = StateProvider<String>((ref) => '');

final foodProductsProvider = FutureProvider<List<FoodProduct>>((ref) async {
  final q = ref.watch(foodSearchQueryProvider);
  if (q.isEmpty) return [];
  return ref.watch(openFoodServiceProvider).searchProducts(q);
});

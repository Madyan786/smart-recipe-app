import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/recipe.dart';

class FavoritesRepository {
  static const _key = 'favorites';

  Future<List<Recipe>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_key) ?? [];
    return jsonList.map((s) => Recipe.fromJson(json.decode(s) as Map<String, dynamic>)).toList();
  }

  Future<void> addFavorite(Recipe recipe) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_key) ?? [];
    if (!current.any((s) => (json.decode(s) as Map<String, dynamic>)['id'] == recipe.id)) {
      current.add(json.encode(recipe.toJson()));
      await prefs.setStringList(_key, current);
    }
  }

  Future<void> removeFavorite(int recipeId) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_key) ?? [];
    current.removeWhere((s) => (json.decode(s) as Map<String, dynamic>)['id'] == recipeId);
    await prefs.setStringList(_key, current);
  }

  Future<bool> isFavorite(int recipeId) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_key) ?? [];
    return current.any((s) => (json.decode(s) as Map<String, dynamic>)['id'] == recipeId);
  }
}

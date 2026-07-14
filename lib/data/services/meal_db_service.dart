import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/meal_db_models.dart';

class MealDbService {
  static const String _base = 'https://www.themealdb.com/api/json/v1/1';
  final http.Client _client;

  MealDbService({http.Client? client}) : _client = client ?? http.Client();

  Future<List<MealCategory>> getCategories() async {
    final res = await _client.get(Uri.parse('$_base/categories.php'));
    _check(res);
    final data = json.decode(res.body) as Map<String, dynamic>;
    final list = data['categories'] as List<dynamic>;
    return list.map((c) => MealCategory.fromJson(c as Map<String, dynamic>)).toList();
  }

  Future<MealDbRecipe?> getRandomMeal() async {
    final res = await _client.get(Uri.parse('$_base/random.php'));
    _check(res);
    final data = json.decode(res.body) as Map<String, dynamic>;
    final meals = data['meals'] as List<dynamic>?;
    if (meals == null || meals.isEmpty) return null;
    return MealDbRecipe.fromJson(meals[0] as Map<String, dynamic>);
  }

  Future<List<MealDbRecipe>> searchMeals(String query) async {
    final res = await _client.get(Uri.parse('$_base/search.php?s=${Uri.encodeComponent(query)}'));
    _check(res);
    final data = json.decode(res.body) as Map<String, dynamic>;
    final meals = data['meals'] as List<dynamic>? ?? [];
    return meals.map((m) => MealDbRecipe.fromJson(m as Map<String, dynamic>)).toList();
  }

  Future<List<MealDbRecipe>> filterByCategory(String category) async {
    final res = await _client.get(Uri.parse('$_base/filter.php?c=${Uri.encodeComponent(category)}'));
    _check(res);
    final data = json.decode(res.body) as Map<String, dynamic>;
    final meals = data['meals'] as List<dynamic>? ?? [];
    return meals.take(12).map((m) {
      final map = m as Map<String, dynamic>;
      return MealDbRecipe(
        id: map['idMeal'] as String,
        name: map['strMeal'] as String,
        category: category,
        area: '',
        instructions: '',
        thumbnail: map['strMealThumb'] as String? ?? '',
      );
    }).toList();
  }

  Future<MealDbRecipe?> getMealById(String id) async {
    final res = await _client.get(Uri.parse('$_base/lookup.php?i=$id'));
    _check(res);
    final data = json.decode(res.body) as Map<String, dynamic>;
    final meals = data['meals'] as List<dynamic>?;
    if (meals == null || meals.isEmpty) return null;
    return MealDbRecipe.fromJson(meals[0] as Map<String, dynamic>);
  }

  void _check(http.Response res) {
    if (res.statusCode != 200) throw Exception('MealDB error: ${res.statusCode}');
  }

  void dispose() => _client.close();
}

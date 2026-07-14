import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/cocktail_models.dart';

class CocktailService {
  static const _base = 'https://www.thecocktaildb.com/api/json/v1/1';
  final _client = http.Client();

  void dispose() => _client.close();

  Future<List<Cocktail>> searchCocktails(String query) async {
    final uri = Uri.parse('$_base/search.php?s=${Uri.encodeComponent(query)}');
    final res = await _client.get(uri);
    if (res.statusCode != 200) return [];
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final drinks = data['drinks'] as List<dynamic>?;
    if (drinks == null) return [];
    return drinks.map((d) => Cocktail.fromJson(d as Map<String, dynamic>)).toList();
  }

  Future<Cocktail?> getRandomCocktail() async {
    final uri = Uri.parse('$_base/random.php');
    final res = await _client.get(uri);
    if (res.statusCode != 200) return null;
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final drinks = data['drinks'] as List<dynamic>?;
    if (drinks == null || drinks.isEmpty) return null;
    return Cocktail.fromJson(drinks.first as Map<String, dynamic>);
  }

  Future<CocktailDetail?> getCocktailById(String id) async {
    final uri = Uri.parse('$_base/lookup.php?i=$id');
    final res = await _client.get(uri);
    if (res.statusCode != 200) return null;
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final drinks = data['drinks'] as List<dynamic>?;
    if (drinks == null || drinks.isEmpty) return null;
    return CocktailDetail.fromJson(drinks.first as Map<String, dynamic>);
  }

  Future<List<Cocktail>> filterByCategory(String category) async {
    final uri = Uri.parse('$_base/filter.php?c=${Uri.encodeComponent(category)}');
    final res = await _client.get(uri);
    if (res.statusCode != 200) return [];
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final drinks = data['drinks'] as List<dynamic>?;
    if (drinks == null) return [];
    return drinks.map((d) => Cocktail.fromJson(d as Map<String, dynamic>)).toList();
  }

  Future<List<CocktailCategory>> getCategories() async {
    final uri = Uri.parse('$_base/list.php?c=list');
    final res = await _client.get(uri);
    if (res.statusCode != 200) return [];
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final drinks = data['drinks'] as List<dynamic>?;
    if (drinks == null) return [];
    return drinks.map((d) => CocktailCategory.fromJson(d as Map<String, dynamic>)).toList();
  }

  Future<List<Cocktail>> filterByAlcoholic({bool alcoholic = true}) async {
    final filter = alcoholic ? 'Alcoholic' : 'Non_Alcoholic';
    final uri = Uri.parse('$_base/filter.php?a=$filter');
    final res = await _client.get(uri);
    if (res.statusCode != 200) return [];
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final drinks = data['drinks'] as List<dynamic>?;
    if (drinks == null) return [];
    return drinks.map((d) => Cocktail.fromJson(d as Map<String, dynamic>)).toList();
  }
}

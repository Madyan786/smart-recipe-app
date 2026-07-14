import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../models/recipe.dart';

class SpoonacularService {
  final http.Client _client;

  SpoonacularService({http.Client? client}) : _client = client ?? http.Client();

  Uri _buildUri(String path, Map<String, String> params) {
    return Uri.parse('${ApiConstants.baseUrl}$path').replace(
      queryParameters: {'apiKey': ApiConstants.apiKey, ...params},
    );
  }

  Future<List<Recipe>> getRandomRecipes({int number = 10, String? tags}) async {
    final params = <String, String>{'number': '$number'};
    if (tags != null) params['tags'] = tags;

    final response = await _client.get(_buildUri(ApiConstants.randomRecipes, params));
    _checkStatus(response);

    final data = json.decode(response.body) as Map<String, dynamic>;
    final recipes = data['recipes'] as List<dynamic>;
    return recipes.map((r) => Recipe.fromJson(r as Map<String, dynamic>)).toList();
  }

  Future<List<Recipe>> searchRecipes({
    String? query,
    String? cuisine,
    String? diet,
    int number = 12,
    int offset = 0,
  }) async {
    final params = <String, String>{
      'number': '$number',
      'offset': '$offset',
      'addRecipeInformation': 'true',
    };
    if (query != null && query.isNotEmpty) params['query'] = query;
    if (cuisine != null && cuisine.isNotEmpty) params['cuisine'] = cuisine;
    if (diet != null && diet.isNotEmpty) params['diet'] = diet;

    final response = await _client.get(_buildUri(ApiConstants.searchRecipes, params));
    _checkStatus(response);

    final data = json.decode(response.body) as Map<String, dynamic>;
    final results = data['results'] as List<dynamic>;
    return results.map((r) => Recipe.fromJson(r as Map<String, dynamic>)).toList();
  }

  Future<List<FridgeRecipe>> findByIngredients(List<String> ingredients, {int number = 12}) async {
    final params = <String, String>{
      'ingredients': ingredients.join(','),
      'number': '$number',
      'ranking': '1',
      'ignorePantry': 'true',
    };

    final response = await _client.get(_buildUri(ApiConstants.findByIngredients, params));
    _checkStatus(response);

    final data = json.decode(response.body) as List<dynamic>;
    return data.map((r) => FridgeRecipe.fromJson(r as Map<String, dynamic>)).toList();
  }

  Future<RecipeDetail> getRecipeDetail(int id) async {
    final path = ApiConstants.recipeInfo.replaceAll('{id}', '$id');
    final params = <String, String>{'includeNutrition': 'true'};

    final response = await _client.get(_buildUri(path, params));
    _checkStatus(response);

    final data = json.decode(response.body) as Map<String, dynamic>;
    return RecipeDetail.fromJson(data);
  }

  void _checkStatus(http.Response response) {
    if (response.statusCode == 401) throw Exception('Invalid API key. Please check your Spoonacular API key.');
    if (response.statusCode == 402) throw Exception('API quota exceeded. Upgrade your Spoonacular plan.');
    if (response.statusCode != 200) throw Exception('API error: ${response.statusCode}');
  }

  void dispose() => _client.close();
}

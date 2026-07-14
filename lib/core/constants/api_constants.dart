import 'api_keys.dart';

class ApiConstants {
  static const String baseUrl = 'https://api.spoonacular.com';
  static const String apiKey = kSpoonacularApiKey;

  static const String randomRecipes = '/recipes/random';
  static const String searchRecipes = '/recipes/complexSearch';
  static const String findByIngredients = '/recipes/findByIngredients';
  static const String recipeInfo = '/recipes/{id}/information';
  static const String nutrition = '/recipes/{id}/nutritionWidget.json';

  static const List<String> cuisines = [
    'Italian', 'Mexican', 'Indian', 'Chinese', 'Japanese',
    'Thai', 'French', 'Mediterranean', 'American', 'Greek',
  ];

  static const List<Map<String, dynamic>> diets = [
    {'label': 'Vegan', 'icon': '🌱', 'value': 'vegan'},
    {'label': 'Vegetarian', 'icon': '🥦', 'value': 'vegetarian'},
    {'label': 'Keto', 'icon': '🥩', 'value': 'ketogenic'},
    {'label': 'Gluten Free', 'icon': '🌾', 'value': 'gluten free'},
    {'label': 'Paleo', 'icon': '🦴', 'value': 'paleo'},
    {'label': 'Whole30', 'icon': '✅', 'value': 'whole30'},
  ];
}

class Recipe {
  final int id;
  final String title;
  final String image;
  final int readyInMinutes;
  final int servings;
  final double? calories;
  final List<String> dishTypes;
  final List<String> cuisines;
  final List<String> diets;
  final bool vegetarian;
  final bool vegan;
  final bool glutenFree;

  const Recipe({
    required this.id,
    required this.title,
    required this.image,
    this.readyInMinutes = 0,
    this.servings = 1,
    this.calories,
    this.dishTypes = const [],
    this.cuisines = const [],
    this.diets = const [],
    this.vegetarian = false,
    this.vegan = false,
    this.glutenFree = false,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'] as int,
      title: json['title'] as String,
      image: json['image'] as String? ?? '',
      readyInMinutes: json['readyInMinutes'] as int? ?? 0,
      servings: json['servings'] as int? ?? 1,
      dishTypes: (json['dishTypes'] as List<dynamic>?)?.cast<String>() ?? [],
      cuisines: (json['cuisines'] as List<dynamic>?)?.cast<String>() ?? [],
      diets: (json['diets'] as List<dynamic>?)?.cast<String>() ?? [],
      vegetarian: json['vegetarian'] as bool? ?? false,
      vegan: json['vegan'] as bool? ?? false,
      glutenFree: json['glutenFree'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'image': image,
    'readyInMinutes': readyInMinutes,
    'servings': servings,
    'dishTypes': dishTypes,
    'cuisines': cuisines,
    'diets': diets,
    'vegetarian': vegetarian,
    'vegan': vegan,
    'glutenFree': glutenFree,
  };
}

class RecipeDetail extends Recipe {
  final String summary;
  final List<RecipeStep> steps;
  final NutritionInfo? nutrition;
  final List<Ingredient> ingredients;
  final String? sourceUrl;

  const RecipeDetail({
    required super.id,
    required super.title,
    required super.image,
    super.readyInMinutes,
    super.servings,
    super.calories,
    super.dishTypes,
    super.cuisines,
    super.diets,
    super.vegetarian,
    super.vegan,
    super.glutenFree,
    this.summary = '',
    this.steps = const [],
    this.nutrition,
    this.ingredients = const [],
    this.sourceUrl,
  });

  factory RecipeDetail.fromJson(Map<String, dynamic> json) {
    List<RecipeStep> steps = [];
    final analyzedInstructions = json['analyzedInstructions'] as List<dynamic>?;
    if (analyzedInstructions != null && analyzedInstructions.isNotEmpty) {
      final stepsList = (analyzedInstructions[0] as Map<String, dynamic>)['steps'] as List<dynamic>?;
      if (stepsList != null) {
        steps = stepsList.map((s) => RecipeStep.fromJson(s as Map<String, dynamic>)).toList();
      }
    }

    NutritionInfo? nutrition;
    if (json['nutrition'] != null) {
      nutrition = NutritionInfo.fromJson(json['nutrition'] as Map<String, dynamic>);
    }

    final extIngredients = json['extendedIngredients'] as List<dynamic>? ?? [];
    final ingredients = extIngredients.map((i) => Ingredient.fromJson(i as Map<String, dynamic>)).toList();

    return RecipeDetail(
      id: json['id'] as int,
      title: json['title'] as String,
      image: json['image'] as String? ?? '',
      readyInMinutes: json['readyInMinutes'] as int? ?? 0,
      servings: json['servings'] as int? ?? 1,
      summary: _stripHtml(json['summary'] as String? ?? ''),
      dishTypes: (json['dishTypes'] as List<dynamic>?)?.cast<String>() ?? [],
      cuisines: (json['cuisines'] as List<dynamic>?)?.cast<String>() ?? [],
      diets: (json['diets'] as List<dynamic>?)?.cast<String>() ?? [],
      vegetarian: json['vegetarian'] as bool? ?? false,
      vegan: json['vegan'] as bool? ?? false,
      glutenFree: json['glutenFree'] as bool? ?? false,
      steps: steps,
      nutrition: nutrition,
      ingredients: ingredients,
      sourceUrl: json['sourceUrl'] as String?,
    );
  }

  static String _stripHtml(String html) {
    return html.replaceAll(RegExp(r'<[^>]*>'), '').replaceAll('&amp;', '&').replaceAll('&lt;', '<').replaceAll('&gt;', '>');
  }
}

class RecipeStep {
  final int number;
  final String step;

  const RecipeStep({required this.number, required this.step});

  factory RecipeStep.fromJson(Map<String, dynamic> json) {
    return RecipeStep(
      number: json['number'] as int,
      step: json['step'] as String,
    );
  }
}

class Ingredient {
  final int id;
  final String name;
  final String original;
  final double amount;
  final String unit;
  final String? image;

  const Ingredient({
    required this.id,
    required this.name,
    required this.original,
    required this.amount,
    required this.unit,
    this.image,
  });

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      id: json['id'] as int,
      name: json['name'] as String,
      original: json['original'] as String,
      amount: (json['amount'] as num).toDouble(),
      unit: json['unit'] as String? ?? '',
      image: json['image'] as String?,
    );
  }
}

class NutritionInfo {
  final double calories;
  final double protein;
  final double fat;
  final double carbs;
  final double fiber;
  final double sugar;

  const NutritionInfo({
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.fiber,
    required this.sugar,
  });

  factory NutritionInfo.fromJson(Map<String, dynamic> json) {
    double findNutrient(String name) {
      final nutrients = json['nutrients'] as List<dynamic>? ?? [];
      for (final n in nutrients) {
        final nutrient = n as Map<String, dynamic>;
        if ((nutrient['name'] as String).toLowerCase() == name.toLowerCase()) {
          return (nutrient['amount'] as num).toDouble();
        }
      }
      return 0.0;
    }

    return NutritionInfo(
      calories: findNutrient('calories'),
      protein: findNutrient('protein'),
      fat: findNutrient('fat'),
      carbs: findNutrient('carbohydrates'),
      fiber: findNutrient('fiber'),
      sugar: findNutrient('sugar'),
    );
  }
}

class FridgeRecipe {
  final int id;
  final String title;
  final String image;
  final int usedIngredientCount;
  final int missedIngredientCount;
  final List<String> missedIngredients;

  const FridgeRecipe({
    required this.id,
    required this.title,
    required this.image,
    required this.usedIngredientCount,
    required this.missedIngredientCount,
    required this.missedIngredients,
  });

  factory FridgeRecipe.fromJson(Map<String, dynamic> json) {
    final missed = (json['missedIngredients'] as List<dynamic>? ?? [])
        .map((i) => (i as Map<String, dynamic>)['name'] as String)
        .toList();

    return FridgeRecipe(
      id: json['id'] as int,
      title: json['title'] as String,
      image: json['image'] as String? ?? '',
      usedIngredientCount: json['usedIngredientCount'] as int? ?? 0,
      missedIngredientCount: json['missedIngredientCount'] as int? ?? 0,
      missedIngredients: missed,
    );
  }
}

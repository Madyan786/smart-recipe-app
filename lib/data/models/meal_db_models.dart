class MealCategory {
  final String name;
  final String thumbnail;
  final String description;

  const MealCategory({
    required this.name,
    required this.thumbnail,
    required this.description,
  });

  factory MealCategory.fromJson(Map<String, dynamic> json) {
    return MealCategory(
      name: json['strCategory'] as String,
      thumbnail: json['strCategoryThumb'] as String? ?? '',
      description: (json['strCategoryDescription'] as String? ?? '').length > 100
          ? '${(json['strCategoryDescription'] as String).substring(0, 100)}...'
          : (json['strCategoryDescription'] as String? ?? ''),
    );
  }
}

class MealDbRecipe {
  final String id;
  final String name;
  final String category;
  final String area;
  final String instructions;
  final String thumbnail;
  final String? youtubeUrl;
  final String? tags;
  final List<MealIngredient> ingredients;

  const MealDbRecipe({
    required this.id,
    required this.name,
    required this.category,
    required this.area,
    required this.instructions,
    required this.thumbnail,
    this.youtubeUrl,
    this.tags,
    this.ingredients = const [],
  });

  factory MealDbRecipe.fromJson(Map<String, dynamic> json) {
    final ingredients = <MealIngredient>[];
    for (int i = 1; i <= 20; i++) {
      final ing = json['strIngredient$i'] as String?;
      final measure = json['strMeasure$i'] as String?;
      if (ing != null && ing.trim().isNotEmpty) {
        ingredients.add(MealIngredient(
          name: ing.trim(),
          measure: measure?.trim() ?? '',
        ));
      }
    }

    return MealDbRecipe(
      id: json['idMeal'] as String,
      name: json['strMeal'] as String,
      category: json['strCategory'] as String? ?? '',
      area: json['strArea'] as String? ?? '',
      instructions: json['strInstructions'] as String? ?? '',
      thumbnail: json['strMealThumb'] as String? ?? '',
      youtubeUrl: json['strYoutube'] as String?,
      tags: json['strTags'] as String?,
      ingredients: ingredients,
    );
  }

  List<String> get instructionSteps {
    return instructions
        .split(RegExp(r'\r?\n'))
        .where((s) => s.trim().isNotEmpty)
        .toList();
  }
}

class MealIngredient {
  final String name;
  final String measure;

  const MealIngredient({required this.name, required this.measure});
}

class MealArea {
  final String name;
  final String flag;

  const MealArea({required this.name, required this.flag});
}

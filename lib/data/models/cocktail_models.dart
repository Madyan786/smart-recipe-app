class Cocktail {
  final String id;
  final String name;
  final String? category;
  final String? glass;
  final String thumbnail;
  final bool isAlcoholic;
  final List<String> ingredients;

  const Cocktail({
    required this.id,
    required this.name,
    this.category,
    this.glass,
    required this.thumbnail,
    required this.isAlcoholic,
    required this.ingredients,
  });

  factory Cocktail.fromJson(Map<String, dynamic> json) {
    final ingredients = <String>[];
    for (int i = 1; i <= 15; i++) {
      final ing = json['strIngredient$i'];
      if (ing != null && (ing as String).isNotEmpty) ingredients.add(ing);
    }
    return Cocktail(
      id: json['idDrink'] ?? '',
      name: json['strDrink'] ?? '',
      category: json['strCategory'],
      glass: json['strGlass'],
      thumbnail: json['strDrinkThumb'] ?? '',
      isAlcoholic: (json['strAlcoholic'] ?? '').toString().toLowerCase() == 'alcoholic',
      ingredients: ingredients,
    );
  }
}

class CocktailDetail extends Cocktail {
  final String? instructions;
  final String? youtubeUrl;
  final List<CocktailIngredient> fullIngredients;
  final String? tags;

  const CocktailDetail({
    required super.id,
    required super.name,
    super.category,
    super.glass,
    required super.thumbnail,
    required super.isAlcoholic,
    required super.ingredients,
    this.instructions,
    this.youtubeUrl,
    required this.fullIngredients,
    this.tags,
  });

  factory CocktailDetail.fromJson(Map<String, dynamic> json) {
    final ingList = <CocktailIngredient>[];
    for (int i = 1; i <= 15; i++) {
      final ing = json['strIngredient$i'];
      final meas = json['strMeasure$i'];
      if (ing != null && (ing as String).isNotEmpty) {
        ingList.add(CocktailIngredient(name: ing, measure: meas?.toString().trim() ?? ''));
      }
    }
    final base = Cocktail.fromJson(json);
    return CocktailDetail(
      id: base.id,
      name: base.name,
      category: base.category,
      glass: base.glass,
      thumbnail: base.thumbnail,
      isAlcoholic: base.isAlcoholic,
      ingredients: base.ingredients,
      instructions: json['strInstructions'],
      youtubeUrl: json['strVideo'],
      fullIngredients: ingList,
      tags: json['strTags'],
    );
  }
}

class CocktailIngredient {
  final String name;
  final String measure;

  const CocktailIngredient({required this.name, required this.measure});
}

class CocktailCategory {
  final String name;

  const CocktailCategory({required this.name});

  factory CocktailCategory.fromJson(Map<String, dynamic> json) {
    return CocktailCategory(name: json['strCategory'] ?? '');
  }
}

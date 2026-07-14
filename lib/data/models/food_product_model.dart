class FoodProduct {
  final String id;
  final String name;
  final String? brands;
  final String? imageUrl;
  final String? categories;
  final NutritionPer100g? nutrition;
  final List<String> allergens;
  final String? ingredients;
  final String? nutriscore;

  const FoodProduct({
    required this.id,
    required this.name,
    this.brands,
    this.imageUrl,
    this.categories,
    this.nutrition,
    required this.allergens,
    this.ingredients,
    this.nutriscore,
  });

  factory FoodProduct.fromJson(Map<String, dynamic> json) {
    final nutriments = json['nutriments'] as Map<String, dynamic>?;
    final allergensList = <String>[];
    final allergenTags = json['allergens_tags'] as List<dynamic>?;
    if (allergenTags != null) {
      for (final tag in allergenTags) {
        final cleaned = tag.toString().replaceAll('en:', '').replaceAll('-', ' ');
        if (cleaned.isNotEmpty) allergensList.add(cleaned);
      }
    }

    return FoodProduct(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: (json['product_name'] ?? json['product_name_en'] ?? json['abbreviated_product_name'] ?? 'Unknown Product').toString(),
      brands: json['brands']?.toString(),
      imageUrl: json['image_front_url']?.toString() ?? json['image_url']?.toString(),
      categories: json['categories']?.toString(),
      nutrition: nutriments != null ? NutritionPer100g.fromJson(nutriments) : null,
      allergens: allergensList,
      ingredients: json['ingredients_text']?.toString(),
      nutriscore: json['nutriscore_grade']?.toString().toUpperCase(),
    );
  }
}

class NutritionPer100g {
  final double? calories;
  final double? fat;
  final double? saturatedFat;
  final double? carbs;
  final double? sugars;
  final double? fiber;
  final double? protein;
  final double? salt;

  const NutritionPer100g({
    this.calories,
    this.fat,
    this.saturatedFat,
    this.carbs,
    this.sugars,
    this.fiber,
    this.protein,
    this.salt,
  });

  factory NutritionPer100g.fromJson(Map<String, dynamic> json) {
    double? parse(String key) {
      final v = json[key];
      if (v == null) return null;
      return double.tryParse(v.toString());
    }

    return NutritionPer100g(
      calories: parse('energy-kcal_100g') ?? parse('energy-kcal') ?? parse('energy_100g'),
      fat: parse('fat_100g') ?? parse('fat'),
      saturatedFat: parse('saturated-fat_100g') ?? parse('saturated-fat'),
      carbs: parse('carbohydrates_100g') ?? parse('carbohydrates'),
      sugars: parse('sugars_100g') ?? parse('sugars'),
      fiber: parse('fiber_100g') ?? parse('fiber'),
      protein: parse('proteins_100g') ?? parse('proteins'),
      salt: parse('salt_100g') ?? parse('salt'),
    );
  }
}

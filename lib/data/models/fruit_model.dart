class Fruit {
  final String name;
  final String family;
  final double calories;
  final double carbs;
  final double protein;
  final double fat;
  final double sugar;

  const Fruit({
    required this.name,
    required this.family,
    required this.calories,
    required this.carbs,
    required this.protein,
    required this.fat,
    required this.sugar,
  });

  factory Fruit.fromJson(Map<String, dynamic> json) {
    final n = json['nutritions'] as Map<String, dynamic>? ?? {};
    return Fruit(
      name: json['name'] as String? ?? '',
      family: json['family'] as String? ?? '',
      calories: _toDouble(n['calories']),
      carbs: _toDouble(n['carbohydrates']),
      protein: _toDouble(n['protein']),
      fat: _toDouble(n['fat']),
      sugar: _toDouble(n['sugar']),
    );
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    return double.tryParse(v.toString()) ?? 0;
  }
}

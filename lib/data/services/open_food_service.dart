import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/food_product_model.dart';

class OpenFoodService {
  static const _base = 'https://world.openfoodfacts.org';
  final _client = http.Client();

  void dispose() => _client.close();

  Future<List<FoodProduct>> searchProducts(String query, {int page = 1}) async {
    final uri = Uri.parse(
      '$_base/cgi/search.pl?search_terms=${Uri.encodeComponent(query)}'
      '&search_simple=1&action=process&json=1&page=$page&page_size=20'
      '&fields=_id,product_name,product_name_en,brands,image_front_url,image_url,'
      'categories,nutriments,allergens_tags,ingredients_text,nutriscore_grade',
    );
    final res = await _client.get(uri, headers: {'User-Agent': 'SmartRecipeApp/1.0'});
    if (res.statusCode != 200) return [];
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final products = data['products'] as List<dynamic>?;
    if (products == null) return [];
    return products
        .where((p) => (p['product_name'] ?? p['product_name_en'] ?? '').toString().isNotEmpty)
        .map((p) => FoodProduct.fromJson(p as Map<String, dynamic>))
        .toList();
  }

  Future<FoodProduct?> getProductByBarcode(String barcode) async {
    final uri = Uri.parse(
      '$_base/api/v2/product/$barcode.json'
      '?fields=_id,product_name,product_name_en,brands,image_front_url,'
      'categories,nutriments,allergens_tags,ingredients_text,nutriscore_grade',
    );
    final res = await _client.get(uri, headers: {'User-Agent': 'SmartRecipeApp/1.0'});
    if (res.statusCode != 200) return null;
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (data['status'] != 1) return null;
    final product = data['product'] as Map<String, dynamic>?;
    if (product == null) return null;
    return FoodProduct.fromJson(product);
  }
}

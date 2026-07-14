import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/fruit_model.dart';

class FruityviceService {
  static const _base = 'https://www.fruityvice.com/api/fruit';
  final _client = http.Client();

  void dispose() => _client.close();

  Future<Fruit?> getFruitInfo(String name) async {
    try {
      final uri = Uri.parse('$_base/${Uri.encodeComponent(name.toLowerCase())}');
      final res = await _client.get(uri).timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        return Fruit.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
      }
    } catch (_) {}
    return null;
  }

  Future<List<Fruit>> getAllFruits() async {
    try {
      final uri = Uri.parse('$_base/all');
      final res = await _client.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List<dynamic>;
        return list
            .map((f) => Fruit.fromJson(f as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return [];
  }
}

import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

class AdviceService {
  static const _base = 'https://api.adviceslip.com';
  final _client = http.Client();

  void dispose() => _client.close();

  Future<String> getCookingTip() async {
    try {
      final res = await _client
          .get(Uri.parse('$_base/advice/search/cook'))
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final slips = data['slips'] as List<dynamic>?;
        if (slips != null && slips.isNotEmpty) {
          final random = slips[Random().nextInt(slips.length)];
          return (random as Map<String, dynamic>)['advice'] as String;
        }
      }
    } catch (_) {}
    return _fallbackTips[Random().nextInt(_fallbackTips.length)];
  }

  static const _fallbackTips = [
    'The secret ingredient is always love. — Chef Unknown',
    'Cooking is an art, but all art requires knowing something about the techniques. — Nathan Myhrvold',
    'You don\'t have to cook fancy or complicated masterpieces — just good food from fresh ingredients.',
    'The discovery of a new dish does more for human happiness than the discovery of a new star. — Brillat-Savarin',
    'Taste as you go. The best chefs never stop tasting.',
    'Mise en place — have everything ready before you start cooking.',
    'A recipe has no soul. You, as the cook, must bring soul to the recipe. — Thomas Keller',
    'Salt is the most important ingredient. Season at every layer.',
    'Let meat rest after cooking so the juices redistribute.',
    'High heat = flavour. Don\'t crowd the pan!',
  ];
}

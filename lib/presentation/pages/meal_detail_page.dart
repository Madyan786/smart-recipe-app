import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:async';
import '../../core/theme/app_theme.dart';
import '../providers/recipe_providers.dart';

class MealDetailPage extends ConsumerStatefulWidget {
  final String mealId;
  final String mealName;
  final String mealThumb;

  const MealDetailPage({
    super.key,
    required this.mealId,
    required this.mealName,
    required this.mealThumb,
  });

  @override
  ConsumerState<MealDetailPage> createState() => _MealDetailPageState();
}

class _MealDetailPageState extends ConsumerState<MealDetailPage> {
  // ── Timer state ───────────────────────────────────────────
  int _timerMinutes = 30;
  int _remaining = 0;
  bool _timerRunning = false;
  Timer? _timer;

  // ── Servings ──────────────────────────────────────────────
  int _servings = 4;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _remaining = _timerMinutes * 60;
    setState(() => _timerRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_remaining <= 0) {
        t.cancel();
        setState(() => _timerRunning = false);
      } else {
        setState(() => _remaining--);
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() {_timerRunning = false; _remaining = 0;});
  }

  String get _timerDisplay {
    final m = _remaining ~/ 60;
    final s = _remaining % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  double get _timerProgress =>
      _timerMinutes > 0 ? 1 - (_remaining / (_timerMinutes * 60)) : 0;

  @override
  Widget build(BuildContext context) {
    final mealAsync = ref.watch(mealDetailProvider(widget.mealId));

    return Scaffold(
      body: mealAsync.when(
        data: (meal) {
          if (meal == null) {
            return const Center(child: Text('Recipe not found'));
          }
          return CustomScrollView(
            slivers: [
              // ── Hero image app bar ────────────────────────
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                stretch: true,
                backgroundColor: AppColors.primary,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: meal.thumbnail,
                        fit: BoxFit.cover,
                        errorWidget: (_, _, _) => Container(color: AppColors.primaryLight),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black.withAlpha(200)],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 16,
                        left: 20,
                        right: 70,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(meal.name,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    shadows: [Shadow(blurRadius: 8, color: Colors.black45)])),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                if (meal.category.isNotEmpty)
                                  _infoBadge(meal.category, Icons.category_outlined),
                                if (meal.area.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  _infoBadge(meal.area, Icons.place_outlined),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  // Share button
                  Container(
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(color: Colors.white.withAlpha(200), shape: BoxShape.circle),
                    child: IconButton(
                      icon: const Icon(Icons.share_outlined, color: AppColors.textPrimary),
                      onPressed: () => Share.share(
                        '🍽️ Check out this amazing recipe: ${meal.name}\n\nCategory: ${meal.category} | Origin: ${meal.area}\n\nMade with SmartRecipe App!',
                        subject: meal.name,
                      ),
                    ),
                  ),
                  // YouTube button
                  if (meal.youtubeUrl != null && meal.youtubeUrl!.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(color: Colors.white.withAlpha(200), shape: BoxShape.circle),
                      child: IconButton(
                        icon: const Icon(Icons.play_circle_outline, color: Color(0xFFFF0000)),
                        onPressed: () => _launchUrl(meal.youtubeUrl!),
                      ),
                    ),
                ],
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Tags ─────────────────────────────
                      if (meal.tags != null && meal.tags!.isNotEmpty) ...[
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: meal.tags!.split(',').where((t) => t.trim().isNotEmpty).map((tag) =>
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withAlpha(20),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.primary.withAlpha(40)),
                              ),
                              child: Text('#${tag.trim()}',
                                  style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
                            ),
                          ).toList(),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // ── Cooking Timer ─────────────────────
                      _buildTimer(context),
                      const SizedBox(height: 24),

                      // ── Ingredients with servings ─────────
                      _buildIngredientsSection(context, meal.ingredients),
                      const SizedBox(height: 24),

                      // ── Instructions ──────────────────────
                      if (meal.instructionSteps.isNotEmpty) ...[
                        _sectionTitle(context, 'Instructions 📋'),
                        const SizedBox(height: 12),
                        ...meal.instructionSteps.asMap().entries.map((e) =>
                          _stepCard(context, e.key + 1, e.value)),
                        const SizedBox(height: 24),
                      ],

                      // ── YouTube CTA ───────────────────────
                      if (meal.youtubeUrl != null && meal.youtubeUrl!.isNotEmpty)
                        _buildYoutubeCta(context, meal.youtubeUrl!),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(height: 16),
              Text('Loading recipe...', style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 60, color: AppColors.error),
              const SizedBox(height: 16),
              Text(e.toString(), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  // ── Timer widget ──────────────────────────────────────────
  Widget _buildTimer(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withAlpha(20), AppColors.primaryLight.withAlpha(10)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(context, 'Cooking Timer ⏱️'),
          const SizedBox(height: 14),
          Row(
            children: [
              // Progress circle
              SizedBox(
                width: 80,
                height: 80,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: _timerRunning ? _timerProgress : 0,
                      backgroundColor: AppColors.primary.withAlpha(30),
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                      strokeWidth: 6,
                    ),
                    Text(
                      _timerRunning ? _timerDisplay : '${_timerMinutes}m',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: _timerRunning ? 16 : 18,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!_timerRunning) ...[
                      Text('Set minutes:', style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _timerBtn(Icons.remove, () {
                            if (_timerMinutes > 5) setState(() => _timerMinutes -= 5);
                          }),
                          const SizedBox(width: 8),
                          Text('$_timerMinutes min',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.primary)),
                          const SizedBox(width: 8),
                          _timerBtn(Icons.add, () => setState(() => _timerMinutes += 5)),
                        ],
                      ),
                    ] else
                      Text('Cooking in progress...', style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _timerRunning ? _stopTimer : _startTimer,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _timerRunning ? AppColors.error : AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              elevation: 0,
                            ),
                            child: Text(_timerRunning ? '⏹ Stop' : '▶ Start',
                                style: const TextStyle(fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _timerBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppColors.primary.withAlpha(20),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.primary.withAlpha(50)),
        ),
        child: Icon(icon, size: 18, color: AppColors.primary),
      ),
    );
  }

  // ── Ingredients section ───────────────────────────────────
  Widget _buildIngredientsSection(BuildContext context, List<dynamic> ingredients) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _sectionTitle(context, 'Ingredients 🥕'),
            // Servings adjuster
            Row(
              children: [
                const Icon(Icons.people_outline, size: 16, color: AppColors.primary),
                const SizedBox(width: 4),
                _adjustBtn(Icons.remove, () {
                  if (_servings > 1) setState(() => _servings--);
                }),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text('$_servings',
                      style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary, fontSize: 16)),
                ),
                _adjustBtn(Icons.add, () => setState(() => _servings++)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...ingredients.asMap().entries.map((e) {
          final i = e.key;
          final ing = e.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text('${i + 1}',
                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    ing.name,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
                Text(
                  ing.measure,
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms, delay: (i * 30).ms);
        }),
      ],
    );
  }

  Widget _adjustBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.primary.withAlpha(20),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: AppColors.primary),
      ),
    );
  }

  // ── Step card ─────────────────────────────────────────────
  Widget _stepCard(BuildContext context, int num, String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryLight],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text('$num',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(text,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6)),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: (num * 40).ms).slideX(begin: 0.1);
  }

  // ── YouTube CTA ───────────────────────────────────────────
  Widget _buildYoutubeCta(BuildContext context, String url) {
    return GestureDetector(
      onTap: () => _launchUrl(url),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFF0000).withAlpha(15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFF0000).withAlpha(60)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFF0000),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Watch on YouTube',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 16)),
                  Text('See how this recipe is made step by step',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textSecondary),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1);
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Text(title, style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize: 18));
  }

  Widget _infoBadge(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(40),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 12),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

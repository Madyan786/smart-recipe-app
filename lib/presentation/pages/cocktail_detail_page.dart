import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_theme.dart';
import '../providers/recipe_providers.dart';

class CocktailDetailPage extends ConsumerStatefulWidget {
  final String id;
  final String name;
  final String thumb;

  const CocktailDetailPage({
    super.key,
    required this.id,
    required this.name,
    required this.thumb,
  });

  @override
  ConsumerState<CocktailDetailPage> createState() => _CocktailDetailPageState();
}

class _CocktailDetailPageState extends ConsumerState<CocktailDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  Timer? _timer;
  int _timerSeconds = 300;
  int _remaining = 300;
  bool _timerRunning = false;

  static const _drinkColor = Color(0xFFE63946);

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _timerRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remaining <= 0) {
        _timer?.cancel();
        setState(() => _timerRunning = false);
      } else {
        setState(() => _remaining--);
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() {
      _timerRunning = false;
      _remaining = _timerSeconds;
    });
  }

  String _formatTime(int s) => '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(cocktailDetailProvider(widget.id));

    return Scaffold(
      body: detailAsync.when(
        data: (detail) {
          if (detail == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.local_bar_outlined, size: 64, color: AppColors.textSecondary),
                  const SizedBox(height: 16),
                  Text('Drink not found', style: Theme.of(context).textTheme.headlineMedium),
                ],
              ),
            );
          }
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                stretch: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Hero(
                        tag: 'cocktail_${widget.id}',
                        child: CachedNetworkImage(
                          imageUrl: detail.thumbnail,
                          fit: BoxFit.cover,
                          errorWidget: (_, _, _) => Container(
                            color: _drinkColor.withAlpha(30),
                            child: const Icon(Icons.local_bar_rounded,
                                size: 80, color: _drinkColor),
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black.withAlpha(180)],
                            stops: const [0.4, 1.0],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.share_outlined, color: Colors.white),
                    onPressed: () {
                      Share.share(
                        '${detail.name} cocktail recipe!\n\nIngredients: ${detail.ingredients.join(', ')}\n\nDiscover more in SmartRecipe App!',
                        subject: detail.name,
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(detail.name,
                                style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 26)),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: detail.isAlcoholic
                                  ? Colors.orange.withAlpha(30)
                                  : Colors.green.withAlpha(30),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: detail.isAlcoholic ? Colors.orange : Colors.green),
                            ),
                            child: Text(
                              detail.isAlcoholic ? '🍸 Cocktail' : '🧃 Mocktail',
                              style: TextStyle(
                                color: detail.isAlcoholic ? Colors.orange : Colors.green,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          if (detail.category != null)
                            _InfoChip(
                                icon: Icons.category_outlined,
                                label: detail.category!,
                                color: _drinkColor),
                          if (detail.glass != null)
                            _InfoChip(
                                icon: Icons.wine_bar_outlined,
                                label: detail.glass!,
                                color: _drinkColor),
                          if (detail.tags != null && detail.tags!.isNotEmpty)
                            ...detail.tags!.split(',').take(3).map(
                                  (t) => _InfoChip(
                                      icon: Icons.tag,
                                      label: t.trim(),
                                      color: AppColors.primary),
                                ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Timer card
                      _timerCard(context),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: TabBar(
                  controller: _tabCtrl,
                  labelColor: _drinkColor,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorColor: _drinkColor,
                  tabs: const [Tab(text: 'Ingredients'), Tab(text: 'Instructions')],
                ),
              ),
              SliverFillRemaining(
                child: TabBarView(
                  controller: _tabCtrl,
                  children: [
                    _ingredientsTab(context, detail.fullIngredients),
                    _instructionsTab(context, detail.instructions),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Error: $e', style: Theme.of(context).textTheme.bodyMedium),
        ),
      ),
    );
  }

  Widget _timerCard(BuildContext context) {
    final progress = _timerSeconds > 0 ? (_timerSeconds - _remaining) / _timerSeconds : 0.0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _drinkColor.withAlpha(10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _drinkColor.withAlpha(40)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 5,
                  backgroundColor: _drinkColor.withAlpha(30),
                  color: _drinkColor,
                ),
                Center(
                  child: Text(
                    _formatTime(_remaining),
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700, color: _drinkColor),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Prep Timer',
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(fontWeight: FontWeight.w700)),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: () => setState(() {
                        _timerSeconds = (_timerSeconds - 60).clamp(60, 3600);
                        if (!_timerRunning) _remaining = _timerSeconds;
                      }),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 4),
                    Text('${_timerSeconds ~/ 60} min',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: () => setState(() {
                        _timerSeconds = (_timerSeconds + 60).clamp(60, 3600);
                        if (!_timerRunning) _remaining = _timerSeconds;
                      }),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _timerRunning ? _stopTimer : _startTimer,
            style: ElevatedButton.styleFrom(
              backgroundColor: _drinkColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            child: Text(_timerRunning ? 'Stop' : 'Start'),
          ),
        ],
      ),
    );
  }

  Widget _ingredientsTab(BuildContext context, List ingList) {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: ingList.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (ctx, i) {
        final ing = ingList[i];
        final imageUrl =
            'https://www.thecocktaildb.com/images/ingredients/${Uri.encodeComponent(ing.name)}-Small.png';
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              width: 44,
              height: 44,
              fit: BoxFit.contain,
              errorWidget: (_, _, _) => Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                    color: _drinkColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.science_outlined, color: _drinkColor, size: 20),
              ),
            ),
          ),
          title: Text(ing.name,
              style: Theme.of(ctx).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
          trailing: ing.measure.isNotEmpty
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _drinkColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(ing.measure,
                      style: const TextStyle(
                          color: _drinkColor, fontWeight: FontWeight.w700, fontSize: 12)),
                )
              : null,
        );
      },
    );
  }

  Widget _instructionsTab(BuildContext context, String? instructions) {
    if (instructions == null || instructions.isEmpty) {
      return const Center(child: Text('No instructions available'));
    }
    final steps = instructions
        .split('. ')
        .where((s) => s.trim().isNotEmpty)
        .toList();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        for (int i = 0; i < steps.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: _drinkColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text('${i + 1}',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    steps[i].trim().endsWith('.') ? steps[i].trim() : '${steps[i].trim()}.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        if (ref.watch(cocktailDetailProvider(widget.id)).value?.youtubeUrl?.isNotEmpty == true)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: GestureDetector(
              onTap: () async {
                final url = ref.read(cocktailDetailProvider(widget.id)).value?.youtubeUrl;
                if (url != null && url.isNotEmpty) {
                  final uri = Uri.parse(url);
                  if (await canLaunchUrl(uri)) launchUrl(uri);
                }
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF0000).withAlpha(15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFF0000).withAlpha(60)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.play_circle_fill_rounded,
                        color: Color(0xFFFF0000), size: 36),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Watch on YouTube',
                              style: TextStyle(
                                  color: Color(0xFFFF0000),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15)),
                          Text('See how to make this drink',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    Icon(Icons.open_in_new_rounded, color: AppColors.textSecondary, size: 16),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

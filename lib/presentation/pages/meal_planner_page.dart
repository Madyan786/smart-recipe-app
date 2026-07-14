import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_theme.dart';

// ── Meal planner state ─────────────────────────────────────────
class MealPlanNotifier extends StateNotifier<Map<String, Map<String, String>>> {
  static const _key = 'meal_plan_v1';

  MealPlanNotifier() : super({}) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        state = decoded.map(
          (day, slots) => MapEntry(
            day,
            (slots as Map<String, dynamic>)
                .map((s, m) => MapEntry(s, m as String)),
          ),
        );
      } catch (_) {}
    }
  }

  Future<void> setMeal(String day, String slot, String meal) async {
    state = {
      ...state,
      day: {...(state[day] ?? {}), slot: meal},
    };
    await _persist();
  }

  Future<void> clearMeal(String day, String slot) async {
    final updated = Map<String, String>.from(state[day] ?? {});
    updated.remove(slot);
    state = {...state, day: updated};
    await _persist();
  }

  Future<void> clearDay(String day) async {
    final updated = Map<String, Map<String, String>>.from(state);
    updated.remove(day);
    state = updated;
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(state));
  }
}

final mealPlanProvider =
    StateNotifierProvider<MealPlanNotifier, Map<String, Map<String, String>>>(
  (ref) => MealPlanNotifier(),
);

// ── Page ───────────────────────────────────────────────────────
class MealPlannerPage extends ConsumerStatefulWidget {
  const MealPlannerPage({super.key});

  @override
  ConsumerState<MealPlannerPage> createState() => _MealPlannerPageState();
}

class _MealPlannerPageState extends ConsumerState<MealPlannerPage> {
  static const _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static const _slots = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];

  static const _slotIcons = {
    'Breakfast': Icons.free_breakfast_outlined,
    'Lunch': Icons.lunch_dining_outlined,
    'Dinner': Icons.dinner_dining_outlined,
    'Snack': Icons.cookie_outlined,
  };

  static const _slotColors = {
    'Breakfast': Color(0xFFFF9800),
    'Lunch': Color(0xFF4CAF50),
    'Dinner': Color(0xFF3F51B5),
    'Snack': Color(0xFFE91E63),
  };

  @override
  Widget build(BuildContext context) {
    final plan = ref.watch(mealPlanProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Meal Planner',
            style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Clear all',
            onPressed: () => _confirmClearAll(context),
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
        itemCount: _days.length,
        separatorBuilder: (c, i) => const SizedBox(height: 16),
        itemBuilder: (context, i) {
          final day = _days[i];
          final dayPlan = plan[day] ?? {};
          return _DayCard(
            day: day,
            dayPlan: dayPlan,
            slots: _slots,
            slotIcons: _slotIcons,
            slotColors: _slotColors,
            onAddMeal: (slot) => _showAddMealSheet(context, day, slot),
            onClearMeal: (slot) =>
                ref.read(mealPlanProvider.notifier).clearMeal(day, slot),
            onClearDay: () =>
                ref.read(mealPlanProvider.notifier).clearDay(day),
          );
        },
      ),
    );
  }

  void _showAddMealSheet(BuildContext context, String day, String slot) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$day — $slot',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text('What are you planning to eat?',
                style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'e.g. Avocado toast with eggs',
                prefixIcon: const Icon(Icons.edit_outlined),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                      color: AppColors.primary, width: 2),
                ),
              ),
              onSubmitted: (v) => _saveMeal(ctx, day, slot, v),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14))),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () =>
                        _saveMeal(ctx, day, slot, controller.text),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _saveMeal(BuildContext ctx, String day, String slot, String text) {
    final trimmed = text.trim();
    if (trimmed.isNotEmpty) {
      ref.read(mealPlanProvider.notifier).setMeal(day, slot, trimmed);
    }
    Navigator.pop(ctx);
  }

  void _confirmClearAll(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear all plans?'),
        content: const Text('This will remove all meals from your weekly plan.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              for (final day in _days) {
                ref.read(mealPlanProvider.notifier).clearDay(day);
              }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}

// ── Day Card ───────────────────────────────────────────────────
class _DayCard extends StatelessWidget {
  final String day;
  final Map<String, String> dayPlan;
  final List<String> slots;
  final Map<String, IconData> slotIcons;
  final Map<String, Color> slotColors;
  final void Function(String slot) onAddMeal;
  final void Function(String slot) onClearMeal;
  final VoidCallback onClearDay;

  const _DayCard({
    required this.day,
    required this.dayPlan,
    required this.slots,
    required this.slotIcons,
    required this.slotColors,
    required this.onAddMeal,
    required this.onClearMeal,
    required this.onClearDay,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filledCount = dayPlan.values.where((v) => v.isNotEmpty).length;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: AppColors.primary.withAlpha(10),
              blurRadius: 20,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day header
          Container(
            padding: const EdgeInsets.fromLTRB(18, 14, 12, 14),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(isDark ? 30 : 15),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Text(day,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w800)),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: filledCount > 0
                        ? AppColors.primary.withAlpha(40)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$filledCount/${slots.length} meals',
                    style: TextStyle(
                      fontSize: 11,
                      color: filledCount > 0
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                if (filledCount > 0)
                  IconButton(
                    icon: const Icon(Icons.clear_all_rounded,
                        size: 20, color: AppColors.textSecondary),
                    tooltip: 'Clear $day',
                    onPressed: onClearDay,
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ),
          // Slots
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Column(
              children: slots.map((slot) {
                final meal = dayPlan[slot];
                final color = slotColors[slot] ?? AppColors.primary;
                final icon = slotIcons[slot] ?? Icons.restaurant_outlined;
                return _SlotRow(
                  slot: slot,
                  icon: icon,
                  color: color,
                  meal: meal,
                  onTap: () => onAddMeal(slot),
                  onClear: meal != null ? () => onClearMeal(slot) : null,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Slot Row ───────────────────────────────────────────────────
class _SlotRow extends StatelessWidget {
  final String slot;
  final IconData icon;
  final Color color;
  final String? meal;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _SlotRow({
    required this.slot,
    required this.icon,
    required this.color,
    required this.meal,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final hasMeal = meal != null && meal!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: hasMeal
                ? color.withAlpha(15)
                : Colors.grey.withAlpha(10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasMeal ? color.withAlpha(60) : Colors.grey.withAlpha(30),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(slot,
                        style: TextStyle(
                            fontSize: 11,
                            color: color,
                            fontWeight: FontWeight.w700)),
                    if (hasMeal)
                      Text(meal!,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w500))
                    else
                      const Text('Tap to add meal',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary)),
                  ],
                ),
              ),
              if (hasMeal && onClear != null)
                GestureDetector(
                  onTap: onClear,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: const Icon(Icons.close_rounded,
                        size: 16, color: AppColors.textSecondary),
                  ),
                )
              else
                const Icon(Icons.add_rounded,
                    size: 18, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

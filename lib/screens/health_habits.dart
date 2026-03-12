import 'package:flutter/material.dart';

import 'meal_plan.dart';

class HealthHabits extends StatefulWidget {
  const HealthHabits({super.key});

  @override
  State<HealthHabits> createState() => _HealthHabitsState();
}

class _HealthHabitsState extends State<HealthHabits> {
  final List<String> recommended = const [
    'Plan more meals',
    'Eat more protein',
    'Track macros',
    'Workout more',
    'Track calories',
  ];

  final List<String> moreHabits = const [
    'Track nutrients',
    'Eat mindfully',
    'Eat a balanced diet',
    'Eat whole foods',
    'Eat more fiber',
    'Eat more vegetables',
    'Eat more fruit',
    'Drink more water',
    'Prioritize sleep',
    'Move more',
    'Meal prep and cook',
    'Something else',
    "I'm not sure",
  ];

  final Set<String> selected = {};

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF1A1C23),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF4C8DF6),
        brightness: Brightness.dark,
      ),
      textTheme: const TextTheme(
        headlineSmall: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
        titleMedium: TextStyle(
          fontSize: 14,
          color: Color(0xFF9AA4B2),
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
        bodyLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
      ),
      useMaterial3: true,
    );

    return Theme(
      data: theme,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 15, right: 15, top: 5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    const Text(
                      "Goals",
                      style: TextStyle(fontSize: 20, color: Colors.white),
                    ),
                    const SizedBox(height: 40),
                    Row(
                      children: List.generate(10, (index) {
                        return Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            height: 4,
                            decoration: BoxDecoration(
                              color: index == 2
                                  ? const Color(0xFF37c47e)
                                  : Colors.grey[700],
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Which health habits are most important to you?',
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 18),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(left: 15, right: 15, top: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Recommended for you',
                          style: theme.textTheme.titleMedium),
                      const SizedBox(height: 12),
                      _ChipWrap(
                        items: recommended,
                        selected: selected,
                        onToggle: _toggle,
                      ),
                      const SizedBox(height: 28),
                      Text('More healthy habits',
                          style: theme.textTheme.titleMedium),
                      const SizedBox(height: 12),
                      _ChipWrap(
                        items: moreHabits,
                        selected: selected,
                        onToggle: _toggle,
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // Bottom bar always visible
              Container(
                color: const Color(0xFF151724),
                padding: const EdgeInsets.all(15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.blue.withOpacity(0.2),
                      radius: 25,
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_outlined,
                            color: Color(0xFF4f9bff)),
                      ),
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.75,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4f9bff),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            if (selected.isEmpty) {
                              selected.add("I'm not sure");
                            }
                          });
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const MealPlan()),
                          );
                        },
                        child: const Text(
                          "Next",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggle(String value) {
    setState(() {
      if (selected.contains(value)) {
        selected.remove(value);
      } else {
        selected.add(value);
      }
    });
  }
}

/// Wrap of pill chips matching the screenshot style
class _ChipWrap extends StatelessWidget {
  final List<String> items;
  final Set<String> selected;
  final void Function(String) onToggle;

  const _ChipWrap({
    required this.items,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 10,
      runSpacing: 18,
      children: items.map((text) {
        final isSel = selected.contains(text);
        return InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: () => onToggle(text),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: isSel
                  ? cs.primary.withOpacity(0.18)
                  : const Color(0xFF252733),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isSel ? cs.primary : const Color(0xFF2A3140),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSel) ...[
                  Icon(Icons.check_rounded, size: 18, color: cs.primary),
                  const SizedBox(width: 8),
                ],
                Text(
                  text,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

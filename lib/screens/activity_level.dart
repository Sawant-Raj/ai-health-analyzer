import 'package:flutter/material.dart';
import 'package:smart_scale/core/tag_utils.dart';
import 'package:smart_scale/core/user_prefs.dart';
import 'package:smart_scale/core/nutrition_calculator.dart' show ActivityLevel;

import 'allergies.dart';

class ActivityLevelScreen extends StatefulWidget {
  const ActivityLevelScreen({super.key});

  @override
  State<ActivityLevelScreen> createState() => _ActivityLevelScreenState();
}

class _ActivityLevelScreenState extends State<ActivityLevelScreen> {
  final List<_ActivityOption> options = const [
    _ActivityOption(
      title: 'Not Very Active',
      subtitle: 'Mostly sitting with little or no physical activity',
    ),
    _ActivityOption(
      title: 'Lightly Active',
      subtitle: 'Light exercise or sports 1–3 times per week',
    ),
    _ActivityOption(
      title: 'Active',
      subtitle: 'An active job or moderate exercise 3–5 times per week',
    ),
    _ActivityOption(
      title: 'Very Active',
      subtitle:
          'A physically demanding job or intense exercise 6–7 times per week',
    ),
  ];

  int selectedIndex = -1;

  Future<void> _saveActivityLevel() async {
    final a = switch (selectedIndex) {
      0 => ActivityLevel.sedentary,
      1 => ActivityLevel.light,
      2 => ActivityLevel.moderate,
      3 => ActivityLevel.veryActive,
      _ => ActivityLevel.sedentary,
    };

    final prefCode = TagUtils.mapActivityEnumToCode(a);
    await UserPrefs.saveActivity(prefCode);
  }

  void _showError() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.grey[800],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding:
              const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min, // shrink to content
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "What's your activity level?",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "It helps us personalize your meal recommendations.",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Go Back",
                    style: TextStyle(
                        color: Colors.blue, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      scaffoldBackgroundColor: const Color(0xFF1A1C23),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF4F9BFF),
        secondary: Color(0xFF4F9BFF),
      ),
      textTheme: const TextTheme(
        headlineSmall: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
        titleMedium: TextStyle(
            fontSize: 14, color: Colors.white60, fontWeight: FontWeight.bold),
        bodyLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
      ),
      useMaterial3: true,
    );

    return Theme(
      data: theme,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              // CONTENT
              Expanded(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),
                      const Text('Activity Level',
                          style: TextStyle(fontSize: 20, color: Colors.white)),
                      const SizedBox(height: 40),
                      Row(
                        children: List.generate(10, (index) {
                          return Expanded(
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              height: 4,
                              decoration: BoxDecoration(
                                color: index == 4
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
                        'What is your baseline activity level?',
                        style: theme.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Not including workouts – we count that separately.',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 35),

                      const Text(
                        "Choose what describes you best:",
                        style: TextStyle(fontSize: 12, color: Colors.white60),
                      ),
                      const SizedBox(height: 8),

                      // Option cards
                      for (int i = 0; i < options.length; i++) ...[
                        _ActivityCard(
                          option: options[i],
                          selected: selectedIndex == i,
                          onTap: () => setState(() => selectedIndex = i),
                        ),
                        const SizedBox(height: 8),
                      ],
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),

              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  color: const Color(0xFF151724),
                  padding: const EdgeInsets.all(15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.blue.withOpacity(0.2),
                        radius: 25,
                        child: IconButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
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
                          onPressed: () async {
                            if (selectedIndex != -1) {
                              await _saveActivityLevel();

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        AllergyRestrictions()),
                              );
                            } else {
                              _showError();
                            }
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityOption {
  final String title;
  final String subtitle;
  const _ActivityOption({required this.title, required this.subtitle});
}

class _ActivityCard extends StatelessWidget {
  final _ActivityOption option;
  final bool selected;
  final VoidCallback onTap;

  const _ActivityCard({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: const Color(0xFF1A1F29),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF252733),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? cs.primary : const Color(0xFF2A3140),
              width: 2,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Texts
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(option.title,
                        style: const TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white)),
                    const SizedBox(height: 6),
                    Text(
                      option.subtitle,
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: Color(0xFF9AA4B2),
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _CheckDot(selected: selected),
            ],
          ),
        ),
      ),
    );
  }
}

/// Circular dot with a check mark when selected
class _CheckDot extends StatelessWidget {
  final bool selected;
  const _CheckDot({required this.selected});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? cs.primary : const Color(0xFF6B7280),
          width: 2,
        ),
        color: selected ? cs.primary.withOpacity(0.15) : Colors.transparent,
      ),
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          transitionBuilder: (child, anim) =>
              ScaleTransition(scale: anim, child: child),
          child: selected
              ? Icon(Icons.check,
                  key: const ValueKey(true), size: 16, color: cs.primary)
              : const SizedBox.shrink(key: ValueKey(false)),
        ),
      ),
    );
  }
}

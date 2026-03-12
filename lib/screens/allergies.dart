import 'package:flutter/material.dart';
import 'package:smart_scale/core/tag_utils.dart';

import '../core/user_prefs.dart';
import 'medical_condition.dart';

class AllergyRestrictions extends StatefulWidget {
  const AllergyRestrictions({super.key});

  @override
  State<AllergyRestrictions> createState() => _AllergyRestrictionsState();
}

class _AllergyRestrictionsState extends State<AllergyRestrictions> {
  final List<String> allergies = const [
    'Dairy',
    'Eggs',
    'Fish',
    'Gluten (Wheat)',
    'Peanuts',
    'Shellfish',
    'Soy',
    'Tree Nuts',
    'Mustard seeds',
    'Sesame (Til)',
    'Other',
    "I don’t have any",
  ];

  final List<String> preference = const [
    'Vegetarian',
    'Non-Vegetarian',
    'Eggetarian',
    'Vegan',
  ];

  Set<String> _selectedAllergies = {};
  String _selectedPreference = '';

  void _toggleAllergy(String value) {
    setState(() {
      if (value == "I don’t have any") {
        _selectedAllergies = {"I don’t have any"};
      } else {
        _selectedAllergies.remove("I don’t have any");
        if (_selectedAllergies.contains(value)) {
          _selectedAllergies.remove(value);
        } else {
          _selectedAllergies.add(value);
        }
      }
    });
  }

  void _togglePreference(String value) {
    setState(() {
      _selectedPreference = value;
    });
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
                "Error",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Please select your diet preference.",
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

  Future<void> _saveAllergiesAndPrefs() async {
    final prefCode = TagUtils.mapPreference(_selectedPreference);
    await UserPrefs.saveDietPreference(prefCode);

    final normalizedAllergies =
        _selectedAllergies.map(TagUtils.normalizeAllergen).toList();
    await UserPrefs.saveAllergies(normalizedAllergies);
  }

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
              // Header + progress
              Padding(
                padding: const EdgeInsets.only(left: 15, right: 15, top: 5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    const Text("You",
                        style: TextStyle(fontSize: 20, color: Colors.white)),
                    const SizedBox(height: 40),
                    Row(
                      children: List.generate(10, (index) {
                        return Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            height: 4,
                            decoration: BoxDecoration(
                              color: index == 5
                                  ? const Color(0xFF37c47e)
                                  : Colors.grey[700],
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 18),
                    Text('What type of diet do you prefer?',
                        style: theme.textTheme.bodyLarge),
                    const SizedBox(height: 20),
                  ],
                ),
              ),

              // Preference (single-select)
              SingleChildScrollView(
                padding: const EdgeInsets.only(left: 15, right: 15, top: 5),
                child: _ChipWrap(
                  items: preference,
                  selected: {_selectedPreference},
                  onToggle: _togglePreference,
                  singleSelect: true,
                ),
              ),

              const SizedBox(height: 50),

              Padding(
                padding: const EdgeInsets.only(left: 15, right: 15, top: 5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 18),
                    Text('Do you have any food allergies?',
                        style: theme.textTheme.bodyLarge),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(left: 15, right: 15, top: 5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ChipWrap(
                        items: allergies,
                        selected: _selectedAllergies,
                        onToggle: _toggleAllergy,
                        singleSelect: false,
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // Bottom bar
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
                          onPressed: () async {
                            if (_selectedPreference.isNotEmpty) {
                              await _saveAllergiesAndPrefs();

                              if (_selectedAllergies.isEmpty) {
                                setState(() {
                                  _selectedAllergies.add("I don’t have any");
                                });
                              }

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const MedicalCondition(),
                                ),
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

// Reusable chip wrap that handles single or multi select
class _ChipWrap extends StatelessWidget {
  final List<String> items;
  final Set<String> selected;
  final void Function(String) onToggle;
  final bool singleSelect;

  const _ChipWrap({
    super.key,
    required this.items,
    this.selected = const {},
    required this.onToggle,
    this.singleSelect = false,
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
                  style: const TextStyle(
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

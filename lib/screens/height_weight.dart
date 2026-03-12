import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smart_scale/core/user_prefs.dart';
import 'package:smart_scale/screens/generate_meal.dart';

import 'diet_chart.dart';

class HeightWeight extends StatefulWidget {
  const HeightWeight({super.key});

  @override
  State<HeightWeight> createState() => _HeightWeightState();
}

class _HeightWeightState extends State<HeightWeight> {
  final _formKey = GlobalKey<FormState>();
  final heightCtrl = TextEditingController();
  final weightCtrl = TextEditingController();
  final goalWeightCtrl = TextEditingController();

  @override
  void dispose() {
    heightCtrl.dispose();
    weightCtrl.dispose();
    goalWeightCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveHeightAndWeight() async {
    final height = heightCtrl.text;
    final weight = weightCtrl.text;
    final goalWeight = goalWeightCtrl.text;
    await UserPrefs.saveAnthro(
        heightCm: double.parse(height), weightKg: double.parse(weight));
    await UserPrefs.saveGoalWeight(double.parse(goalWeight));
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF1A1C23),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF4F9BFF),
        secondary: Color(0xFF4F9BFF),
      ),
      textTheme: const TextTheme(
        headlineSmall: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
        bodyLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        titleMedium: TextStyle(
          fontSize: 14,
          color: Colors.white60,
          fontWeight: FontWeight.w600,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1A1C23),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        isDense: true,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF323440)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF4F9BFF), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.8),
        ),

        // Error text style
        errorStyle: const TextStyle(
          color: Colors.redAccent,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: const TextStyle(color: Color(0xFF7B8592)),
        labelStyle: const TextStyle(color: Colors.white),
      ),
    );

    return Theme(
      data: theme,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 6),
                        const Text('You',
                            style:
                                TextStyle(fontSize: 20, color: Colors.white)),
                        const SizedBox(height: 40),
                        Row(
                          children: List.generate(10, (index) {
                            return Expanded(
                              child: Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 1),
                                height: 4,
                                decoration: BoxDecoration(
                                  color: index == 8
                                      ? const Color(0xFF37c47e)
                                      : Colors.grey[700],
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 18),

                        Text('Just a few more questions',
                            style: theme.textTheme.bodyLarge),
                        const SizedBox(height: 18),

                        // HEIGHT
                        const _FieldLabel('How tall are you?'),
                        const SizedBox(height: 8),
                        _FieldWithUnit(
                          controller: heightCtrl,
                          unit: 'cm',
                          keyboard: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d+\.?\d{0,2}'))
                          ],
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter an accurate height.';
                            }
                            final h = double.tryParse(value);
                            if (h == null)
                              return 'Please enter a valid number.';
                            if (h < 100 || h > 250)
                              return 'Enter a height between 100 and 250 cm.';
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),

                        // WEIGHT
                        const _FieldLabel('How much do you weigh?'),
                        const SizedBox(height: 8),
                        _FieldWithUnit(
                          controller: weightCtrl,
                          unit: 'kg',
                          keyboard: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d+\.?\d{0,2}'))
                          ],
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your current weight.';
                            }
                            final w = double.tryParse(value);
                            if (w == null)
                              return 'Please enter a valid number.';
                            if (w < 20 || w > 300)
                              return 'Enter a weight between 20 and 300 kg.';
                            return null;
                          },
                        ),
                        const SizedBox(height: 6),
                        const Text("It's OK to estimate, you can update later.",
                            style: TextStyle(
                                color: Colors.white60,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w200)),
                        const SizedBox(height: 16),

                        // GOAL WEIGHT
                        const _FieldLabel("What's your goal weight?"),
                        const SizedBox(height: 8),
                        _FieldWithUnit(
                          controller: goalWeightCtrl,
                          unit: 'kg',
                          keyboard: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d+\.?\d{0,2}'))
                          ],
                          validator: (value) {
                            if (value == null || value.trim().isEmpty)
                              return 'Please enter an estimated goal weight.';
                            final g = double.tryParse(value);
                            if (g == null)
                              return 'Please enter a valid number.';
                            if (g <= 20 || g > 300)
                              return 'Enter a reasonable goal weight.';
                            return null;
                          },
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          "Don't worry, this doesn't affect your daily calorie goal and you can always change it later.",
                          style: TextStyle(
                              color: Colors.white60,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w200),
                        ),

                        const SizedBox(height: 90),
                      ],
                    ),
                  ),
                ),
              ),

              // bottom bar
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
                            if (_formKey.currentState!.validate()) {
                              FocusScope.of(context).unfocus();
                              await Future.delayed(
                                  const Duration(milliseconds: 80));
                              await _saveHeightAndWeight();

                              if (!mounted) return;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => GenerateMealScreen()),
                              );
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

/// Label above each field (gray, bold like screenshot)
class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        color: Colors.white60,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

/// Text field + trailing unit chip (cm/kg)
class _FieldWithUnit extends StatelessWidget {
  final TextEditingController controller;
  final String unit;
  final TextInputType keyboard;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;

  const _FieldWithUnit({
    required this.controller,
    required this.unit,
    required this.keyboard,
    this.inputFormatters,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: controller,
            keyboardType: keyboard,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            inputFormatters: inputFormatters,
            validator: validator,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 35),
          decoration: BoxDecoration(
            color: const Color(0xFF23334a),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Color(0xFF2A3140)),
          ),
          child: Center(
            child: Text(
              unit,
              style: TextStyle(
                color: cs.primary,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

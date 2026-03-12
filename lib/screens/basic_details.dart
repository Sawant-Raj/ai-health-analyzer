import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smart_scale/core/user_prefs.dart';

import 'height_weight.dart';

class BasicDetails extends StatefulWidget {
  const BasicDetails({super.key});

  @override
  State<BasicDetails> createState() => _BasicDetailsState();
}

class _BasicDetailsState extends State<BasicDetails> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController ageCtrl = TextEditingController();

  int? selectedSexIndex;

  @override
  void dispose() {
    ageCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveBasicDetails() async {
    final sex = selectedSexIndex == 0 ? 'Male' : 'Female';
    await UserPrefs.saveSex(sex);

    final age = ageCtrl.text;
    await UserPrefs.saveAge(int.parse(age));
  }

  void _showError(int? sexIndex, String age) {
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
              Text(
                sexIndex == null
                    ? "Please select your gender to proceed"
                    : "How old are you?",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 8),
              sexIndex != null
                  ? Text(
                      "Please enter your age.",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    )
                  : SizedBox.shrink(),
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
        fillColor: const Color(0xFF121722),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.white60),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF4F9BFF), width: 2),
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
              // CONTENT
              Expanded(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),
                      const Text('You',
                          style: TextStyle(fontSize: 20, color: Colors.white)),
                      const SizedBox(height: 40),
                      Row(
                        children: List.generate(10, (index) {
                          return Expanded(
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              height: 4,
                              decoration: BoxDecoration(
                                color: index == 7
                                    ? const Color(0xFF37c47e)
                                    : Colors.grey[700],
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 18),

                      Text('Tell us a little bit about yourself',
                          style: theme.textTheme.bodyLarge),
                      const SizedBox(height: 18),
                      Text(
                        'Please select which gender we should use to calculate your calorie needs:',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),

                      // Male / Female cards
                      Row(
                        children: [
                          Expanded(
                            child: _ChoiceCard(
                              label: 'Male',
                              selected: selectedSexIndex == 0,
                              onTap: () => setState(() => selectedSexIndex = 0),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ChoiceCard(
                              label: 'Female',
                              selected: selectedSexIndex == 1,
                              onTap: () => setState(() => selectedSexIndex = 1),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),
                      Text('How old are you?',
                          style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),

                      Form(
                        key: _formKey,
                        child: TextFormField(
                          controller: ageCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: theme.scaffoldBackgroundColor,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                  color: Color(0xFF2A3140), width: 1.2),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                  color: Color(0xFF4F9BFF), width: 1.5),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                  color: Colors.red, width: 1.5),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                  color: Colors.red, width: 1.8),
                            ),
                            errorStyle: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          validator: (value) {
                            if (value == null) {
                              return "Please enter your age.";
                            }

                            final age = int.tryParse(value);
                            if (age == null) {
                              return "Please enter your age.";
                            }
                            if (age < 18) {
                              return "You must be 18 or older.";
                            } else if (age > 120) {
                              return "Age must be between 18 and 120.";
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'We use gender and age to calculate an accurate goal for you.',
                        style:
                            TextStyle(color: Color(0xFF9AA4B2), fontSize: 12.5),
                      ),

                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),

              // BOTTOM BAR
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
                            if (_formKey.currentState!.validate() &&
                                selectedSexIndex != null &&
                                ageCtrl.text.isNotEmpty) {
                              await _saveBasicDetails();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => HeightWeight()),
                              );
                            } else {
                              _showError(selectedSexIndex, ageCtrl.text);
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

/// Choice card with a circular check on the right
class _ChoiceCard extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ChoiceCard({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: const Color(0xFF252733),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? cs.primary : const Color(0xFF2A3140),
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white),
                ),
              ),
              _CheckDot(selected: selected),
            ],
          ),
        ),
      ),
    );
  }
}

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

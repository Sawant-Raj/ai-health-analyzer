import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_scale/smart_scale/dashboard.dart';

import 'body_composition.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController heightController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  DateTime? selectedDob, recordedTime, baselineTime;
  String? selectedGender;
  bool isMale = true,
      isDataLoading = true,
      hasFirstEntry = false,
      hasPreviousRecord = false;
  final _formKey = GlobalKey<FormState>();

  double weightDiff = 0.0;
  double bmiDiff = 0.0;

  // Memory for last entered values
  Map<String, double> previousValues = {
    "Weight": 0.0,
    "BMI": 0.0,
  };

// Persisted last diff to show immediately on re-run (optional)
  Map<String, double> lastDiff = {
    "Weight": 0.0,
    "BMI": 0.0,
  };

  Map<String, double> baselineValues = {
    "Weight": 0.0,
    "BMI": 0.0,
  };

  @override
  void initState() {
    super.initState();
  }

  void onStartPressed() async {
    final oldHeight = heightController.text;
    final oldWeight = weightController.text;
    final oldDob = selectedDob;
    final oldGender = selectedGender;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: const Color(0xFF242736),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 🔵 Header
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0xFF4f9bff),
                              Color(0xFF005de8),
                            ],
                          ),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                        ),
                        child: Text(
                          "Add Details",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.roboto(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),

                      // ⚪ Content
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextFormField(
                              controller: heightController,
                              decoration: InputDecoration(
                                labelText: "Height (cm)",
                                labelStyle: TextStyle(color: Colors.white70),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              style: TextStyle(color: Colors.white),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter
                                    .digitsOnly, // allow only digits
                              ],
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return "Height is required";
                                }
                                final height = double.tryParse(value.trim());
                                if (height == null) {
                                  return "Enter a valid number";
                                }
                                if (height < 30 || height > 220) {
                                  return "Enter a realistic height (30–220 cm)";
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: weightController,
                              decoration: InputDecoration(
                                labelText: "Weight (kg)",
                                labelStyle: TextStyle(color: Colors.white70),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              style: TextStyle(color: Colors.white),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter
                                    .digitsOnly, // allow only digits
                              ],
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return "Weight is required";
                                }
                                final weight = double.tryParse(value.trim());
                                if (weight == null) {
                                  return "Enter a valid number";
                                }
                                if (weight < 5 || weight > 200) {
                                  return "Enter a realistic weight (5–200 kg)";
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            FormField<DateTime>(
                              validator: (value) {
                                if (selectedDob == null) {
                                  return "Date of Birth is required";
                                }
                                return null;
                              },
                              builder: (field) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    InkWell(
                                      onTap: () async {
                                        final DateTime? picked =
                                            await showDatePicker(
                                          context: context,
                                          initialDate: selectedDob ??
                                              DateTime(
                                                  2000), // 🔹 keep previous or default
                                          firstDate: DateTime(1900),
                                          lastDate: DateTime.now(),
                                        );
                                        if (picked != null) {
                                          setState(() {
                                            selectedDob = picked;
                                          });
                                          field.didChange(
                                              picked); // 🔹 updates FormField state
                                        }
                                      },
                                      child: InputDecorator(
                                        decoration: InputDecoration(
                                          labelText: "Date of Birth",
                                          labelStyle:
                                              TextStyle(color: Colors.white70),
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          errorText: field
                                              .errorText, // 🔹 show validation error
                                        ),
                                        child: Text(
                                          selectedDob == null
                                              ? "dd/mm/yyyy"
                                              : "${selectedDob!.day.toString().padLeft(2, '0')}/"
                                                  "${selectedDob!.month.toString().padLeft(2, '0')}/"
                                                  "${selectedDob!.year}",
                                          style: TextStyle(
                                            color: selectedDob == null
                                                ? Colors.white70
                                                : Colors.white,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              value: selectedGender,
                              dropdownColor: const Color(0xFF2E3142),
                              decoration: InputDecoration(
                                labelText: "Gender",
                                labelStyle: TextStyle(color: Colors.white70),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              style: TextStyle(color: Colors.white),
                              items: const [
                                DropdownMenuItem(
                                    value: "Male",
                                    child: Text(
                                      "Male",
                                      style: TextStyle(color: Colors.white),
                                    )),
                                DropdownMenuItem(
                                    value: "Female",
                                    child: Text(
                                      "Female",
                                      style: TextStyle(color: Colors.white),
                                    )),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  selectedGender = value;
                                  isMale = selectedGender == "Male";
                                });
                              },
                              validator: (value) =>
                                  value == null || value.isEmpty
                                      ? "Please select your gender"
                                      : null,
                            )
                          ],
                        ),
                      ),

                      // 🔘 Buttons
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () {
                                // ⬇️ Restore old values
                                heightController.text = oldHeight;
                                weightController.text = oldWeight;
                                selectedDob = oldDob;
                                selectedGender = oldGender;
                                isMale = oldGender == "Male";

                                Navigator.pop(context);
                              },
                              child: const Text(
                                "Cancel",
                                style: TextStyle(color: Color(0xFF4f9bff)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4f9bff),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                              ),
                              onPressed: () async {
                                if (_formKey.currentState!.validate()) {
                                  Navigator.pop(context);
                                  _onSavePressed();
                                }
                              },
                              child: const Text("Save"),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _saveData(double currentWeight, double currentBMI) async {
    final prefs = await SharedPreferences.getInstance();

    // update recorded time
    recordedTime = DateTime.now();

    final monthKey =
        "${recordedTime!.year}-${recordedTime!.month.toString().padLeft(2, '0')}";

    // Track entry count
    int entriesCount = prefs.getInt('entriesCount') ?? 0;
    entriesCount += 1;
    await prefs.setInt('entriesCount', entriesCount);

    // Save current inputs
    await prefs.setString('weight', weightController.text);
    await prefs.setString('height', heightController.text);
    if (selectedDob != null) {
      await prefs.setString('dob', selectedDob!.toIso8601String());
    }
    if (selectedGender != null) {
      await prefs.setString('gender', selectedGender!);
    }

    // Baseline keys for this month
    final baselineWeightKey = 'baseline_${monthKey}_weight';
    final baselineBMIKey = 'baseline_${monthKey}_bmi';
    final baselineTimeKey = 'baseline_${monthKey}_time';

    final baselineWeight = prefs.getDouble(baselineWeightKey);
    final baselineBMI = prefs.getDouble(baselineBMIKey);

    if (baselineWeight == null || baselineBMI == null) {
      // first entry in this month → set baseline
      await prefs.setDouble(baselineWeightKey, currentWeight);
      await prefs.setDouble(baselineBMIKey, currentBMI);
      await prefs.setString(baselineTimeKey, recordedTime!.toIso8601String());
      baselineTime = recordedTime;

      weightDiff = 0.0;
      bmiDiff = 0.0;
    } else {
      // compare with baseline (not previous entry)
      weightDiff = currentWeight - baselineWeight;
      bmiDiff = currentBMI - baselineBMI;

      final baselineStr = prefs.getString(baselineTimeKey);
      baselineTime =
          baselineStr != null ? DateTime.tryParse(baselineStr) : null;
    }

    // Save diffs
    await prefs.setDouble('lastWeightDiff', weightDiff);
    await prefs.setDouble('lastBMIDiff', bmiDiff);

    // Save recorded time
    await prefs.setString('recorded_time', recordedTime!.toIso8601String());

    // Flags
    if (entriesCount >= 1) {
      await prefs.setBool('hasFirstEntry', true);
      hasFirstEntry = true;
    }
    if (entriesCount >= 2) {
      await prefs.setBool('hasPreviousRecord', true);
      hasPreviousRecord = true;
    }
  }

  void _onSavePressed() async {
    final currentWeight = double.tryParse(weightController.text) ?? 0.0;
    final currentHeight = double.tryParse(heightController.text) ?? 0.0;
    final currentBMI =
        double.tryParse(BodyComposition.bmi(currentWeight, currentHeight)) ??
            0.0;

    // Capture previous values BEFORE updating memory
    final prevWeight = previousValues['Weight'] ?? 0.0;
    final prevBMI = previousValues['BMI'] ?? 0.0;

    // Calculate differences for *UI display* (not storage)
    final newWeightDiff = currentWeight - prevWeight;
    final newBMIDiff = currentBMI - prevBMI;

    // Update memory for next calculation
    previousValues['Weight'] = currentWeight;
    previousValues['BMI'] = currentBMI;

    // Update UI immediately
    setState(() {
      weightDiff = newWeightDiff;
      bmiDiff = newBMIDiff;
    });

    await _saveData(currentWeight, currentBMI);

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const DashboardScreen()),
      );
    }
  }

  @override
  void dispose() {
    weightController.dispose();
    heightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1b1d29),
      appBar: AppBar(
        backgroundColor: Color(0xFF1b1d29),
        title: const Text(
          'Body Stats',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            child: Text(
              "Analyze Your Body Stats",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(
            height: 50,
          ),
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.95,
            child: ElevatedButton(
                onPressed: () {
                  onStartPressed();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF4f9bff),
                ),
                child: Text(
                  "Start",
                  style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 15),
                )),
          ),
        ]),
      ),
    );
  }
}

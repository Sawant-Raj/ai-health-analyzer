import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_scale/smart_scale/star_overlay_loading.dart';

import 'body_composition.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

bool hasFirstEntry = false;
bool hasPreviousRecord = false;

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  int? expandedIndex; // which measurement row is open

  final TextEditingController heightController = TextEditingController();
  final TextEditingController weightController = TextEditingController();

  DateTime? selectedDob;

  String? selectedGender;

  bool isMale = true;

  late AnimationController _controller;

  bool _isLoading = false;

  int calculateAge(DateTime dob) {
    final today = DateTime.now();
    int age = today.year - dob.year;

    if (today.month < dob.month ||
        (today.month == dob.month && today.day < dob.day)) {
      age--;
    }
    return age;
  }

  DateTime? firstEntryTimeThisMonth;
  DateTime? recordedTime;

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
  DateTime? baselineTime;

  bool isDataLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedData();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6500),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          isDataLoading = false;
        });
      }
    });

    startAnimation();

    _startLoadingAnimation();
  }

  void startAnimation() {
    _controller.repeat();
    Future.delayed(const Duration(milliseconds: 6500), () {
      _controller.stop();
      _controller.reset();
    });
  }

  @override
  void dispose() {
    weightController.dispose();
    heightController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();

    // Flags
    hasFirstEntry = prefs.getBool('hasFirstEntry') ?? false;
    hasPreviousRecord = prefs.getBool('hasPreviousRecord') ?? false;

    // Restore saved raw inputs (so form fields show the last entered values)
    final savedWeightStr = prefs.getString('weight') ?? '';
    final savedHeightStr = prefs.getString('height') ?? '';

    weightController.text = savedWeightStr;
    heightController.text = savedHeightStr;

    // DOB and gender
    final dobStr = prefs.getString('dob');
    selectedDob = (dobStr != null && dobStr.isNotEmpty)
        ? DateTime.tryParse(dobStr)
        : null;

    selectedGender = prefs.getString('gender');

    // Recompute numeric saved values
    final savedWeight = double.tryParse(savedWeightStr) ?? 0.0;
    final savedHeight = double.tryParse(savedHeightStr) ?? 0.0;
    final savedBMI = (savedWeight > 0 && savedHeight > 0)
        ? (double.tryParse(BodyComposition.bmi(savedWeight, savedHeight)) ??
            0.0)
        : 0.0;

    // Populate previousValues so in-memory diffs (if you use them) are correct
    previousValues['Weight'] = savedWeight;
    previousValues['BMI'] = savedBMI;

    // Load last diffs (what was persisted)
    weightDiff = prefs.getDouble('lastWeightDiff') ?? 0.0;
    bmiDiff = prefs.getDouble('lastBMIDiff') ?? 0.0;

    // Load recorded (last entry) time
    final savedRecorded = prefs.getString('recorded_time');
    recordedTime =
        savedRecorded != null ? DateTime.tryParse(savedRecorded) : null;

    // Load baseline (first entry of the current month)
    final monthKey =
        "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}";
    final baselineWeightKey = 'baseline_${monthKey}_weight';
    final baselineBMIKey = 'baseline_${monthKey}_bmi';
    final baselineTimeKey = 'baseline_${monthKey}_time';

    final bWeight = prefs.getDouble(baselineWeightKey);
    final bBMI = prefs.getDouble(baselineBMIKey);
    final bTimeStr = prefs.getString(baselineTimeKey);

    if (bWeight != null) baselineValues['Weight'] = bWeight;
    if (bBMI != null) baselineValues['BMI'] = bBMI;
    baselineTime = (bTimeStr != null && bTimeStr.isNotEmpty)
        ? DateTime.tryParse(bTimeStr)
        : null;

    // Ensure UI refresh once with everything restored
    setState(() {});
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

    _startLoadingAnimation();

    await _saveData(currentWeight, currentBMI);
  }

  void _startLoadingAnimation() {
    setState(() => _isLoading = true);

    Future.delayed(const Duration(milliseconds: 6500), () {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    });
  }

  final _formKey = GlobalKey<FormState>();

  List<Map<String, dynamic>> get measurements {
    final weight = double.tryParse(weightController.text.trim()) ?? 0.00;
    final height = double.tryParse(heightController.text.trim()) ?? 0.0;
    final age = selectedDob != null ? calculateAge(selectedDob!) : 0;

    final bmi = BodyComposition.bmi(weight, height);

    final bodyFatPercent =
        BodyComposition.bodyFat(double.parse(bmi), age, isMale);

    final fatFreeMass =
        BodyComposition.fatFreeMass(weight, double.parse(bodyFatPercent));

    final bmr = BodyComposition.bmr(weight, height, age, isMale);

    final heightInMeter = height / 100;

    final idealWeight = 22 * heightInMeter * heightInMeter;

    final expectedMuscleMass = double.parse(fatFreeMass) * 0.50;

    final expectedBoneMass = weight * (isMale ? 0.040 : 0.035);

    final idealBmr = 10.0 * idealWeight +
        6.25 * height -
        5.0 * age +
        (isMale ? 5.0 : -161.0);

    return [
      {
        "image": const AssetImage("images/scale.png"),
        "label": "Weight",
        "value": weight.toStringAsFixed(2),
        "unit": "kg",
        "description": "One of the important indicators of health",
        "segments": [
          {
            "label": "Severely Low",
            "color": const Color(0xFFac8ee8),
            "min": "5",
            "max": (idealWeight * 0.73).toStringAsFixed(2)
          },
          {
            "label": "Low",
            "color": const Color(0xFF39bded),
            "min": (idealWeight * 0.73).toStringAsFixed(2),
            "max": (idealWeight * 0.82).toStringAsFixed(2)
          },
          {
            "label": "Standard",
            "color": const Color(0xFFa9cc1b),
            "min": (idealWeight * 0.82).toStringAsFixed(2),
            "max": idealWeight.toStringAsFixed(2)
          },
          {
            "label": "High",
            "color": const Color(0xFFf0be0a),
            "min": idealWeight.toStringAsFixed(2),
            "max": (idealWeight * 1.10).toStringAsFixed(2)
          },
          {
            "label": "Severely High",
            "color": const Color(0xFFeb4e3d),
            "min": (idealWeight * 1.10).toStringAsFixed(2),
            "max": (35 * heightInMeter * heightInMeter).toStringAsFixed(2)
          },
        ],
      },
      {
        "image": const AssetImage("images/bmi.png"),
        "label": "BMI",
        "value": bmi,
        "description": "Body Mass Index",
        "segments": [
          {
            "label": "Low",
            "color": const Color(0xFF39bded),
            "min": "0",
            "max": "18.5"
          },
          {
            "label": "Standard",
            "color": const Color(0xFFa9cc1b),
            "min": "18.5",
            "max": "25.0"
          },
          {
            "label": "High",
            "color": const Color(0xFFf0be0a),
            "min": "25.0",
            "max": "70.0"
          },
        ],
      },
      {
        "image": const AssetImage("images/percentage.png"),
        "label": "Body Fat",
        "value": bodyFatPercent,
        "unit": "%",
        "description": "Body composition fat tissue ratio",
        "segments": [
          {
            "label": "Low",
            "color": const Color(0xFF39bded),
            "min": "3.0%",
            "max": isMale ? "11.0%" : "20.0%"
          },
          {
            "label": "Standard",
            "color": const Color(0xFFa9cc1b),
            "min": isMale ? "11.0%" : "20.0%",
            "max": isMale ? "20.0%" : "30.0%"
          },
          {
            "label": "High",
            "color": const Color(0xFFf0be0a),
            "min": isMale ? "20.0%" : "30.0%",
            "max": isMale ? "25.0%" : "35.0%"
          },
          {
            "label": "Severely High",
            "color": const Color(0xFFeb4e3d),
            "min": isMale ? "25.0%" : "35.0%",
            "max": "80%"
          }
        ],
      },
      {
        "image": const AssetImage("images/trans-fat-free.png"),
        "label": "Fat-free Body Weight",
        "value": fatFreeMass,
        "unit": "kg",
        "description":
            "Muscle, in addition to body fat, is a major component of body weight",
      },
      {
        "image": const AssetImage("images/brick.png"),
        "label": "Subcutaneous Fat",
        "value": BodyComposition.subcutaneousFat(double.parse(bodyFatPercent)),
        "unit": "%",
        "description":
            "The ratio of subcutaneous fat stored in your skin to your body weight",
        "segments": [
          {
            "label": "Low",
            "color": const Color(0xFF39bded),
            "min": "2.6%",
            "max": isMale ? "9.4%" : "17.0%"
          },
          {
            "label": "Standard",
            "color": const Color(0xFFa9cc1b),
            "min": isMale ? "9.4%" : "17.0%",
            "max": isMale ? "17.0%" : "25.5%"
          },
          {
            "label": "High",
            "color": const Color(0xFFf0be0a),
            "min": isMale ? "17.0%" : "25.5%",
            "max": "60.0%"
          },
        ]
      },
      {
        "image": const AssetImage("images/kidneys.png"),
        "label": "Visceral Fat",
        "value": BodyComposition.visceralFat(double.parse(bodyFatPercent)),
        "description":
            "A type of body fat that is found around the human organs and which mainly resides in the abdominal cavity",
        "segments": [
          {
            "label": "Standard",
            "color": const Color(0xFFa9cc1b),
            "min": "1 ",
            "max": "9"
          },
          {
            "label": "High",
            "color": const Color(0xFFf0be0a),
            "min": "9",
            "max": "14"
          },
          {
            "label": "Severely High",
            "color": const Color(0xFFeb4e3d),
            "min": "14",
            "max": "30"
          },
        ],
      },
      {
        "image": const AssetImage("images/arthritis.png"),
        "label": "Skeletal Muscle",
        "value": BodyComposition.skeletalMusclePercent(
            weight, double.parse(bodyFatPercent), isMale),
        "unit": "%",
        "description":
            "The ratio of muscle involved in the mechanical system of our limbs and other parts of the body",
        "segments": [
          {
            "label": "Low",
            "color": const Color(0xFF39bded),
            "min": "5%",
            "max": isMale ? "36.0%" : "32.0%"
          },
          {
            "label": "Standard",
            "color": const Color(0xFFa9cc1b),
            "min": isMale ? "36.0%" : "32.0%",
            "max": isMale ? "46.0%" : "40.0%"
          },
          {
            "label": "High",
            "color": const Color(0xFFf0be0a),
            "min": isMale ? "46.0%" : "40.0%",
            "max": "80.0%"
          },
        ],
      },
      {
        "image": const AssetImage("images/strength.png"),
        "label": "Muscle Mass",
        "value": BodyComposition.muscleMass(
            weight, double.parse(bodyFatPercent), isMale),
        "unit": "kg",
        "description":
            "The total muscle weight, including skeletal muscle, cardiac, and smooth muscle",
        "segments": [
          {
            "label": "Inadequate",
            "color": const Color(0xFF39bded),
            "min": (expectedMuscleMass * 0.70).toStringAsFixed(2),
            "max": (expectedMuscleMass * 0.92).toStringAsFixed(2)
          },
          {
            "label": "Standard",
            "color": const Color(0xFFa9cc1b),
            "min": (expectedMuscleMass * 0.92).toStringAsFixed(2),
            "max": (expectedMuscleMass * 1.08).toStringAsFixed(2)
          },
          {
            "label": "Adequate",
            "color": Colors.green.shade600,
            "min": (expectedMuscleMass * 1.08).toStringAsFixed(2),
            "max": (expectedMuscleMass * 1.3).toStringAsFixed(2)
          },
        ],
      },
      {
        "image": const AssetImage("images/muscles.png"),
        "label": "Muscle Storage Ability Level",
        "value": BodyComposition.muscleStorageAbility(
            weight, double.parse(bodyFatPercent), isMale),
        "description":
            "The size of muscle storage capacity represents the number of human muscles and reflects the current level of the body's ability yto retain iliac muscles",
        "segments": [
          {
            "label": "Low",
            "color": const Color(0xFF39bded),
            "min": "0",
            "max": "2"
          },
          {
            "label": "Standard",
            "color": const Color(0xFFa9cc1b),
            "min": "2",
            "max": "4"
          },
          {
            "label": "Good",
            "color": Colors.green.shade600,
            "min": "4",
            "max": "5"
          },
        ],
      },
      {
        "image": const AssetImage("images/water-drop.png"),
        "label": "Body Water",
        "value":
            BodyComposition.bodyWater(weight, double.parse(bodyFatPercent)),
        "description":
            "Water weight, which includes the blood, lymph, extracellular fluid, etc.",
        "unit": "%",
        "segments": [
          {
            "label": "Low",
            "color": const Color(0xFF39bded),
            "min": "10.0%",
            "max": isMale ? "55.0%" : "50.0%"
          },
          {
            "label": "Standard",
            "color": const Color(0xFFa9cc1b),
            "min": isMale ? "55.0%" : "50.0%",
            "max": isMale ? "65.0%" : "60.0%"
          },
          {
            "label": "Adequate",
            "color": Colors.green.shade600,
            "min": isMale ? "65.0%" : "60.0%",
            "max": "80.0%"
          },
        ],
      },
      {
        "image": const AssetImage("images/bone.png"),
        "label": "Bone Mass",
        "value": BodyComposition.boneMass(weight, isMale),
        "unit": "kg",
        "description":
            "Bone tissue consists of bone minerals (calcium, phosphorus, etc) and bone matrix (collagen fiber, ground substance, inorganic salt, etc.) per unit volume",
        "segments": [
          {
            "label": "Low",
            "color": const Color(0xFF39bded),
            "min":
                (expectedBoneMass * (isMale ? 0.80 : 0.75)).toStringAsFixed(2),
            "max":
                (expectedBoneMass * (isMale ? 0.93 : 0.90)).toStringAsFixed(2)
          },
          {
            "label": "Standard",
            "color": const Color(0xFFa9cc1b),
            "min":
                (expectedBoneMass * (isMale ? 0.93 : 0.90)).toStringAsFixed(2),
            "max":
                (expectedBoneMass * (isMale ? 1.07 : 1.10)).toStringAsFixed(2)
          },
          {
            "label": "High",
            "color": const Color(0xFFf0be0a),
            "min":
                (expectedBoneMass * (isMale ? 1.07 : 1.10)).toStringAsFixed(2),
            "max":
                (expectedBoneMass * (isMale ? 1.22 : 1.25)).toStringAsFixed(2)
          },
        ],
      },
      {
        "image": const AssetImage("images/dna.png"),
        "label": "Protein",
        "value": BodyComposition.protein(weight, double.parse(bodyFatPercent)),
        "unit": "%",
        "description":
            "Protein plays a vital role in the body, as it builds and maintains muscles, organs, and other tissue",
        "segments": [
          {
            "label": "Low",
            "color": const Color(0xFF39bded),
            "min": "2.0%",
            "max": isMale ? "15.0%" : "13.0%"
          },
          {
            "label": "Standard",
            "color": const Color(0xFFa9cc1b),
            "min": isMale ? "15.0%" : "13.0%",
            "max": isMale ? "19.0%" : "17.0%"
          },
          {
            "label": "Adequate",
            "color": Colors.green.shade600,
            "min": isMale ? "19.0%" : "17.0%",
            "max": "40.0%"
          },
        ],
      },
      {
        "image": const AssetImage("images/recycle.png"),
        "label": "BMR",
        "value": bmr,
        "unit": "kcal",
        "description":
            "Basal Metabolic Rate. In an inactive state, this is the minimum necessary energy needed",
        "segments": [
          {
            "label": "Standard Not Met",
            "color": const Color(0xFFf0be0a),
            "min": "500",
            "max": (idealBmr).toStringAsFixed(0),
          },
          {
            "label": "Standard Met",
            "color": const Color(0xFFa9cc1b),
            "min": (idealBmr).toStringAsFixed(0),
            "max": (idealBmr * 1.25).toStringAsFixed(0),
          },
        ],
      },
      {
        "image": const AssetImage("images/healthy.png"),
        "label": "Metabolic Age",
        "value": BodyComposition.metabolicAge(
            weight, height, age, isMale, double.parse(bmr)),
        "description": "Body age is an indicator to assess physical condition",
        "segments": [
          {
            "label": "Standard Met",
            "color": const Color(0xFFa9cc1b),
            "min": 0,
            "max": age
          },
          {
            "label": "Standard Not Met",
            "color": const Color(0xFFf0be0a),
            "min": age,
            "max": 120
          },
        ],
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            leading: IconButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: Icon(Icons.arrow_back_ios_new_rounded),
              color: Colors.white,
            ),
            backgroundColor: Color(0xFF1B1D29),
            title: Text(
              "Test",
              style: GoogleFonts.roboto(color: Colors.white, fontSize: 18),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                onPressed: () {
                  // ⬇️ Save current values before opening dialog
                  final oldHeight = heightController.text;
                  final oldWeight = weightController.text;
                  final oldDob = selectedDob;
                  final oldGender = selectedGender;

                  showDialog(
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
                                        "Edit Details",
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
                                              labelStyle: TextStyle(
                                                  color: Colors.white70),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                            style:
                                                TextStyle(color: Colors.white),
                                            keyboardType: TextInputType.number,
                                            inputFormatters: [
                                              FilteringTextInputFormatter
                                                  .digitsOnly, // allow only digits
                                            ],
                                            validator: (value) {
                                              if (value == null ||
                                                  value.trim().isEmpty) {
                                                return "Height is required";
                                              }
                                              final height =
                                                  double.tryParse(value.trim());
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
                                              labelStyle: TextStyle(
                                                  color: Colors.white70),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                            style:
                                                TextStyle(color: Colors.white),
                                            keyboardType: TextInputType.number,
                                            inputFormatters: [
                                              FilteringTextInputFormatter
                                                  .digitsOnly, // allow only digits
                                            ],
                                            validator: (value) {
                                              if (value == null ||
                                                  value.trim().isEmpty) {
                                                return "Weight is required";
                                              }
                                              final weight =
                                                  double.tryParse(value.trim());
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
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  InkWell(
                                                    onTap: () async {
                                                      final DateTime? picked =
                                                          await showDatePicker(
                                                        context: context,
                                                        initialDate: selectedDob ??
                                                            DateTime(
                                                                2000), // 🔹 keep previous or default
                                                        firstDate:
                                                            DateTime(1900),
                                                        lastDate:
                                                            DateTime.now(),
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
                                                      decoration:
                                                          InputDecoration(
                                                        labelText:
                                                            "Date of Birth",
                                                        labelStyle: TextStyle(
                                                            color:
                                                                Colors.white70),
                                                        border:
                                                            OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(12),
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
                                                          color: selectedDob ==
                                                                  null
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
                                            dropdownColor:
                                                const Color(0xFF2E3142),
                                            decoration: InputDecoration(
                                              labelText: "Gender",
                                              labelStyle: TextStyle(
                                                  color: Colors.white70),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                            style:
                                                TextStyle(color: Colors.white),
                                            items: const [
                                              DropdownMenuItem(
                                                  value: "Male",
                                                  child: Text(
                                                    "Male",
                                                    style: TextStyle(
                                                        color: Colors.white),
                                                  )),
                                              DropdownMenuItem(
                                                  value: "Female",
                                                  child: Text(
                                                    "Female",
                                                    style: TextStyle(
                                                        color: Colors.white),
                                                  )),
                                            ],
                                            onChanged: (value) {
                                              setState(() {
                                                selectedGender = value;
                                                isMale =
                                                    selectedGender == "Male";
                                              });
                                            },
                                            validator: (value) => value ==
                                                        null ||
                                                    value.isEmpty
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
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
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
                                              style: TextStyle(
                                                  color: Color(0xFF4f9bff)),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  const Color(0xFF4f9bff),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              foregroundColor: Colors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 24,
                                                      vertical: 12),
                                            ),
                                            onPressed: () async {
                                              if (_formKey.currentState!
                                                  .validate()) {
                                                Navigator.pop(context);

                                                startAnimation();

                                                _onSavePressed();
                                              }
                                            },
                                            child: const Text("Update"),
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
                },
                icon: const Icon(Icons.edit),
                color: Colors.white,
              )
            ],
          ),
          body: Stack(children: [
            SingleChildScrollView(
              child: Column(
                children: [
                  // 🔵 Top blue section
                  Container(
                    width: double.infinity,
                    height: MediaQuery.of(context).size.height * 0.32,
                    // padding: const EdgeInsets.only(bottom: 20),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFF1B1D29),
                          Color(0xFF3A3D52),
                        ],
                        stops: [
                          0.55,
                          1.0
                        ], // smoother, more visible gradient transition
                      ),
                    ),

                    child: Column(
                      children: [
                        const SizedBox(height: 5),

                        // Dotted circle with weight
                        SizedBox(
                          width: 200,
                          height: 200,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Animated border only
                              AnimatedBuilder(
                                animation: _controller,
                                builder: (context, child) {
                                  return Transform.rotate(
                                    angle: _controller.value * 2 * 3.14159,
                                    child: DottedBorder(
                                      borderType: BorderType.Circle,
                                      color: Colors.white,
                                      strokeWidth: 3,
                                      dashPattern: const [4, 12],
                                      child: const SizedBox(
                                        width: 200,
                                        height: 200,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              // Static weight text
                              RichText(
                                text: TextSpan(
                                  text: (() {
                                    final insertedWeight = double.tryParse(
                                            weightController.text.trim()) ??
                                        0.0;
                                    return insertedWeight.toStringAsFixed(2);
                                  })(),
                                  style: GoogleFonts.roboto(
                                    fontSize: 43,
                                    color: Colors.white,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: " kg",
                                      style: GoogleFonts.roboto(
                                        fontSize: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),
                        Text("Weight goal",
                            style: GoogleFonts.roboto(color: Colors.white)),
                      ],
                    ),
                  ),

                  // 📅 Summary section
                  Container(
                    color: Colors.white,
                    child: Column(
                      // crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        baselineTime != null
                            ? Visibility(
                                visible: hasPreviousRecord,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          left: 30.0, top: 10),
                                      child: Text(
                                          "From ${DateFormat('MMMM dd, yyyy h:mm a').format(baselineTime!)}",
                                          style: GoogleFonts.roboto(
                                              color: Colors.grey)),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      children: [
                                        _SummaryItem(
                                          label: "Weight",
                                          value: (weightDiff >= 0 ? "+" : "") +
                                              weightDiff.toStringAsFixed(2),
                                          unit: "kg",
                                        ),
                                        _SummaryItem(
                                          label: "BMI",
                                          value: (bmiDiff >= 0 ? "+" : "") +
                                              bmiDiff.toStringAsFixed(2),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              )
                            : SizedBox.shrink(),
                        hasFirstEntry
                            ? const SizedBox(height: 10)
                            : SizedBox(height: 1),
                        recordedTime != null
                            ? Container(
                                width: double.infinity,
                                color: Colors.grey.shade200,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 30),
                                child: Text(
                                    DateFormat('MMMM dd, yyyy h:mm a')
                                        .format(recordedTime!),
                                    style:
                                        GoogleFonts.roboto(color: Colors.grey)),
                              )
                            : SizedBox.shrink(),
                        // hasFirstEntry?SizedBox(
                        //   height: 0,
                        // ):SizedBox.shrink()
                      ],
                    ),
                  ),

                  // 📊 Measurements list
                  ...List.generate(
                    measurements.length,
                    (index) {
                      final item = measurements[index];
                      return _ExpandableMeasurementRow(
                        // icon: item["icon"],
                        image: item["image"],
                        label: item["label"],
                        value: item["value"],
                        unit: item["unit"],
                        description: item["description"],
                        segments: item["segments"],
                        isExpanded: expandedIndex == index,
                        onTap: hasFirstEntry
                            ? () {
                                setState(() {
                                  expandedIndex =
                                      expandedIndex == index ? null : index;
                                });
                              }
                            : () {},
                      );
                    },
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 20),
                    child: Text(
                      "The data results are only used for sports and fitness monitoring reference. They cannot be used as the data basis for medical equipment. For decisions concerning diagnosis and treatment, please consult doctors and other medical staff for advice.",
                      style: GoogleFonts.roboto(
                          fontSize: 14,
                          color: Colors.grey,
                          fontWeight: FontWeight.w400),
                    ),
                  ),
                  SizedBox(
                    height: 5,
                  ),
                ],
              ),
            ),
          ]),

          // ⬇️ Bottom Navigation Bar
          bottomNavigationBar: BottomNavigationBar(
            backgroundColor: Colors.white,
            currentIndex: 0,
            selectedItemColor: Color(0xFF3341ff),
            unselectedItemColor: Colors.grey,
            items: const [
              BottomNavigationBarItem(
                  icon: Icon(Icons.speed), label: "Measurements"),
              BottomNavigationBarItem(
                  icon: Icon(Icons.track_changes), label: "Tracking"),
              BottomNavigationBarItem(
                  icon: Icon(Icons.person_outlined), label: "My Account"),
            ],
          ),
        ),
        if (isDataLoading)
          Container(
            color: Colors.black.withOpacity(0.8), // dark transparent background
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white), // white spinner
              ),
            ),
          ),
        if (_isLoading)
          Positioned.fill(
            child: StarOverlayLoading(
              isLoading: _isLoading,
            ),
          ),
      ],
    );
  }
}

// 📌 Summary item widget
class _SummaryItem extends StatelessWidget {
  final String label, value;
  final String? unit;
  const _SummaryItem({required this.label, required this.value, this.unit});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: GoogleFonts.roboto(
                  fontSize: 20,
                  color: Colors.grey,
                ),
              ),
              if (unit != null && unit!.isNotEmpty)
                TextSpan(
                  text: " $unit",
                  style: GoogleFonts.roboto(
                    fontSize: 12, // smaller size for unit
                    color: Colors.grey,
                    fontWeight: FontWeight.w400,
                  ),
                ),
            ],
          ),
        ),
        Text(label, style: GoogleFonts.roboto(color: Colors.grey)),
      ],
    );
  }
}

// 📌 Expandable Measurement row widget
class _ExpandableMeasurementRow extends StatefulWidget {
  // final IconData icon;
  final ImageProvider image;
  final String label, value;
  final String? unit;
  final String description;
  final bool isExpanded;
  final VoidCallback onTap;
  final List<Map<String, dynamic>>? segments;

  const _ExpandableMeasurementRow({
    // required this.icon,
    required this.image,
    required this.label,
    required this.value,
    this.unit,
    required this.description,
    required this.isExpanded,
    required this.onTap,
    this.segments,
  });

  @override
  State<_ExpandableMeasurementRow> createState() =>
      _ExpandableMeasurementRowState();
}

class _ExpandableMeasurementRowState extends State<_ExpandableMeasurementRow> {
  double _sliderValue = 50;

  int currentSegmentIndex = 0;

  @override
  void initState() {
    super.initState();
    _setInitialSegmentIndex();
  }

  void _setInitialSegmentIndex() {
    if (widget.segments == null || widget.segments!.isEmpty) return;

    final valueStr = widget.value.replaceAll(RegExp(r'[^0-9.]'), '');
    final currentValue = double.tryParse(valueStr) ?? 0.0;

    for (int i = 0; i < widget.segments!.length; i++) {
      final seg = widget.segments![i];
      final min = double.tryParse((seg["min"]?.toString() ?? "")
              .replaceAll(RegExp(r'[^0-9.]'), '')) ??
          double.negativeInfinity;
      final max = double.tryParse((seg["max"]?.toString() ?? "")
              .replaceAll(RegExp(r'[^0-9.]'), '')) ??
          double.infinity;

      if (currentValue >= min && currentValue <= max) {
        setState(() {
          currentSegmentIndex = i;
        });
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double _parseNumber(dynamic raw) {
      if (raw == null) return double.nan;
      final str = raw.toString().replaceAll(RegExp(r'[^0-9.]'), '');
      return str.isEmpty ? double.nan : double.tryParse(str) ?? double.nan;
    }

    Widget buildMeasurementBar(
        String value, List<Map<String, dynamic>> segments) {
      if (segments.isEmpty) return const SizedBox.shrink();

      return SizedBox(
        height: 16, // enough space for circle + bar
        child: Stack(
          children: [
            // Segmented bar
            Align(
              alignment: Alignment.center,
              child: Row(
                children: segments
                    .map((seg) => Expanded(
                          child: ColoredBox(
                            color: seg["color"] as Color? ?? Colors.grey,
                            child: const SizedBox(height: 6),
                          ),
                        ))
                    .toList(),
              ),
            ),

            // Circle marker
            Align(
              alignment: Alignment(
                (() {
                  final valueNum = _parseNumber(value);
                  final segs = segments;
                  final n = segs.length;
                  final segWidth = 2.0 / n;

                  int idx = n - 1;
                  for (int i = 0; i < n; i++) {
                    final min = _parseNumber(segs[i]["min"]);
                    final max = _parseNumber(segs[i]["max"]);
                    final isFirst = i == 0;
                    final isLast = i == n - 1;

                    final meetsMin = min.isNaN ? isFirst : (valueNum >= min);
                    final meetsMax = max.isNaN ? isLast : (valueNum <= max);

                    if (meetsMin && meetsMax) {
                      idx = i;
                      break;
                    }
                  }

                  // Save the segment index into a local variable via closure
                  currentSegmentIndex = idx;

                  double segMin = _parseNumber(segs[idx]["min"]);
                  double segMax = _parseNumber(segs[idx]["max"]);
                  double t;

                  if (!segMin.isNaN && !segMax.isNaN && segMax > segMin) {
                    t = (valueNum - segMin) / (segMax - segMin);
                  } else if (segMin.isNaN && !segMax.isNaN) {
                    t = 0.1;
                  } else if (!segMin.isNaN && segMax.isNaN) {
                    t = 0.9;
                  } else {
                    t = 0.5;
                  }

                  t = (t.clamp(0.0, 1.0) as double);

                  final leftEdge = -1.0 + idx * segWidth;
                  final x = leftEdge + t * segWidth;

                  return (x.clamp(-1.0, 1.0) as double);
                })(),
                0,
              ),
              child: Builder(
                builder: (_) {
                  // Pick border color from the current segment
                  final borderColor =
                      segments[currentSegmentIndex]["color"] as Color? ??
                          Colors.grey;

                  return Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: borderColor,
                        width: 3,
                      ),
                    ),
                  );
                },
              ),
            )
          ],
        ),
      );
    }

    final segments = widget.segments;

    // Put these inside _ExpandableMeasurementRowState
    int _precisionFrom(String reference) {
      // Extract first number (e.g., "63.0", "21.35")
      final m = RegExp(r'(\d+(?:\.(\d+))?)').firstMatch(reference);
      if (m == null) return 0;
      final dec = m.group(2);
      return dec?.length ?? 0;
    }

    String _formatLike(String reference, double value) {
      final decimals = _precisionFrom(reference);
      return value.toStringAsFixed(decimals);
    }

    String getDifferenceFromStandard() {
      final segs = (widget.segments ?? const <Map<String, dynamic>>[])
          .cast<Map<String, dynamic>>();
      if (segs.isEmpty) return "";

      // ✅ Current value (numeric)
      final currentValue = double.tryParse(
            widget.value.replaceAll(RegExp(r'[^0-9.]'), ''),
          ) ??
          0.0;

      // ✅ Case 1: Normal "Standard"
      final standardSegment = segs.firstWhere(
        (seg) => (seg["label"] as String).toLowerCase() == "standard",
        orElse: () => <String, dynamic>{},
      );
      if (standardSegment.isNotEmpty) {
        final minStandard = double.tryParse(
              (standardSegment["min"] ?? "")
                  .toString()
                  .replaceAll(RegExp(r'[^0-9.]'), ''),
            ) ??
            0.0;
        final maxStandard = double.tryParse(
              (standardSegment["max"] ?? "")
                  .toString()
                  .replaceAll(RegExp(r'[^0-9.]'), ''),
            ) ??
            0.0;

        if (currentValue > maxStandard) {
          final diff = currentValue - maxStandard;
          return "${_formatLike(widget.value, diff)}${widget.unit ?? ""} more than the standard value";
        } else if (currentValue < minStandard) {
          final diff = minStandard - currentValue;
          return "${_formatLike(widget.value, diff)}${widget.unit ?? ""} less than the standard value";
        }
        return ""; // within range
      }

      // ✅ Case 2: BMR (Standard Not Met + Standard Met)
      if (widget.label == "BMR") {
        final stdMet = segs.firstWhere(
          (seg) => (seg["label"] as String).toLowerCase() == "standard met",
          orElse: () => <String, dynamic>{},
        );

        if (stdMet.isNotEmpty) {
          final minStdMet = double.tryParse(
                (stdMet["min"] ?? "")
                    .toString()
                    .replaceAll(RegExp(r'[^0-9.]'), ''),
              ) ??
              0.0;

          if (currentValue < minStdMet) {
            final diff = minStdMet - currentValue;
            return "${_formatLike(widget.value, diff)}${widget.unit ?? ""} less than the standard value";
          }
        }
        return ""; // above Standard Met → fine
      }

      // ✅ Case 3: Metabolic Age (Standard Met + Standard Not Met)
      if (widget.label == "Metabolic Age") {
        final stdNotMet = segs.firstWhere(
          (seg) => (seg["label"] as String).toLowerCase() == "standard not met",
          orElse: () => <String, dynamic>{},
        );

        if (stdNotMet.isNotEmpty) {
          final minStdNotMet = double.tryParse(
                (stdNotMet["min"] ?? "")
                    .toString()
                    .replaceAll(RegExp(r'[^0-9.]'), ''),
              ) ??
              0.0;

          if (currentValue > minStdNotMet) {
            final diff = currentValue - minStdNotMet;
            return "${_formatLike(widget.value, diff)}${widget.unit ?? ""} more than the actual age";
          }
        }
        return ""; // within or below → fine
      }

      return ""; // fallback
    }

    return GestureDetector(
      onTap: widget.onTap,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 7),
            child: Row(
              children: [
                hasFirstEntry
                    ? Visibility(
                        visible: (segments != null &&
                                segments[currentSegmentIndex]['label'] !=
                                    'Standard' &&
                                segments[currentSegmentIndex]['label'] !=
                                    'Adequate' &&
                                segments[currentSegmentIndex]['label'] !=
                                    'Standard Met')
                            ? false
                            : true,
                        child: SizedBox(
                          height: 35,
                        ),
                      )
                    : SizedBox(
                        height: 35,
                      ),
                Padding(
                  padding: const EdgeInsets.only(left: 2, right: 18),
                  child: Image(
                    image: widget.image,
                    color: Colors.grey,
                    width: 20,
                    height: 20,
                  ),
                ),
                Expanded(
                  child: Text(
                    widget.label,
                    style: GoogleFonts.roboto(fontSize: 15),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          hasFirstEntry
                              ? TextSpan(
                                  text: widget.value,
                                  style: GoogleFonts.roboto(
                                    color:
                                        (segments != null && segments.isNotEmpty
                                            ? segments[currentSegmentIndex]
                                                    ["color"] as Color? ??
                                                Colors.grey
                                            : Colors.green.shade600),
                                    fontSize: 19,
                                    fontWeight: FontWeight.w400,
                                  ),
                                )
                              : TextSpan(
                                  text: "- -",
                                  style: GoogleFonts.roboto(
                                    color: Colors.grey,
                                    fontSize: 19,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                          if (widget.unit != null &&
                              hasFirstEntry) // only show if unit exists
                            TextSpan(
                              text: " ${widget.unit}",
                              style: GoogleFonts.roboto(
                                color: (segments != null && segments.isNotEmpty
                                    ? segments[currentSegmentIndex]["color"]
                                            as Color? ??
                                        Colors.grey
                                    : Colors.green.shade600),
                                fontSize: 11,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(width: 14),
                    AnimatedRotation(
                      turns: widget.isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: const Icon(Icons.keyboard_arrow_down,
                          color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Visibility(
            visible: hasFirstEntry &&
                segments != null &&
                segments[currentSegmentIndex]['label'] != 'Standard' &&
                segments[currentSegmentIndex]['label'] != 'Adequate' &&
                segments[currentSegmentIndex]['label'] != 'Standard Met',
            child: Padding(
              padding:
                  const EdgeInsets.only(left: 20, right: 20, bottom: 8, top: 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Left side padding for image + its padding
                  const SizedBox(width: 38), // 20 (image) + 18 (padding)

                  // Text aligned under label
                  Expanded(
                    child: Text(
                      getDifferenceFromStandard(),
                      style:
                          GoogleFonts.roboto(fontSize: 12, color: Colors.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  // Container aligned under down arrow
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 3, vertical: 0),
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: (segments != null && segments.isNotEmpty
                              ? segments[currentSegmentIndex]["color"]
                                      as Color? ??
                                  Colors.grey
                              : Colors.green.shade600)),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(
                      "${segments?[currentSegmentIndex]["label"]}",
                      style: GoogleFonts.roboto(
                          fontSize: 12,
                          color: (segments != null && segments.isNotEmpty
                              ? segments[currentSegmentIndex]["color"]
                                      as Color? ??
                                  Colors.grey
                              : Colors.green.shade600),
                          height: 1.2),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Expandable area
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Container(
              color: Colors.grey.shade200,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🔹 Boundary labels above the bar
                  if (segments != null && segments!.isNotEmpty)
                    Visibility(
                      visible: widget.isExpanded, // only show when expanded
                      maintainState: true,
                      child: Stack(
                        children: [
                          Row(
                            children: List.generate(
                              segments!.length,
                              (_) => const Expanded(child: SizedBox(height: 0)),
                            ),
                          ),
                          ...List.generate(segments!.length - 1, (i) {
                            final segmentMaxStr =
                                segments![i]["max"].toString();
                            final segmentUnit = segments![i]["unit"] ?? "";
                            final boundaryValue = "$segmentMaxStr$segmentUnit";

                            final alignmentX =
                                -1.0 + 2 * (i + 1) / segments!.length;
                            return Align(
                              alignment: Alignment(alignmentX, -1.2),
                              child: Text(
                                boundaryValue,
                                style: GoogleFonts.roboto(
                                  fontSize: 10,
                                  color: Colors.black54,
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  const SizedBox(height: 4),

                  if (segments != null && segments!.isNotEmpty)
                    buildMeasurementBar(widget.value, segments!),

                  Visibility(
                    visible: widget.isExpanded,
                    maintainState: true,
                    child: Row(
                      children: (segments ?? [])
                          .map((seg) => Expanded(
                                child: Text(
                                  seg["label"] ?? "",
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.roboto(
                                    fontSize: 10,
                                    color: Colors.black54,
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  ),

                  if (segments != null && segments!.isNotEmpty)
                    const SizedBox(height: 32),
                  Visibility(
                    visible: widget.isExpanded,
                    maintainState: true,
                    child: Text(
                      widget.description,
                      style: GoogleFonts.roboto(
                        color: Colors.black38,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            crossFadeState: widget.isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),

          hasFirstEntry
              ? Visibility(
                  visible: (segments != null &&
                          segments[currentSegmentIndex]['label'] !=
                              'Standard' &&
                          segments[currentSegmentIndex]['label'] !=
                              'Adequate' &&
                          segments[currentSegmentIndex]['label'] !=
                              'Standard Met')
                      ? false
                      : true,
                  child: SizedBox(
                    height: 5,
                  ),
                )
              : SizedBox(
                  height: 5,
                ),

          if (!widget.isExpanded)
            Divider(
              color: Colors.grey.shade300, // lighter shade
              thickness: 1,
              indent: 58,
              height: 0,
            )
        ],
      ),
    );
  }
}

// 📌 Range Tag widget
class _RangeTag extends StatelessWidget {
  final String label;
  final Color color;

  const _RangeTag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        alignment: Alignment.center,
        color: Colors.white,
        child: Text(label,
            style: GoogleFonts.roboto(
                fontSize: 10, color: color, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget buildSegmentedBar({
    required String valueWithUnit,
    required List<Map<String, dynamic>> segments,
  }) {
    // Compute boundaries (max of each segment except last)
    final boundaries = <String>[];
    for (int i = 0; i < segments.length - 1; i++) {
      boundaries.add("${segments[i]["max"]}"); // add unit if needed
    }

    // Parse numeric value for marker positioning
    final doubleValue =
        double.tryParse(valueWithUnit.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;

    // Total range
    final totalMin = segments.first["min"] as double;
    final totalMax = segments.last["max"] as double;

    // Normalized alignment for marker (-1 to 1)
    final alignmentX =
        ((doubleValue - totalMin) / (totalMax - totalMin)) * 2 - 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 🔹 Boundary labels
        Stack(
          children: [
            Row(
              children: List.generate(
                segments.length,
                (_) => const Expanded(child: SizedBox(height: 0)),
              ),
            ),
            ...List.generate(boundaries.length, (i) {
              final alignment = -1.0 + 2 * (i + 1) / segments.length;
              return Align(
                alignment: Alignment(alignment, -1.2), // above the bar
                child: Text(
                  boundaries[i],
                  style:
                      GoogleFonts.roboto(fontSize: 10, color: Colors.black54),
                ),
              );
            }),
          ],
        ),
        const SizedBox(height: 4),

        // 🔹 Segmented bar + circle marker
        SizedBox(
          height: 16, // enough to center the dot
          child: Stack(
            alignment: Alignment.center,
            children: [
              Row(
                children: segments
                    .map((seg) => Expanded(
                          child: ColoredBox(
                            color: seg["color"] as Color? ?? Colors.grey,
                            child: const SizedBox(height: 6),
                          ),
                        ))
                    .toList(),
              ),
              Align(
                alignment: Alignment(alignmentX, 0),
                // horizontally dynamic, vertically centered
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.lightGreen.shade500,
                      width: 3,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // 🔹 Labels under bar
        Row(
          children: segments
              .map((seg) => Expanded(
                    child: Text(
                      seg["label"] ?? "",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.roboto(
                          fontSize: 10, color: Colors.black54),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

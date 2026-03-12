import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:smart_scale/core/user_prefs.dart';
import 'package:smart_scale/core/nutrition_calculator.dart';
import 'package:smart_scale/data/meal_planner.dart';
import 'package:smart_scale/data/plan_from_prefs.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:file_saver/file_saver.dart';
import 'package:open_filex/open_filex.dart';

import '../../core/tag_utils.dart';
import '../services/scaleway_ai_service.dart';

class DietChartAi extends StatefulWidget {
  const DietChartAi({super.key});
  @override
  State<DietChartAi> createState() => _DietChartAiState();
}

class _DietChartAiState extends State<DietChartAi> {
  String _name = '';
  bool _showIntro = true;
  int _currentMessageIndex = 0;

  Timer? _introHideTimer;
  Timer? _msgTimer;

  pw.Font? _pdfBaseFont;
  pw.Font? _pdfBoldFont;

  final ai = ScalewayAIService();
  String? result;
  bool isLoading = false;
  Map<String, dynamic> user = {};

  final List<String> _messages = const [
    "Preparing your diet chart…",
    "Adding healthy food choices…",
    "Balancing your nutrition…",
    "Almost ready for you!",
  ];

  @override
  void initState() {
    super.initState();
    _loadName();
    _kickoffIntroStepper();
    loadUserDetails();
  }

  Future<void> _ensurePdfFonts() async {
    _pdfBaseFont ??=
        pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSans-Regular.ttf'));
    _pdfBoldFont ??=
        pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSans-Bold.ttf'));
  }

  void _kickoffIntroStepper() {
    setState(() {
      _showIntro = true;
      _currentMessageIndex = 0;
    });

    final perStepMs = (3000 / _messages.length).floor();
    _msgTimer?.cancel();
    _msgTimer = Timer.periodic(Duration(milliseconds: perStepMs), (_) {
      if (!mounted) return;
      setState(() {
        _currentMessageIndex = (_currentMessageIndex + 1) % _messages.length;
      });
    });

    // Hide intro after 3 seconds
    _introHideTimer?.cancel();
    _introHideTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      _msgTimer?.cancel();
      setState(() => _showIntro = false);
    });
  }

  Future<void> _loadName() async {
    final savedName = await UserPrefs.getName() ?? '';
    if (!mounted) return;
    setState(() => _name = savedName);
  }

  Future<void> generatePlan(Map<String, dynamic> user) async {
    setState(() => isLoading = true);

    try {
      final mealPlan = await ai.generateMealPlan(user);
      setState(() => result = mealPlan);
    } catch (e) {
      setState(() => result = e.toString());
    } finally {
      print("result is $result");
      setState(() => isLoading = false);
    }
  }

  Future<void> loadUserDetails() async {
    final name = await UserPrefs.getName();
    String? dietPref = await UserPrefs.getDietPreference(); // optional
    final userSex = await UserPrefs.getSex(); // 'Male' | 'Female'
    final allergies = await UserPrefs.getAllergies(); // List<String>?
    final heightCm = await UserPrefs.getHeightCm(); // double?
    final weightKg = await UserPrefs.getWeightKg(); // double?
    final ageYears = await UserPrefs.getAgeYears(); // int?
    final activityCode = await UserPrefs
        .getActivity(); // 'sedentary'|'light'|'moderate'|'veryActive'
    final goalLabel = await UserPrefs.getGoalLabel(); // e.g. 'Gain Muscle'
    final medicalList = await UserPrefs.getMedicalConditions(); // List<String>?

    final excludeAllergens = Set<String>.from(
      (await UserPrefs.getAllergies()),
    );

    final medicalTags = Set<String>.from(medicalList);

    final activity = TagUtils.mapActivityCodeToEnum(activityCode!);
    final goalEnum = TagUtils.mapGoalLabelToEnum(goalLabel!);

    user = {
      'name': name,
      'gender': userSex!,
      'age': ageYears!,
      'height': heightCm!,
      'weight': weightKg!,
      'activityLevel': activity,
      'goal': goalEnum,
      'mealPreference': dietPref,
      'allergies': excludeAllergens,
      'conditions': medicalTags,
    };

    await generatePlan(user);
  }

  Future<Uint8List> _buildDietPdf() async {
    await _ensurePdfFonts();

    final doc = pw.Document(
      theme: pw.ThemeData.withFont(
        base: _pdfBaseFont!,
        bold: _pdfBoldFont!,
      ),
    );

    final dateStr = DateFormat('EEE, d MMM yyyy').format(DateTime.now());

    final titleStyle =
        pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold);
    final sectionTitle =
        pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold);
    final normal = pw.TextStyle(fontSize: 11);
    final muted = pw.TextStyle(fontSize: 10, color: PdfColors.grey600);

    doc.addPage(
      pw.MultiPage(
        pageTheme: const pw.PageTheme(
          margin: pw.EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        ),
        header: (_) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('GGMS • Diet Chart', style: muted),
            pw.Text(dateStr, style: muted),
          ],
        ),
        footer: (ctx) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Page ${ctx.pageNumber}/${ctx.pagesCount}',
            style: muted,
          ),
        ),
        build: (_) {
          final widgets = <pw.Widget>[
            pw.Text('Diet Chart for $_name', style: titleStyle),
            pw.SizedBox(height: 6),
            pw.Text(
              'Your custom plan to guide your fitness journey.',
              style: normal,
            ),
            pw.SizedBox(height: 12),
          ];

          if (result == null || result!.trim().isEmpty) {
            widgets.add(
              pw.Text('No diet chart available.', style: normal),
            );
            return widgets;
          }

          final lines = result!.split('\n');

          for (final raw in lines) {
            final line = raw.trim();
            if (line.isEmpty) {
              widgets.add(pw.SizedBox(height: 4));
              continue;
            }

            // Meal title line, e.g. "Breakfast:"
            if (line.endsWith(':')) {
              widgets.add(pw.SizedBox(height: 10));
              widgets.add(
                pw.Text(line, style: sectionTitle),
              );
              widgets.add(pw.SizedBox(height: 2));
              continue;
            }

            // Macro line, e.g. "Protein: 10g | Carbs: 40g | Fats: 8g"
            final lower = line.toLowerCase();
            if (lower.contains('protein') && lower.contains('carbs')) {
              widgets.add(
                pw.Text(line, style: muted),
              );
              continue;
            }

            // Normal description / item line
            widgets.add(
              pw.Text(line, style: normal),
            );
          }

          return widgets;
        },
      ),
    );

    return Uint8List.fromList(await doc.save());
  }

  Future<void> _saveAsPdf() async {
    try {
      final bytes = await _buildDietPdf();
      final fileName =
          'diet_chart_${DateTime.now().toIso8601String().split('T').first}.pdf';

      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes, flush: true);

      await OpenFilex.open(file.path);
    } catch (e) {
      debugPrint('Error saving PDF: $e');
      // showSnackBar / dialog if you want
    }
  }

  Future<void> _shareDietPdf() async {
    try {
      final bytes = await _buildDietPdf();
      final fileName = 'diet_chart.pdf';

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(bytes, flush: true);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Here is your personalized diet chart.',
      );
    } catch (e) {
      debugPrint('Error sharing PDF: $e');
    }
  }

  @override
  void dispose() {
    _introHideTimer?.cancel();
    _msgTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      scaffoldBackgroundColor: const Color(0xFF1A1C23),
      textTheme: const TextTheme(
        titleMedium: TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 21),
        titleSmall: TextStyle(
            color: Colors.white, fontWeight: FontWeight.w300, fontSize: 15),
      ),
      useMaterial3: true,
    );

    return Theme(
      data: theme,
      child: Scaffold(
        body: Stack(
          children: [
            SafeArea(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 6),
                    const Text(
                      "Diet Chart",
                      style: TextStyle(fontSize: 20, color: Colors.white),
                    ),
                    const SizedBox(height: 90),
                    Center(
                      child: Column(
                        children: [
                          Text(
                            _name.isEmpty
                                ? "Congratulations!"
                                : "Congratulations, $_name!",
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 10),
                          RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: theme.textTheme.titleSmall,
                              children: const [
                                TextSpan(
                                    text:
                                        "Your custom plan is ready and will help guide you"),
                                TextSpan(
                                    text: "\nthrough your fitness journey."),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                          if (result == null)
                            Column(
                              children: const [
                                CircularProgressIndicator(),
                                SizedBox(height: 12),
                                Text(
                                  "Generating your plan…",
                                  style: TextStyle(color: Colors.white70),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            )
                          else
                            Text(
                              result!,
                              style: const TextStyle(color: Colors.white),
                            ),
                          SizedBox(
                            height: 32,
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_showIntro)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    color: const Color(0xFF0E1117),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Lottie.asset('images/sparkles.json',
                            width: 220, repeat: true),
                        const SizedBox(height: 16),
                        Text(
                          _messages[_currentMessageIndex],
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),

        // Bottom actions
        bottomNavigationBar: _showIntro
            ? null
            : Container(
                color: const Color(0xFF151724),
                padding: const EdgeInsets.all(15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F9BFF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: result == null ? null : _saveAsPdf,
                        // onPressed: null,
                        icon: const Icon(Icons.download_rounded,
                            color: Colors.white),
                        label: const Text(
                          "Save",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF37C47E),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: result == null ? null : _shareDietPdf,
                        // onPressed: null,
                        icon: const Icon(Icons.share_rounded,
                            color: Colors.white),
                        label: const Text(
                          "Share",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.white),
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

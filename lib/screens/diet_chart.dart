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

class DietChart extends StatefulWidget {
  const DietChart({super.key});
  @override
  State<DietChart> createState() => _DietChartState();
}

class _DietChartState extends State<DietChart> {
  String _name = '';
  bool _showIntro = true;
  int _currentMessageIndex = 0;

  Timer? _introHideTimer;
  Timer? _msgTimer;

  pw.Font? _pdfBaseFont;
  pw.Font? _pdfBoldFont;

  final List<String> _messages = const [
    "Preparing your diet chart…",
    "Adding healthy food choices…",
    "Balancing your nutrition…",
    "Almost ready for you!",
  ];

  final MealsRepository _repo = MealsRepository();
  Map<MealSlot, SlotPlan>? _plan; // multi-item plan

  @override
  void initState() {
    super.initState();
    _loadName();
    _kickoffIntroStepper();
    _loadPlan();
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

  Future<void> _loadPlan() async {
    try {
      final plan = await generateDailyPlanFromPrefs(_repo);
      if (!mounted) return;
      setState(() {
        _plan = plan; // even if empty map, UI will render per-slot cards
      });
    } catch (e, st) {
      // ignore: avoid_print
      print('Diet plan error: $e\n$st'); // check console for exact source
      if (!mounted) return;
      setState(() {
        _plan = const {}; // not null -> shows section cards with "No items"
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot build plan: $e',
              style: const TextStyle(color: Colors.white)),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _saveAsPdf() async {
    if (_plan == null) return;
    try {
      final bytes = await _buildPdfBytes();
      final fileName =
          'diet_chart_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';

      final savedPath = await FileSaver.instance.saveFile(
        name: fileName,
        bytes: bytes,
        ext: 'pdf',
        mimeType: MimeType.pdf,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved: $fileName')),
      );

      // Optional: open it
      if (savedPath != null && savedPath.isNotEmpty) {
        await OpenFilex.open(savedPath);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save PDF: $e')),
      );
    }
  }

  Future<void> _shareDietChart() async {
    if (_plan == null) return;
    try {
      final bytes = await _buildPdfBytes();
      final tmp = await getTemporaryDirectory();
      final f = File('${tmp.path}/diet_chart_share.pdf');
      await f.writeAsBytes(bytes, flush: true);
      await Share.shareXFiles([XFile(f.path)],
          text: 'My daily diet chart', subject: 'Diet Chart');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to share PDF: $e')),
      );
    }
  }

  Future<Uint8List> _buildPdfBytes() async {
    await _ensurePdfFonts();

    final doc = pw.Document(
      theme: pw.ThemeData.withFont(base: _pdfBaseFont!, bold: _pdfBoldFont!),
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
          child:
              pw.Text('Page ${ctx.pageNumber}/${ctx.pagesCount}', style: muted),
        ),
        build: (_) {
          final widgets = <pw.Widget>[
            pw.Text('Diet Chart for $_name', style: titleStyle),
            pw.SizedBox(height: 6),
            pw.Text('Your custom plan to guide your fitness journey.',
                style: normal),
            pw.SizedBox(height: 12),
          ];

          if (_plan != null) {
            widgets.add(_totalsBox(_plan!, normal));
            widgets.add(pw.SizedBox(height: 16));
          }

          final order = <MealSlot>[
            MealSlot.earlyMorning,
            MealSlot.breakfast,
            MealSlot.lunch,
            MealSlot.eveningSnacks,
            MealSlot.dinner,
            MealSlot.bedtime,
          ];

          for (final slot in order) {
            final sp = _plan?[slot];

            widgets.add(
              pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 12),
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: sp == null || sp.items.isEmpty
                    ? pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(_titleFor(slot), style: sectionTitle),
                          pw.SizedBox(height: 4),
                          pw.Text(_subtitleFor(slot), style: muted),
                          pw.SizedBox(height: 8),
                          pw.Text('No items assigned for this slot.',
                              style: normal),
                        ],
                      )
                    : pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(_titleFor(slot), style: sectionTitle),
                          pw.SizedBox(height: 4),
                          pw.Text(_subtitleFor(slot), style: muted),
                          pw.SizedBox(height: 8),

                          // items
                          ...sp.items.expand<pw.Widget>((item) {
                            final amount = _formatAmountWithPiecesPdf(item);
                            final macros =
                                'P ${item.proteinG.toStringAsFixed(1)}g  •  C ${item.carbsG.toStringAsFixed(1)}g  •  F ${item.fatG.toStringAsFixed(1)}g';
                            return [
                              pw.Text(
                                  '- ${item.meal.name}  •  $amount  •  ${item.plannedKcal} kcal',
                                  style: normal),
                              pw.Text(macros, style: muted),
                              pw.SizedBox(height: 4),
                            ];
                          }),

                          pw.Divider(thickness: 0.5),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'Total: P ${sp.proteinTotal.toStringAsFixed(1)}g  •  '
                            'C ${sp.carbsTotal.toStringAsFixed(1)}g  •  '
                            'F ${sp.fatTotal.toStringAsFixed(1)}g',
                            style: normal,
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            _kcalLine(sp),
                            style: muted,
                          ),
                        ],
                      ),
              ),
            );
          }

          return widgets;
        },
      ),
    );

    return Uint8List.fromList(await doc.save());
  }

  pw.Widget _totalsBox(Map<MealSlot, SlotPlan> plan, pw.TextStyle normal) {
    double kcal = 0, p = 0, c = 0, f = 0;
    plan.forEach((_, sp) {
      if (sp == null) return;
      kcal += sp.plannedKcalTotal.toDouble();
      p += sp.proteinTotal;
      c += sp.carbsTotal;
      f += sp.fatTotal;
    });

    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFF6F7F9),
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Daily Total: ${kcal.toStringAsFixed(0)} kcal',
              style: normal),
          pw.Text(
              'P ${p.toStringAsFixed(1)}g • C ${c.toStringAsFixed(1)}g • F ${f.toStringAsFixed(1)}g',
              style: normal),
        ],
      ),
    );
  }

// --- helpers reused from your UI logic ---
  String _kcalLine(SlotPlan sp) {
    final planned = sp.plannedKcalTotal;
    final target = sp.targetKcal;
    final delta = planned - target;
    final deltaStr =
        delta == 0 ? '' : (delta > 0 ? '  •  +$delta' : '  •  $delta');
    return '$planned kcal  •  target $target$deltaStr';
  }

  String _titleFor(MealSlot s) {
    switch (s) {
      case MealSlot.earlyMorning:
        return 'Early Morning';
      case MealSlot.breakfast:
        return 'Breakfast';
      case MealSlot.lunch:
        return 'Lunch';
      case MealSlot.eveningSnacks:
        return 'Evening Snacks';
      case MealSlot.dinner:
        return 'Dinner';
      case MealSlot.bedtime:
        return 'Bedtime';
    }
  }

  String _subtitleFor(MealSlot s) {
    switch (s) {
      case MealSlot.earlyMorning:
        return 'Start hydrated & light';
      case MealSlot.breakfast:
        return 'Balanced carbs + protein';
      case MealSlot.lunch:
        return 'Nutritious meal to fuel your afternoon';
      case MealSlot.eveningSnacks:
        return 'Light & protein-forward';
      case MealSlot.dinner:
        return 'Balanced but lighter than lunch';
      case MealSlot.bedtime:
        return 'Light, calming & sleep-friendly';
    }
  }

  /// Formats amounts like "240 g (≈ 6 pcs)" or "250 ml" for PDF text.
  String _formatAmountWithPiecesPdf(ItemPick item) {
    final meal = item.meal;
    final unit = meal.unit; // 'g' or 'ml'
    final amt = item.amount;
    String base = '${amt.toStringAsFixed(0)} $unit';

    final avg = meal.avgWeightG;
    if (unit == 'g' && avg != null && avg > 0) {
      final pcs = (amt / avg).round();
      if (pcs >= 1) base += '  ( $pcs pcs)';
    }
    return base;
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

    final sectionCards = _buildSectionCards();

    return Theme(
      data: theme,
      child: Scaffold(
        body: Stack(
          children: [
            SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 6),
                    const Text("Diet Chart",
                        style: TextStyle(fontSize: 20, color: Colors.white)),
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
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: (_plan == null && !_showIntro)
                          ? const _EmptyStateCard()
                          : ListView(
                              padding: const EdgeInsets.only(bottom: 16),
                              children: sectionCards,
                            ),
                    ),
                  ],
                ),
              ),
            ),

            // Intro overlay
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
                        onPressed: _plan == null ? null : _saveAsPdf,
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
                        onPressed: _plan == null ? null : _shareDietChart,
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

  // ---------- UI builders (multi-item) ----------

  List<Widget> _buildSectionCards() {
    if (_plan == null) {
      return const [
        _SkeletonCard(title: 'Early Morning'),
        _SkeletonCard(title: 'Breakfast'),
        _SkeletonCard(title: 'Lunch'),
        _SkeletonCard(title: 'Evening Snacks'),
        _SkeletonCard(title: 'Dinner'),
        _SkeletonCard(title: 'Bedtime'),
      ];
    }

    final order = <MealSlot>[
      MealSlot.earlyMorning,
      MealSlot.breakfast,
      MealSlot.lunch,
      MealSlot.eveningSnacks,
      MealSlot.dinner,
      MealSlot.bedtime,
    ];

    IconData _iconFor(MealSlot s) {
      switch (s) {
        case MealSlot.earlyMorning:
          return Icons.wb_twilight_rounded;
        case MealSlot.breakfast:
          return Icons.free_breakfast_rounded;
        case MealSlot.lunch:
          return Icons.lunch_dining_rounded;
        case MealSlot.eveningSnacks:
          return Icons.coffee_rounded;
        case MealSlot.dinner:
          return Icons.dinner_dining_rounded;
        case MealSlot.bedtime:
          return Icons.bedtime_rounded;
      }
    }

    String _titleFor(MealSlot s) {
      switch (s) {
        case MealSlot.earlyMorning:
          return 'Early Morning';
        case MealSlot.breakfast:
          return 'Breakfast';
        case MealSlot.lunch:
          return 'Lunch';
        case MealSlot.eveningSnacks:
          return 'Evening Snacks';
        case MealSlot.dinner:
          return 'Dinner';
        case MealSlot.bedtime:
          return 'Bedtime';
      }
    }

    String _subtitleFor(MealSlot s) {
      switch (s) {
        case MealSlot.earlyMorning:
          return 'Start hydrated & light';
        case MealSlot.breakfast:
          return 'Balanced carbs + protein';
        case MealSlot.lunch:
          return 'Nutritious meal to fuel your afternoon';
        case MealSlot.eveningSnacks:
          return 'Light & protein-forward';
        case MealSlot.dinner:
          return 'Balanced but lighter than lunch';
        case MealSlot.bedtime:
          return 'Light, calming & sleep-friendly';
      }
    }

    final cards = <Widget>[];

    for (final slot in order) {
      final slotPlan = _plan![slot];

      if (slotPlan == null || slotPlan.items.isEmpty) {
        // Show a graceful placeholder card for missing slot content
        cards.add(
          _MealSectionCard(
            title: _titleFor(slot),
            subtitle: _subtitleFor(slot),
            items: const ['No items assigned for this slot.'],
            calories: '',
            leadingIcon: _iconFor(slot),
          ),
        );
        continue;
      }

      // Per-slot totals & delta
      final planned = slotPlan.plannedKcalTotal;
      final target = slotPlan.targetKcal;
      final delta = planned - target;
      final deltaStr =
          delta == 0 ? '' : (delta > 0 ? '  •  +$delta' : '  •  $delta');
      final kcalLine = '$planned kcal  •  target $target$deltaStr';

      // Per-item lines
      final lines = <String>[];
      for (final item in slotPlan.items) {
        final amount = _formatAmountWithPieces(item);
        final macros =
            'P ${item.proteinG.toStringAsFixed(1)}g  •  C ${item.carbsG.toStringAsFixed(1)}g  •  F ${item.fatG.toStringAsFixed(1)}g';
        lines.add(
            '✱ ${item.meal.name}  •  $amount  •  ${item.plannedKcal} kcal');
        lines.add(macros);
      }

      // Totals line (macros)
      lines.add(
          'Total → P ${slotPlan.proteinTotal.toStringAsFixed(1)}g  •  C ${slotPlan.carbsTotal.toStringAsFixed(1)}g  •  F ${slotPlan.fatTotal.toStringAsFixed(1)}g');

      cards.add(
        _MealSectionCard(
          title: _titleFor(slot),
          subtitle: _subtitleFor(slot),
          items: lines,
          calories: kcalLine,
          leadingIcon: _iconFor(slot),
        ),
      );
    }

    return cards;
  }

  /// Formats amounts like "240 g (≈ 6 pcs)" or "250 ml".
  String _formatAmountWithPieces(ItemPick item) {
    final meal = item.meal;
    final unit = meal.unit; // 'g' or 'ml'
    final amt = item.amount;
    String base = '${amt.toStringAsFixed(0)} $unit';

    // Show piece count for solids with avgWeightG
    final avg = meal.avgWeightG;
    if (unit == 'g' && avg != null && avg > 0) {
      final pcs = (amt / avg).round();
      if (pcs >= 1) base += '  (≈ $pcs pcs)';
    }
    return base;
  }
}

// ------- Skeleton / Cards / Empty state -------

class _SkeletonCard extends StatelessWidget {
  final String title;
  const _SkeletonCard({required this.title});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF151724),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(title, style: const TextStyle(color: Colors.white70)),
        subtitle: const Padding(
          padding: EdgeInsets.only(top: 8.0),
          child: LinearProgressIndicator(minHeight: 6),
        ),
      ),
    );
  }
}

class _MealSectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<String> items;
  final String calories;
  final IconData leadingIcon;

  const _MealSectionCard({
    required this.title,
    required this.subtitle,
    required this.items,
    required this.calories,
    required this.leadingIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF151724),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(leadingIcon, color: Colors.white70),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: Colors.white60)),
                  const SizedBox(height: 10),
                  ...items.map((i) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(i,
                            style: const TextStyle(color: Colors.white)),
                      )),
                  if (calories.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(calories,
                        style: const TextStyle(color: Colors.white70)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF151724),
      child: const Padding(
        padding: EdgeInsets.all(20.0),
        child: Text(
          'No plan could be generated.\nCheck your profile details and try again.',
          style: TextStyle(color: Colors.white70),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smart_scale/ai/screens/ai_diet_chart.dart';
import 'package:smart_scale/screens/diet_chart.dart';

class GenerateMealScreen extends StatefulWidget {
  const GenerateMealScreen({super.key});

  @override
  State<GenerateMealScreen> createState() => _GenerateMealScreenState();
}

class _GenerateMealScreenState extends State<GenerateMealScreen> {
  Future<void> _onGenerateNormal() async {
    Navigator.push(context, MaterialPageRoute(builder: (_) => DietChart()));
  }

  Future<void> _onGenerateAI() async {
    Navigator.push(context, MaterialPageRoute(builder: (_) => DietChartAi()));
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF1A1C23);
    const card = Color(0xFF151724);
    const accent = Color(0xFF4f9bff);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Pick Your Style",
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Row(
                    children: List.generate(10, (index) {
                      return Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          height: 4,
                          decoration: BoxDecoration(
                            color: index == 9
                                ? const Color(0xFF37c47e)
                                : Colors.grey[700],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 18),
                ],
              ),
            ),

            // ===== Two Sections (no bottom bar) =====
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(15, 0, 15, 15),
                child: Column(
                  children: [
                    // ─── Upper: Normal Generation ───
                    Expanded(
                      child: _SectionCard(
                        color: card,
                        title: "Generate Diet Chart",
                        subtitle:
                            "Create a personalized plan using your selected goal, health habits, and preferences.",
                        bullets: const [
                          "Balanced macros from your inputs",
                          "Simple, quick setup",
                          "Offline friendly"
                        ],
                        buttonLabel: "Generate",
                        onPressed: _onGenerateNormal,
                        accent: accent,
                        leadingIcon: Icons.event_note_outlined,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // ─── Lower: AI Generation ───
                    Expanded(
                      child: _SectionCard(
                        color: card,
                        title: "Generate with AI",
                        subtitle:
                            "Leverage AI to tailor meals to your schedule, activity level, and nutrition targets.",
                        bullets: const [
                          "Smart substitutions & variety",
                          "Adapts to feedback",
                          "Learns your routine"
                        ],
                        buttonLabel: "Generate with AI",
                        onPressed: _onGenerateAI,
                        accent: accent,
                        leadingIcon: Icons.auto_awesome,
                        badge: "AI",
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.color,
    required this.title,
    required this.subtitle,
    required this.bullets,
    required this.buttonLabel,
    required this.onPressed,
    required this.accent,
    required this.leadingIcon,
    this.badge,
  });

  final Color color;
  final String title;
  final String subtitle;
  final List<String> bullets;
  final String buttonLabel;
  final VoidCallback onPressed;
  final Color accent;
  final IconData leadingIcon;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(leadingIcon, color: accent, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: accent.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(999),
                              border:
                                  Border.all(color: accent.withOpacity(0.3)),
                            ),
                            child: Text(
                              badge!,
                              style: TextStyle(
                                color: accent,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ]
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.75),
                        fontSize: 13.5,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Bullets
          Column(
            children: bullets
                .map(
                  (b) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.check_circle_rounded,
                            size: 16, color: accent.withOpacity(0.9)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            b,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),

          const Spacer(),

          // Generate button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              onPressed: onPressed,
              child: Text(
                buttonLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

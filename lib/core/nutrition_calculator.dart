// enum Sex { male, female }

enum ActivityLevel {
  sedentary,
  light,
  moderate,
  veryActive,
}

enum Goal {
  loseWeight,
  maintainWeight,
  gainWeight,
  gainMuscle, // similar to gainWeight but biases higher protein
}

enum MealSlot { earlyMorning, breakfast, lunch, eveningSnacks, dinner, bedtime }

class SlotTarget {
  final int kcal;
  final double proteinG;
  final double carbsG;
  final double fatG;
  const SlotTarget({
    required this.kcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
  });
}

class NutritionResult {
  // Energy & macros
  final double bmr; // kcal/day
  final double tdee; // kcal/day
  final int kcalTarget; // rounded kcal/day
  final double proteinTargetG;
  final double fatTargetG;
  final double carbsTargetG;

  // Breakdown by fixed 5 slots
  final Map<MealSlot, SlotTarget> perSlot;

  const NutritionResult({
    required this.bmr,
    required this.tdee,
    required this.kcalTarget,
    required this.proteinTargetG,
    required this.fatTargetG,
    required this.carbsTargetG,
    required this.perSlot,
  });
}

class NutritionCalculator {
  // Fixed slot distribution (sum to 1.0)
  static const Map<MealSlot, double> _slotShare = {
    MealSlot.earlyMorning: 0.08,
    MealSlot.breakfast: 0.25,
    MealSlot.lunch: 0.30,
    MealSlot.eveningSnacks: 0.12,
    MealSlot.dinner: 0.20,
    MealSlot.bedtime: 0.05,
  };

  // Default macro presets (can be nudged by goal)
  // We compute protein from g/kg, fat from % calories, carbs = remainder.
  static const double _proteinGPerKgMaintain = 1.6;
  static const double _proteinGPerKgGain = 1.8;
  static const double _proteinGPerKgGainMuscle = 2.0;
  static const double _proteinGPerKgCut = 1.8;

  static const double _fatPctMaintain = 0.30; // 30% calories from fat
  static const double _fatPctGain = 0.30;
  static const double _fatPctGainMuscle = 0.30;
  static const double _fatPctCut = 0.25; // slightly lower fat on a cut

  // Activity multipliers
  static double _activityFactor(ActivityLevel a) {
    switch (a) {
      case ActivityLevel.sedentary:
        return 1.20;
      case ActivityLevel.light:
        return 1.375;
      case ActivityLevel.moderate:
        return 1.55;
      case ActivityLevel.veryActive:
        return 1.725;
    }
  }

  // Mifflin–St Jeor BMR
  static double bmrMifflinStJeor({
    required String sex,
    required double weightKg,
    required double heightCm,
    required int ageYears,
  }) {
    final base = 10 * weightKg + 6.25 * heightCm - 5 * ageYears;
    return sex == "Male" ? base + 5 : base - 161;
  }

  // Choose kcal delta (surplus/deficit) based on goal.
  // Returns calories to add to (or subtract from) TDEE.
  static int _kcalDeltaForGoal(Goal goal) {
    switch (goal) {
      case Goal.maintainWeight:
        return 0;
      case Goal.gainWeight:
        return 400; // moderate surplus
      case Goal.gainMuscle:
        return 450; // slight bias higher
      case Goal.loseWeight:
        return -450; // moderate deficit
    }
  }

  static NutritionResult calculate({
    required String sex,
    required int ageYears,
    required double heightCm,
    required double weightKg,
    required ActivityLevel activity,
    required Goal goal,
  }) {
    // BMR & TDEE
    final bmr = bmrMifflinStJeor(
      sex: sex,
      weightKg: weightKg,
      heightCm: heightCm,
      ageYears: ageYears,
    );

    final tdee = bmr * _activityFactor(activity);

    // Calorie target (TDEE + delta)
    final delta = _kcalDeltaForGoal(goal);

    int kcalTarget = (tdee + delta).round();

    // Guardrails (avoid extremes)
    final minKcal = (bmr * 1.15).round(); // don't go below 15% above BMR
    final maxKcal =
        (tdee * 1.25).round(); // don't exceed 25% above TDEE by default
    if (goal == Goal.loseWeight) {
      // ensure not too low
      if (kcalTarget < minKcal) kcalTarget = minKcal;
    } else {
      // ensure not excessively high
      if (kcalTarget > maxKcal) kcalTarget = maxKcal;
    }

    // Macro targets
    // Protein (g/kg) selection
    double proteinPerKg;
    switch (goal) {
      case Goal.maintainWeight:
        proteinPerKg = _proteinGPerKgMaintain;
        break;
      case Goal.gainWeight:
        proteinPerKg = _proteinGPerKgGain;
        break;
      case Goal.gainMuscle:
        proteinPerKg = _proteinGPerKgGainMuscle;
        break;
      case Goal.loseWeight:
        proteinPerKg = _proteinGPerKgCut;
        break;
    }

    final proteinTargetG = _round(weightKg * proteinPerKg);

    // Fat % selection
    double fatPct;
    switch (goal) {
      case Goal.maintainWeight:
        fatPct = _fatPctMaintain;
        break;
      case Goal.gainWeight:
        fatPct = _fatPctGain;
        break;
      case Goal.gainMuscle:
        fatPct = _fatPctGainMuscle;
        break;
      case Goal.loseWeight:
        fatPct = _fatPctCut;
        break;
    }

    // Convert to grams:
    // Protein 4 kcal/g, Carbs 4 kcal/g, Fat 9 kcal/g
    final kcalFromProtein = proteinTargetG * 4.0;
    final fatTargetG = _round((kcalTarget * fatPct) / 9.0);
    final kcalFromFat = fatTargetG * 9.0;

    // Remaining kcal go to carbs
    double remainingKcal = kcalTarget - (kcalFromProtein + kcalFromFat);
    if (remainingKcal < 0) remainingKcal = 0;
    final carbsTargetG = _round(remainingKcal / 4.0);

    // Per-slot breakdown (proportionally by kcal; macros follow kcal share)
    final perSlot = <MealSlot, SlotTarget>{};
    for (final entry in _slotShare.entries) {
      final share = entry.value;
      final slotKcal = (kcalTarget * share).round();
      final slotProtein = _round(proteinTargetG * share);
      final slotFat = _round(fatTargetG * share);
      final slotCarbs = _round(carbsTargetG * share);
      perSlot[entry.key] = SlotTarget(
        kcal: slotKcal,
        proteinG: slotProtein,
        carbsG: slotCarbs,
        fatG: slotFat,
      );
    }

    return NutritionResult(
      bmr: _round(bmr),
      tdee: _round(tdee),
      kcalTarget: kcalTarget,
      proteinTargetG: proteinTargetG,
      fatTargetG: fatTargetG,
      carbsTargetG: carbsTargetG,
      perSlot: perSlot,
    );
  }

  // Helpers
  static double _round(double v) => (v * 10).round() / 10.0;
}

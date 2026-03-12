class BodyComposition {
  static String bmi(double weight, double heightCm) {
    final h = heightCm / 100.0;
    return (weight / (h * h)).toStringAsFixed(1);
  }

  static String bodyFat(double bmi, int age, bool isMale) {
    final g = isMale ? 1 : 0;
    final bf = (1.20 * bmi) + (0.23 * age) - (10.8 * g) - 5.4;
    return (bf.clamp(5, 50).toStringAsFixed(1)); // clamp to realistic range
  }

  static String fatFreeMass(double weight, double bodyFatPercent) {
    // FFM = total weight - fat mass
    final ffm = weight * (1.0 - bodyFatPercent / 100.0);
    return ffm.toStringAsFixed(2); // in kg
  }

  static String subcutaneousFat(double bodyFatPercent) {
    return (bodyFatPercent * 0.85).toStringAsFixed(1);
  }

  static String visceralFat(double bodyFatPercent) {
    return (bodyFatPercent * 0.15).toStringAsFixed(0);
  }

  static String skeletalMusclePercent(
      double weight, double bodyFatPercent, bool isMale) {
    final ffm = double.parse(fatFreeMass(weight, bodyFatPercent));
    // Fraction of FFM that is skeletal muscle (typical ranges)
    final fraction = isMale ? 0.52 : 0.48;
    // Convert to % of total body weight
    final smPercent = (ffm * fraction / weight) * 100.0;
    return smPercent
        .clamp(28.0, 52.0)
        .toStringAsFixed(1); // clamp to realistic range
  }

  static String muscleMass(double weight, double bodyFatPercent, bool isMale) {
    // Total body fat mass
    final fatMass = weight * (bodyFatPercent / 100);

    // Fat-Free Mass
    final ffm = weight - fatMass;

    // Approximate muscle fraction of total body weight
    // Includes skeletal + smooth muscles, not just limbs
    final muscleFraction = isMale ? 0.52 : 0.48;

    // Muscle mass = total body weight * fraction
    final mass = ffm * muscleFraction;

    return mass.toStringAsFixed(2);
  }

  static String muscleStorageAbility(
      double weight, double bodyFatPercent, bool isMale) {
    // Step 1: FFM
    final ffm = weight * (1.0 - bodyFatPercent / 100.0);

    // Step 2: Skeletal muscle mass (kg)
    final fraction = isMale ? 0.52 : 0.48;
    final muscleKg = ffm * fraction;

    // Step 3: Skeletal muscle % of body weight
    final musclePercent = (muscleKg / weight) * 100.0;

    // Step 4: Scale to a 1–6 index (rounded)
    // Typical skeletal muscle % range ~30–50
    final scaled = ((musclePercent - 30) / (50 - 30) * 6).clamp(1.0, 6.0);
    final value = scaled.round();

    return value.toString();
  }

  static String bodyWater(double weight, double bodyFatPercent) {
    final ffm = double.parse(fatFreeMass(weight, bodyFatPercent));

    // Total body water is roughly 73% of FFM
    final waterKg = ffm * 0.73;

    // Express as % of total weight
    final waterPercent = (waterKg / weight) * 100;

    return waterPercent.toStringAsFixed(1); // %
  }

  static String boneMass(double weight, bool isMale) {
    return (isMale ? weight * 0.04 : weight * 0.035).toStringAsFixed(2);
  }

  static String protein(double weight, double bodyFatPercent) {
    final ffm = weight * (1 - bodyFatPercent / 100);

    final proteinKg = ffm * 0.19;

    return proteinKg.toStringAsFixed(1); // kg
  }

  static String bmr(double weight, double heightCm, int age, bool isMale) {
    final s = isMale ? 5 : -161;
    final mifflin = (10.0 * weight) + (6.25 * heightCm) - (5.0 * age) + s;

    // 2) Katch–McArdle via FFM estimated from Deurenberg BF%
    final hM = heightCm / 100.0;
    final bmiVal = (hM > 0) ? (weight / (hM * hM)) : 0.0;
    final sex = isMale ? 1.0 : 0.0;
    var bf = 1.20 * bmiVal + 0.23 * age - 10.8 * sex - 5.4;
    bf = bf.clamp(3.0, 60.0);
    final ffm = weight * (1.0 - bf / 100.0);
    final katch = 370.0 + 21.6 * ffm;

    // 3) Blend for stability (Mifflin more weight than Katch since BF% is estimated)
    final blended = 0.7 * mifflin + 0.3 * katch;
    return blended.round().clamp(500, 4000).toString();
  }

  static String metabolicAge(
      double weight, double heightCm, int age, bool isMale, double actualBmr) {
    if (!actualBmr.isFinite || actualBmr <= 0) {
      return age.clamp(10, 100).toString();
    }

    // Step 1: Compute standard BMR for the same age
    final s = isMale ? 5 : -161;
    final numerator = 10.0 * weight + 6.25 * heightCm + s - actualBmr;
    final solvedAge = (numerator / 5.0).round();

    // Clamp to reasonable range
    return solvedAge.clamp(10, 100).toString();
  }
}

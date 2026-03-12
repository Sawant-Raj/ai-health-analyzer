import 'package:smart_scale/core/user_prefs.dart';
import 'package:smart_scale/core/tag_utils.dart';
import 'package:smart_scale/data/meal_planner.dart';
import 'package:smart_scale/core/nutrition_calculator.dart';

/// Generate a daily plan using values from UserPrefs.
/// Returns a multi-item plan: Map<MealSlot, SlotPlan>
Future<Map<MealSlot, SlotPlan>> generateDailyPlanFromPrefs(
  MealsRepository repo,
) async {
  // Read from your typed API
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

  // Normalize diet preference to canonical tag (but do NOT require it)
  if (dietPref != null &&
      !{'veg', 'nonveg', 'eggetarian', 'vegan'}.contains(dietPref)) {
    dietPref = TagUtils.mapPreference(dietPref);
  }

  // Null-safe: normalize allergens -> canonical tags
  final excludeAllergens = Set<String>.from(
    (await UserPrefs.getAllergies()) ?? const <String>[],
  );

  // Null-safe: medical condition labels -> canonical tags
  final medicalTags = Set<String>.from(medicalList ?? const <String>[]);

  // Validate presence (dietPref is OPTIONAL)
  final missing = <String>[];
  if (userSex == null) missing.add('sex');
  if (activityCode == null) missing.add('activity level');
  if (goalLabel == null) missing.add('goal');
  if (heightCm == null) missing.add('height');
  if (weightKg == null) missing.add('weight');
  if (ageYears == null) missing.add('age');

  if (missing.isNotEmpty) {
    throw StateError('Missing/invalid: ${missing.join(', ')}');
  }

  // Map enums
  final activity = TagUtils.mapActivityCodeToEnum(activityCode!);
  final goalEnum = TagUtils.mapGoalLabelToEnum(goalLabel!);

  // Build plan (multi-item)
  final planner = MealPlanner(repo);
  final plan = await planner.buildDailyPlan(
    sex: userSex!,
    ageYears: ageYears!,
    heightCm: heightCm!,
    weightKg: weightKg!,
    activity: activity,
    overrideGoal: goalEnum,
    dietPreferenceTag: dietPref, // may be null → soft bias only
    excludeAllergens: excludeAllergens, // canonical tags
    requireMedicalSafe: medicalTags, // e.g. {'diabetes','pcos'}
    seedKey:
        'user:${name ?? "anon"}|${DateTime.now().toIso8601String().substring(0, 10)}',
  );

  return plan;
}

import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:smart_scale/core/tag_utils.dart';
import 'package:smart_scale/core/user_prefs.dart';
import 'package:smart_scale/data/slot_templates.dart';
import '../core/nutrition_calculator.dart';
import 'dart:math';

// ---- Models ----

const int _KCAL_TOL = 20; // allow a tiny wiggle room

class Per100g {
  final double kcal;
  final double protein;
  final double carbs;
  final double fat;
  const Per100g({
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  factory Per100g.fromJson(Map<String, dynamic> j) => Per100g(
        kcal: (j['kcal'] as num).toDouble(),
        protein: (j['protein'] as num).toDouble(),
        carbs: (j['carbs'] as num).toDouble(),
        fat: (j['fat'] as num).toDouble(),
      );
}

class Meal {
  final int id;
  final String name;
  final String slot;

  final String? role;

  final String unit;

  final Per100g per100g;

  final double? avgWeightG;

  final double? min; // grams/ml lower bound
  final double? max; // grams/ml upper bound
  final double? step; // grams/ml step for scaling

  final List<String> tags;

  final List<String> notSafeFor;

  final List<String> containsAllergens;

  Meal({
    required this.id,
    required this.name,
    required this.slot,
    required this.unit,
    required this.per100g,
    this.role,
    this.avgWeightG,
    this.min,
    this.max,
    this.step,
    required this.tags,
    required this.notSafeFor,
    required this.containsAllergens,
  });

  factory Meal.fromJson(Map<String, dynamic> j) => Meal(
        id: j['id'] as int,
        name: j['name'] as String,
        slot: j['slot'] as String,
        role: j['role'] as String?,
        unit: j['unit'] as String,
        per100g: Per100g.fromJson(j['per_100g'] as Map<String, dynamic>),
        avgWeightG: (j['avg_weight_g'] == null)
            ? null
            : (j['avg_weight_g'] as num).toDouble(),
        min: (j['min'] == null) ? null : (j['min'] as num).toDouble(),
        max: (j['max'] == null) ? null : (j['max'] as num).toDouble(),
        step: (j['step'] == null) ? null : (j['step'] as num).toDouble(),
        tags: ((j['tags'] as List?) ?? const [])
            .map((e) => e.toString().toLowerCase().trim())
            .toList(),
        notSafeFor: ((j['not_safe_for'] as List?) ?? const [])
            .map((e) => e.toString().toLowerCase().trim())
            .toList(),
        containsAllergens: ((j['contains_allergens'] as List?) ?? const [])
            .map((e) => e.toString().toLowerCase().trim())
            .toList(),
      );
}

// ---- New result models (multi-item) ----
class ItemPick {
  final Meal meal;
  final double amount; // g/ml AFTER snapping and bounds
  final int plannedKcal;
  final double proteinG;
  final double carbsG;
  final double fatG;

  const ItemPick({
    required this.meal,
    required this.amount,
    required this.plannedKcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
  });
}

class SlotPlan {
  final MealSlot slot;
  final int targetKcal;
  final List<ItemPick> items;

  const SlotPlan({
    required this.slot,
    required this.targetKcal,
    required this.items,
  });

  int get plannedKcalTotal => items.fold(0, (s, i) => s + i.plannedKcal);
  double get proteinTotal => items.fold(0.0, (s, i) => s + i.proteinG);
  double get carbsTotal => items.fold(0.0, (s, i) => s + i.carbsG);
  double get fatTotal => items.fold(0.0, (s, i) => s + i.fatG);
}

// ---- Repository ----
class MealsRepository {
  List<Meal>? _cache;
  Future<List<Meal>> loadMeals() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle
        .loadString('assets/meals2.json'); // adjust path if needed
    final List list = jsonDecode(raw) as List;
    _cache = list.map((e) => Meal.fromJson(e as Map<String, dynamic>)).toList();
    return _cache!;
  }
}

enum MedicalMatchMode {
  andAll,
  orAny
} // kept for API compat (not used directly)

// ---- Planner ----

class MealPlanner {
  final MealsRepository repo;
  MealPlanner(this.repo);

  Future<Map<MealSlot, SlotPlan>> buildDailyPlan({
    required String sex, // "Male" | "Female"
    required int ageYears,
    required double heightCm,
    required double weightKg,
    required ActivityLevel activity,
    Goal? overrideGoal,
    String? dietPreferenceTag,
    Set<String> excludeAllergens = const {},
    Set<String> requireMedicalSafe = const {},
    String? seedKey,
  }) async {
    final excludeAllergensL =
        excludeAllergens.map((e) => e.toLowerCase()).toSet();
    final requireMedicalSafeL =
        requireMedicalSafe.map((e) => e.toLowerCase()).toSet();
    final selectedGoal = await UserPrefs.getGoalLabel();
    final savedGoalStr = selectedGoal ?? 'Maintain Weight';
    final goal = overrideGoal ?? TagUtils.mapGoalLabelToEnum(savedGoalStr);

    final targets = NutritionCalculator.calculate(
      sex: sex,
      ageYears: ageYears,
      heightCm: heightCm,
      weightKg: weightKg,
      activity: activity,
      goal: goal,
    );

    final all = await repo.loadMeals();
    final out = <MealSlot, SlotPlan>{};

    for (final slot in MealSlot.values) {
      final slotKey = TagUtils.mapMealSlotEnumToKey(slot);
      final slotTarget = targets.perSlot[slot];
      if (slotTarget == null) continue;

      final int slotTargetKcal = (slotTarget.kcal as num).round();

      // Base candidate pool for this slot after user filters:
      List<Meal> base = all
          .where((m) => m.slot == slotKey)
          .where((m) => _isAllowedByDiet(m, dietPreferenceTag))
          .toList();

      if (excludeAllergensL.isNotEmpty) {
        base = base.where((m) {
          final item = m.containsAllergens.toSet();
          return item.intersection(excludeAllergensL).isEmpty; // keep only safe
        }).toList();
      }

      if (requireMedicalSafeL.isNotEmpty) {
        base = base.where((m) {
          final nsf = m.notSafeFor.toSet();
          return nsf
              .intersection(requireMedicalSafeL)
              .isEmpty; // keep only safe
        }).toList();
      }

      if (base.isEmpty) continue;

      // Role-driven planning:
      final roleRules = SLOT_TEMPLATES[slot] ?? const <RoleRule>[];

      // Distribute kcal to roles by typicalKcal, then scale to slot target.
      final typicalSum = roleRules.fold<int>(
          0, (s, r) => s + (r.typicalKcal > 0 ? r.typicalKcal : 0));
      final quotas = <RoleRule, int>{};
      if (typicalSum > 0) {
        for (final r in roleRules) {
          final q = r.typicalKcal > 0
              ? (slotTarget.kcal * r.typicalKcal / typicalSum).round()
              : 0;
          quotas[r] = max(0, q);
        }
      } else {
        // No typicals? give equal slices.
        final slice = (slotTarget.kcal / max(1, roleRules.length)).round();
        for (final r in roleRules) quotas[r] = slice;
      }

      // Pick items per role
      final rand = Random(_seedForSlot(slot: slot, seedKey: seedKey));
      final usedIds = <int>{};
      final pickedItems = <ItemPick>[];
      var remainingKcal = slotTarget.kcal;

      for (final rule in roleRules) {
        // find candidates for this role
        List<Meal> roleCands =
            base.where((m) => (m.role ?? '').trim() == rule.role).toList();

        // If none and required, allow a heuristic fallback (closest mac fit)
        if (roleCands.isEmpty && rule.required) {
          roleCands = List.of(base);
        }

        // Remove already used meals with the exact same id (avoid duplicates)
        roleCands.removeWhere((m) => usedIds.contains(m.id));
        if (roleCands.isEmpty) {
          if (rule.required) {
            // Can't fulfill this role at all; skip this slot gracefully
            continue;
          } else {
            continue;
          }
        }

        // Rank role candidates with a goal-aware score for the allotted quota
        final quota = quotas[rule] ?? min(remainingKcal, 200);
        roleCands.sort((a, b) {
          final sb = _scoreForRoleFill(b, quota, goal) +
              _dietTagBonus(b, dietPreferenceTag);
          final sa = _scoreForRoleFill(a, quota, goal) +
              _dietTagBonus(a, dietPreferenceTag);
          return sb.compareTo(sa);
        });

        // Try a few from the top
        ItemPick? picked;
        for (final m in roleCands.take(5)) {
          final bounds = _mergeBounds(meal: m, rule: rule);
          final targetForThis = min(quota, remainingKcal);
          final p = _scaleMealToKcalWithBounds(
            meal: m,
            targetKcal: targetForThis,
            goal: goal,
            bounds: bounds,
          );
          if (p != null) {
            picked = p;
            break;
          }
        }

        if (picked != null) {
          pickedItems.add(picked);
          usedIds.add(picked.meal.id);
          remainingKcal = max(0, remainingKcal - picked.plannedKcal);
        } else if (rule.required) {
          // last-chance: try exact min if required, but still respect tolerance
          final m = roleCands.first;
          final bounds = _mergeBounds(meal: m, rule: rule);
          final forced = _scaleMealToExactAmount(m, bounds.min, goal);
          if (forced != null &&
              forced.plannedKcal <= remainingKcal + _KCAL_TOL) {
            pickedItems.add(forced);
            usedIds.add(forced.meal.id);
            remainingKcal = max(0, remainingKcal - forced.plannedKcal);
          }
          // else: skip if even min would overshoot too much
        }
      }

      // Optional top-up if we’re still far under target and we have flexible roles
      if (remainingKcal > 80) {
        // prefer flatbread then starch bowl, then protein_main
        final topUpRoles = ['carb_flatbread', 'starch_bowl', 'protein_main'];
        for (final roleName in topUpRoles) {
          if (remainingKcal <= 60) break;
          final rule = roleRules.firstWhere(
            (r) => r.role == roleName,
            orElse: () => RoleRule(
                role: roleName,
                min: 25,
                max: 400,
                step: 25,
                typicalKcal: 0,
                required: false),
          );
          var roleCands = base
              .where(
                  (m) => (m.role ?? '') == roleName && !usedIds.contains(m.id))
              .toList();
          if (roleCands.isEmpty) continue;
          roleCands.sort((a, b) {
            final sb = _scoreForRoleFill(b, remainingKcal, goal) +
                _dietTagBonus(b, dietPreferenceTag);
            final sa = _scoreForRoleFill(a, remainingKcal, goal) +
                _dietTagBonus(a, dietPreferenceTag);
            return sb.compareTo(sa);
          });

          for (final m in roleCands.take(4)) {
            final bounds = _mergeBounds(meal: m, rule: rule);
            final add = _scaleMealToKcalWithBounds(
              meal: m,
              targetKcal: remainingKcal,
              goal: goal,
              bounds: bounds,
            );
            if (add == null) continue;
            pickedItems.add(add);
            usedIds.add(add.meal.id);
            remainingKcal = max(0, remainingKcal - add.plannedKcal);
            break;
          }
        }
      }

      // If nothing picked by roles, fall back to best single-item (bounded)
      if (pickedItems.isEmpty) {
        final quota = slotTarget.kcal;
        final ranked = base.toList()
          ..sort((a, b) {
            final sb = _scoreForRoleFill(b, quota, goal) +
                _dietTagBonus(b, dietPreferenceTag);
            final sa = _scoreForRoleFill(a, quota, goal) +
                _dietTagBonus(a, dietPreferenceTag);
            return sb.compareTo(sa);
          });

        for (final m in ranked) {
          final bounds = _mergeBounds(meal: m, rule: null);
          final p = _scaleMealToKcalWithBounds(
            meal: m,
            targetKcal: quota,
            goal: goal,
            bounds: bounds,
          );
          if (p != null) {
            pickedItems.add(p);
            break;
          }
        }
      }

      if (pickedItems.isEmpty) continue;
      out[slot] =
          SlotPlan(slot: slot, targetKcal: slotTargetKcal, items: pickedItems);
    }

    return out;
  }

  // ---------- Scaling / bounds helpers ----------

  // Effective bounds = intersection of item bounds and role bounds
  _Bounds _mergeBounds({required Meal meal, RoleRule? rule}) {
    final unitIsMl = meal.unit == 'ml';
    final itemMin = meal.min ?? (unitIsMl ? 80.0 : 25.0);
    final itemMax = meal.max ?? (unitIsMl ? 800.0 : 600.0);
    final itemStep = meal.step;

    final roleMin = rule?.min ?? (unitIsMl ? 80.0 : 25.0);
    final roleMax = rule?.max ?? (unitIsMl ? 800.0 : 600.0);
    final roleStep = rule?.step;

    double minEff = max(itemMin, roleMin);
    double maxEff = min(itemMax, roleMax);

    // If no overlap, collapse to a single point (caller may still reject it)
    if (minEff > maxEff) {
      // choose a sensible single value so clamp() won’t throw
      minEff = maxEff;
    }

    final stepEff = _pickStep(itemStep, roleStep, unitIsMl ? 10.0 : 5.0);
    return _Bounds(min: minEff, max: maxEff, step: stepEff);
  }

  double _pickStep(double? a, double? b, double defaultStep) {
    if (a != null && a > 0 && b != null && b > 0) {
      // choose the larger to avoid violating either; keep it simple
      return max(a, b);
    }
    if (a != null && a > 0) return a;
    if (b != null && b > 0) return b;
    return defaultStep;
  }

  ItemPick? _scaleMealToKcalWithBounds({
    required Meal meal,
    required int targetKcal,
    required Goal goal,
    required _Bounds bounds,
  }) {
    if (bounds.min > bounds.max) return null;

    final kPer100 = meal.per100g.kcal <= 0 ? 1.0 : meal.per100g.kcal;

    double grams = (targetKcal * 100.0) / kPer100;

    grams = _snapToPieces(goal: goal, meal: meal, grams: grams);
    grams = _snapToStep(grams, bounds.step);

    grams = grams.clamp(bounds.min, bounds.max);
    grams = _snapToStep(grams, bounds.step);

    // If snapped amount overshoots the target by more than tolerance,
    // try stepping down to fit under the target.
    ItemPick pick = _calcPick(meal, grams);
    if (pick.plannedKcal > targetKcal + _KCAL_TOL) {
      final step =
          bounds.step > 0 ? bounds.step : (meal.unit == 'ml' ? 10.0 : 5.0);
      double g = grams;
      while (g - step >= bounds.min - 1e-6) {
        g -= step;
        final p2 = _calcPick(meal, _snapToStep(g, step));
        if (p2.plannedKcal <= targetKcal + _KCAL_TOL) {
          return p2;
        }
      }
      // couldn't fit under with steps; allow caller to decide (may skip)
      return null;
    }

    // Also reject if somehow outside bounds after snaps
    if (grams < bounds.min - 1e-6 || grams > bounds.max + 1e-6) return null;

    return pick;
  }

  ItemPick? _scaleMealToExactAmount(Meal meal, double grams, Goal goal) {
    // exact amount (already within merged bounds by caller)
    return _calcPick(meal, grams);
  }

  ItemPick _calcPick(Meal meal, double grams) {
    final f = grams / 100.0;
    final kcal = (meal.per100g.kcal * f).round();
    final p = meal.per100g.protein * f;
    final c = meal.per100g.carbs * f;
    final fat = meal.per100g.fat * f;

    return ItemPick(
      meal: meal,
      amount: ((grams * 10).round() / 10.0),
      plannedKcal: kcal,
      proteinG: ((p * 10).round() / 10.0),
      carbsG: ((c * 10).round() / 10.0),
      fatG: ((fat * 10).round() / 10.0),
    );
  }

  double _snapToPieces({
    required Goal goal,
    required Meal meal,
    required double grams,
  }) {
    final piece = meal.avgWeightG;
    if (piece == null || piece <= 0) return grams;
    final rawPieces = grams / piece;
    int pcs;
    switch (goal) {
      case Goal.loseWeight:
        pcs = rawPieces.floor();
        break;
      case Goal.maintainWeight:
        pcs = rawPieces.round();
        break;
      case Goal.gainMuscle:
      case Goal.gainWeight:
        pcs = rawPieces.ceil();
        break;
    }
    if (pcs < 1) pcs = 1;
    return pcs * piece;
  }

  double _snapToStep(double grams, double step) {
    if (step <= 0) return grams;
    return (grams / step).round() * step;
  }

  // ---------- scoring helpers ----------

  double _scoreForRoleFill(Meal m, int remainingKcal, Goal goal) {
    // goal-aware bias + closeness
    final k = m.per100g.kcal <= 0 ? 1.0 : m.per100g.kcal;
    final grams = (remainingKcal * 100.0) / k;
    final planned = k * (grams / 100.0);
    final closeness = -(planned - remainingKcal).abs();
    switch (goal) {
      case Goal.gainMuscle:
        return (m.tags.contains('high_protein') ? 80 : 0) + closeness;
      case Goal.loseWeight:
        return (m.tags.contains('low_fat') ? 50 : 0) + closeness;
      case Goal.gainWeight:
        return (m.tags.contains('energy_dense') ? 60 : 0) + closeness;
      case Goal.maintainWeight:
      default:
        return closeness;
    }
  }

  int _seedForSlot({required MealSlot slot, String? seedKey}) {
    final base = slot.index * 9973;
    if (seedKey == null || seedKey.isEmpty) return base;
    final h =
        seedKey.codeUnits.fold<int>(0, (p, c) => (p * 131 + c) & 0x7fffffff);
    return base ^ h;
  }

  bool _isAllowedByDiet(Meal m, String? pref) {
    if (pref == null || pref.isEmpty) return true;

    switch (pref) {
      case 'eggetarian':
        // Egg + veg allowed; exclude explicit nonveg
        return !m.tags.contains('nonveg');
      case 'nonveg':
        // Non-veg can eat everything
        return true;
      case 'veg':
        return m.tags.contains('veg') || m.tags.contains('vegan');
      case 'vegan':
        return m.tags.contains('vegan');
      default:
        return true;
    }
  }

  double _dietTagBonus(Meal m, String? pref) {
    if (pref == null || pref.isEmpty) return 0.0;

    switch (pref) {
      case 'eggetarian':
        if (m.tags.contains('nonveg')) return -1000.0; // hard disallow
        if (m.tags.contains('eggetarian')) return 40.0;
        if (m.tags.contains('veg') || m.tags.contains('vegan')) return 15.0;
        return 0.0;

      case 'nonveg':
        if (m.tags.contains('nonveg')) return 45.0;
        if (m.tags.contains('eggetarian')) return 25.0;
        if (m.tags.contains('veg') || m.tags.contains('vegan')) return 10.0;
        return 0.0;

      case 'veg':
        return (m.tags.contains('veg') || m.tags.contains('vegan'))
            ? 40.0
            : -1000.0;

      case 'vegan':
        return m.tags.contains('vegan') ? 50.0 : -1000.0;

      default:
        return 0.0;
    }
  }
}

class _Bounds {
  final double min;
  final double max;
  final double step;
  const _Bounds({required this.min, required this.max, required this.step});
}

// ---- Internal scoring helper used by the single-item path ----
class _ScoredPortion {
  final Meal meal;
  final double
      amountG; // grams or ml prescribed (snapped to pieces/step if any)
  final double plannedKcal;
  final double plannedProtein;
  final double plannedCarbs;
  final double plannedFat;
  final double score;

  _ScoredPortion({
    required this.meal,
    required this.amountG,
    required this.plannedKcal,
    required this.plannedProtein,
    required this.plannedCarbs,
    required this.plannedFat,
    required this.score,
  });

  factory _ScoredPortion.fromMeal({
    required Meal meal,
    required Goal goal,
    required int targetKcal,
  }) {
    final kPer100 = meal.per100g.kcal <= 0 ? 1.0 : meal.per100g.kcal;

    // 1) grams to hit target
    double grams = (targetKcal * 100.0) / kPer100;

    // 2) snap to pieces (goal-aware) then to item step
    grams = _snapAmountToPieces(meal: meal, goal: goal, rawGrams: grams);
    grams = _snapToStepStatic(meal, grams);

    // 3) clamp to per-item bounds (fallback to sensible unit defaults)
    final minBound = meal.min ?? (meal.unit == 'ml' ? 80.0 : 25.0);
    final maxBound = meal.max ?? (meal.unit == 'ml' ? 800.0 : 600.0);
    if (grams < minBound) grams = minBound;
    if (grams > maxBound) grams = maxBound;
    // re-snap to step after clamp
    grams = _snapToStepStatic(meal, grams);

    // 4) macros at final grams
    final factor = grams / 100.0;
    final kcal = meal.per100g.kcal * factor;
    final p = meal.per100g.protein * factor;
    final c = meal.per100g.carbs * factor;
    final f = meal.per100g.fat * factor;

    // 5) score (goal bonuses + closeness)
    final closeness = -((kcal - targetKcal).abs());
    double goalBonus = 0.0;
    switch (goal) {
      case Goal.gainWeight:
        if (meal.tags.contains('energy_dense')) goalBonus += 40.0;
        goalBonus += p * 4.0;
        break;
      case Goal.gainMuscle:
        if (meal.tags.contains('high_protein')) goalBonus += 80.0;
        goalBonus += p * 15.0;
        break;
      case Goal.loseWeight:
        if (meal.tags.contains('low_fat')) goalBonus += 50.0;
        goalBonus += closeness * 1.2 - kcal * 0.2 + p * 4.0;
        break;
      case Goal.maintainWeight:
      default:
        goalBonus += p * 4.0;
        break;
    }
    final universalBonus = meal.tags.contains('universal') ? 20.0 : 0.0;

    final score = closeness + goalBonus + universalBonus;

    return _ScoredPortion(
      meal: meal,
      amountG: grams,
      plannedKcal: kcal,
      plannedProtein: p,
      plannedCarbs: c,
      plannedFat: f,
      score: score,
    );
  }

  static double _snapAmountToPieces({
    required Meal meal,
    required Goal goal,
    required double rawGrams,
  }) {
    final pieceG = meal.avgWeightG;
    if (pieceG == null || pieceG <= 0) return rawGrams;

    final rawPieces = rawGrams / pieceG;
    int pcs;
    switch (goal) {
      case Goal.loseWeight:
        pcs = rawPieces.floor();
        break;
      case Goal.maintainWeight:
        pcs = rawPieces.round();
        break;
      case Goal.gainMuscle:
      case Goal.gainWeight:
        pcs = rawPieces.ceil();
        break;
    }
    if (pcs < 1) pcs = 1;
    return pcs * pieceG;
  }

  static double _snapToStepStatic(Meal meal, double grams) {
    final s = meal.step;
    if (s == null || s <= 0) return grams;
    return ((grams / s).round() * s);
  }
}

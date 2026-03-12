import "nutrition_calculator.dart";

enum Allergy {
  dairy,
  eggs,
  fish,
  shellfish,
  gluten,
  peanut,
  treenut,
  mustard,
  sesame,
  soy,
  other,
  none,
}

class TagUtils {
  static String allergyEnumToTag(Allergy a) {
    switch (a) {
      case Allergy.dairy:
        return 'dairy';
      case Allergy.eggs:
        return 'eggs';
      case Allergy.fish:
        return 'fish';
      case Allergy.shellfish:
        return 'shellfish';
      case Allergy.gluten:
        return 'gluten';
      case Allergy.peanut:
        return 'peanut';
      case Allergy.treenut:
        return 'treenut';
      case Allergy.mustard:
        return 'mustard';
      case Allergy.sesame:
        return 'sesame';
      case Allergy.soy:
        return 'soy';
      case Allergy.other:
        return 'other';
      case Allergy.none:
        return 'none';
    }
  }

  static Allergy allergyLabelToEnum(String label) {
    switch (label) {
      case 'Dairy':
        return Allergy.dairy;
      case 'Eggs':
        return Allergy.eggs;
      case 'Fish':
        return Allergy.fish;
      case 'Shellfish':
        return Allergy.shellfish;
      case 'Gluten (Wheat)':
        return Allergy.gluten;
      case 'Peanuts':
        return Allergy.peanut;
      case 'Tree Nuts':
        return Allergy.treenut;
      case 'Mustard seeds':
        return Allergy.mustard;
      case 'Sesame (Til)':
        return Allergy.sesame;
      case 'Soy':
        return Allergy.soy;
      case 'Other':
        return Allergy.other;
      case 'I don’t have any':
        return Allergy.none;
      default:
        return Allergy.other;
    }
  }

  static String normalizeAllergen(String s) {
    final x = s.trim().toLowerCase();

    // explicit maps first
    if (x.contains("i don't have any") || x.contains('none')) return 'none';
    if (x.contains('gluten') || x.contains('wheat')) return 'gluten';
    if ((x.contains('tree') && x.contains('nut')) || x.contains('tree-nut'))
      return 'treenut';
    if (x.contains('peanut') || x.contains('groundnut')) return 'peanut';
    if (x.contains('mustard')) return 'mustard';
    if (x.contains('sesame') || x.contains('til')) return 'sesame';
    if (x.contains('egg')) return 'eggs';
    if (x.contains('dairy') || x.contains('milk') || x.contains('lactose'))
      return 'dairy';
    if (x.contains('shellfish') || x.contains('crustacean')) return 'shellfish';
    if (x.contains('soy') || x.contains('soya')) return 'soy';

    // fallback: strip known suffix noise and normalize
    return x.replaceAll(' (wheat)', '').replaceAll(' ', '_');
  }

  static String mapPreference(String label) {
    switch (label) {
      case 'Vegetarian':
        return 'veg';
      case 'Non-Vegetarian':
        return 'nonveg';
      case 'Eggetarian':
        return 'eggetarian';
      case 'Vegan':
        return 'vegan';
      default:
        return 'veg';
    }
  }

  static String mapGoalLabelToTag(String label) {
    switch (label) {
      case 'Lose Weight':
        return 'weight_loss';
      case 'Gain Weight':
        return 'weight_gain';
      case 'Gain Muscle':
        return 'muscle_gain';
      case 'Maintain Weight':
      default:
        return 'maintain';
    }
  }

  static Goal mapGoalLabelToEnum(String label) {
    switch (label) {
      case 'Gain Weight':
        return Goal.gainWeight;
      case 'Gain Muscle':
        return Goal.gainMuscle;
      case 'Lose Weight':
        return Goal.loseWeight;
      case 'Maintain Weight':
      default:
        return Goal.maintainWeight;
    }
  }

  static String mapGoalEnumToTag(Goal g) {
    switch (g) {
      case Goal.gainWeight:
        return 'weight_gain';
      case Goal.gainMuscle:
        return 'muscle_gain';
      case Goal.loseWeight:
        return 'weight_loss';
      case Goal.maintainWeight:
        return 'maintain';
    }
  }

  static String mapActivityEnumToCode(ActivityLevel a) {
    switch (a) {
      case ActivityLevel.sedentary:
        return 'sedentary';
      case ActivityLevel.light:
        return 'light';
      case ActivityLevel.moderate:
        return 'moderate';
      case ActivityLevel.veryActive:
        return 'veryActive';
    }
  }

  static ActivityLevel mapActivityCodeToEnum(String? code) {
    switch (code) {
      case 'light':
        return ActivityLevel.light;
      case 'moderate':
        return ActivityLevel.moderate;
      case 'veryActive':
        return ActivityLevel.veryActive;
      case 'sedentary':
      default:
        return ActivityLevel.sedentary;
    }
  }

  static String mapMealSlotEnumToKey(MealSlot s) {
    switch (s) {
      case MealSlot.earlyMorning:
        return 'early_morning';
      case MealSlot.breakfast:
        return 'breakfast';
      case MealSlot.lunch:
        return 'lunch';
      case MealSlot.eveningSnacks:
        return 'snacks';
      case MealSlot.dinner:
        return 'dinner';
      case MealSlot.bedtime:
        return 'bedtime';
    }
  }

  static String mapMedicalConditions(String label) {
    switch (label) {
      case 'Diabetes':
        return 'diabetes';
      case 'Thyroid':
        return 'thyroid';
      case 'Hypertension':
        return 'hypertension';
      case 'PCOS':
        return 'pcos';
      case 'Heart Disease':
        return 'heart';
      case 'Kidney Issues':
        return 'kidney';
      case 'Liver Disease':
        return 'liver';
      case 'High Cholesterol':
        return 'high_chol';
      default:
        return '';
    }
  }
}

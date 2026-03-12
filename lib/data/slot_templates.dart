import 'package:smart_scale/core/nutrition_calculator.dart';

class RoleRule {
  final String role; // e.g. 'salad_raw', 'protein_main', 'carb_flatbread'
  final int minKcal; // soft guide per role (optional; use 0 if unused)
  final int maxKcal; // soft cap per role
  final int typicalKcal; // target when distributing
  final double min; // portion lower bound
  final double max; // portion upper bound
  final double step; // scaling step (e.g., 25g)
  final bool required; // if true, try hard to include

  const RoleRule({
    required this.role,
    this.minKcal = 0,
    this.maxKcal = 1000,
    this.typicalKcal = 0,
    required this.min,
    required this.max,
    required this.step,
    this.required = false,
  });
}

const Map<MealSlot, List<RoleRule>> SLOT_TEMPLATES = {
  MealSlot.earlyMorning: [
    RoleRule(
      role: 'light_start',
      min: 20,
      max: 80,
      step: 10,
      typicalKcal: 80,
      required: true,
    ),
    RoleRule(
      role: 'light_start_fruit',
      min: 60,
      max: 200,
      step: 20,
      typicalKcal: 80,
      required: true,
    ),
    RoleRule(
      role: 'hydration',
      min: 100,
      max: 300,
      step: 50,
      typicalKcal: 30,
      required: true,
    ),
  ],
  MealSlot.breakfast: [
    RoleRule(
        role: 'protein_main',
        min: 60,
        max: 300,
        step: 25,
        typicalKcal: 250,
        required: true),
    RoleRule(
        role: 'carb_bowl',
        min: 80,
        max: 320,
        step: 25,
        typicalKcal: 200,
        required: true),
    RoleRule(
      role: 'smoothie',
      min: 150,
      max: 300,
      step: 50,
      typicalKcal: 180,
      required: true,
    ),
  ],
  MealSlot.lunch: [
    RoleRule(
        role: 'salad_raw',
        min: 80,
        max: 200,
        step: 20,
        typicalKcal: 80,
        required: true),
    RoleRule(
        role: 'curd_dairy',
        min: 80,
        max: 200,
        step: 20,
        typicalKcal: 100,
        required: true),
    RoleRule(
        role: 'protein_main',
        min: 80,
        max: 220,
        step: 25,
        typicalKcal: 250,
        required: true),
    RoleRule(
        role: 'carb_flatbread',
        min: 40,
        max: 160,
        step: 40,
        typicalKcal: 200,
        required: false),
    RoleRule(
        role: 'starch_bowl',
        min: 100,
        max: 250,
        step: 25,
        typicalKcal: 200,
        required: false),
  ],
  MealSlot.eveningSnacks: [
    RoleRule(
        role: 'fruit_side',
        min: 100,
        max: 250,
        step: 25,
        typicalKcal: 120,
        required: true),
    RoleRule(
        role: 'protein_snack',
        min: 50,
        max: 150,
        step: 25,
        typicalKcal: 120,
        required: false),
    RoleRule(role: 'light_nibble', min: 15, max: 50, step: 5, required: false),
  ],
  MealSlot.dinner: [
    RoleRule(
        role: 'veg_side',
        min: 100,
        max: 250,
        step: 25,
        typicalKcal: 80,
        required: true),
    RoleRule(
        role: 'protein_main',
        min: 80,
        max: 220,
        step: 25,
        typicalKcal: 250,
        required: true),
    RoleRule(
        role: 'carb_flatbread',
        min: 40,
        max: 160,
        step: 40,
        typicalKcal: 160,
        required: false),
    RoleRule(
        role: 'starch_bowl',
        min: 100,
        max: 220,
        step: 25,
        typicalKcal: 160,
        required: false),
  ],
  MealSlot.bedtime: [
    RoleRule(
        role: 'sleep_drink',
        min: 50,
        max: 250,
        step: 50,
        typicalKcal: 120,
        required: false),
    RoleRule(role: 'light_nibble', min: 5, max: 40, step: 5, required: false),
  ],
};

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserPrefs {
  // Keys
  static const kName = 'name';
  static const kDietPreference = 'diet_preference';
  static const kAllergies = 'allergies';
  static const kHeightCm = 'height_cm';
  static const kWeightKg = 'weight_kg';
  static const kGoalWeightKg = 'goal_weight_kg';
  static const kAgeYears = 'age_years';
  static const kActivityLevel = 'activity_level';
  static const kSelectedGoal = 'selected_goal';
  static const kMedicalConditions = 'medical_conditions';
  static const kSex = 'sex';

  // WRITE
  static Future<void> saveName(String code) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(kName, code);
  }

  static Future<void> saveDietPreference(String code) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(kDietPreference, code);
  }

  static Future<void> saveAllergies(List<String> tags) async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList(kAllergies, tags);
  }

  static Future<void> saveMedicalConditions(List<String> tags) async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList(kMedicalConditions, tags);
    debugPrint("Medical Conditions are $tags");
  }

  static Future<void> saveAnthro(
      {required double heightCm, required double weightKg}) async {
    final p = await SharedPreferences.getInstance();
    await p.setDouble(kHeightCm, heightCm);
    await p.setDouble(kWeightKg, weightKg);

    debugPrint("Height is $heightCm, Weight is $weightKg");
  }

  static Future<void> saveGoalWeight(double weight) async {
    final p = await SharedPreferences.getInstance();
    await p.setDouble(kGoalWeightKg, weight);
    debugPrint("Goal weight is $weight");
  }

  static Future<void> saveAge(int years) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(kAgeYears, years);
    debugPrint("Age is $years");
  }

  static Future<void> saveActivity(String code) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(kActivityLevel, code);

    debugPrint("Activity is $code");
  }

  static Future<void> saveGoalLabel(String label) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(kSelectedGoal, label);
    debugPrint("Goal is $label");
  }

  static Future<void> saveSex(String label) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(kSex, label);
    debugPrint("Sex is $label");
  }

  // READ
  static Future<String?> getName() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(kName);
  }

  static Future<String?> getDietPreference() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(kDietPreference);
  }

  static Future<List<String>> getAllergies() async {
    final p = await SharedPreferences.getInstance();
    return p.getStringList(kAllergies) ?? <String>[];
  }

  static Future<double?> getHeightCm() async {
    final p = await SharedPreferences.getInstance();
    return p.getDouble(kHeightCm);
  }

  static Future<double?> getWeightKg() async {
    final p = await SharedPreferences.getInstance();
    return p.getDouble(kWeightKg);
  }

  static Future<int?> getAgeYears() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(kAgeYears);
  }

  static Future<String?> getActivity() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(kActivityLevel);
  }

  static Future<String?> getGoalLabel() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(kSelectedGoal);
  }

  static Future<String?> getSex() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(kSex);
  }

  static Future<List<String>> getMedicalConditions() async {
    final p = await SharedPreferences.getInstance();
    return p.getStringList(kMedicalConditions) ?? <String>[];
  }
}

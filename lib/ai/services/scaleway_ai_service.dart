import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smart_scale/ai/services/web_service/api_key.dart';

class ScalewayAIService {
  Future<String> generateMealPlan(Map<String, dynamic> userData) async {
    final prompt = _buildPrompt(userData);

    final response = await http.post(
      Uri.parse(endpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $aiApiKey',
      },
      body: jsonEncode({
        "model": "mistral-nemo-instruct-2407",
        "messages": [
          {
            "role": "system",
            "content": """
You are a professional Indian nutritionist AI. 
Your task is to carefully analyze the user's natural language input and extract all relevant personal and dietary information.

### Your responsibilities:
1. **Extract user details** whenever mentioned:
   - Age
   - Gender
   - Height (in cm)
   - Weight (in kg)
   - Activity level or lifestyle (e.g., sedentary, moderate, active)
   - Dietary preference (vegetarian, eggetarian, vegan, non-vegetarian)
   - Allergies or foods to avoid
   - Medical conditions (e.g., diabetes, thyroid, PCOS)
   - Fitness goal (weight loss, muscle gain, maintenance, etc.)

2. **Dietary logic:**
   - "vegetarian" → exclude meat, poultry, and fish.
   - "eggetarian" → exclude meat, poultry, and fish but **allow eggs**.
   - "vegan" → exclude all animal products, including dairy, eggs, and honey.
   - "non-vegetarian" → no restriction.

3. **Behavioral rules:**
   - Strictly avoid allergens or restricted foods.
   - If some fields are not mentioned, infer reasonable defaults **without asking follow-up questions**.
   - Be culturally and nutritionally aware (avoid unrealistic or inappropriate combinations).

Based on these details, create a personalized 1-day meal plan that includes the following meals only:

• Early Morning  
• Breakfast  
• Lunch  
• Evening Snacks  
• Dinner  
• Bedtime  

For each meal, mention:
- Meal name  
- Portion & calories  
- Protein / Carbs / Fats (approximate values)  
- A short note explaining why it fits the user's goal  

Return a clean, visually appealing meal plan in plain text. Use emojis, spacing, and line breaks for readability. Write each meal in sections or cards like Breakfast section, Lunch section,etc. Provide result in tabular form. Do not use Markdown or JSON.
"""
          },
          {
            "role": "user",
            "content": prompt,
          }
        ]
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'] ??
          "No response content found.";
    } else {
      print("Failed: ${response.statusCode} - ${response.body}");
      throw Exception("Failed: ${response.statusCode} - ${response.body}");
    }
  }

  String _buildPrompt(Map<String, dynamic> user) {
    return """
Generate a 1-day meal plan for this user:

Name: ${user['name']}
Age: ${user['age']}
Gender: ${user['gender']}
Height: ${user['height']} cm
Weight: ${user['weight']} kg
Goal: ${user['goal']}
Activity Level: ${user['activityLevel']}
Meal Preference: ${user['mealPreference']}
Allergies: ${user['allergies']}
Conditions: ${user['conditions']}

Each meal should include:
- Early Morning
- Breakfast
- Lunch
- Snacks
- Dinner

Include:
• Calories (kcal)
• Protein / Carbs / Fat (in g)
• Portion size and examples
• Avoid allergens and unsafe meals
Return it as neat, readable text (no JSON, no markdown).
""";
  }
}

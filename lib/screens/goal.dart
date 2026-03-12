import 'package:flutter/material.dart';
import 'package:smart_scale/core/user_prefs.dart';

import 'health_habits.dart';

class Goal extends StatefulWidget {
  const Goal({super.key});

  @override
  State<Goal> createState() => _GoalState();
}

class _GoalState extends State<Goal> {
  int selectedIndices = 0;

  String? _name;

  Map<String, bool> goals = {
    "Lose Weight": false,
    "Maintain Weight": false,
    "Gain Weight": false,
    "Gain Muscle": false,
    "Plan Meals": false,
    "Manage Stress": false,
    "Stay Active": false,
  };

  int get currentlySelected => goals.values.where((v) => v).length;

  @override
  void initState() {
    super.initState();
    _loadName();
  }

  Future<void> _loadName() async {
    final savedName = await UserPrefs.getName();
    setState(() {
      _name = savedName;
    });
  }

  // Future<void> _saveGoal() async {
  //   final prefCode = TagUtils.mapGoalLabelToTag(goals.entries
  //       .firstWhere((e) => e.value, orElse: () => const MapEntry("None", false))
  //       .key);
  //   await UserPrefs.saveGoalLabel(prefCode);
  // }

  Future<void> _saveGoal() async {
    final selectedLabel = goals.entries
        .firstWhere((e) => e.value, orElse: () => const MapEntry("None", false))
        .key;
    await UserPrefs.saveGoalLabel(selectedLabel);
  }

  void _showError() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.grey[800],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding:
              const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min, // shrink to content
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Error",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Please select at least one response to continue.",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Go Back",
                    style: TextStyle(
                        color: Colors.blue, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color(0xFF1A1C23),
        body: SafeArea(
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Goals",
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
                              color: index == 1
                                  ? const Color(0xFF37c47e)
                                  : Colors.grey[700],
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 18),

                    // Question
                    Text(
                      "Hey, $_name. 👋 Let's start with your goals.",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),

                    const Text(
                      "Select up to 3 that are important to you.",
                      style: TextStyle(fontSize: 12, color: Colors.white60),
                    ),

                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.only(
                            bottom: 80), // space for bottom bar
                        itemCount: goals.keys.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final goal = goals.keys.elementAt(index);
                          final isSelected = goals[goal] ?? false;

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                goals.updateAll((_, __) => false);
                                goals[goal] = !isSelected;
                              });
                            },
                            child: Card(
                              margin: EdgeInsets.zero,
                              color: const Color(0xFF252733),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(
                                  color: isSelected
                                      ? Colors.blue
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 0, vertical: 4),
                                child: IgnorePointer(
                                  child: CheckboxListTile(
                                    // contentPadding:
                                    //     EdgeInsets.symmetric(horizontal: 0),
                                    controlAffinity:
                                        ListTileControlAffinity.leading,
                                    title: Text(
                                      goal,
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 16),
                                    ),
                                    value: isSelected,
                                    activeColor: Colors.blue,
                                    onChanged: (_) {},
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  color: const Color(0xFF151724),
                  padding: const EdgeInsets.all(15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.blue.withOpacity(0.2),
                        radius: 25,
                        child: IconButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.arrow_back_outlined,
                              color: Color(0xFF4f9bff)),
                        ),
                      ),
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.75,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4f9bff),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          onPressed: () async {
                            if (currentlySelected != 0) {
                              await _saveGoal();

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => HealthHabits()),
                              );
                            } else {
                              _showError();
                            }
                          },
                          child: const Text(
                            "Next",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ));
  }
}

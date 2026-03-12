import 'package:flutter/material.dart';
import 'package:smart_scale/core/user_prefs.dart';

import '../core/tag_utils.dart';
import 'basic_details.dart';

class MedicalCondition extends StatefulWidget {
  const MedicalCondition({super.key});

  @override
  State<MedicalCondition> createState() => _MedicalConditionState();
}

class _MedicalConditionState extends State<MedicalCondition> {
  final Map<String, bool> conditions = {
    "Diabetes": false,
    "Thyroid": false,
    "Hypertension": false,
    "PCOS": false,
    "Heart Disease": false,
    "Kidney Issues": false,
    "Liver Disease": false,
    "High Cholesterol": false,
    "Other": false,
    "None": false,
  };

  int get currentlySelected => conditions.values.where((v) => v).length;

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
                "You've selected the max number of responses. To change, deselect a previous response.",
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

  Future<void> _saveMedicalConditions() async {
    final selectedTags = conditions.entries
        .where((e) => e.value)
        .map((e) => TagUtils.mapMedicalConditions(e.key))
        .where((tag) => tag.isNotEmpty)
        .toList();

    await UserPrefs.saveMedicalConditions(selectedTags);
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
                      "You",
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
                              color: index == 6
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
                    const Text(
                      "Do you have any medical conditions?",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),

                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.only(
                            bottom: 80), // space for bottom bar
                        itemCount: conditions.keys.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final condition = conditions.keys.elementAt(index);
                          final isSelected = conditions[condition] ?? false;

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                if (condition == "None") {
                                  if (!isSelected) {
                                    conditions.updateAll((_, __) => false);
                                    conditions["None"] = true;
                                  } else {
                                    conditions["None"] = false;
                                  }
                                  return;
                                }
                                if (conditions["None"] == true) {
                                  conditions["None"] = false;
                                }
                                if (isSelected) {
                                  conditions[condition] = false;
                                } else {
                                  if (currentlySelected < 3) {
                                    conditions[condition] = true;
                                  } else {
                                    _showError();
                                  }
                                }
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
                                      condition,
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
                            if (currentlySelected == 0) {
                              setState(() {
                                conditions["None"] = true;
                              });
                            }
                            await _saveMedicalConditions();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => BasicDetails()),
                            );
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

import 'package:dart_openai/dart_openai.dart';
import 'package:flutter/material.dart';
import 'package:smart_scale/ai/services/web_service/api_key.dart';
import 'package:smart_scale/screens/name.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  OpenAI.baseUrl = baseUrl;
  OpenAI.apiKey = aiApiKey;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Color(0xFF1b1d29),
        appBar: AppBar(
          backgroundColor: Color(0xFF1b1d29),
          title: const Text(
            'Diet Plan',
            style: TextStyle(color: Colors.white),
          ),
          centerTitle: true,
        ),
        body: const DietPlan(),
      ),
    );
  }
}

class DietPlan extends StatefulWidget {
  const DietPlan({super.key});

  @override
  State<DietPlan> createState() => _DietPlanState();
}

class _DietPlanState extends State<DietPlan> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          child: Text(
            "Welcome! Let’s find the perfect diet plan for you.",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(
          height: 50,
        ),
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.95,
          child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                    context, MaterialPageRoute(builder: (context) => Name()));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF4f9bff),
              ),
              child: Text(
                "Start",
                style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 15),
              )),
        ),
      ]),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:smart_scale/smart_scale/intro.dart';
//
// void main() {
//   runApp(const MyApp());
// }
//
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       home: const IntroScreen(),
//     );
//   }
// }

import 'package:flutter/material.dart';

import 'screens/start_screen.dart';
import 'screens/tri_fusion_input_screen.dart';
import 'screens/tri_result_happy_screen.dart';
import 'screens/tri_result_sad_screen.dart';

import 'screens/art_theraphy_screen_01.dart';
import 'screens/art_theraphy_screen_02.dart';
import 'screens/art_theraphy_screen_03.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Suwamanasa",
      debugShowCheckedModeBanner: false,
      home: const StartScreen(),
      routes: {
        "/tri_fusion": (_) => const TriFusionInputScreen(),
        "/tri_result_happy": (_) => const TriResultHappyScreen(),
        "/tri_result_sad": (_) => const TriResultSadScreen(),

        "/art_theraphy_screen_01": (_) => const ArtTherapyStep1Screen(),
        "/art_theraphy_screen_02": (_) => const ArtTherapyStep2Screen(),
        "/art_theraphy_screen_03": (_) => const ArtTherapyStep3Screen(),

        // placeholders if you don’t have these yet:
        "/therapy_option_2": (_) => const _PlaceholderScreen(title: "Therapy Option 2"),
        "/therapy_option_3": (_) => const _PlaceholderScreen(title: "Therapy Option 3"),
      },
    );
  }
}

class _PlaceholderScreen extends StatelessWidget {
  final String title;
  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text("$title screen not added yet.")),
    );
  }
}

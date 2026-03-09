import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/start_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'සුව මනස - Suwa Manasa',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF22C55E)),
        useMaterial3: true,
        textTheme: GoogleFonts.notoSansSinhalaTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      home: const StartScreen(),
    );
  }
}

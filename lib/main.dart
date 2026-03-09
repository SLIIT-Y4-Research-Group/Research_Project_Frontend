import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens/start_screen.dart';
import 'screens/welcome_screen.dart';

// therapy screens
import 'screens/art_theraphy_screen_01.dart';
import 'screens/art_theraphy_screen_02.dart';
import 'screens/art_theraphy_screen_03.dart';

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
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF22C55E),
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.notoSansSinhalaTextTheme(),
      ),
      home: const StartScreen(),
      routes: {
        '/welcome': (context) => const WelcomeScreen(),
        '/art_theraphy_screen_01': (context) => const ArtTherapyStep1Screen(),
        '/art_theraphy_screen_02': (context) => const ArtTherapyStep2Screen(),
        '/art_theraphy_screen_03': (context) => const ArtTherapyStep3Screen(),
      },
    );
  }
}
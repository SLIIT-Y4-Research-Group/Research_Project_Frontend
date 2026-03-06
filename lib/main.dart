import 'package:flutter/material.dart';
import 'screens/start_screen.dart';
import 'screens/welcome_screen.dart';

// import therapy screens
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
      title: 'Suwa Manasa',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),

      // first screen
      home: const StartScreen(),

      // 🔹 ROUTES
      routes: {
        '/welcome': (context) => const WelcomeScreen(),

        '/art_theraphy_screen_01': (context) =>
            const ArtTherapyStep1Screen(),

        '/art_theraphy_screen_02': (context) =>
            const ArtTherapyStep2Screen(),

        '/art_theraphy_screen_03': (context) =>
            const ArtTherapyStep3Screen(),
      },
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return const WelcomeScreen();
  }
}
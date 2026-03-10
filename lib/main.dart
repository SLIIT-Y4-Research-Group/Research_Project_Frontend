import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Screens
import 'package:google_fonts/google_fonts.dart';

import 'screens/start_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/story/home_screen.dart';
import 'screens/story/mood_input_screen.dart';
import 'screens/story/history_screen.dart';
import 'screens/story/story_display_screen.dart';

// Services
import 'services/story/api_service.dart';
import 'services/story/ai_story_service.dart';

// Theme
import 'core/story/theme.dart';

// Models
import 'models/story/story_model.dart';

// therapy screens
import 'screens/art_theraphy_screen_01.dart';
import 'screens/art_theraphy_screen_02.dart';
import 'screens/art_theraphy_screen_03.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        Provider(create: (_) => ApiService()),
        Provider(create: (_) => AIStoryService()),
      ],
      child: const MyApp(),
    ),
  );
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
        textTheme: GoogleFonts.notoSansSinhalaTextTheme(),
      ),
      home: const StartScreen(),
      routes: {
        '/welcome': (context) => const WelcomeScreen(),
        '/art_theraphy_screen_01': (context) => const ArtTherapyStep1Screen(),
        '/art_theraphy_screen_02': (context) => const ArtTherapyStep2Screen(),
        '/art_theraphy_screen_03': (context) => const ArtTherapyStep3Screen(),

        // Story Screens
        '/story-home': (context) => const HomeScreen(),
        '/history': (context) => const HistoryScreen(),

        '/mood-input': (context) => MoodInputScreen(
          initialMood: null,
          onGenerateStory: (moodProfile) async {
            final aiService = Provider.of<AIStoryService>(
              context,
              listen: false,
            );

            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) =>
                  const Center(child: CircularProgressIndicator()),
            );

            try {
              final response = await aiService.generateStory(
                mood: moodProfile.mood,
                weather: moodProfile.weather,
                character: moodProfile.character,
                starterSentence: moodProfile.starterSentence,
                maxLength: 300,
              );

              Navigator.pop(context);

              if (response.success && response.data != null) {
                final storyContent = response.data!['story'] ?? '';
                final metadata = response.data!['metadata'] ?? {};

                final generatedStory = Story(
                  id: metadata['id']?.toString() ?? '0',
                  userId: metadata['user_id']?.toString() ?? 'unknown',
                  title: metadata['title']?.toString() ?? 'AI නිර්මාණය කළ කථාව',
                  content: storyContent,
                  moodProfile: moodProfile,
                  tags: List<String>.from(metadata['tags'] ?? ['ai-generated']),
                  isPublic: metadata['is_public'] ?? false,
                  likeCount: metadata['like_count'] ?? 0,
                  viewCount: metadata['view_count'] ?? 0,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                );

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StoryDisplayScreen(
                      story: generatedStory,
                      isNewStory: true,
                    ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('කථාව නිර්මාණය නොකෙරිණි. නැවත උත්සාහ කරන්න.'),
                  ),
                );
              }
            } catch (e) {
              Navigator.pop(context);

              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('දෝෂයක් ඇතිවිය: $e')));
            }
          },
        ),
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Screens
import 'screens/home_screen.dart';
import 'screens/mood_input_screen.dart';
import 'screens/history_screen.dart';
import 'screens/story_display_screen.dart';
import 'screens/complete_example.dart'; // Optional: for testing
import 'screens/story_generation_screen.dart';
// Services
import 'services/api_service.dart';
import 'services/ai_story_service.dart';

// Theme
import 'core/theme.dart';

import 'models/story_model.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        Provider(create: (_) => ApiService()),
        Provider(create: (_) => AIStoryService()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'සුව මනස',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
      // In main.dart, update the '/mood-input' route:
      routes: {
        '/home': (context) => HomeScreen(),
        '/mood-input': (context) => MoodInputScreen(
  onGenerateStory: (moodProfile) async {
    final aiService = Provider.of<AIStoryService>(context, listen: false);

    // Show a loading indicator while generating
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Generate story from mood profile
      final response = await aiService.generateStory(
        mood: moodProfile.mood,
        weather: moodProfile.weather,
        character: moodProfile.character,
        starterSentence: moodProfile.starterSentence,
        maxLength: 300,
      );

      // Close the loading dialog
      Navigator.pop(context);

      if (response.success && response.data != null) {
        // Convert API response into your Story model
        final storyContent = response.data!['story'] ?? '';
        final metadata = response.data!['metadata'] ?? {};

        final generatedStory = Story(
  id: metadata['id']?.toString() ?? '0',
  userId: metadata['user_id']?.toString() ?? 'unknown', // required
  title: metadata['title']?.toString() ?? 'AI නිර්මාණය කළ කථාව',
  content: storyContent,
  moodProfile: moodProfile,
  tags: List<String>.from(metadata['tags'] ?? ['ai-generated']),
  isPublic: metadata['is_public'] ?? false,
  likeCount: metadata['like_count'] ?? 0,
  viewCount: metadata['view_count'] ?? 0,
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),   // required, can default to now
);



        // Navigate to StoryDisplayScreen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => StoryDisplayScreen(story: generatedStory, isNewStory: true),
          ),
        );
      } else {
        // Handle AI failure
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('කථාව නිර්මාණය නොකෙරිණි. නැවත උත්සාහ කරන්න.')),
        );
      }
    } catch (e) {
      Navigator.pop(context); // Ensure loading dialog is closed
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('දෝෂයක් ඇතිවිය: $e')),
      );
    }
  },
  initialMood: null,
),

        '/history': (context) => HistoryScreen(),
        '/example': (context) => CompleteExampleScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/story') {
          final story = settings.arguments;
          return MaterialPageRoute(
            builder: (context) => StoryDisplayScreen(story: story as Story),
          );
        }
        return null;
      },
    );
  }
}

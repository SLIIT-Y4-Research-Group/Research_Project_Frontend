import 'package:flutter/material.dart';
import '../../models/story/mood_model.dart';
import '../../services/story/ai_story_service.dart';
import 'story_display_screen.dart';
import '../../models/story/story_model.dart';

class SimpleGenerationScreen extends StatefulWidget {
  final MoodProfile moodProfile;

  const SimpleGenerationScreen({Key? key, required this.moodProfile})
    : super(key: key);

  @override
  _SimpleGenerationScreenState createState() => _SimpleGenerationScreenState();
}

class _SimpleGenerationScreenState extends State<SimpleGenerationScreen> {
  @override
  void initState() {
    super.initState();
    print('[DEBUG] SimpleGenerationScreen init with: ${widget.moodProfile}');
    _startGeneration();
  }

  Future<void> _startGeneration() async {
    print('[DEBUG] Starting story generation...');

    try {
      final aiService = AIStoryService();
      final response = await aiService.generateStory(
        mood: widget.moodProfile.mood,
        weather: widget.moodProfile.weather,
        character: widget.moodProfile.character,
        starterSentence: widget.moodProfile.starterSentence,
        maxLength: 200,
      );

      print('[DEBUG] Generation response: ${response.success}');

      if (!mounted) return;

      if (!response.success) {
        _showError(response.message ?? 'Generation failed');
        return;
      }

      final storyData = response.data!;
      print('[DEBUG] Story data received: $storyData');

      // Handle different response formats
      String storyContent = 'කථාව නිර්මාණය කරන ලදී';
      if (storyData['story'] is String) {
        storyContent = storyData['story'];
      } else if (storyData['content'] is String) {
        storyContent = storyData['content'];
      } else if (storyData is Map && storyData.containsKey('story')) {
        storyContent = storyData['story'].toString();
      }

      final story = Story(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        userId: 'demo-user',
        title: _getStoryTitle(),
        content: storyContent,
        moodProfile: widget.moodProfile,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        viewCount: 0,
        likeCount: 0,
        // readingTime: _calculateReadingTime(storyContent),
        isPublic: false,
        tags: [
          'ai-generated',
          widget.moodProfile.mood,
          widget.moodProfile.character,
        ],
      );

      print('[DEBUG] Story created, navigating to display...');

      // Navigate to story display
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              StoryDisplayScreen(story: story, isNewStory: true),
        ),
      );
    } catch (e) {
      print('[ERROR] Generation error: $e');
      if (mounted) {
        _showError('දෝෂයක් ඇතිවිය: $e');
      }
    }
  }

  String _getStoryTitle() {
    final characterNames = {
      'hare': 'කුරුල්ලා',
      'lion': 'සිංහයා',
      'elephant': 'අලියා',
    };

    final moodNames = {
      'sad': 'දුක් සහගත',
      'happy': 'සතුටු',
      'calm': 'සන්සුන්',
      'anxious': 'කලබල',
      'angry': 'කෝපවත්',
      'confused': 'ව්‍යාකූල',
      'empty': 'හිස්',
      'hopeful': 'බලාපොරොත්තු',
    };

    return '${characterNames[widget.moodProfile.character]}ගේ ${moodNames[widget.moodProfile.mood]} ගමන';
  }

  String _calculateReadingTime(String content) {
    final wordCount = content.split(' ').length;
    final minutes = (wordCount / 200).ceil();
    return '$minutes ${minutes == 1 ? 'මිනිත්තුව' : 'මිනිත්තු'} කියවීම';
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('දෝෂයක්'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('හරි'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close error
              _startGeneration(); // Retry
            },
            child: Text('නැවත උත්සාහ කරන්න'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('කථාව නිර්මාණය වෙමින්...'),
        backgroundColor: Color.fromRGBO(113, 212, 131, 1.0), // optional green
      ),
      body: Stack(
        children: [
          // Background image
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(
                  'images/storyload.jpg',
                ), // put your image path here
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Centered loading content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Color.fromRGBO(113, 212, 131, 1.0),
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'කථාව නිර්මාණය වෙමින්...',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'කරුණාකර රැඳී සිටින්න. මෙය තත්පර කිහිපයක් ගතවනු ඇත.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

}

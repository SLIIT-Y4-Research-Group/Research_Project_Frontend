import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/ai_story_service.dart';
import '../models/mood_model.dart';
import '../models/story_model.dart';

class FullIntegrationExample extends StatefulWidget {
  @override
  _FullIntegrationExampleState createState() => _FullIntegrationExampleState();
}

class _FullIntegrationExampleState extends State<FullIntegrationExample> {
  final ApiService _apiService = ApiService();
  final AIStoryService _aiService = AIStoryService();
  List<Story> _stories = [];
  bool _isGenerating = false;
  String _generatedStory = '';
  
  Future<void> _generateAndSaveStory() async {
    setState(() { _isGenerating = true; });
    
    // 1. Create mood profile
    final moodProfile = MoodProfile(
      mood: 'happy',
      weather: 'sunny',
      character: 'hare',
      starterSentence: 'අද මට හිතෙනවා සතුටක් තියෙනවා කියලා',
    );
    
    // 2. Generate story using AI
    final aiResponse = await _aiService.generateStory(
      mood: moodProfile.mood,
      weather: moodProfile.weather,
      character: moodProfile.character,
      starterSentence: moodProfile.starterSentence,
      maxLength: 200,
    );
    
    if (aiResponse.success) {
      final storyData = aiResponse.data!;
      setState(() { _generatedStory = storyData['content']; });
      
      // 3. Save to backend
      final story = Story(
        userId: 'test_user_123',
        title: 'AI Generated Story',
        content: storyData['content'],
        moodProfile: moodProfile,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        tags: ['ai-generated', 'test'],
      );
      
      final saveResponse = await _apiService.createStory(story);
      
      if (saveResponse.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Story saved successfully!')),
        );
        
        // 4. Refresh stories list
        await _loadStories();
      }
    }
    
    setState(() { _isGenerating = false; });
  }
  
  Future<void> _loadStories() async {
    final response = await _apiService.getPublicStories();
    if (response.success) {
      setState(() { _stories = response.data!; });
    }
  }
  
  @override
  void initState() {
    super.initState();
    _loadStories();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Integration Example')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _isGenerating ? null : _generateAndSaveStory,
              child: _isGenerating 
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(width: 10),
                      Text('Generating...'),
                    ],
                  )
                : Text('Generate & Save Story'),
            ),
            
            SizedBox(height: 20),
            
            if (_generatedStory.isNotEmpty) ...[
              Text('Generated Story:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_generatedStory),
              ),
              SizedBox(height: 20),
            ],
            
            Text('Saved Stories (${_stories.length}):', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            
            Expanded(
              child: ListView.builder(
                itemCount: _stories.length,
                itemBuilder: (context, index) {
                  final story = _stories[index];
                  return Card(
                    child: ListTile(
                      title: Text(story.title),
                      subtitle: Text(story.preview),
                      trailing: Text(story.moodProfile.moodSinhala),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
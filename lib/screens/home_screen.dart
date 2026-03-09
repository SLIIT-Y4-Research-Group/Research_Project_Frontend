import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/ai_story_service.dart';
import 'mood_input_screen.dart';
import 'history_screen.dart';
import 'story_display_screen.dart';
import '../models/mood_model.dart';
import 'story_generation_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);
  
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  final AIStoryService _aiService = AIStoryService();
  bool _isLoading = true;
  bool _serverConnected = false;
  bool _aiAvailable = false;
  List<dynamic>? _recentStories;
  
  @override
  void initState() {
    super.initState();
    _checkServerConnection();
    _loadRecentStories();
  }
  
  Future<void> _checkServerConnection() async {
    final healthResponse = await _apiService.checkHealth();
    final aiResponse = await _aiService.checkAIService();
    
    setState(() {
      _serverConnected = healthResponse.success;
      _aiAvailable = aiResponse.success;
      _isLoading = false;
    });
  }
  
  Future<void> _loadRecentStories() async {
    final response = await _apiService.getPublicStories(limit: 3);
    if (response.success) {
      setState(() {
        _recentStories = response.data;
      });
    }
  }
  
  void _navigateToMoodInput() {
    print('[DEBUG] Navigating to MoodInputScreen');
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MoodInputScreen(
         onGenerateStory: (moodProfile) async {
  print('[DEBUG] MoodInputScreen callback triggered in HomeScreen');
  print('[DEBUG] MoodProfile: $moodProfile');

  await Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (context) => SimpleGenerationScreen(
        moodProfile: moodProfile,
      ),
    ),
  );

  return;
},
          initialMood: null,
        ),
      ),
    );
  }
  
  // Add this test method for debugging
  void _testDirectGeneration() {
    print('[TEST] Direct navigation to generation screen');
    
    final testProfile = MoodProfile(
      mood: 'happy',
      weather: 'sunny',
      character: 'hare',
      starterSentence: 'අද දවස මට ගොඩක් සතුටක්',
    );
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SimpleGenerationScreen(
          moodProfile: testProfile,
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
  centerTitle: false,
  title: Row(
    children: [
      CircleAvatar(
        radius: 22, // adjust size
        backgroundColor: Colors.transparent,
        backgroundImage: AssetImage('images/logo.png'),
      ),
      SizedBox(width: 10),
      Text(
        'සුව මනස',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
    ],
  ),
),


      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Server status card
                  // Card(
                  //   child: Padding(
                  //     padding: EdgeInsets.all(16),
                  //     child: Column(
                  //       children: [
                  //         Row(
                  //           children: [
                  //             Icon(
                  //               _serverConnected ? Icons.check_circle : Icons.error,
                  //               color: _serverConnected ? Colors.green : Colors.red,
                  //             ),
                  //             SizedBox(width: 10),
                  //             Text(
                  //               _serverConnected ? 'Backend Connected' : 'Backend Unavailable',
                  //               style: TextStyle(
                  //                 fontWeight: FontWeight.bold,
                  //                 fontSize: 16,
                  //               ),
                  //             ),
                  //           ],
                  //         ),
                  //         SizedBox(height: 10),
                  //         // Row(
                  //         //   children: [
                  //         //     Icon(
                  //         //       _aiAvailable ? Icons.psychology : Icons.psychology_outlined,
                  //         //       color: _aiAvailable ? Colors.blue : Colors.grey,
                  //         //     ),
                  //         //     SizedBox(width: 10),
                  //         //     Text(
                  //         //       _aiAvailable ? 'AI Model Ready' : 'AI Model Unavailable',
                  //         //       style: TextStyle(
                  //         //         fontSize: 14,
                  //         //         color: _aiAvailable ? Colors.blue : Colors.grey,
                  //         //       ),
                  //         //     ),
                  //         //   ],
                  //         // ),
                  //       ],
                  //     ),
                  //   ),
                  // ),
                  
                  SizedBox(height: 30),
                  
                  // Hero section
                  Column(
                    children: [
                      Icon(
                        Icons.auto_stories,
                        size: 100,
                        color: Color.fromRGBO(113, 212, 131, 1.0),
                      ),
                      SizedBox(height: 20),
                      Text(
                        'ළමා හිතකාමී ජන කතා',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color.fromRGBO(113, 212, 131, 1.0),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 10),
                      Text(
                        'ඔබේ හැඟීම් වලට ගැලපෙන ජන කතා',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 40),
                  
                  // Main Generate button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _navigateToMoodInput,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 18),
                        backgroundColor: Color.fromRGBO(113, 212, 131, 1.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 4,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add, color: Colors.white, size: 24),
                          SizedBox(width: 10),
                          Text(
                            'ජන කථාවක්',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Test button for debugging (optional - you can remove this later)
                  // SizedBox(height: 10),
                  // SizedBox(
                  //   width: double.infinity,
                  //   child: OutlinedButton(
                  //     onPressed: _testDirectGeneration,
                  //     style: OutlinedButton.styleFrom(
                  //       padding: EdgeInsets.symmetric(vertical: 12),
                  //       shape: RoundedRectangleBorder(
                  //         borderRadius: BorderRadius.circular(15),
                  //       ),
                  //       side: BorderSide(color: Colors.red),
                  //     ),
                  //     child: Row(
                  //       mainAxisAlignment: MainAxisAlignment.center,
                  //       children: [
                  //         SizedBox(width: 8),
                  //         Text(
                  //           'TEST: Direct Generation (Debug)',
                  //           style: TextStyle(
                  //             fontSize: 14,
                  //             color: Colors.red,
                  //             fontWeight: FontWeight.w500,
                  //           ),
                  //         ),
                  //       ],
                  //     ),
                  //   ),
                  // ),
                  
                  SizedBox(height: 20),
                  
                  // Recent stories section
                  if (_recentStories != null && _recentStories!.isNotEmpty) ...[
                    Text(
                      'පෙර කථා',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    SizedBox(height: 10),
                    ..._recentStories!.map((story) {
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Color.fromRGBO(113, 212, 131, 1.0),
                            child: Text('📖'),
                          ),
                          title: Text(
                            story.title,
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: Text(
                            story.preview,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => StoryDisplayScreen(story: story),
                              ),
                            );
                          },
                        ),
                      );
                    }).toList(),
                  ],
                  
                  SizedBox(height: 20),
                  
                  // Quick actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildQuickAction(
                        icon: Icons.history,
                        label: 'ඉතිහාසය',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => HistoryScreen()),
                          );
                        },
                      ),
                      _buildQuickAction(
                        icon: Icons.share,
                        label: 'බෙදාගන්න',
                        onTap: _shareApp,
                      ),
                      _buildQuickAction(
                        icon: Icons.settings,
                        label: 'සැකසුම්',
                        onTap: _openSettings,
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
  
  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 24, color: const Color.fromARGB(255, 71, 223, 119)),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
  
  void _shareApp() {
    // Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Share feature coming soon!'),
        duration: Duration(seconds: 2),
      ),
    );
  }
  
  void _openSettings() {
    // Implement settings
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Settings feature coming soon!'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
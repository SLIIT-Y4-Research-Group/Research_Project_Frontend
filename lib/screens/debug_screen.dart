import 'package:flutter/material.dart';
import '../services/ai_story_service.dart';
import '../services/api_service.dart';
import '../core/config.dart';

class DebugScreen extends StatefulWidget {
  const DebugScreen({Key? key}) : super(key: key);

  @override
  _DebugScreenState createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  final ApiService _apiService = ApiService();
  final AIStoryService _aiService = AIStoryService();

  String _status = 'Idle';
  String _responseData = '';
  bool _isTesting = false;

  Future<void> _testBackendConnection() async {
    setState(() {
      _isTesting = true;
      _status = 'Testing backend connection...';
      _responseData = '';
    });

    try {
      final response = await _apiService.checkHealth();

      setState(() {
        _status = 'Backend response: ${response.success}';
        _responseData =
            'Message: ${response.message}\n\nData: ${response.data}';
      });
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
      });
    } finally {
      setState(() {
        _isTesting = false;
      });
    }
  }

  Future<void> _testAIConnection() async {
    setState(() {
      _isTesting = true;
      _status = 'Testing AI endpoint...';
      _responseData = '';
    });

    try {
      final response = await _aiService.testAIConnection();

      setState(() {
        _status = 'AI Test: ${response.success}';
        _responseData =
            'Message: ${response.message}\n\nData: ${response.data}';
      });
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
      });
    } finally {
      setState(() {
        _isTesting = false;
      });
    }
  }

  Future<void> _testDirectAI() async {
    setState(() {
      _isTesting = true;
      _status = 'Testing direct AI generation...';
      _responseData = '';
    });

    try {
      final response = await _aiService.generateStory(
        mood: 'happy',
        weather: 'sunny',
        character: 'hare',
        starterSentence: 'අද දවස මට ගොඩක් සතුටක්',
      );

      setState(() {
        _status = 'Direct AI: ${response.success}';
        _responseData =
            'Message: ${response.message}\n\nData: ${response.data}';
      });
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
      });
    } finally {
      setState(() {
        _isTesting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Debug Screen')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Debug Information',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),

            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Endpoints:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text('Base URL: ${AppConfig.baseUrl}'),
                    Text('AI Generate: ${AppConfig.aiGenerateEndpoint}'),
                    Text('Health: ${AppConfig.healthEndpoint}'),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            if (_isTesting) Center(child: CircularProgressIndicator()),

            SizedBox(height: 20),

            Text('Status: $_status', style: TextStyle(fontSize: 16)),

            SizedBox(height: 20),

            if (_responseData.isNotEmpty)
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: SelectableText(
                    _responseData,
                    style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
              ),

            SizedBox(height: 20),

            ElevatedButton(
              onPressed: _isTesting ? null : _testBackendConnection,
              child: Text('Test Backend Connection'),
            ),

            SizedBox(height: 10),

            ElevatedButton(
              onPressed: _isTesting ? null : _testAIConnection,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: Text('Test AI Connection'),
            ),

            SizedBox(height: 10),

            ElevatedButton(
              onPressed: _isTesting ? null : _testDirectAI,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: Text('Test Direct AI Generation'),
            ),

            SizedBox(height: 20),

            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Back to Home'),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../services/story/api_service.dart';
import '../../services/story/ai_story_service.dart';

class ConnectionTestScreen extends StatefulWidget {
  @override
  _ConnectionTestScreenState createState() => _ConnectionTestScreenState();
}

class _ConnectionTestScreenState extends State<ConnectionTestScreen> {
  final ApiService _apiService = ApiService();
  final AIStoryService _aiService = AIStoryService();
  
  String _backendStatus = 'Checking...';
  String _aiStatus = 'Checking...';
  bool _isTesting = true;
  
  @override
  void initState() {
    super.initState();
    _testConnections();
  }
  
  Future<void> _testConnections() async {
    // Test backend
    final backendResponse = await _apiService.checkHealth();
    setState(() {
      _backendStatus = backendResponse.success ? '✅ Connected' : '❌ Failed';
    });
    
    // Test AI service
    final aiResponse = await _aiService.checkAIService();
    setState(() {
      _aiStatus = aiResponse.success ? '✅ Available' : '❌ Unavailable';
      _isTesting = false;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Connection Test')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wifi_find,
              size: 80,
              color: Colors.deepPurple,
            ),
            SizedBox(height: 30),
            Text(
              'Backend Connection',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              _backendStatus,
              style: TextStyle(
                fontSize: 16,
                color: _backendStatus.contains('✅') ? Colors.green : Colors.red,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'AI Service',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              _aiStatus,
              style: TextStyle(
                fontSize: 16,
                color: _aiStatus.contains('✅') ? Colors.green : Colors.red,
              ),
            ),
            SizedBox(height: 30),
            if (!_isTesting)
              ElevatedButton(
                onPressed: _testConnections,
                child: Text('Test Again'),
              ),
            if (_isTesting)
              CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import '../widgets/mood_wheel.dart';
import '../widgets/weather_picker.dart';
import '../widgets/character_picker.dart';
import '../widgets/story_starter_picker.dart';

class CompleteExampleScreen extends StatefulWidget {
  const CompleteExampleScreen({Key? key}) : super(key: key);
  
  @override
  _CompleteExampleScreenState createState() => _CompleteExampleScreenState();
}

class _CompleteExampleScreenState extends State<CompleteExampleScreen> {
  String? _selectedMood;
  String? _selectedWeather;
  String? _selectedCharacter;
  String? _selectedStarter;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Complete Example'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Mood Wheel
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: MoodWheelWidget(
                  onMoodSelected: (mood) {
                    setState(() {
                      _selectedMood = mood;
                    });
                    print('Selected mood: $mood');
                  },
                  initialMood: _selectedMood,
                ),
              ),
            ),
            
            SizedBox(height: 20),
            
            // Weather Picker
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: WeatherPicker(
                  onWeatherSelected: (weather) {
                    setState(() {
                      _selectedWeather = weather;
                    });
                    print('Selected weather: $weather');
                  },
                  initialWeather: _selectedWeather,
                  showDescriptions: true,
                ),
              ),
            ),
            
            SizedBox(height: 20),
            
            // Character Picker
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CharacterPicker(
                  onCharacterSelected: (character) {
                    setState(() {
                      _selectedCharacter = character;
                    });
                    print('Selected character: $character');
                  },
                  initialCharacter: _selectedCharacter,
                  showDescriptions: true,
                ),
              ),
            ),
            
            SizedBox(height: 20),
            
            // Story Starter Picker
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: StoryStarterPicker(
                  onStarterSelected: (starter) {
                    setState(() {
                      _selectedStarter = starter;
                    });
                    print('Selected starter: $starter');
                  },
                  initialStarter: _selectedStarter,
                  showCustomField: true,
                ),
              ),
            ),
            
            SizedBox(height: 30),
            
            // Summary Card
            if (_selectedMood != null || _selectedWeather != null || _selectedCharacter != null)
              Card(
                color: Colors.deepPurple[50],
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'තෝරාගත් අංග',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple[800],
                        ),
                      ),
                      SizedBox(height: 12),
                      if (_selectedMood != null)
                        _buildSummaryItem('මනස', _selectedMood!, Colors.blue),
                      if (_selectedWeather != null)
                        _buildSummaryItem('කාලගුණය', _selectedWeather!, Colors.green),
                      if (_selectedCharacter != null)
                        _buildSummaryItem('චරිතය', _selectedCharacter!, Colors.orange),
                      if (_selectedStarter != null)
                        _buildSummaryItem('කථා ආරම්භය', _selectedStarter!, Colors.purple),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSummaryItem(String label, String value, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          Expanded(
            child: Text(
              _getDisplayValue(value, label),
              style: TextStyle(color: Colors.grey[800]),
            ),
          ),
        ],
      ),
    );
  }
  
  String _getDisplayValue(String value, String category) {
    // Convert API values to display values
    switch (category) {
      case 'මනස':
        final moodMap = {
          'sad': 'දුක් සහගත',
          'anxious': 'කලබල',
          'empty': 'හිස්',
          'calm': 'සන්සුන්',
          'happy': 'සතුටු',
          'angry': 'කෝපවත්',
          'confused': 'ව්‍යාකූල',
          'hopeful': 'බලාපොරොත්තු',
        };
        return moodMap[value] ?? value;
        
      case 'කාලගුණය':
        final weatherMap = {
          'sunny': 'සූර්යාලෝක',
          'rainy': 'වර්ෂාව',
          'stormy': 'කුණාටුව',
          'foggy': 'මීදුම',
        };
        return weatherMap[value] ?? value;
        
      case 'චරිතය':
        final characterMap = {
          'hare': 'කුරුල්ලා',
          'lion': 'සිංහයා',
          'elephant': 'අලියා',
        };
        return characterMap[value] ?? value;
        
      default:
        return value;
    }
  }
}
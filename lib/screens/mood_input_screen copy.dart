import 'package:flutter/material.dart';
import '../models/mood_model.dart';
import '../widgets/mood_wheel.dart';
import '../widgets/weather_picker.dart'; // Note: This file contains WeatherPicker class
import '../widgets/character_picker.dart'; // Note: This file contains CharacterPicker class
import '../core/story_constants.dart';

class MoodInputScreen extends StatefulWidget {
  final Future<void> Function(MoodProfile) onGenerateStory;
  final MoodProfile? initialMood;
  
  const MoodInputScreen({
    Key? key,
    required this.onGenerateStory,
    this.initialMood,
  }) : super(key: key);
  
  @override
  _MoodInputScreenState createState() => _MoodInputScreenState();
}

class _MoodInputScreenState extends State<MoodInputScreen> {
  String? _selectedMood;
  String? _selectedWeather;
  String? _selectedCharacter;
  String? _selectedStarterSentence;
  String _selectedStoryLength = 'medium'; // Default
  bool _useGemini = true; // Default to using Gemini
  final TextEditingController _customStarterController = TextEditingController();
  bool _isCustomStarter = false;
  
  // Common story starters that match the Python backend
  final List<String> _defaultStarters = StoryConstants.commonStarters;
  
  @override
  void initState() {
    super.initState();
    if (widget.initialMood != null) {
      _selectedMood = widget.initialMood!.mood;
      _selectedWeather = widget.initialMood!.weather;
      _selectedCharacter = widget.initialMood!.character;
      _selectedStarterSentence = widget.initialMood!.starterSentence;
      _selectedStoryLength = widget.initialMood!.storyLength;
      _useGemini = widget.initialMood!.useGemini;
      
      if (_selectedStarterSentence != null && 
          !_defaultStarters.contains(_selectedStarterSentence)) {
        _customStarterController.text = _selectedStarterSentence!;
        _isCustomStarter = true;
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ඔබේ හැඟීම් ඇතුලත් කරන්න'),
        backgroundColor: Color.fromRGBO(113, 212, 131, 1.0),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Step indicator
            _buildStepIndicator(),
            SizedBox(height: 20),
            
            // Mood Wheel
            MoodWheelWidget(
              onMoodSelected: (mood) {
                setState(() {
                  _selectedMood = mood;
                });
              },
              initialMood: _selectedMood,
            ),
            
            SizedBox(height: 30),
            
            // Weather Picker - FIXED: Use WeatherPicker instead of WeatherPickerWidget
            WeatherPicker(
              onWeatherSelected: (weather) {
                setState(() {
                  _selectedWeather = weather;
                });
              },
              initialWeather: _selectedWeather,
              showDescriptions: true,
            ),
            
            SizedBox(height: 30),
            
            // Character Picker - FIXED: Use CharacterPicker instead of CharacterPickerWidget
            CharacterPicker(
              onCharacterSelected: (character) {
                setState(() {
                  _selectedCharacter = character;
                });
              },
              initialCharacter: _selectedCharacter,
              showDescriptions: true,
            ),
            
            SizedBox(height: 30),
            
            // Story Length Selection
            _buildStoryLengthSection(),
            
            SizedBox(height: 30),
            
            // Generation Method Selection
            _buildGenerationMethodSection(),
            
            SizedBox(height: 30),
            
            // Story Starter (Optional)
            _buildStoryStarterSection(),
            
            SizedBox(height: 40),
            
            // Generate Button
            ElevatedButton(
              onPressed: _canGenerate() ? () {
                print('[DEBUG] Generate button pressed in MoodInputScreen');
                
                final moodProfile = MoodProfile(
                  mood: _selectedMood!,
                  weather: _selectedWeather!,
                  character: _selectedCharacter!,
                  starterSentence: _selectedStarterSentence,
                  storyLength: _selectedStoryLength,
                  useGemini: _useGemini,
                );
                
                print('[DEBUG] Calling onGenerateStory callback with: $moodProfile');
                
                // Call the callback which should handle navigation
                widget.onGenerateStory(moodProfile);
              } : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromRGBO(113, 212, 131, 1.0),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
              child: Text(
                'කථාව නිර්මාණය කරන්න',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
            
            SizedBox(height: 20),
            
            // Preview Card
            if (_selectedMood != null && _selectedWeather != null && _selectedCharacter != null)
              _buildPreviewCard(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStepIndicator() {
    final steps = ['මනස', 'කාලගුණය', 'චරිතය', 'දිග', 'ක්‍රමය', 'කථාව'];
    final currentStep = _getCurrentStep();
    
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: steps.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value;
            final isActive = index <= currentStep;
            final isCompleted = index < currentStep;
            
            return Column(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: isActive ? Color.fromRGBO(113, 212, 131, 1.0) : Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: isCompleted
                        ? Icon(Icons.check, size: 16, color: Colors.white)
                        : Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: isActive ? Colors.white : Colors.grey[600],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  step,
                  style: TextStyle(
                    fontSize: 10,
                    color: isActive ? Color.fromRGBO(113, 212, 131, 1.0) : Colors.grey[600],
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
        SizedBox(height: 10),
        LinearProgressIndicator(
          value: (currentStep + 1) / steps.length,
          backgroundColor: Colors.grey[200],
          color: Color.fromRGBO(113, 212, 131, 1.0),
        ),
      ],
    );
  }
  
  int _getCurrentStep() {
    if (_selectedMood == null) return 0;
    if (_selectedWeather == null) return 1;
    if (_selectedCharacter == null) return 2;
    // After character is selected, we consider steps 3-5 as active
    return 5; // All steps after character selection are considered active
  }
  
  Widget _buildStoryLengthSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'කථාවේ දිග',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple[800],
              ),
            ),
            SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildLengthOption(
                    length: 'short',
                    sinhala: 'කෙටි',
                    description: 'වාක්‍ය 8-12',
                    icon: Icons.short_text,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildLengthOption(
                    length: 'medium',
                    sinhala: 'මධ්‍යම',
                    description: 'වාක්‍ය 12-18',
                    icon: Icons.format_align_center,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildLengthOption(
                    length: 'long',
                    sinhala: 'දිගු',
                    description: 'වාක්‍ය 18-25',
                    icon: Icons.format_align_justify,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLengthOption({
    required String length,
    required String sinhala,
    required String description,
    required IconData icon,
  }) {
    final isSelected = _selectedStoryLength == length;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedStoryLength = length;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? Colors.deepPurple[50] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.deepPurple : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        padding: EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.deepPurple : Colors.grey[600],
              size: 24,
            ),
            SizedBox(height: 8),
            Text(
              sinhala,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.deepPurple : Colors.grey[800],
              ),
            ),
            SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? Colors.deepPurple[300] : Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            if (isSelected)
              Padding(
                padding: EdgeInsets.only(top: 8),
                child: Icon(Icons.check_circle, color: Colors.deepPurple, size: 16),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildGenerationMethodSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'කථා නිර්මාණ ක්‍රමය',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple[800],
              ),
            ),
            SizedBox(height: 16),
            
            Container(
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              padding: EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[800], size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'AI (Gemini) ක්‍රමය වඩාත් ගුණාත්මක කථා නිර්මාණය කරයි. නමුත් අන්තර්ජාල සම්බන්ධතාවයක් අවශ්‍ය වේ.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildMethodOption(
                    method: true,
                    title: 'AI ක්‍රමය',
                    subtitle: 'Gemini AI',
                    description: 'උසස් තත්ත්වයේ, ස්වාභාවික කථා',
                    icon: Icons.auto_awesome,
                    color: Colors.purple,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildMethodOption(
                    method: false,
                    title: 'සාමාන්‍ය ක්‍රමය',
                    subtitle: 'Local Model',
                    description: 'වේගවත්, අන්තර්ජාලය අවශ්‍ය නොවේ',
                    icon: Icons.device_hub,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            
            if (!_useGemini)
              Padding(
                padding: EdgeInsets.only(top: 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber[200]!),
                  ),
                  padding: EdgeInsets.all(8),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber, color: Colors.amber[800], size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'සාමාන්‍ය ක්‍රමය අන්තර්ජාලය නොමැතිව වැඩ කරයි, නමුත් කථාවේ ගුණාත්මකභාවය අඩු විය හැක.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.amber[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMethodOption({
    required bool method,
    required String title,
    required String subtitle,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _useGemini == method;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _useGemini = method;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        padding: EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? color : Colors.grey[600],
              size: 32,
            ),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? color : Colors.grey[800],
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? color.withOpacity(0.7) : Colors.grey[500],
              ),
            ),
            SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? color.withOpacity(0.8) : Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            if (isSelected)
              Padding(
                padding: EdgeInsets.only(top: 8),
                child: Icon(Icons.check_circle, color: color, size: 16),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStoryStarterSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'කථාව ආරම්භ කිරීමට වාක්‍ය ඛණ්ඩයක් (වැඩිදුරටත්)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.deepPurple[800],
              ),
            ),
            SizedBox(height: 12),
            
            // Default starters
            Column(
              children: _defaultStarters.map((starter) {
                final isSelected = !_isCustomStarter && _selectedStarterSentence == starter;
                
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 4),
                  color: isSelected ? Colors.deepPurple[50] : Colors.white,
                  child: ListTile(
                    title: Text(
                      starter,
                      style: TextStyle(
                        fontFamily: 'NotoSansSinhala',
                      ),
                    ),
                    trailing: isSelected ? Icon(Icons.check, color: Colors.deepPurple) : null,
                    onTap: () {
                      setState(() {
                        _selectedStarterSentence = starter;
                        _isCustomStarter = false;
                        _customStarterController.clear();
                      });
                    },
                  ),
                );
              }).toList(),
            ),
            
            SizedBox(height: 16),
            
            // Custom starter option
            ListTile(
              leading: Checkbox(
                value: _isCustomStarter,
                onChanged: (value) {
                  setState(() {
                    _isCustomStarter = value ?? false;
                    if (!_isCustomStarter) {
                      _customStarterController.clear();
                      _selectedStarterSentence = null;
                    }
                  });
                },
              ),
              title: Text('ඔබේම වාක්‍යයක් ලියන්න'),
            ),
            
            if (_isCustomStarter)
              Padding(
                padding: EdgeInsets.only(left: 16, right: 16, bottom: 8),
                child: TextField(
                  controller: _customStarterController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'ඔබේම වාක්‍ය ඛණ්ඩය ඇතුලත් කරන්න...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    contentPadding: EdgeInsets.all(12),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _selectedStarterSentence = value.isNotEmpty ? value : null;
                    });
                  },
                ),
              ),
            
            // No starter option
            ListTile(
              leading: Checkbox(
                value: _selectedStarterSentence == null && !_isCustomStarter,
                onChanged: (value) {
                  if (value ?? false) {
                    setState(() {
                      _selectedStarterSentence = null;
                      _isCustomStarter = false;
                      _customStarterController.clear();
                    });
                  }
                },
              ),
              title: Text('කිසිදු වාක්‍ය ඛණ්ඩයක් අවශ්‍ය නැත'),
            ),
            
            // Info text about traditional starters
            if (_selectedStarterSentence != null && _defaultStarters.contains(_selectedStarterSentence))
              Padding(
                padding: EdgeInsets.only(top: 12),
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.amber[800], size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'මෙය සාම්ප්‍රදායික කථා ආරම්භයකි. උත්පාදකය මෙය සම්පූර්ණ කරනු ඇත.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.amber[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPreviewCard() {
    return Card(
      color: Colors.deepPurple[50],
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'පූර්ව දර්ශනය',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple[800],
              ),
            ),
            SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildPreviewChip(
                  icon: Icons.mood,
                  label: StoryConstants.moodSinhala[_selectedMood] ?? _selectedMood!,
                  color: Colors.blue,
                ),
                _buildPreviewChip(
                  icon: Icons.cloud,
                  label: StoryConstants.weatherSinhala[_selectedWeather] ?? _selectedWeather!,
                  color: Colors.green,
                ),
                _buildPreviewChip(
                  icon: Icons.person,
                  label: StoryConstants.characterSinhala[_selectedCharacter] ?? _selectedCharacter!,
                  color: Colors.orange,
                ),
                _buildPreviewChip(
                  icon: Icons.format_size,
                  label: _getStoryLengthSinhala(),
                  color: Colors.purple,
                ),
                _buildPreviewChip(
                  icon: _useGemini ? Icons.auto_awesome : Icons.device_hub,
                  label: _useGemini ? 'AI ක්‍රමය' : 'සාමාන්‍ය ක්‍රමය',
                  color: _useGemini ? Colors.purple : Colors.blue,
                ),
              ],
            ),
            if (_selectedStarterSentence != null && _selectedStarterSentence!.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'කථා ආරම්භය:',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    SizedBox(height: 4),
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.deepPurple[100]!),
                      ),
                      child: Text(
                        _selectedStarterSentence!,
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.grey[700],
                          fontFamily: 'NotoSansSinhala',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  String _getStoryLengthSinhala() {
    switch (_selectedStoryLength) {
      case 'short':
        return 'කෙටි (8-12)';
      case 'medium':
        return 'මධ්‍යම (12-18)';
      case 'long':
        return 'දිගු (18-25)';
      default:
        return 'මධ්‍යම';
    }
  }
  
  Widget _buildPreviewChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Chip(
      backgroundColor: color.withOpacity(0.2),
      label: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      avatar: Icon(icon, size: 16, color: color),
      padding: EdgeInsets.symmetric(horizontal: 8),
    );
  }
  
  bool _canGenerate() {
    return _selectedMood != null && 
           _selectedWeather != null && 
           _selectedCharacter != null;
  }
  
  @override
  void dispose() {
    _customStarterController.dispose();
    super.dispose();
  }
}
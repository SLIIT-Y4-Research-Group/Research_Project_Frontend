import 'package:flutter/material.dart';
import '../models/mood_model.dart';
import '../widgets/mood_wheel.dart';
import '../widgets/weather_picker.dart';
import '../widgets/character_picker.dart';
import '../widgets/story_starter_picker.dart';

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
  final TextEditingController _customStarterController = TextEditingController();
  bool _isCustomStarter = false;
  
  // Default starter sentences in Sinhala
  final List<String> _defaultStarters = [
    'අද දවස මට ගොඩක් දුක් වගේ...',
    'මම කිසිම විටක කථා කරන්න අවශ්‍ය නෑ...',
    'මගේ හිත තුල ගැබ් ගැනීමක් රැඳී සිටිනවා...',
    'අද මට හිතෙනවා සැනසිල්ලක් තියෙනවා කියලා...',
    'මම අද තරමක් ව්‍යාකූලව සිටිනවා...',
    'අද මගේ හිත පිරිසිදු අහසක් වගේ...',
    'මට අද තරමක් තනියම වෙන්න ඕන වගේ...',
    'මගේ හිත තුල සතුටක් පුරවා ගියා...',
  ];
  
  @override
  void initState() {
    super.initState();
    if (widget.initialMood != null) {
      _selectedMood = widget.initialMood!.mood;
      _selectedWeather = widget.initialMood!.weather;
      _selectedCharacter = widget.initialMood!.character;
      _selectedStarterSentence = widget.initialMood!.starterSentence;
      
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
        backgroundColor: Colors.deepPurple[300],
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
            
            // Weather Picker
            WeatherPickerWidget(
              onWeatherSelected: (weather) {
                setState(() {
                  _selectedWeather = weather;
                });
              },
              initialWeather: _selectedWeather,
            ),
            
            SizedBox(height: 30),
            
            // Character Picker
            CharacterPickerWidget(
              onCharacterSelected: (character) {
                setState(() {
                  _selectedCharacter = character;
                });
              },
              initialCharacter: _selectedCharacter,
            ),
            
            SizedBox(height: 30),
            
            // Story Starter (Optional)
            _buildStoryStarterSection(),
            
            SizedBox(height: 40),
            
            // Generate Button
            // In mood_input_screen.dart, find the ElevatedButton and replace it with:

ElevatedButton(
  onPressed: _canGenerate() ? () {
    print('[DEBUG] Generate button pressed in MoodInputScreen');
    
    final moodProfile = MoodProfile(
      mood: _selectedMood!,
      weather: _selectedWeather!,
      character: _selectedCharacter!,
      starterSentence: _selectedStarterSentence,
    );
    
    print('[DEBUG] Calling onGenerateStory callback with: $moodProfile');
    
    // Call the callback which should handle navigation
    widget.onGenerateStory(moodProfile);
  } : null,
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.deepPurple,
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
    final steps = ['මනස', 'කාලගුණය', 'චරිතය', 'කථාව'];
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
                    color: isActive ? Colors.deepPurple : Colors.grey[300],
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
                    fontSize: 12,
                    color: isActive ? Colors.deepPurple : Colors.grey[600],
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
          color: Colors.deepPurple,
        ),
      ],
    );
  }
  
  int _getCurrentStep() {
    if (_selectedMood == null) return 0;
    if (_selectedWeather == null) return 1;
    if (_selectedCharacter == null) return 2;
    return 3;
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
                    title: Text(starter),
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
          ],
        ),
      ),
    );
  }
  
  Widget _buildPreviewCard() {
    final moodNames = {
      'sad': 'දුක් සහගත',
      'anxious': 'කලබල',
      'empty': 'හිස්',
      'calm': 'සන්සුන්',
      'happy': 'සතුටු',
      'angry': 'කෝපවත්',
      'confused': 'ව්‍යාකූල',
      'hopeful': 'බලාපොරොත්තු',
    };
    
    final weatherNames = {
      'sunny': 'සූර්යාලෝක',
      'rainy': 'වර්ෂාව',
      'stormy': 'කුණාටුව',
      'foggy': 'මීදුම',
    };
    
    final characterNames = {
      'hare': 'කුරුල්ලා',
      'lion': 'සිංහයා',
      'elephant': 'අලියා',
    };
    
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
            Row(
              children: [
                _buildPreviewChip(
                  icon: Icons.mood,
                  label: moodNames[_selectedMood] ?? _selectedMood!,
                  color: Colors.blue,
                ),
                SizedBox(width: 8),
                _buildPreviewChip(
                  icon: Icons.cloud,
                  label: weatherNames[_selectedWeather] ?? _selectedWeather!,
                  color: Colors.green,
                ),
                SizedBox(width: 8),
                _buildPreviewChip(
                  icon: Icons.person,
                  label: characterNames[_selectedCharacter] ?? _selectedCharacter!,
                  color: Colors.orange,
                ),
              ],
            ),
            if (_selectedStarterSentence != null && _selectedStarterSentence!.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text(
                  'කථා ආරම්භය:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            if (_selectedStarterSentence != null && _selectedStarterSentence!.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  _selectedStarterSentence!,
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey[700],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
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
  
  // In MoodInputScreen, fix the _handleGenerateStory method:

Future<void> _handleGenerateStory() async {
  print('[DEBUG] Generate button pressed');
  
  if (!_canGenerate()) {
    print('[DEBUG] Cannot generate - missing inputs');
    print('Mood: $_selectedMood, Weather: $_selectedWeather, Character: $_selectedCharacter');
    return;
  }

  final moodProfile = MoodProfile(
    mood: _selectedMood!,
    weather: _selectedWeather!,
    character: _selectedCharacter!,
    starterSentence: _selectedStarterSentence,
  );

  print('[DEBUG] Created MoodProfile: $moodProfile');
  
  try {
    print('[DEBUG] Calling onGenerateStory callback...');
    widget.onGenerateStory(moodProfile);
    print('[DEBUG] onGenerateStory completed');
  } catch (e) {
    print('[ERROR] in _handleGenerateStory: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('දෝෂයක් ඇතිවිය: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}  // THIS CLOSING BRACE WAS MISSING

// Remove the extra closing brace at the very end of the file
// The file should end with the closing braces for _CharacterPickerWidgetState class
}

  
  // @override
  // void dispose() {
  //   _customStarterController.dispose();
  //   super.dispose();
  // }

// Weather Picker Widget
class WeatherPickerWidget extends StatefulWidget {
  final Function(String) onWeatherSelected;
  final String? initialWeather;
  
  const WeatherPickerWidget({
    Key? key,
    required this.onWeatherSelected,
    this.initialWeather,
  }) : super(key: key);
  
  @override
  _WeatherPickerWidgetState createState() => _WeatherPickerWidgetState();
}

class _WeatherPickerWidgetState extends State<WeatherPickerWidget> {
  String? _selectedWeather;
  
  final Map<String, Map<String, dynamic>> _weatherData = {
    'sunny': {
      'emoji': '☀️',
      'color': Colors.orange,
      'sinhala': 'සූර්යාලෝක',
      'description': 'සාමකාමී, ප්රීතිමත්'
    },
    'rainy': {
      'emoji': '🌧️',
      'color': Colors.blue,
      'sinhala': 'වර්ෂාව',
      'description': 'දුක්ඛිත, පරාවර්තක'
    },
    'stormy': {
      'emoji': '⛈️',
      'color': Colors.indigo,
      'sinhala': 'කුණාටුව',
      'description': 'අධික ලෙස, කෝපයෙන්'
    },
    'foggy': {
      'emoji': '🌫️',
      'color': Colors.grey,
      'sinhala': 'මීදුම',
      'description': 'ව්‍යාකූල, උදාසීන'
    },
  };
  
  @override
  void initState() {
    super.initState();
    _selectedWeather = widget.initialWeather;
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ඔබගේ හිත තුළ තියෙන්නේ මොන වගේ කාලගුණයක්ද?',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple[800],
          ),
        ),
        SizedBox(height: 20),
        GridView.count(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: _weatherData.entries.map((entry) {
            final weather = entry.key;
            final data = entry.value;
            final isSelected = _selectedWeather == weather;
            
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedWeather = weather;
                });
                widget.onWeatherSelected(weather);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? data['color'].withOpacity(0.2) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? data['color'] : Colors.grey[300]!,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: data['color'].withOpacity(0.1),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    )
                  ] : [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    )
                  ],
                ),
                padding: EdgeInsets.all(12),
                child: Row(
                  children: [
                    Text(
                      data['emoji'],
                      style: TextStyle(fontSize: 28),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            data['sinhala'],
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? data['color'] : Colors.grey[800],
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            data['description'],
                            style: TextStyle(
                              fontSize: 11,
                              color: isSelected ? data['color'].withOpacity(0.8) : Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Icon(Icons.check_circle, color: data['color'], size: 20),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// Character Picker Widget
class CharacterPickerWidget extends StatefulWidget {
  final Function(String) onCharacterSelected;
  final String? initialCharacter;
  
  const CharacterPickerWidget({
    Key? key,
    required this.onCharacterSelected,
    this.initialCharacter,
  }) : super(key: key);
  
  @override
  _CharacterPickerWidgetState createState() => _CharacterPickerWidgetState();
}

class _CharacterPickerWidgetState extends State<CharacterPickerWidget> {
  String? _selectedCharacter;
  
  final Map<String, Map<String, dynamic>> _characterData = {
    'hare': {
      'sinhala': 'කුරුල්ලා',
      'description': 'කනස්සල්ලෙන් නමුත් දක්ෂයි',
      'color': Colors.brown,
    },
    'lion': {
      'sinhala': 'සිංහයා',
      'description': 'ශක්තිමත් නමුත් තනිකම',
      'color': Colors.orange,
    },
    'elephant': {
      'sinhala': 'අලියා',
      'description': 'කරුණාවන්ත නමුත් බර හදවතක් උසුලයි',
      'color': Colors.grey,
    },
  };
  
  @override
  void initState() {
    super.initState();
    _selectedCharacter = widget.initialCharacter;
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ඔබ අද හැගෙන්නේ කුමන ප්‍රධාන චරිතයක් වගේද?',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple[800],
          ),
        ),
        SizedBox(height: 20),
        ListView.separated(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: _characterData.length,
          separatorBuilder: (context, index) => SizedBox(height: 12),
          itemBuilder: (context, index) {
            final character = _characterData.keys.elementAt(index);
            final data = _characterData[character]!;
            final isSelected = _selectedCharacter == character;
            
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCharacter = character;
                });
                widget.onCharacterSelected(character);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? data['color'].withOpacity(0.1) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? data['color'] : Colors.grey[300]!,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: data['color'].withOpacity(0.1),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    )
                  ] : [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.05),
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    )
                  ],
                ),
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: data['color'].withOpacity(0.2),
                      radius: 24,
                      child: Text(
                        data['sinhala'].substring(0, 1),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: data['color'],
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['sinhala'],
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? data['color'] : Colors.grey[800],
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            data['description'],
                            style: TextStyle(
                              fontSize: 13,
                              color: isSelected ? data['color'].withOpacity(0.8) : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Icon(Icons.check_circle, color: data['color'], size: 24),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

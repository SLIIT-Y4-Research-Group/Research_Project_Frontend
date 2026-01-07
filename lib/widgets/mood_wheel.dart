import 'package:flutter/material.dart';
import '../models/mood_model.dart';

class MoodWheelWidget extends StatefulWidget {
  final Function(String) onMoodSelected;
  final String? initialMood;
  
  const MoodWheelWidget({
    Key? key,
    required this.onMoodSelected,
    this.initialMood,
  }) : super(key: key);
  
  @override
  _MoodWheelWidgetState createState() => _MoodWheelWidgetState();
}

class _MoodWheelWidgetState extends State<MoodWheelWidget> {
  String? _selectedMood;
  final Map<String, Map<String, dynamic>> _moodData = {
    'sad': {'emoji': '😢', 'color': Colors.blue, 'sinhala': 'දුක් සහගත'},
    'anxious': {'emoji': '😰', 'color': Colors.orange, 'sinhala': 'කලබල'},
    'empty': {'emoji': '😐', 'color': Colors.grey, 'sinhala': 'හිස්'},
    'calm': {'emoji': '😌', 'color': Colors.green, 'sinhala': 'සන්සුන්'},
    'happy': {'emoji': '😊', 'color': Colors.yellow, 'sinhala': 'සතුටු'},
    'angry': {'emoji': '😠', 'color': Colors.red, 'sinhala': 'කෝපවත්'},
    'confused': {'emoji': '😕', 'color': Colors.purple, 'sinhala': 'ව්‍යාකූල'},
    'hopeful': {'emoji': '🤗', 'color': Colors.lightBlue, 'sinhala': 'බලාපොරොත්තු'},
  };
  
  @override
  void initState() {
    super.initState();
    _selectedMood = widget.initialMood;
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'අද ඔබට මොන වගේ හැඟීමක්ද තියෙන්නේ?',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple[800],
          ),
        ),
        SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _moodData.entries.map((entry) {
            final mood = entry.key;
            final data = entry.value;
            final isSelected = _selectedMood == mood;
            
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedMood = mood;
                });
                widget.onMoodSelected(mood);
              },
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected 
                    ? data['color'].withOpacity(0.3)
                    : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? data['color'] : Colors.transparent,
                    width: 2,
                  ),
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: data['color'].withOpacity(0.2),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    )
                  ] : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      data['emoji'],
                      style: TextStyle(fontSize: 32),
                    ),
                    SizedBox(height: 8),
                    Text(
                      data['sinhala'],
                      style: TextStyle(
                        fontSize: 14,
                        color: isSelected ? data['color'] : Colors.grey[800],
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
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
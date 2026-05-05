import 'package:flutter/material.dart';

class WeatherPicker extends StatefulWidget {
  final Function(String) onWeatherSelected;
  final String? initialWeather;
  final bool showDescriptions;
  
  const WeatherPicker({
    Key? key,
    required this.onWeatherSelected,
    this.initialWeather,
    this.showDescriptions = true,
  }) : super(key: key);
  
  @override
  _WeatherPickerState createState() => _WeatherPickerState();
}

class _WeatherPickerState extends State<WeatherPicker> {
  String? _selectedWeather;
  
  // Weather data with Sinhala translations
  final Map<String, Map<String, dynamic>> _weatherOptions = {
    'sunny': {
      'emoji': '☀️',
      'color': Colors.orange,
      'sinhala': 'සූර්යාලෝක',
      'english': 'Sunny',
      'description': 'Peaceful, joyful',
      'fullDescription': 'සාමය සහ සතුට පිරි අහසක්',
    },
    'rainy': {
      'emoji': '🌧️',
      'color': Colors.blue,
      'sinhala': 'වර්ෂාව',
      'english': 'Rainy',
      'description': 'Sad, reflective',
      'fullDescription': 'කඳුළු වැගිරෙන සිහිනයක්',
    },
    'stormy': {
      'emoji': '⛈️',
      'color': Colors.indigo,
      'sinhala': 'කුණාටුව',
      'english': 'Stormy',
      'description': 'Overwhelmed, angry',
      'fullDescription': 'කෝපයෙන් පිරුණු අහස',
    },
    'foggy': {
      'emoji': '🌫️',
      'color': Colors.grey,
      'sinhala': 'මීදුම',
      'english': 'Foggy',
      'description': 'Confused, numb',
      'fullDescription': 'ව්‍යාකූල සිතිවිලි වලින් වැසුණු අහස',
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
        // Title
        Text(
          'ඔබගේ හිත තුළ කුමන කාලගුණයක් ද?',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple[800],
          ),
        ),
        
        SizedBox(height: 8),
        
        // Subtitle
        Text(
          'ඔබේ අභ්‍යන්තර ලෝකයට ගැලපෙන කාලගුණය තෝරන්න',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        
        SizedBox(height: 20),
        
        // Weather options grid
        GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: _weatherOptions.length,
          itemBuilder: (context, index) {
            final weatherKey = _weatherOptions.keys.elementAt(index);
            final weather = _weatherOptions[weatherKey]!;
            final isSelected = _selectedWeather == weatherKey;
            
            return _buildWeatherCard(
              weatherKey: weatherKey,
              weather: weather,
              isSelected: isSelected,
            );
          },
        ),
        
        SizedBox(height: 20),
        
        // Selected weather details
        if (_selectedWeather != null && widget.showDescriptions)
          _buildWeatherDetails(_selectedWeather!),
      ],
    );
  }
  
  Widget _buildWeatherCard({
    required String weatherKey,
    required Map<String, dynamic> weather,
    required bool isSelected,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxHeight < 150;
        final verticalGap = isCompact ? 4.0 : 8.0;
        final englishGap = isCompact ? 2.0 : 4.0;

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedWeather = weatherKey;
            });
            widget.onWeatherSelected(weatherKey);
          },
          child: Container(
            padding: EdgeInsets.symmetric(vertical: isCompact ? 8 : 12),
            decoration: BoxDecoration(
              color: isSelected ? weather['color'].withOpacity(0.1) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? weather['color'] : Colors.grey[200]!,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(isSelected ? 0.1 : 0.05),
                  blurRadius: isSelected ? 8 : 4,
                  offset: Offset(0, isSelected ? 4 : 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  weather['emoji'],
                  style: TextStyle(fontSize: isCompact ? 32 : 36),
                ),
                SizedBox(height: verticalGap),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      weather['sinhala'],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? weather['color'] : Colors.grey[800],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: englishGap),
                Flexible(
                  child: Text(
                    weather['english'],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: isCompact ? 11 : 12,
                      color: isSelected
                          ? weather['color'].withOpacity(0.8)
                          : Colors.grey[600],
                    ),
                  ),
                ),
                if (isSelected)
                  Padding(
                    padding: EdgeInsets.only(top: isCompact ? 6 : 8),
                    child: Icon(
                      Icons.check_circle,
                      color: weather['color'],
                      size: isCompact ? 18 : 20,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildWeatherDetails(String weatherKey) {
    final weather = _weatherOptions[weatherKey]!;
    
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: weather['color'].withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: weather['color'].withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                weather['emoji'],
                style: TextStyle(fontSize: 24),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      weather['sinhala'],
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: weather['color'],
                      ),
                    ),
                    Text(
                      weather['english'],
                      style: TextStyle(
                        fontSize: 14,
                        color: weather['color'].withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          SizedBox(height: 12),
          
          // Short description
          Text(
            'විස්තරය: ${weather['description']}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[800],
            ),
          ),
          
          SizedBox(height: 8),
          
          // Full description in Sinhala
          Text(
            weather['fullDescription'],
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
              fontStyle: FontStyle.italic,
            ),
          ),
          
          SizedBox(height: 12),
          
          // Therapeutic message based on weather
          _getWeatherMessage(weatherKey),
        ],
      ),
    );
  }
  
  Widget _getWeatherMessage(String weatherKey) {
    final messages = {
      'sunny': '''
☀️ සූර්යාලෝකය යනු ආශාව සහ බලාපොරොත්තුවේ සංකේතයකි.
මෙම මොහොතේ ඔබේ සතුට අනුභව කරන්න.
''',
      'rainy': '''
🌧️ වර්ෂාව ස්වභාවධර්මයේ පිරිසිදු කිරීමේ ක්‍රියාවලියකි.
සෑම කඳුළක්ම හදවත පිරිසිදු කරයි.
''',
      'stormy': '''
⛈️ කුණාටු සෑම විටම සාමය ගෙන එයි.
මෙම බලවත් ශක්තිය ඔබේ අභ්‍යන්තර ශක්තිය පිළිබිඹු කරයි.
''',
      'foggy': '''
🌫️ මීදුම යනු අවකාශයකි - ඔබේම කාලය සහ සිතිවිලි සඳහා.
මෙම මොහොතේ සන්සුන්ව සිටින්න.
''',
    };
    
    return Text(
      messages[weatherKey] ?? '',
      style: TextStyle(
        fontSize: 12,
        color: Colors.grey[600],
        height: 1.4,
      ),
    );
  }
}
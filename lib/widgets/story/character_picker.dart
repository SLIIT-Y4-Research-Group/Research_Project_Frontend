import 'package:flutter/material.dart';

class CharacterPicker extends StatefulWidget {
  final Function(String) onCharacterSelected;
  final String? initialCharacter;
  final bool showDescriptions;
  
  const CharacterPicker({
    Key? key,
    required this.onCharacterSelected,
    this.initialCharacter,
    this.showDescriptions = true,
  }) : super(key: key);
  
  @override
  _CharacterPickerState createState() => _CharacterPickerState();
}

class _CharacterPickerState extends State<CharacterPicker> {
  String? _selectedCharacter;
  
  // Character data with Sinhala folk tale references
  final Map<String, Map<String, dynamic>> _characterOptions = {
    'hare': {
      'sinhala': 'කුරුල්ලා',
      'english': 'The Hare',
      'emoji': '🐇',
      'color': Colors.brown,
      'description': 'Worried but clever',
      'fullDescription': 'බුද්ධිමත් නමුත් නිතර කලබල වන චරිතය',
      'storyHint': 'සිංහල ජනකතාවල කුරුල්ලා බුද්ධිමත් චරිතයකි',
      'strengths': ['බුද්ධිය', 'වේගය', 'ප්‍රතිභාවය'],
      'weaknesses': ['කලබල', 'අවිශ්වාසය', 'බිය'],
    },
    'lion': {
      'sinhala': 'සිංහයා',
      'english': 'The Lion',
      'emoji': '🦁',
      'color': Colors.orange,
      'description': 'Strong but lonely',
      'fullDescription': 'ශක්තිමත් නමුත් තනිකමින් පෙළෙන චරිතය',
      'storyHint': 'රජතුමා ලෙස හැඳින්වෙන සිංහයා ගෞරවනීය චරිතයකි',
      'strengths': ['ශක්තිය', 'නායකත්වය', 'සාරභූතභාවය'],
      'weaknesses': ['අභිමානය', 'තනිකම', 'පරිවරයන්ගෙන් ඈත්වීම'],
    },
    'elephant': {
      'sinhala': 'අලියා',
      'english': 'The Elephant',
      'emoji': '🐘',
      'color': Colors.grey,
      'description': 'Kind but carrying a heavy heart',
      'fullDescription': 'කරුණාවන්ත නමුත් බරින් පෙළෙන චරිතය',
      'storyHint': 'ජනකතාවල අලියා ඥානවන්ත හා ශක්තිමත් චරිතයකි',
      'strengths': ['කරුණාව', 'ඉවසීම', 'බුද්ධිය'],
      'weaknesses': ['මන්දගාමී බව', 'බර පැටවීම', 'විශාල අපේක්ෂා'],
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
        // Title
        Text(
          'ඔබ අද හැගෙන්නේ කුමන ප්‍රබන්ධ චරිතයක් වගේද?',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple[800],
          ),
        ),
        
        SizedBox(height: 8),
        
        // Subtitle
        Text(
          'සිංහල ජනකතා වලින් ඔබට ගැලපෙන චරිතය තෝරන්න',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        
        SizedBox(height: 20),
        
        // Character options list
        ListView.separated(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: _characterOptions.length,
          separatorBuilder: (context, index) => SizedBox(height: 16),
          itemBuilder: (context, index) {
            final characterKey = _characterOptions.keys.elementAt(index);
            final character = _characterOptions[characterKey]!;
            final isSelected = _selectedCharacter == characterKey;
            
            return _buildCharacterCard(
              characterKey: characterKey,
              character: character,
              isSelected: isSelected,
            );
          },
        ),
        
        SizedBox(height: 20),
        
        // Selected character details
        if (_selectedCharacter != null && widget.showDescriptions)
          _buildCharacterDetails(_selectedCharacter!),
      ],
    );
  }
  
  Widget _buildCharacterCard({
    required String characterKey,
    required Map<String, dynamic> character,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCharacter = characterKey;
        });
        widget.onCharacterSelected(characterKey);
      },
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? character['color'].withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? character['color'] : Colors.grey[200]!,
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
        child: Row(
          children: [
            // Character avatar/emoji
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: character['color'].withOpacity(0.2),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Center(
                child: Text(
                  character['emoji'],
                  style: TextStyle(fontSize: 32),
                ),
              ),
            ),
            
            SizedBox(width: 16),
            
            // Character info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    character['sinhala'],
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? character['color'] : Colors.grey[800],
                    ),
                  ),
                  
                  SizedBox(height: 4),
                  
                  // English name
                  Text(
                    character['english'],
                    style: TextStyle(
                      fontSize: 14,
                      color: isSelected ? character['color'].withOpacity(0.8) : Colors.grey[600],
                    ),
                  ),
                  
                  SizedBox(height: 8),
                  
                  // Description
                  Text(
                    character['description'],
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
            
            // Selection indicator
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: character['color'],
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCharacterDetails(String characterKey) {
    final character = _characterOptions[characterKey]!;
    
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: character['color'].withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: character['color'].withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with emoji and name
          Row(
            children: [
              Text(
                character['emoji'],
                style: TextStyle(fontSize: 32),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      character['sinhala'],
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: character['color'],
                      ),
                    ),
                    Text(
                      character['english'],
                      style: TextStyle(
                        fontSize: 16,
                        color: character['color'].withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          SizedBox(height: 16),
          
          // Full description
          Text(
            character['fullDescription'],
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[800],
              height: 1.5,
            ),
          ),
          
          SizedBox(height: 12),
          
          // Story hint
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber[100]!),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline, color: Colors.amber[700], size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    character['storyHint'],
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.amber[800],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 16),
          
          // Strengths and weaknesses
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Strengths
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ශක්තිමත් අංග',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.green[700],
                      ),
                    ),
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: character['strengths'].map<Widget>((strength) {
                        return Chip(
                          label: Text(
                            strength,
                            style: TextStyle(fontSize: 12),
                          ),
                          backgroundColor: Colors.green[50],
                          labelStyle: TextStyle(color: Colors.green[700]),
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              
              SizedBox(width: 16),
              
              // Weaknesses
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'දුර්වල අංග',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.red[700],
                      ),
                    ),
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: character['weaknesses'].map<Widget>((weakness) {
                        return Chip(
                          label: Text(
                            weakness,
                            style: TextStyle(fontSize: 12),
                          ),
                          backgroundColor: Colors.red[50],
                          labelStyle: TextStyle(color: Colors.red[700]),
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          SizedBox(height: 16),
          
          // Therapeutic message for character
          _getCharacterMessage(characterKey),
        ],
      ),
    );
  }
  
  Widget _getCharacterMessage(String characterKey) {
    final messages = {
      'hare': '''
🐇 කුරුල්ලාගේ කථාව ඔබට උපකාර කරයි:
• ඔබේ බුද්ධිය භාවිතා කරන්න
• කුඩා පියවරෙන් පියවර ගන්න
• ඔබේ බිය අවබෝධ කරගන්න
''',
      'lion': '''
🦁 සිංහයාගේ කථාව ඔබට උපකාර කරයි:
• ඔබේ ශක්තිය හඳුනාගන්න
• ඔබේ ගෞරවය පවත්වාගන්න
• සම්බන්ධතා ගොඩනගාගන්න
''',
      'elephant': '''
🐘 අලියාගේ කථාව ඔබට උපකාර කරයි:
• ඔබේ ඉවසීම භාවිතා කරන්න
• බර බෙදාගන්න
• කරුණාව සහ අවබෝධය ප්‍රකාශ කරන්න
''',
    };
    
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[100]!),
      ),
      child: Text(
        messages[characterKey] ?? '',
        style: TextStyle(
          fontSize: 12,
          color: Colors.blue[800],
          height: 1.4,
        ),
      ),
    );
  }
}
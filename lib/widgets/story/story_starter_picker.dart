import 'package:flutter/material.dart';

class StoryStarterPicker extends StatefulWidget {
  final Function(String?) onStarterSelected;
  final String? initialStarter;
  final bool showCustomField;
  
  const StoryStarterPicker({
    Key? key,
    required this.onStarterSelected,
    this.initialStarter,
    this.showCustomField = true,
  }) : super(key: key);
  
  @override
  _StoryStarterPickerState createState() => _StoryStarterPickerState();
}

class _StoryStarterPickerState extends State<StoryStarterPicker> {
  String? _selectedStarter;
  final TextEditingController _customController = TextEditingController();
  final List<String> _defaultStarters = [
    'අද දවස මට ගොඩක් දුක් වගේ...',
    'මම කිසිම විටක කථා කරන්න අවශ්‍ය නෑ...',
    'මගේ හිත තුල ගැබ් ගැනීමක් රැඳී සිටිනවා...',
    'අද මට හිතෙනවා සැනසිල්ලක් තියෙනවා කියලා...',
    'මම අද තරමක් ව්‍යාකූලව සිටිනවා...',
  ];
  
  @override
  void initState() {
    super.initState();
    _selectedStarter = widget.initialStarter;
    if (_selectedStarter != null && 
        !_defaultStarters.contains(_selectedStarter)) {
      _customController.text = _selectedStarter!;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
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
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _defaultStarters.map((starter) {
            final isSelected = _selectedStarter == starter;
            
            return ChoiceChip(
              label: Text(
                starter,
                style: TextStyle(
                  fontSize: 13,
                  color: isSelected ? Colors.white : Colors.grey[800],
                ),
              ),
              selected: isSelected,
              selectedColor: Colors.deepPurple,
              backgroundColor: Colors.grey[100],
              onSelected: (selected) {
                setState(() {
                  _selectedStarter = selected ? starter : null;
                  _customController.clear();
                });
                widget.onStarterSelected(_selectedStarter);
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            );
          }).toList(),
        ),
        
        SizedBox(height: 20),
        
        // Custom starter input
        if (widget.showCustomField) ...[
          TextField(
            controller: _customController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'ඔබේම වාක්‍යයක් ලියන්න',
              hintText: 'ඔබේම වාක්‍ය ඛණ්ඩය ඇතුලත් කරන්න...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.grey[50],
              contentPadding: EdgeInsets.all(12),
            ),
            onChanged: (value) {
              if (value.isNotEmpty) {
                setState(() {
                  _selectedStarter = value;
                });
                widget.onStarterSelected(value);
              }
            },
          ),
          SizedBox(height: 10),
        ],
        
        // None option
        ListTile(
          leading: Radio<String?>(
            value: null,
            groupValue: _selectedStarter,
            onChanged: (value) {
              setState(() {
                _selectedStarter = value;
                _customController.clear();
              });
              widget.onStarterSelected(null);
            },
          ),
          title: Text(
            'කිසිදු වාක්‍ය ඛණ්ඩයක් අවශ්‍ය නැත',
            style: TextStyle(color: Colors.grey[700]),
          ),
          dense: true,
        ),
      ],
    );
  }
  
  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }
}
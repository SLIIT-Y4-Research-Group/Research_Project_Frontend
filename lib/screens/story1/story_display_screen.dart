import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/story/api_service.dart';
import '../../models/story/story_model.dart';
import '../../models/story/mood_model.dart';
import '../../services/story/local_story_storage.dart';

class StoryDisplayScreen extends StatefulWidget {
  final Story story;
  final bool isNewStory;
  
  const StoryDisplayScreen({
    Key? key,
    required this.story,
    this.isNewStory = false,
  }) : super(key: key);
  
  @override
  _StoryDisplayScreenState createState() => _StoryDisplayScreenState();
}

class _StoryDisplayScreenState extends State<StoryDisplayScreen> {
  final ApiService _apiService = ApiService();
  bool _isLiked = false;
  bool _isSaved = false;
  bool _isFullContent = false;
  
  @override
  void initState() {
    super.initState();
    if (!widget.isNewStory) {
      _incrementViews();
    }
    _checkIfLiked();
  }
  
  Future<void> _incrementViews() async {
    try {
      // In a real app, you would have an endpoint to increment views
      // For now, we'll just update locally
      final updatedStory = widget.story.copyWith(
        viewCount: widget.story.viewCount + 1,
      );
      
      // Update in backend
      await _apiService.updateStory(updatedStory);
    } catch (e) {
      print('Failed to increment views: $e');
    }
  }
  
  Future<void> _checkIfLiked() async {
    // In a real app, check from user's liked stories
    // For now, using local state
    setState(() {
      _isLiked = widget.story.likeCount > 0;
    });
  }
  
  Future<void> _toggleLike() async {
    try {
      final newLikeCount = _isLiked 
          ? widget.story.likeCount - 1
          : widget.story.likeCount + 1;
      
      final updatedStory = widget.story.copyWith(
        likeCount: newLikeCount,
      );
      
      final response = await _apiService.updateStory(updatedStory);
      
      if (response.success) {
        setState(() {
          _isLiked = !_isLiked;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isLiked ? 'කථාව ලයික් කරන ලදී' : 'ලයික් ඉවත් කරන ලදී'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('දෝෂයක් ඇතිවිය: $e')),
      );
    }
  }
  
  Future<void> _shareStory() async {
    // In a real app, use share plugin
    final shareText = '${widget.story.title}\n\n${widget.story.content}\n\n#StoryGen';
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('කථාව පිටපත් කරන ලදී'),
        action: SnackBarAction(
          label: 'පෙන්වන්න',
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('පිටපත් කරන ලද තොගය'),
                content: SelectableText(shareText),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('හරි'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
  
  Future<void> _saveToLocal() async {
  try {
    await LocalStoryStorage.saveStory(widget.story);

    setState(() {
      _isSaved = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('කථාව සුරකින ලදී')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('දෝෂයක් ඇතිවිය: $e')),
    );
  }
}
  
  Future<void> _togglePublic() async {
    try {
      final updatedStory = widget.story.copyWith(
        isPublic: !widget.story.isPublic,
      );
      
      final response = await _apiService.updateStory(updatedStory);
      
      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              updatedStory.isPublic 
                ? 'කථාව පොදු කරන ලදී'
                : 'කථාව පෞද්ගලික කරන ලදී'
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('දෝෂයක් ඇතිවිය: $e')),
      );
    }
  }
  
  String _formatDate(DateTime date) {
    final months = [
      'ජනවාරි', 'පෙබරවාරි', 'මාර්තු', 'අප්‍රේල්', 'මැයි', 'ජුනි',
      'ජූලි', 'අගෝස්තු', 'සැප්තැම්බර්', 'ඔක්තෝබර්', 'නොවැම්බර්', 'දෙසැම්බර්'
    ];
    
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
  
  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('කථාව'),
        actions: [
          IconButton(
            icon: Icon(_isLiked ? Icons.favorite : Icons.favorite_border),
            onPressed: _toggleLike,
            color: _isLiked ? Colors.red : null,
            tooltip: _isLiked ? 'ලයික් ඉවත් කරන්න' : 'ලයික් කරන්න',
          ),
          IconButton(
            icon: Icon(Icons.share),
            onPressed: _shareStory,
            tooltip: 'බෙදාගන්න',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'save') _saveToLocal();
              if (value == 'copy') _shareStory();
              if (value == 'public') _togglePublic();
              if (value == 'regenerate') {
                // Navigate back to mood input with same profile
                Navigator.pop(context);
                // In real app, trigger regeneration
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'save',
                child: Row(
                  children: [
                    Icon(Icons.save, size: 20),
                    SizedBox(width: 8),
                    Text('සුරකින්න'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'copy',
                child: Row(
                  children: [
                    Icon(Icons.copy, size: 20),
                    SizedBox(width: 8),
                    Text('පිටපත් කරන්න'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'public',
                child: Row(
                  children: [
                    Icon(
                      widget.story.isPublic ? Icons.lock : Icons.public,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(widget.story.isPublic ? 'පෞද්ගලික කරන්න' : 'පොදු කරන්න'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'regenerate',
                child: Row(
                  children: [
                    Icon(Icons.autorenew, size: 20),
                    SizedBox(width: 8),
                    Text('නැවත නිර්මාණය කරන්න'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Story title and metadata
            Card(
              elevation: 2,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.story.title,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple[800],
                      ),
                    ),
                    SizedBox(height: 12),
                    
                    // Mood indicators
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(
                          label: Text(widget.story.moodProfile.moodSinhala),
                          backgroundColor: widget.story.moodProfile.moodColor.withOpacity(0.2),
                          avatar: CircleAvatar(
                            backgroundColor: widget.story.moodProfile.moodColor,
                            radius: 10,
                            child: Icon(
                              Icons.mood,
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Chip(
                          label: Text(widget.story.moodProfile.weatherSinhala),
                          backgroundColor: Colors.blue[50],
                          avatar: CircleAvatar(
                            backgroundColor: Colors.blue,
                            radius: 10,
                            child: Icon(
                              Icons.cloud,
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Chip(
                          label: Text(widget.story.moodProfile.characterSinhala),
                          backgroundColor: Colors.orange[50],
                          avatar: CircleAvatar(
                            backgroundColor: Colors.orange,
                            radius: 10,
                            child: Icon(
                              Icons.person,
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 16),
                    
                    // Story stats and metadata
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 16, color: Colors.grey),
                        SizedBox(width: 4),
                        Text(
                          widget.story.readingTime,
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                        SizedBox(width: 16),
                        // Icon(Icons.remove_red_eye, size: 16, color: Colors.grey),
                        // SizedBox(width: 4),
                        // Text(
                        //   '${widget.story.viewCount} නරඹීම්',
                        //   style: TextStyle(color: Colors.grey, fontSize: 14),
                        // ),
                        // SizedBox(width: 16),
                        // Icon(Icons.favorite, size: 16, color: Colors.grey),
                        // SizedBox(width: 4),
                        // Text(
                        //   '${widget.story.likeCount} ලයික්',
                        //   style: TextStyle(color: Colors.grey, fontSize: 14),
                        // ),
                        // if (!widget.story.isPublic) ...[
                        //   SizedBox(width: 16),
                        //   Icon(Icons.lock, size: 16, color: Colors.grey),
                        //   SizedBox(width: 4),
                        //   Text(
                        //     'පෞද්ගලික',
                        //     style: TextStyle(color: Colors.grey, fontSize: 14),
                        //   ),
                        // ],
                      ],
                    ),
                    
                    SizedBox(height: 8),
                    
                    // Date and time
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                        SizedBox(width: 4),
                        Text(
                          'ලියන ලද්දේ: ${_formatDate(widget.story.createdAt)}',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                        SizedBox(width: 12),
                        Icon(Icons.schedule, size: 14, color: Colors.grey),
                        SizedBox(width: 4),
                        Text(
                          _formatTime(widget.story.createdAt),
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                    
                    // Starter sentence if available
                    if (widget.story.moodProfile.starterSentence != null &&
                        widget.story.moodProfile.starterSentence!.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: Text(
                          'කථා ආරම්භය: "${widget.story.moodProfile.starterSentence}"',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 24),
            
            // Story content
            Card(
              elevation: 1,
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'කථාව',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple[700],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            _isFullContent 
                              ? Icons.unfold_less 
                              : Icons.unfold_more,
                          ),
                          onPressed: () {
                            setState(() {
                              _isFullContent = !_isFullContent;
                            });
                          },
                          tooltip: _isFullContent ? 'කෙටි කරන්න' : 'සම්පූර්ණයෙන්',
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Text(
                      _isFullContent 
                        ? widget.story.content
                        : (widget.story.content.length > 500
                            ? '${widget.story.content.substring(0, 500)}...'
                            : widget.story.content),
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.6,
                        color: Colors.grey[800],
                      ),
                      textAlign: TextAlign.justify,
                    ),
                    
                    if (!_isFullContent && widget.story.content.length > 500)
                      Center(
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              _isFullContent = true;
                            });
                          },
                          child: Text('සම්පූර්ණ කථාව කියවන්න'),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 24),
            
            // Tags
            // if (widget.story.tags.isNotEmpty) ...[
            //   Text(
            //     'ටැග්',
            //     style: TextStyle(
            //       fontSize: 16,
            //       fontWeight: FontWeight.bold,
            //       color: Colors.grey[800],
            //     ),
            //   ),
            //   SizedBox(height: 8),
            //   Wrap(
            //     spacing: 8,
            //     runSpacing: 8,
            //     children: widget.story.tags.map((tag) {
            //       return Chip(
            //         label: Text(tag),
            //         backgroundColor: Colors.grey[100],
            //         labelStyle: TextStyle(fontSize: 12),
            //       );
            //     }).toList(),
            //   ),
            //   SizedBox(height: 24),
            // ],
            
            // Therapeutic message
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.psychology, color: Colors.blue[700]),
                        SizedBox(width: 8),
                        Text(
                          'හැඟීම් පණිවිඩය',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text(
                      _getTherapeuticMessage(widget.story.moodProfile.mood),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue[800],
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 32),
          ],
        ),
      ),
      
      // Action buttons
      bottomNavigationBar: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(color: Colors.deepPurple),
                ),
                child: Text(
                  'ආපසු',
                  style: TextStyle(color: Colors.deepPurple),
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  // Generate new story with same mood profile
                  Navigator.pop(context);
                  // In real app, you would navigate to mood input with this profile
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text('නැවත නිර්මාණය කරන්න'),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  String _getTherapeuticMessage(String mood) {
    final messages = {
      'sad': '''
සෑම කඳුළු බිංදුවක්ම ඔබේ හදවතේ ශක්තිය පෙන්වයි. 
දුක සමඟ පැමිණෙන්නේ ඔබේ ශක්තිමත් බවට සාක්ෂියක් වශයෙනි. 
මෙම කතාව ඔබේ හැඟීම් වල අගය පිළිගන්නා අයුරින් නිර්මාණය කර ඇත.
''',
      'anxious': '''
කලබලය ස්වභාවිකය. එය ඔබේ සැලකිල්ල පෙන්වන ආකාරයකි. 
මෙම මොහොතේ ශ්වසනයට අවකාශය දෙන්න. 
සෑම අභියෝගයක්ම ඔබව ශක්තිමත් කරන අවස්ථාවකි.
''',
      'empty': '''
හිස්කම අවකාශයක්. මෙම අවකාශය නව දේවල් සඳහා සුදුසු ය. 
ඔබගේම කාලය ගත කිරීම අත්‍යවශ්‍ය වේ. 
මෙම කතාව ඔබේ අභ්‍යන්තර ලෝකය සොයා යාමට උපකාරී වේවා.
''',
      'calm': '''
සන්සුන් බව අභ්‍යන්තර ශක්තියකි. 
මෙම සමත්වය ඔබේ අභ්‍යන්තර සමබරතාව පිළිබිඹු කරයි. 
මෙම මොහොතේ සාමය අනුභව කරන්න.
''',
      'happy': '''
සතුට බෙදාගන්න. ඔබේ ආනන්දය අන් අයට ද ආශිර්වාදයක් වේවා. 
මෙම ධනාත්මක ශක්තිය ඔබේ සම්පූර්ණ දිනය ආලෝකමත් කරයි.
''',
      'angry': '''
කෝපය යනු වෙනස්කම් සඳහා බලවත් ශක්තියකි. 
එය නිසි ආකාරයෙන් යොමු කරන විට ධනාත්මක වෙනසක් ගෙන එයි. 
මෙම කතාව ඔබේ ශක්තිය ගොඩනැගීමට උපකාරී වේවා.
''',
      'confused': '''
ව්‍යාකූලතාව යනු ඉගෙනීමේ අවස්ථාවකි. 
සෑම ප්‍රශ්නයක්ම නව අවබෝධයකට මග පාදයි. 
මෙම කතාව ඔබේ ගමනට මගපෙන්වීමක් වේවා.
''',
      'hopeful': '''
බලාපොරොත්තුව යනු අනාගතයට දීප්තිමත් දෘෂ්ටියකි. 
සෑම නව උදෑසනක්ම නව අවස්ථාවක් ගෙන එයි. 
මෙම කතාව ඔබේ බලාපොරොත්තු සත්‍ය කිරීමට උපකාරී වේවා.
''',
    };
    
    return messages[mood] ?? 'මෙම කතාව ඔබේ හැඟීම් වලට ගැලපෙන පරිදි නිර්මාණය කර ඇත.';
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../services/story/api_service.dart';
import '../../models/story/story_model.dart';
import '../../models/story/mood_model.dart';

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
  late FlutterTts _flutterTts;
  
  bool _isLiked = false;
  bool _isSaved = false;
  bool _isFullContent = false;
  
  // Text-to-speech variables
  bool _isSpeaking = false;
  bool _isPaused = false;
  double _speechSpeed = 0.5; // Slower speed for children
  double _speechPitch = 1.0;
  bool _ttsInitialized = false;
  
  @override
  void initState() {
    super.initState();
    _initTts();
    if (!widget.isNewStory) {
      _incrementViews();
    }
    _checkIfLiked();
  }
  
  Future<void> _initTts() async {
    try {
      _flutterTts = FlutterTts();
      
      // Set up completion handler
      _flutterTts.setCompletionHandler(() {
        if (mounted) {
          setState(() {
            _isSpeaking = false;
            _isPaused = false;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('කථාව කියවීම අවසන්'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      });
      
      // Set up error handler
      _flutterTts.setErrorHandler((msg) {
        if (mounted) {
          setState(() {
            _isSpeaking = false;
            _isPaused = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('කථනයේ දෝෂයකි: $msg')),
          );
        }
      });
      
      // Set up pause handler
      _flutterTts.setPauseHandler(() {
        if (mounted) {
          setState(() {
            _isPaused = true;
          });
        }
      });
      
      // Set up continue handler
      _flutterTts.setContinueHandler(() {
        if (mounted) {
          setState(() {
            _isPaused = false;
          });
        }
      });
      
      // Set initial parameters for children
      await _flutterTts.setLanguage("si-LK");
      await _flutterTts.setSpeechRate(_speechSpeed);
      await _flutterTts.setPitch(_speechPitch);
      
      setState(() {
        _ttsInitialized = true;
      });
      
    } catch (e) {
      print("TTS initialization error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('කථන පද්ධතිය ආරම්භ කිරීමට නොහැකි විය')),
        );
      }
    }
  }
  
  Future<void> _speak() async {
    if (!_ttsInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('කථන පද්ධතිය සූදානම් නැත')),
      );
      return;
    }
    
    try {
      if (_isSpeaking) {
        if (_isPaused) {
          // Resume if paused
          await _flutterTts.speak(_getStoryTextForTTS());
          if (mounted) {
            setState(() {
              _isPaused = false;
            });
          }
        } else {
          // Pause if speaking
          await _flutterTts.pause();
          if (mounted) {
            setState(() {
              _isPaused = true;
            });
          }
        }
      } else {
        // Start speaking
        String text = _getStoryTextForTTS();
        if (text.isNotEmpty) {
          var result = await _flutterTts.speak(text);
          // Check if result is not null and equals 1 (success)
          if (result == 1) {
            if (mounted) {
              setState(() {
                _isSpeaking = true;
                _isPaused = false;
              });
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('කථාව කියවීම ආරම්භ කර ඇත...'),
                  duration: Duration(seconds: 2),
                ),
              );
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('කථනය ආරම්භ කිරීමට නොහැකි විය')),
              );
            }
          }
        }
      }
    } catch (e) {
      print("TTS speak error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('කථනයේ දෝෂයකි')),
        );
        setState(() {
          _isSpeaking = false;
          _isPaused = false;
        });
      }
    }
  }
  
  Future<void> _stopSpeaking() async {
    try {
      await _flutterTts.stop();
      if (mounted) {
        setState(() {
          _isSpeaking = false;
          _isPaused = false;
        });
      }
    } catch (e) {
      print("TTS stop error: $e");
    }
  }
  
  String _getStoryTextForTTS() {
    try {
      String content = _isFullContent 
          ? widget.story.content
          : (widget.story.content.length > 500 
              ? '${widget.story.content.substring(0, 500)}...' 
              : widget.story.content);
      
      // Clean up text for better TTS
      content = content
          .replaceAll('\n', ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      
      String therapeuticMsg = _getTherapeuticMessage(widget.story.moodProfile.mood)
          .replaceAll('\n', ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      
      return '${widget.story.title}. $content. හැඟීම් පණිවිඩය: $therapeuticMsg';
    } catch (e) {
      print("Error preparing TTS text: $e");
      return widget.story.title; // Return at least the title
    }
  }
  
  Future<void> _adjustSpeed(bool increase) async {
    if (!_ttsInitialized) return;
    
    setState(() {
      if (increase && _speechSpeed < 1.0) {
        _speechSpeed += 0.1;
      } else if (!increase && _speechSpeed > 0.3) {
        _speechSpeed -= 0.1;
      }
    });
    
    try {
      await _flutterTts.setSpeechRate(_speechSpeed);
      
      // If currently speaking, restart with new speed
      if (_isSpeaking && !_isPaused) {
        await _stopSpeaking();
        await Future.delayed(Duration(milliseconds: 100));
        await _speak();
      }
    } catch (e) {
      print("Error adjusting speed: $e");
    }
  }
  
  Future<void> _incrementViews() async {
    try {
      final updatedStory = widget.story.copyWith(
        viewCount: widget.story.viewCount + 1,
      );
      await _apiService.updateStory(updatedStory);
    } catch (e) {
      print('Failed to increment views: $e');
    }
  }
  
  Future<void> _checkIfLiked() async {
    if (mounted) {
      setState(() {
        _isLiked = widget.story.likeCount > 0;
      });
    }
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
      
      if (response.success && mounted) {
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('දෝෂයක් ඇතිවිය: $e')),
        );
      }
    }
  }
  
  Future<void> _shareStory() async {
    final shareText = '${widget.story.title}\n\n${widget.story.content}\n\n#StoryGen';
    
    if (mounted) {
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
  }
  
  Future<void> _saveToLocal() async {
    setState(() {
      _isSaved = true;
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('කථාව සුරකින ලදී')),
      );
    }
  }
  
  Future<void> _togglePublic() async {
    try {
      final updatedStory = widget.story.copyWith(
        isPublic: !widget.story.isPublic,
      );
      
      final response = await _apiService.updateStory(updatedStory);
      
      if (response.success && mounted) {
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('දෝෂයක් ඇතිවිය: $e')),
        );
      }
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
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('කථාව'),
        actions: [
          // Text-to-speech button
          IconButton(
            icon: Icon(
              _isSpeaking 
                ? (_isPaused ? Icons.play_arrow : Icons.pause)
                : Icons.volume_up,
              color: _isSpeaking ? Colors.blue : null,
            ),
            onPressed: _ttsInitialized ? _speak : null,
            tooltip: _isSpeaking 
              ? (_isPaused ? 'නැවත ආරම්භ කරන්න' : 'විරාම කරන්න')
              : 'කථාව කියවන්න',
          ),
          
          // Stop button (only visible when speaking)
          if (_isSpeaking)
            IconButton(
              icon: Icon(Icons.stop, color: Colors.red),
              onPressed: _stopSpeaking,
              tooltip: 'නවත්වන්න',
            ),
          
          // Speed control (only visible when speaking)
          if (_isSpeaking && _ttsInitialized)
            PopupMenuButton<String>(
              icon: Icon(Icons.speed),
              tooltip: 'කියවීමේ වේගය',
              onSelected: (value) {
                if (value == 'slower') _adjustSpeed(false);
                if (value == 'faster') _adjustSpeed(true);
                if (value == 'reset') {
                  setState(() => _speechSpeed = 0.5);
                  _flutterTts.setSpeechRate(0.5);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'slower',
                  child: Row(
                    children: [
                      Icon(Icons.slow_motion_video, size: 20),
                      SizedBox(width: 8),
                      Text('මන්දගාමී කරන්න'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'faster',
                  child: Row(
                    children: [
                      Icon(Icons.fast_forward, size: 20),
                      SizedBox(width: 8),
                      Text('වේගවත් කරන්න'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'reset',
                  child: Row(
                    children: [
                      Icon(Icons.restore, size: 20),
                      SizedBox(width: 8),
                      Text('සාමාන්‍ය වේගය'),
                    ],
                  ),
                ),
              ],
            ),
          
          // Like button
          IconButton(
            icon: Icon(_isLiked ? Icons.favorite : Icons.favorite_border),
            onPressed: _toggleLike,
            color: _isLiked ? Colors.red : null,
            tooltip: _isLiked ? 'ලයික් ඉවත් කරන්න' : 'ලයික් කරන්න',
          ),
          
          // Share button
          IconButton(
            icon: Icon(Icons.share),
            onPressed: _shareStory,
            tooltip: 'බෙදාගන්න',
          ),
          
          // More options menu
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'save') _saveToLocal();
              if (value == 'copy') _shareStory();
              if (value == 'public') _togglePublic();
              if (value == 'regenerate') {
                _stopSpeaking();
                Navigator.pop(context);
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
            // TTS Controller Bar (visible when speaking)
            if (_isSpeaking && _ttsInitialized)
              Container(
                margin: EdgeInsets.only(bottom: 16),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isPaused ? Icons.play_circle_filled : Icons.pause_circle_filled,
                          color: Colors.blue[700],
                          size: 28,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isPaused ? 'විරාම කර ඇත' : 'කථාව කියවනවා...',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[800],
                                ),
                              ),
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.speed, size: 16, color: Colors.blue[600]),
                                  SizedBox(width: 4),
                                  Text(
                                    'වේගය: ${(_speechSpeed * 100).toInt()}%',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue[700],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.remove_circle_outline),
                              onPressed: () => _adjustSpeed(false),
                              color: Colors.blue[700],
                              iconSize: 20,
                              tooltip: 'මන්දගාමී කරන්න',
                            ),
                            IconButton(
                              icon: Icon(Icons.add_circle_outline),
                              onPressed: () => _adjustSpeed(true),
                              color: Colors.blue[700],
                              iconSize: 20,
                              tooltip: 'වේගවත් කරන්න',
                            ),
                            IconButton(
                              icon: Icon(Icons.stop_circle_outlined),
                              onPressed: _stopSpeaking,
                              color: Colors.red[400],
                              iconSize: 24,
                              tooltip: 'නවත්වන්න',
                            ),
                          ],
                        ),
                      ],
                    ),
                    // Speed indicator
                    if (!_isPaused)
                      Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: LinearProgressIndicator(
                          value: _speechSpeed,
                          backgroundColor: Colors.blue[100],
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[700]!),
                        ),
                      ),
                  ],
                ),
              ),
            
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
                    
                    // Date and time
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                        SizedBox(width: 4),
                        Text(
                          '${_formatDate(widget.story.createdAt)}',
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
                    
                    // Reading time
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 14, color: Colors.grey),
                        SizedBox(width: 4),
                        Text(
                          'කියවීමට ගතවන කාලය: ${widget.story.readingTime}',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                    
                    // Starter sentence if available
                    if (widget.story.moodProfile.starterSentence != null &&
                        widget.story.moodProfile.starterSentence!.isNotEmpty)
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
                              Icon(Icons.auto_stories, size: 16, color: Colors.amber[800]),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '"${widget.story.moodProfile.starterSentence}"',
                                  style: TextStyle(
                                    fontStyle: FontStyle.italic,
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
                            
                            // If speaking, restart TTS with new content length
                            if (_isSpeaking && !_isPaused) {
                              _stopSpeaking();
                              Future.delayed(Duration(milliseconds: 100), () {
                                _speak();
                              });
                            }
                          },
                          tooltip: _isFullContent ? 'කෙටි කරන්න' : 'සම්පූර්ණයෙන්',
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    
                    // Story text with highlight when TTS is active
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _isSpeaking ? Colors.blue[50] : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: _isSpeaking ? Border.all(color: Colors.blue[200]!) : null,
                      ),
                      child: Text(
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
                    
                    // Quick TTS button for therapeutic message
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: _ttsInitialized ? () async {
                          await _stopSpeaking();
                          await Future.delayed(Duration(milliseconds: 100));
                          await _flutterTts.speak(
                            _getTherapeuticMessage(widget.story.moodProfile.mood)
                          );
                        } : null,
                        icon: Icon(Icons.volume_up, size: 16),
                        label: Text('මෙය කියවන්න'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.blue[700],
                        ),
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
                  _stopSpeaking();
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
                  _stopSpeaking();
                  Navigator.pop(context);
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
    final Map<String, String> messages = {
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
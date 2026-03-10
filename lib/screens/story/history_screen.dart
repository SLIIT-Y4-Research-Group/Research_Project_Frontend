import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/story/api_service.dart';
import '../../models/story/story_model.dart';
import 'story_display_screen.dart';
import '../../services/story/local_story_storage.dart';
import '../../models/story/story_model.dart';
import '../../widgets/story/mood_wheel.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);
  
  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final ApiService _apiService = ApiService();
  List<Story> _stories = [];
  bool _isLoading = true;
  String _filter = 'all'; // 'all', 'favorites', 'public', 'private'
  String _sortBy = 'newest'; // 'newest', 'oldest', 'title'
  String _userId = 'test_user_123'; // Replace with actual user ID
  List<Story> _localStories = [];

  @override
  void initState() {
    super.initState();
    _loadStories();
  }
  
  Future<void> _loadStories() async {
  setState(() {
    _isLoading = true;
  });

  try {
    // Load remote stories
    final response = await _apiService.getUserStories(_userId);
    List<Story> remoteStories = [];
    if (response.success && response.data != null) {
      remoteStories = response.data!;
    }

    // Load local stories
    _localStories = await LocalStoryStorage.getStories();

    // Merge both lists (optional: remove duplicates based on id)
    List<Story> mergedStories = [
      ..._localStories,
      ...remoteStories.where((r) => !_localStories.any((l) => l.id == r.id)),
    ];

    setState(() {
      _stories = mergedStories;
      _isLoading = false;
    });
  } catch (e) {
    setState(() {
      _isLoading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error loading stories: $e')),
    );
  }
}
  
  List<Story> _getFilteredStories() {
    List<Story> filtered = List.from(_stories);
    
    // Apply filter
    switch (_filter) {
      case 'favorites':
        // In real app, check favorites list
        filtered = filtered.where((story) => story.likeCount > 0).toList();
        break;
      case 'public':
        filtered = filtered.where((story) => story.isPublic).toList();
        break;
      case 'private':
        filtered = filtered.where((story) => !story.isPublic).toList();
        break;
      default: // 'all'
        break;
    }
    
    // Apply sorting
    switch (_sortBy) {
      case 'oldest':
        filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'title':
        filtered.sort((a, b) => a.title.compareTo(b.title));
        break;
      default: // 'newest'
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }
    
    return filtered;
  }
  
  Future<void> _deleteStory(Story story) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('කථාව මකන්න'),
      content: Text('ඔබට මෙම කථාව මැකීමට අවශ්‍යද? මෙම ක්‍රියාව අහෝසි කළ නොහැක.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('අවලංගු කරන්න'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text('මකන්න', style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );

  if (confirmed != true) return;

  bool deletedFromServer = false;
  bool deletedFromLocal = false;

  try {
    // Delete from server if it has an ID
    if (story.id != null && story.id!.isNotEmpty) {
      final response = await _apiService.deleteStory(story.id!);
      deletedFromServer = response.success;
    }

    // Delete from local storage
    _localStories.removeWhere((s) => s.id == story.id || s.title == story.title);
    await LocalStoryStorage.clearStories(); // clear all
    for (var s in _localStories) {
      await LocalStoryStorage.saveStory(s); // re-save remaining
    }
    deletedFromLocal = true;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('කථාව මකා දමන ලදී')),
    );

    // Reload stories list
    _loadStories();

  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('දෝෂය මකාදැමීමේදී: $e')),
    );
  }
}
  
  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'පෙරහන',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            ...['all', 'public', 'private', 'favorites'].map((filter) {
              return ListTile(
                title: Text(_getFilterName(filter)),
                trailing: _filter == filter ? Icon(Icons.check, color: Colors.deepPurple) : null,
                onTap: () {
                  setState(() {
                    _filter = filter;
                  });
                  Navigator.pop(context);
                },
              );
            }).toList(),
            SizedBox(height: 20),
            Text(
              'වර්ග කරන්න',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            ...['newest', 'oldest', 'title'].map((sort) {
              return ListTile(
                title: Text(_getSortName(sort)),
                trailing: _sortBy == sort ? Icon(Icons.check, color: Colors.deepPurple) : null,
                onTap: () {
                  setState(() {
                    _sortBy = sort;
                  });
                  Navigator.pop(context);
                },
              );
            }).toList(),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
  
  String _getFilterName(String filter) {
    switch (filter) {
      case 'all': return 'සියලුම කථා';
      case 'public': return 'පොදු කථා';
      case 'private': return 'පෞද්ගලික කථා';
      case 'favorites': return 'ප්‍රියතම කථා';
      default: return filter;
    }
  }
  
  String _getSortName(String sort) {
    switch (sort) {
      case 'newest': return 'අලුත්ම';
      case 'oldest': return 'පැරණිම';
      case 'title': return 'නම අනුව';
      default: return sort;
    }
  }
  
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'අද';
    } else if (difference.inDays == 1) {
      return 'ඊයේ';
    } else if (difference.inDays < 7) {
      return 'දින ${difference.inDays} කට පෙර';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return 'සති $weeks කට පෙර';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final filteredStories = _getFilteredStories();
    
    return Scaffold(
      appBar: AppBar(
        title: Text('මගේ කථා'),
        backgroundColor: Color.fromARGB(255, 113, 212, 131),
        actions: [
          // IconButton(
          //   icon: Icon(Icons.filter_list),
          //   onPressed: _showFilterSheet,
          //   tooltip: 'පෙරහන',
          // ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadStories,
            tooltip: 'නැවත පූරණය කරන්න',
          ),
        ],
      ),
      body: Stack(
      children: [
        // Background image
        Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('images/storyHistory.jpg'), // Put your image path here
              fit: BoxFit.cover,
            ),
          ),
        ),

        // Content
        _isLoading
            ? Center(child: CircularProgressIndicator())
            : filteredStories.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.auto_stories,
                          size: 80,
                          color: const Color.fromARGB(255, 255, 255, 255),
                        ),
                        SizedBox(height: 20),
                        Text(
                          'කිසිදු කථාවක් නැත',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'පළමු කථාව නිර්මාණය කරන්න',
                          style: TextStyle(color: const Color.fromARGB(255, 255, 255, 255)),
                        ),
                        SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context); // Go back to home
                          },
                          child: Text('නව කථාවක්'),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadStories,
                    child: ListView.builder(
                      padding: EdgeInsets.all(8),
                      itemCount: filteredStories.length,
                      itemBuilder: (context, index) {
                        final story = filteredStories[index];
                        return _buildStoryCard(story);
                      },
                    ),
                  ),
      ],
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: () {
        Navigator.pop(context); // Go back to home to create new story
      },
      backgroundColor: Color.fromARGB(255, 255, 255, 255),
      child: Icon(Icons.add, color: Color.fromARGB(255, 113, 212, 131)),
    ),
  );
}
  
  Widget _buildStoryCard(Story story) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      elevation: 2,
      child: ListTile(
        contentPadding: EdgeInsets.all(12),
        leading: CircleAvatar(
          backgroundColor: story.moodProfile.moodColor.withOpacity(0.3),
          radius: 24,
          child: Text(
            story.moodProfile.moodSinhala.substring(0, 1),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: story.moodProfile.moodColor,
            ),
          ),
        ),
        title: Text(
          story.title,
          style: TextStyle(fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text(
              story.preview,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time, size: 12, color: Colors.grey),
                SizedBox(width: 4),
                Text(
                  story.readingTime,
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
                SizedBox(width: 12),
                Icon(Icons.calendar_today, size: 12, color: Colors.grey),
                SizedBox(width: 4),
                Text(
                  _formatDate(story.createdAt),
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
                if (!story.isPublic)
                  Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(Icons.lock, size: 12, color: Colors.grey),
                  ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'view') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StoryDisplayScreen(story: story),
                ),
              );
            } else if (value == 'edit') {
              // Implement edit functionality
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('සංස්කරණය කිරීම ඉදිරියේදී')),
              );
            } else if (value == 'delete') {
              _deleteStory(story);
            } else if (value == 'share') {
              // Implement share functionality
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('බෙදාගැනීම ඉදිරියේදී')),
              );
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'view',
              child: Row(
                children: [
                  Icon(Icons.visibility, size: 20),
                  SizedBox(width: 8),
                  Text('නැරඹීම'),
                ],
              ),
            ),
            // PopupMenuItem(
            //   value: 'edit',
            //   child: Row(
            //     children: [
            //       Icon(Icons.edit, size: 20),
            //       SizedBox(width: 8),
            //       Text('සංස්කරණය කරන්න'),
            //     ],
            //   ),
            // ),
            // PopupMenuItem(
            //   value: 'share',
            //   child: Row(
            //     children: [
            //       Icon(Icons.share, size: 20),
            //       SizedBox(width: 8),
            //       Text('බෙදාගන්න'),
            //     ],
            //   ),
            // ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('මකන්න', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StoryDisplayScreen(story: story),
            ),
          );
        },
      ),
    );
  }
}
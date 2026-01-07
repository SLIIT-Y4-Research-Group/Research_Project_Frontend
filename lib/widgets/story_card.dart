import 'package:flutter/material.dart';
import '../models/story_model.dart';

class StoryCard extends StatelessWidget {
  final Story story;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onShare;
  
  const StoryCard({
    Key? key,
    required this.story,
    this.onTap,
    this.onDelete,
    this.onShare,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Mood indicator
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: story.moodProfile.moodColor.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        _getMoodIcon(story.moodProfile.mood),
                        color: story.moodProfile.moodColor,
                        size: 20,
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  
                  // Title and metadata
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          story.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.access_time, size: 12, color: Colors.grey),
                            SizedBox(width: 4),
                            Text(
                              story.readingTime,
                              style: TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.calendar_today, size: 12, color: Colors.grey),
                            SizedBox(width: 4),
                            Text(
                              _formatDate(story.createdAt),
                              style: TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Action buttons
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, size: 20, color: Colors.grey),
                    onSelected: (value) {
                      if (value == 'delete' && onDelete != null) onDelete!();
                      if (value == 'share' && onShare != null) onShare!();
                    },
                    itemBuilder: (context) => [
                      if (onShare != null)
                        PopupMenuItem(
                          value: 'share',
                          child: Row(
                            children: [
                              Icon(Icons.share, size: 20),
                              SizedBox(width: 8),
                              Text('බෙදාගන්න'),
                            ],
                          ),
                        ),
                      if (onDelete != null)
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
                ],
              ),
              
              SizedBox(height: 12),
              
              // Story preview
              Text(
                story.preview,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              
              SizedBox(height: 12),
              
              // Tags and stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Wrap(
                    spacing: 6,
                    children: [
                      // Mood tag
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: story.moodProfile.moodColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          story.moodProfile.moodSinhala,
                          style: TextStyle(
                            fontSize: 11,
                            color: story.moodProfile.moodColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      
                      // Character tag
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          story.moodProfile.characterSinhala,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.orange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  // Stats
                  Row(
                    children: [
                      if (story.likeCount > 0) ...[
                        Icon(Icons.favorite, size: 14, color: Colors.red),
                        SizedBox(width: 2),
                        Text(
                          '${story.likeCount}',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        SizedBox(width: 8),
                      ],
                      if (story.viewCount > 0) ...[
                        Icon(Icons.remove_red_eye, size: 14, color: Colors.grey),
                        SizedBox(width: 2),
                        Text(
                          '${story.viewCount}',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  IconData _getMoodIcon(String mood) {
    switch (mood) {
      case 'happy': return Icons.sentiment_very_satisfied;
      case 'sad': return Icons.sentiment_very_dissatisfied;
      case 'calm': return Icons.sentiment_satisfied;
      case 'angry': return Icons.sentiment_very_dissatisfied;
      case 'anxious': return Icons.sentiment_dissatisfied;
      default: return Icons.sentiment_neutral;
    }
  }
  
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) return 'අද';
    if (difference.inDays == 1) return 'ඊයේ';
    if (difference.inDays < 7) return 'දින ${difference.inDays} කට පෙර';
    
    final months = ['ජන', 'පෙබ', 'මාර්', 'අප්‍රේ', 'මැයි', 'ජුනි', 'ජූලි', 'අගෝ', 'සැප්', 'ඔක්', 'නොවැ', 'දෙසැ'];
    return '${date.day} ${months[date.month - 1]}';
  }
}
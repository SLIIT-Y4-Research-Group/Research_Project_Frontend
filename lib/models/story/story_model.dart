import 'mood_model.dart';

class Story {
  final String? id;
  final String userId;
  final String title;
  final String content;
  final MoodProfile moodProfile;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> tags;
  final bool isPublic;
  final int likeCount;
  final int viewCount;
  final String? imageUrl;

  Story({
    this.id,
    required this.userId,
    required this.title,
    required this.content,
    required this.moodProfile,
    required this.createdAt,
    required this.updatedAt,
    this.tags = const [],
    this.isPublic = true,
    this.likeCount = 0,
    this.viewCount = 0,
    this.imageUrl,
  });

  // Convert to JSON for API request
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'title': title,
      'content': content,
      'mood_profile': moodProfile.toJson(),
      'tags': tags,
      'is_public': isPublic,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      if (imageUrl != null) 'image_url': imageUrl,
    };
  }

  // Convert from JSON for API response
  factory Story.fromJson(Map<String, dynamic> json) {
    return Story(
      id: json['_id'] ?? json['id'],
      userId: json['user_id'],
      title: json['title'],
      content: json['content'],
      moodProfile: MoodProfile.fromJson(json['mood_profile']),
      tags: List<String>.from(json['tags'] ?? []),
      isPublic: json['is_public'] ?? true,
      likeCount: json['like_count'] ?? 0,
      viewCount: json['view_count'] ?? 0,
      imageUrl: json['image_url'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  // Generate title based on mood
  String generateTitle() {
    return '${moodProfile.characterSinhala}ගේ ${moodProfile.moodSinhala} ගමන';
  }

  // Get reading time
  String get readingTime {
    final wordCount = content.split(' ').length;
    final minutes = (wordCount / 200).ceil();
    return '$minutes ${minutes == 1 ? 'මිනිත්තුව' : 'මිනිත්තු'}';
  }

  // Get preview text
  String get preview {
    if (content.length <= 150) return content;
    return '${content.substring(0, 150)}...';
  }

  Story copyWith({
    String? id,
    String? userId,
    String? title,
    String? content,
    MoodProfile? moodProfile,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? tags,
    bool? isPublic,
    int? likeCount,
    int? viewCount,
    String? imageUrl,
  }) {
    return Story(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      content: content ?? this.content,
      moodProfile: moodProfile ?? this.moodProfile,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tags: tags ?? this.tags,
      isPublic: isPublic ?? this.isPublic,
      likeCount: likeCount ?? this.likeCount,
      viewCount: viewCount ?? this.viewCount,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
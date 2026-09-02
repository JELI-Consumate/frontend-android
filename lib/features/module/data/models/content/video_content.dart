import 'package:flutter/foundation.dart';

@immutable
class VideoContent {
  const VideoContent({
    required this.id,
    required this.title,
    required this.description,
    required this.youtubeUrl,
    required this.youtubeVideoId,
    required this.promptQuestion,
  });

  final String id;
  final String title;
  final String? description;
  final String youtubeUrl;

  final String? youtubeVideoId;
  final String? promptQuestion;

  factory VideoContent.fromJson(Map<String, dynamic> json) {
    return VideoContent(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      youtubeUrl: json['youtube_url'] as String? ?? '',
      youtubeVideoId: json['youtube_video_id'] as String?,
      promptQuestion: json['prompt_question'] as String?,
    );
  }
}
